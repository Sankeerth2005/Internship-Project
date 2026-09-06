public interface IBusinessPincodeService
{
    Task<string> GetPincodeData(
        string postcode,
        string? countryIso2 = null,
        string? countryName = null);
}
