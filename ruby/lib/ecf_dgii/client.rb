require "uri"

module EcfDgii
  class Client
    ENVIRONMENT_URLS = {
      test: "https://api.test.ecfx.ssd.com.do",
      cert: "https://api.cert.ecfx.ssd.com.do",
      prod: "https://api.prod.ecfx.ssd.com.do"
    }.freeze

    attr_reader :api_client, :environment

    def initialize(api_key: nil, base_url: nil, environment: :test, timeout: 30)
      token = api_key || ENV["ECF_API_KEY"]
      resolved_url = base_url || ENV["ECF_API_URL"] || ENVIRONMENT_URLS[environment.to_sym]
      raise ArgumentError, "Se requiere un api_key o la variable de entorno ECF_API_KEY" if token.nil? || token.empty?
      raise ArgumentError, "El entorno especificado o la URL base no son válidos" if resolved_url.nil? || resolved_url.empty?

      config = EcfDgii::Generated::Configuration.new
      uri = URI.parse(resolved_url)
      
      config.scheme = uri.scheme
      config.host = uri.host
      config.base_path = uri.path.empty? ? "" : uri.path
      
      config.access_token = token
      config.timeout = timeout

      @api_client = EcfDgii::Generated::ApiClient.new(config)
      @environment = environment.to_sym
    end

    # ------------------------------------------------------------------
    # Base API Clients
    # ------------------------------------------------------------------

    def ecf_api
      @ecf_api ||= EcfDgii::Generated::EcfApi.new(api_client)
    end

    def dgii_api
      @dgii_api ||= EcfDgii::Generated::DgiiApi.new(api_client)
    end

    def recepcion_api
      @recepcion_api ||= EcfDgii::Generated::RecepcionApi.new(api_client)
    end

    def company_api
      @company_api ||= EcfDgii::Generated::CompanyApi.new(api_client)
    end

    def aprobacion_comercial_api
      @aprobacion_comercial_api ||= EcfDgii::Generated::AprobacionComercialApi.new(api_client)
    end

    def api_key_api
      @api_key_api ||= EcfDgii::Generated::ApiKeyApi.new(api_client)
    end

    # ------------------------------------------------------------------
    # ECF send operations (per-type)
    # ------------------------------------------------------------------

    def send_ecf31(ecf)
      ecf_api.recepcion_ecf_31(ecf)
    end

    def send_ecf32(ecf)
      ecf_api.recepcion_ecf_32(ecf)
    end

    def send_ecf33(ecf)
      ecf_api.recepcion_ecf_33(ecf)
    end

    def send_ecf34(ecf)
      ecf_api.recepcion_ecf_34(ecf)
    end

    def send_ecf41(ecf)
      ecf_api.recepcion_ecf_41(ecf)
    end

    def send_ecf43(ecf)
      ecf_api.recepcion_ecf_43(ecf)
    end

    def send_ecf44(ecf)
      ecf_api.recepcion_ecf_44(ecf)
    end

    def send_ecf45(ecf)
      ecf_api.recepcion_ecf_45(ecf)
    end

    def send_ecf46(ecf)
      ecf_api.recepcion_ecf_46(ecf)
    end

    def send_ecf47(ecf)
      ecf_api.recepcion_ecf_47(ecf)
    end

    # ------------------------------------------------------------------
    # Polling send operations
    # ------------------------------------------------------------------

    def send_ecf31_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf31(ecf), options)
    end

    def send_ecf32_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf32(ecf), options)
    end

    def send_ecf33_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf33(ecf), options)
    end

    def send_ecf34_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf34(ecf), options)
    end

    def send_ecf41_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf41(ecf), options)
    end

    def send_ecf43_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf43(ecf), options)
    end

    def send_ecf44_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf44(ecf), options)
    end

    def send_ecf45_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf45(ecf), options)
    end

    def send_ecf46_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf46(ecf), options)
    end

    def send_ecf47_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf47(ecf), options)
    end

    # ------------------------------------------------------------------
    # Dynamic send_ecf routing (similar to TS sendEcf)
    # ------------------------------------------------------------------

    ECF_TYPE_ROUTE_MAP = {
      "FacturaDeCreditoFiscalElectronica" => "31",
      "FacturaDeConsumoElectronica" => "32",
      "NotaDeDebitoElectronica" => "33",
      "NotaDeCreditoElectronica" => "34",
      "ComprasElectronico" => "41",
      "GastosMenoresElectronico" => "43",
      "RegimenesEspecialesElectronico" => "44",
      "GubernamentalElectronico" => "45",
      "ComprobanteDeExportacionesElectronico" => "46",
      "ComprobanteParaPagosAlExteriorElectronico" => "47"
    }.freeze

    def send_ecf(ecf)
      tipoe_cf = nil
      if ecf.respond_to?(:encabezado) && ecf.encabezado.respond_to?(:id_doc)
        tipoe_cf = ecf.encabezado.id_doc.tipoe_cf
      elsif ecf.is_a?(Hash)
        tipoe_cf = ecf.dig(:encabezado, :id_doc, :tipoe_cf) || ecf.dig("encabezado", "idDoc", "tipoeCF")
      end

      raise ArgumentError, "El objeto ECF debe contener encabezado.id_doc.tipoe_cf" if tipoe_cf.nil? || tipoe_cf.to_s.empty?

      route = ECF_TYPE_ROUTE_MAP[tipoe_cf.to_s]
      raise ArgumentError, "Tipo de eCF desconocido: #{tipoe_cf}" if route.nil?

      send("send_ecf#{route}", ecf)
    end

    def send_ecf_and_poll(ecf, options = nil)
      _send_and_poll(send_ecf(ecf), options)
    end

    # ------------------------------------------------------------------
    # ECF query & search operations
    # ------------------------------------------------------------------

    def query_ecf(rnc, encf, opts = {})
      ecf_api.query_ecf(rnc, encf, opts)
    end

    def search_ecfs(rnc, opts = {})
      ecf_api.search_ecfs(rnc, opts)
    end

    def search_all_ecfs(opts = {})
      ecf_api.search_all_ecfs(opts)
    end

    def get_ecf_by_id(id)
      ecf_api.get_ecf_by_id(id)
    end

    def anulacion_rangos(body)
      ecf_api.anulacion_rangos(body)
    end

    def list_anulaciones(opts = {})
      ecf_api.list_anulaciones(opts)
    end

    def send_aprobacion_comercial(body)
      recepcion_api.send_aprobacion_comercial(body)
    end

    def firmar_semilla(body)
      ecf_api.firmar_semilla(body)
    end

    # ------------------------------------------------------------------
    # Company operations
    # ------------------------------------------------------------------

    def get_companies(opts = {})
      company_api.get_companies(opts)
    end

    def get_company_by_rnc(rnc)
      company_api.get_company_by_rnc(rnc)
    end

    def upsert_company(body)
      company_api.upsert_company(body)
    end

    def delete_company(rnc)
      company_api.delete_company(rnc)
    end

    def get_current_certificate(rnc)
      company_api.get_current_certificate(rnc)
    end

    def update_certificate_company(rnc, opts = {})
      company_api.update_certificate_company(rnc, opts)
    end

    # ------------------------------------------------------------------
    # Api Key operations
    # ------------------------------------------------------------------

    def new_company_api_key(body)
      api_key_api.new_company_api_key(body)
    end

    # ------------------------------------------------------------------
    # DGII operations
    # ------------------------------------------------------------------

    def consulta_estado(rnc, rnc_emisor, ncf_electronico, rnc_comprador, codigo_seguridad)
      dgii_api.consulta_estado(rnc, rnc_emisor, ncf_electronico, rnc_comprador, codigo_seguridad)
    end

    def consulta_track_id(rnc, rnc_emisor, encf)
      dgii_api.consulta_track_id(rnc, rnc_emisor, encf)
    end

    def consulta_timbre(rnc, rnc_emisor, ncf_electronico, rnc_comprador, codigo_seguridad, fecha_emision, monto_total, uid_timbre)
      dgii_api.consulta_timbre(rnc, rnc_emisor, ncf_electronico, rnc_comprador, codigo_seguridad, fecha_emision, monto_total, uid_timbre)
    end

    def consulta_timbre_fc(rnc, rnc_emisor, ncf_electronico, rnc_comprador, fecha_emision, monto_total)
      dgii_api.consulta_timbre_fc(rnc, rnc_emisor, ncf_electronico, rnc_comprador, fecha_emision, monto_total)
    end

    def consulta_resultado(rnc, track_id)
      dgii_api.consulta_resultado(rnc, track_id)
    end

    def consulta_rfce(rnc, rnc_emisor, ncf_electronico)
      dgii_api.consulta_rfce(rnc, rnc_emisor, ncf_electronico)
    end

    def consulta_directorio(rnc)
      dgii_api.consulta_directorio_listado(rnc)
    end

    def consulta_directorio_por_rnc(rnc, target_rnc)
      dgii_api.consulta_directorio_obtener_directorio_por_rnc(rnc, target_rnc)
    end

    def estatus_servicio(rnc)
      dgii_api.estatus_servicios_obtener_estatus(rnc)
    end

    def ventanas_mantenimiento(rnc)
      dgii_api.estatus_servicios_obtener_ventanas_mantenimiento(rnc)
    end

    # ------------------------------------------------------------------
    # Reception operations
    # ------------------------------------------------------------------

    def get_ecf_reception_request(message_id)
      recepcion_api.get_ecf_reception_request(message_id)
    end

    def get_ecf_receptor_by_message_id(message_id)
      recepcion_api.get_ecf_receptor_by_message_id(message_id)
    end

    def search_ecf_reception_requests(opts = {})
      recepcion_api.search_ecf_reception_requests(opts)
    end

    def search_ecf_reception_requests_by_rnc(rnc, opts = {})
      recepcion_api.search_ecf_reception_requests_by_rnc(rnc, opts)
    end

    # ------------------------------------------------------------------
    # Aprobacion Comercial operations
    # ------------------------------------------------------------------

    def get_acecf_reception_request(message_id)
      aprobacion_comercial_api.get_acecf_reception_request(message_id)
    end

    def search_acecf_reception_requests(opts = {})
      aprobacion_comercial_api.search_acecf_reception_requests(opts)
    end

    private

    def _send_and_poll(initial, options)
      EcfDgii::Polling.poll_until_complete(options) do
        results = query_ecf(initial.rnc_emisor, initial.encf, include_ecf_content: false)
        results && !results.empty? ? results.first : initial
      end
    end
  end
end
