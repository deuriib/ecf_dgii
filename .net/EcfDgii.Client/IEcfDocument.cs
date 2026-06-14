namespace EcfDgii.Client
{
    /// <summary>
    /// Internal interface to unify Kiota-generated ECF models.
    /// </summary>
    internal interface IEcfDocument
    {
        string? TipoeCF { get; }
        string? RncEmisor { get; }
        string? Encf { get; }
    }
}
