using System.Text.RegularExpressions;

namespace localink_be.Validation
{
    /// <summary>
    /// Country-aware postal/pincode format rules keyed by ISO 3166-1 alpha-2.
    /// Must stay aligned with Flutter PostalCodeRules / AppValidators.pincode.
    /// </summary>
    public static class PostalCodeRules
    {
        private const int FallbackMin = 3;
        private const int FallbackMax = 10;
        private static readonly Regex FallbackCharset = new(@"^[A-Za-z0-9\-\s]+$", RegexOptions.Compiled);
        private static readonly Regex Iso2Regex = new(@"^[A-Z]{2}$", RegexOptions.Compiled);

        private static readonly Dictionary<string, Regex> PatternsByIso2 = new(StringComparer.OrdinalIgnoreCase)
        {
            ["IN"] = Compile(@"^[0-9]{6}$"),
            ["US"] = Compile(@"^[0-9]{5}(-[0-9]{4})?$"),
            ["GB"] = Compile(@"^(GIR\s?0AA|[A-Z]{1,2}[0-9][A-Z0-9]?\s?[0-9][A-Z]{2})$"),
            ["CA"] = Compile(@"^[ABCEGHJ-NPRSTVXY][0-9][ABCEGHJ-NPRSTV-Z]\s?[0-9][ABCEGHJ-NPRSTV-Z][0-9]$"),
            ["AU"] = Compile(@"^[0-9]{4}$"),
            ["NZ"] = Compile(@"^[0-9]{4}$"),
            ["DE"] = Compile(@"^[0-9]{5}$"),
            ["FR"] = Compile(@"^[0-9]{5}$"),
            ["IT"] = Compile(@"^[0-9]{5}$"),
            ["ES"] = Compile(@"^[0-9]{5}$"),
            ["NL"] = Compile(@"^[0-9]{4}\s?[A-Z]{2}$"),
            ["BE"] = Compile(@"^[0-9]{4}$"),
            ["CH"] = Compile(@"^[0-9]{4}$"),
            ["AT"] = Compile(@"^[0-9]{4}$"),
            ["SE"] = Compile(@"^[0-9]{3}\s?[0-9]{2}$"),
            ["NO"] = Compile(@"^[0-9]{4}$"),
            ["DK"] = Compile(@"^[0-9]{4}$"),
            ["FI"] = Compile(@"^[0-9]{5}$"),
            ["IE"] = Compile(@"^[A-Z][0-9]{2}\s?[A-Z0-9]{4}$"),
            ["PT"] = Compile(@"^[0-9]{4}-?[0-9]{3}$"),
            ["PL"] = Compile(@"^[0-9]{2}-?[0-9]{3}$"),
            ["CZ"] = Compile(@"^[0-9]{3}\s?[0-9]{2}$"),
            ["SK"] = Compile(@"^[0-9]{3}\s?[0-9]{2}$"),
            ["HU"] = Compile(@"^[0-9]{4}$"),
            ["RO"] = Compile(@"^[0-9]{6}$"),
            ["BG"] = Compile(@"^[0-9]{4}$"),
            ["GR"] = Compile(@"^[0-9]{3}\s?[0-9]{2}$"),
            ["TR"] = Compile(@"^[0-9]{5}$"),
            ["RU"] = Compile(@"^[0-9]{6}$"),
            ["UA"] = Compile(@"^[0-9]{5}$"),
            ["CN"] = Compile(@"^[0-9]{6}$"),
            ["JP"] = Compile(@"^[0-9]{3}-?[0-9]{4}$"),
            ["KR"] = Compile(@"^[0-9]{5}$"),
            ["SG"] = Compile(@"^[0-9]{6}$"),
            ["MY"] = Compile(@"^[0-9]{5}$"),
            ["TH"] = Compile(@"^[0-9]{5}$"),
            ["ID"] = Compile(@"^[0-9]{5}$"),
            ["PH"] = Compile(@"^[0-9]{4}$"),
            ["VN"] = Compile(@"^[0-9]{5,6}$"),
            ["PK"] = Compile(@"^[0-9]{5}$"),
            ["BD"] = Compile(@"^[0-9]{4}$"),
            ["LK"] = Compile(@"^[0-9]{5}$"),
            ["NP"] = Compile(@"^[0-9]{5}$"),
            ["SA"] = Compile(@"^[0-9]{5}(-[0-9]{4})?$"),
            ["IL"] = Compile(@"^[0-9]{5,7}$"),
            ["KW"] = Compile(@"^[0-9]{5}$"),
            ["BH"] = Compile(@"^[0-9]{3,4}$"),
            ["OM"] = Compile(@"^[0-9]{3}$"),
            ["JO"] = Compile(@"^[0-9]{5}$"),
            ["LB"] = Compile(@"^[0-9]{4}(\s?[0-9]{4})?$"),
            ["EG"] = Compile(@"^[0-9]{5}$"),
            ["MA"] = Compile(@"^[0-9]{5}$"),
            ["TN"] = Compile(@"^[0-9]{4}$"),
            ["DZ"] = Compile(@"^[0-9]{5}$"),
            ["ZA"] = Compile(@"^[0-9]{4}$"),
            ["NG"] = Compile(@"^[0-9]{6}$"),
            ["KE"] = Compile(@"^[0-9]{5}$"),
            ["GH"] = Compile(@"^[A-Z]{2}-?[0-9]{3,4}-?[0-9]{4}$"),
            ["BR"] = Compile(@"^[0-9]{5}-?[0-9]{3}$"),
            ["MX"] = Compile(@"^[0-9]{5}$"),
            ["AR"] = Compile(@"^([A-Z][0-9]{4}[A-Z]{3}|[0-9]{4})$"),
            ["CL"] = Compile(@"^[0-9]{7}$"),
            ["CO"] = Compile(@"^[0-9]{6}$"),
            ["PE"] = Compile(@"^[0-9]{5}$"),
            ["VE"] = Compile(@"^[0-9]{4}$"),
            ["UY"] = Compile(@"^[0-9]{5}$"),
            ["PY"] = Compile(@"^[0-9]{4}$"),
            ["EC"] = Compile(@"^[0-9]{6}$"),
            ["BO"] = Compile(@"^[0-9]{4}$"),
            ["HK"] = Compile(@"^[0-9]{6}$"),
            ["TW"] = Compile(@"^[0-9]{3,5}$"),
            ["MO"] = Compile(@"^[0-9]{6}$"),
            ["MM"] = Compile(@"^[0-9]{5}$"),
            ["KH"] = Compile(@"^[0-9]{5,6}$"),
            ["LA"] = Compile(@"^[0-9]{5}$"),
            ["IR"] = Compile(@"^[0-9]{5,10}$"),
            ["IQ"] = Compile(@"^[0-9]{5}$"),
            ["AF"] = Compile(@"^[0-9]{4}$"),
            ["UZ"] = Compile(@"^[0-9]{6}$"),
            ["KZ"] = Compile(@"^[0-9]{6}$"),
            ["BY"] = Compile(@"^[0-9]{6}$"),
            ["LT"] = Compile(@"^[A-Z]{2}-?[0-9]{5}$"),
            ["LV"] = Compile(@"^(LV-)?[0-9]{4}$"),
            ["EE"] = Compile(@"^[0-9]{5}$"),
            ["SI"] = Compile(@"^[0-9]{4}$"),
            ["HR"] = Compile(@"^[0-9]{5}$"),
            ["RS"] = Compile(@"^[0-9]{5}$"),
            ["BA"] = Compile(@"^[0-9]{5}$"),
            ["MK"] = Compile(@"^[0-9]{4}$"),
            ["AL"] = Compile(@"^[0-9]{4}$"),
            ["IS"] = Compile(@"^[0-9]{3}$"),
            ["LU"] = Compile(@"^[0-9]{4}$"),
            ["MT"] = Compile(@"^[A-Z]{3}\s?[0-9]{4}$"),
            ["CY"] = Compile(@"^[0-9]{4}$"),
            ["GE"] = Compile(@"^[0-9]{4}$"),
            ["AM"] = Compile(@"^[0-9]{4}$"),
            ["AZ"] = Compile(@"^[0-9]{4}$"),
            ["MD"] = Compile(@"^[A-Z]{2}-?[0-9]{4}$"),
            ["PR"] = Compile(@"^[0-9]{5}(-[0-9]{4})?$"),
        };

        private static readonly Dictionary<string, string> MessagesByIso2 = new(StringComparer.OrdinalIgnoreCase)
        {
            ["IN"] = "Indian pincode must be exactly 6 digits",
            ["US"] = "Enter a valid US ZIP code (12345 or 12345-6789)",
            ["GB"] = "Enter a valid UK postcode",
            ["CA"] = "Enter a valid Canadian postal code",
        };

        private const string GenericCountryMessage = "Enter a valid postal code for the selected country";

        private static readonly Dictionary<string, string> AliasesToIso2 = new(StringComparer.OrdinalIgnoreCase)
        {
            ["india"] = "IN",
            ["united states"] = "US",
            ["united states of america"] = "US",
            ["usa"] = "US",
            ["united kingdom"] = "GB",
            ["great britain"] = "GB",
            ["uk"] = "GB",
            ["england"] = "GB",
            ["scotland"] = "GB",
            ["wales"] = "GB",
            ["canada"] = "CA",
            ["australia"] = "AU",
            ["new zealand"] = "NZ",
            ["germany"] = "DE",
            ["france"] = "FR",
            ["italy"] = "IT",
            ["spain"] = "ES",
            ["netherlands"] = "NL",
            ["the netherlands"] = "NL",
            ["belgium"] = "BE",
            ["switzerland"] = "CH",
            ["austria"] = "AT",
            ["sweden"] = "SE",
            ["norway"] = "NO",
            ["denmark"] = "DK",
            ["finland"] = "FI",
            ["ireland"] = "IE",
            ["portugal"] = "PT",
            ["poland"] = "PL",
            ["czech republic"] = "CZ",
            ["czechia"] = "CZ",
            ["slovakia"] = "SK",
            ["hungary"] = "HU",
            ["romania"] = "RO",
            ["bulgaria"] = "BG",
            ["greece"] = "GR",
            ["turkey"] = "TR",
            ["russia"] = "RU",
            ["ukraine"] = "UA",
            ["china"] = "CN",
            ["japan"] = "JP",
            ["south korea"] = "KR",
            ["korea"] = "KR",
            ["singapore"] = "SG",
            ["malaysia"] = "MY",
            ["thailand"] = "TH",
            ["indonesia"] = "ID",
            ["philippines"] = "PH",
            ["vietnam"] = "VN",
            ["pakistan"] = "PK",
            ["bangladesh"] = "BD",
            ["sri lanka"] = "LK",
            ["nepal"] = "NP",
            ["saudi arabia"] = "SA",
            ["israel"] = "IL",
            ["united arab emirates"] = "AE",
            ["uae"] = "AE",
            ["qatar"] = "QA",
            ["kuwait"] = "KW",
            ["bahrain"] = "BH",
            ["oman"] = "OM",
            ["jordan"] = "JO",
            ["lebanon"] = "LB",
            ["egypt"] = "EG",
            ["morocco"] = "MA",
            ["tunisia"] = "TN",
            ["algeria"] = "DZ",
            ["south africa"] = "ZA",
            ["nigeria"] = "NG",
            ["kenya"] = "KE",
            ["ghana"] = "GH",
            ["brazil"] = "BR",
            ["mexico"] = "MX",
            ["argentina"] = "AR",
            ["chile"] = "CL",
            ["colombia"] = "CO",
            ["peru"] = "PE",
            ["venezuela"] = "VE",
            ["uruguay"] = "UY",
            ["paraguay"] = "PY",
            ["ecuador"] = "EC",
            ["bolivia"] = "BO",
            ["hong kong"] = "HK",
            ["taiwan"] = "TW",
            ["macau"] = "MO",
            ["macao"] = "MO",
            ["myanmar"] = "MM",
            ["cambodia"] = "KH",
            ["laos"] = "LA",
            ["iran"] = "IR",
            ["iraq"] = "IQ",
            ["afghanistan"] = "AF",
            ["uzbekistan"] = "UZ",
            ["kazakhstan"] = "KZ",
            ["belarus"] = "BY",
            ["lithuania"] = "LT",
            ["latvia"] = "LV",
            ["estonia"] = "EE",
            ["slovenia"] = "SI",
            ["croatia"] = "HR",
            ["serbia"] = "RS",
            ["bosnia and herzegovina"] = "BA",
            ["north macedonia"] = "MK",
            ["albania"] = "AL",
            ["iceland"] = "IS",
            ["luxembourg"] = "LU",
            ["malta"] = "MT",
            ["cyprus"] = "CY",
            ["georgia"] = "GE",
            ["armenia"] = "AM",
            ["azerbaijan"] = "AZ",
            ["moldova"] = "MD",
            ["puerto rico"] = "PR",
        };

        public static string? ResolveIso2(string? countryIso2, string? countryName)
        {
            var iso = (countryIso2 ?? string.Empty).Trim().ToUpperInvariant();
            if (IsIso2(iso)) return iso;

            var name = (countryName ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(name)) return null;
            var asIso = name.ToUpperInvariant();
            if (name.Length == 2 && IsIso2(asIso)) return asIso;

            return AliasesToIso2.TryGetValue(name, out var mapped) ? mapped : null;
        }

        public static string? Validate(string value, string? countryIso2, string? countryName)
        {
            var v = (value ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(v)) return null;

            var iso = ResolveIso2(countryIso2, countryName);
            if (iso == null) return FallbackValidate(v);

            if (!PatternsByIso2.TryGetValue(iso, out var pattern))
                return FallbackValidate(v);

            if (!pattern.IsMatch(v))
                return MessagesByIso2.TryGetValue(iso, out var message) ? message : GenericCountryMessage;

            return null;
        }

        public static string? FallbackValidate(string value)
        {
            var v = (value ?? string.Empty).Trim();
            if (v.Length < FallbackMin || v.Length > FallbackMax)
                return "Pincode must be between 3 and 10 characters";
            if (!FallbackCharset.IsMatch(v))
                return "Pincode contains invalid characters";
            return null;
        }

        private static bool IsIso2(string value) => value.Length == 2 && Iso2Regex.IsMatch(value);

        private static Regex Compile(string pattern) =>
            new(pattern, RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }
}
