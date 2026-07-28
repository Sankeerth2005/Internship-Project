namespace localink_be.Services.Interfaces
{
    public interface ICurrencyService
    {
        Task<decimal> ConvertCurrencyAsync(decimal amount, string fromCurrency, string toCurrency);
        Task<Dictionary<string, decimal>> GetExchangeRatesAsync(string baseCurrency);
    }
}
