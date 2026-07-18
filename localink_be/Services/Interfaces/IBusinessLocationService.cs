public interface IBusinessLocationService
{
    Task<string> GetCountries();
    Task<string> GetStates(string countryCode);
    Task<string> GetCities(string countryCode, string stateCode);
    Task<bool> ValidateAddressAsync(string country, string state, string city);
}
