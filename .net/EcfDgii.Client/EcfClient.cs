using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using EcfDgii.Client.Generated;
using EcfDgii.Client.Generated.Models;
using Microsoft.Kiota.Http.HttpClientLibrary;

namespace EcfDgii.Client
{
    /// <summary>
    /// High-level client for the ECF DGII API.
    /// Provides both raw Kiota-generated endpoint access via <see cref="Api"/>
    /// and a simplified send-and-poll workflow via the typed <c>SendEcfAsync</c> overloads
    /// (one per e-CF type: 31, 32, 33, 34, 41, 43, 44, 45, 46, 47).
    /// </summary>
    public class EcfClient
    {
        private static readonly Dictionary<string, string> EnvironmentUrls = new Dictionary<string, string>
        {
            ["Test"] = "https://api.test.ecfx.ssd.com.do",
            ["Cert"] = "https://api.cert.ecfx.ssd.com.do",
            ["Prod"] = "https://api.prod.ecfx.ssd.com.do",
        };

        /// <summary>
        /// The underlying Kiota-generated API client for direct endpoint access.
        /// Use this for any raw API calls not covered by the high-level methods.
        /// </summary>
        public EcfApiClient Api { get; }

        /// <summary>
        /// Creates a new <see cref="EcfClient"/> with the specified options.
        /// </summary>
        public EcfClient(EcfClientOptions? options = null)
        {
            var opts = options ?? new EcfClientOptions();

            var apiKey = opts.ApiKey
                ?? Environment.GetEnvironmentVariable("ECF_API_KEY")
                ?? throw new InvalidOperationException(
                    "API key is required. Set EcfClientOptions.ApiKey or the ECF_API_KEY environment variable.");

            var baseUrl = opts.BaseUrl
                ?? Environment.GetEnvironmentVariable("ECF_API_URL")
                ?? EnvironmentUrls[opts.Environment.ToString()];

            var authProvider = new BearerTokenAuthProvider(apiKey);
            var adapter = new HttpClientRequestAdapter(authProvider)
            {
                BaseUrl = baseUrl
            };

            Api = new EcfApiClient(adapter);
        }

        /// <summary>
        /// Creates a restricted, read-only <see cref="EcfFrontendClient"/> for frontend use.
        /// The returned client only exposes GET endpoints — no mutations.
        /// Uses callback-based token management with automatic 401 retry.
        /// </summary>
        /// <param name="options">Frontend client configuration with token callbacks.</param>
        /// <returns>A new <see cref="EcfFrontendClient"/> instance.</returns>
        public static EcfFrontendClient CreateFrontendClient(EcfFrontendClientOptions options)
        {
            return new EcfFrontendClient(options);
        }

        // ---------------------------------------------------------------------------
        // ECF send + poll — Generic implementation with automatic routing
        // ---------------------------------------------------------------------------

        private static readonly Dictionary<string, string> RouteMap = new Dictionary<string, string>
        {
            ["FacturaDeCreditoFiscalElectronica"] = "31",
            ["FacturaDeConsumoElectronica"] = "32",
            ["NotaDeDebitoElectronica"] = "33",
            ["NotaDeCreditoElectronica"] = "34",
            ["ComprasElectronico"] = "41",
            ["GastosMenoresElectronico"] = "43",
            ["RegimenesEspecialesElectronico"] = "44",
            ["GubernamentalElectronico"] = "45",
            ["ComprobanteDeExportacionesElectronico"] = "46",
            ["ComprobanteParaPagosAlExteriorElectronico"] = "47",
        };

        /// <summary>
        /// Send an ECF and poll until processing completes.
        /// Determines the correct endpoint from <c>ecf.Encabezado.IdDoc.TipoeCF</c>,
        /// posts the ECF, then polls until <c>Progress</c> is <c>Finished</c> or <c>Error</c>.
        /// </summary>
        /// <typeparam name="T">The ECF model type (must implement IEcfDocument).</typeparam>
        /// <param name="ecf">The ECF document to send.</param>
        /// <param name="pollingOptions">Optional polling configuration.</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        /// <returns>The final <see cref="EcfResponse"/> after processing.</returns>
        public async Task<EcfResponse> SendEcfAsync<T>(T ecf, PollingOptions? pollingOptions = null, CancellationToken cancellationToken = default) where T : IEcfDocument
        {
            var doc = (IEcfDocument)ecf;
            var tipoeCF = doc.TipoeCF;

            if (string.IsNullOrEmpty(tipoeCF) || !RouteMap.TryGetValue(tipoeCF, out var route))
            {
                throw new ArgumentException($"Unknown or missing TipoeCF: {tipoeCF}. Ensure Encabezado.IdDoc.TipoeCF is set correctly.");
            }

            return await SendInternalAsync(
                doc.RncEmisor,
                doc.Encf,
                ct => PostToRouteAsync(route, ecf, ct),
                pollingOptions,
                cancellationToken).ConfigureAwait(false);
        }

        private Task<EcfResponse?> PostToRouteAsync<T>(string route, T body, CancellationToken ct)
        {
            return route switch
            {
                "31" => Api.Ecf.ThreeOne.PostAsync((Ecf31ECF)(object)body!, cancellationToken: ct),
                "32" => Api.Ecf.ThreeTwo.PostAsync((Ecf32ECF)(object)body!, cancellationToken: ct),
                "33" => Api.Ecf.ThreeThree.PostAsync((Ecf33ECF)(object)body!, cancellationToken: ct),
                "34" => Api.Ecf.ThreeFour.PostAsync((Ecf34ECF)(object)body!, cancellationToken: ct),
                "41" => Api.Ecf.FourOne.PostAsync((Ecf41ECF)(object)body!, cancellationToken: ct),
                "43" => Api.Ecf.FourThree.PostAsync((Ecf43ECF)(object)body!, cancellationToken: ct),
                "44" => Api.Ecf.FourFour.PostAsync((Ecf44ECF)(object)body!, cancellationToken: ct),
                "45" => Api.Ecf.FourFive.PostAsync((Ecf45ECF)(object)body!, cancellationToken: ct),
                "46" => Api.Ecf.FourSix.PostAsync((Ecf46ECF)(object)body!, cancellationToken: ct),
                "47" => Api.Ecf.FourSeven.PostAsync((Ecf47ECF)(object)body!, cancellationToken: ct),
                _ => throw new NotSupportedException($"Route {route} is not supported.")
            };
        }

        private async Task<EcfResponse> SendInternalAsync(
            string? rnc,
            string? encf,
            Func<CancellationToken, Task<EcfResponse?>> postCall,
            PollingOptions? pollingOptions,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(rnc))
                throw new ArgumentException("ECF must have Encabezado.Emisor.RncEmisor");
            if (string.IsNullOrWhiteSpace(encf))
                throw new ArgumentException("ECF must have Encabezado.IdDoc.Encf");

            var postResponse = await postCall(cancellationToken).ConfigureAwait(false);

            if (postResponse?.MessageId == null)
                throw new InvalidOperationException("ECF submission did not return a message ID.");

            var result = await PollingHelper.PollUntilCompleteAsync(
                async () =>
                {
                    var responses = await Api.Ecf[rnc!][encf!].GetAsync(cancellationToken: cancellationToken).ConfigureAwait(false);
                    if (responses == null || responses.Count == 0)
                        throw new InvalidOperationException("No ECF response found for the given rnc/encf.");

                    return responses.FirstOrDefault(r => r.MessageId == postResponse.MessageId) ?? responses[0];
                },
                r => r.Progress == EcfProgress.Finished || r.Progress == EcfProgress.Error,
                pollingOptions,
                cancellationToken
            ).ConfigureAwait(false);

            if (result.Progress == EcfProgress.Error)
            {
                var message = result.Errors ?? result.Mensaje ?? "ECF processing failed";
                throw new EcfException(message, result);
            }

            return result;
        }
    }
}
