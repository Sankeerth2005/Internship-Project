namespace localink_be.Options
{
    public class BusinessShareOptions
    {
        public const string SectionName = "BusinessShare";

        /// <summary>Marketing site base, e.g. https://vocalforsanatan.com/share</summary>
        public string ShareBaseUrl { get; set; } = "https://vocalforsanatan.com/share";

        public int MaxItemsPerShare { get; set; } = 100;

        public int TokenLength { get; set; } = 16;

        public int TokenGenerationMaxAttempts { get; set; } = 12;
    }
}
