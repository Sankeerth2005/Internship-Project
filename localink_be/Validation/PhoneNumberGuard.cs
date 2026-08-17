using System.Text.RegularExpressions;

namespace localink_be.Validation
{
    /// Country-aware phone validation aligned with the Flutter AppValidators rules.
    public static class PhoneNumberGuard
    {
        private static readonly Dictionary<string, int[]> NationalLengthByCallingCode = new()
        {
            ["1"] = [10],
            ["7"] = [10],
            ["20"] = [10],
            ["27"] = [9],
            ["30"] = [10],
            ["31"] = [9],
            ["32"] = [8, 9],
            ["33"] = [9],
            ["34"] = [9],
            ["36"] = [9],
            ["39"] = [9, 10],
            ["40"] = [9],
            ["41"] = [9],
            ["43"] = [10, 11, 12, 13],
            ["44"] = [10],
            ["45"] = [8],
            ["46"] = [7, 8, 9, 10],
            ["47"] = [8],
            ["48"] = [9],
            ["49"] = [10, 11],
            ["51"] = [9],
            ["52"] = [10],
            ["53"] = [8],
            ["54"] = [10],
            ["55"] = [10, 11],
            ["56"] = [9],
            ["57"] = [10],
            ["58"] = [10],
            ["60"] = [9, 10],
            ["61"] = [9],
            ["62"] = [9, 10, 11, 12],
            ["63"] = [10],
            ["64"] = [8, 9, 10],
            ["65"] = [8],
            ["66"] = [9],
            ["81"] = [10],
            ["82"] = [9, 10],
            ["84"] = [9, 10],
            ["86"] = [11],
            ["90"] = [10],
            ["91"] = [10],
            ["92"] = [10],
            ["93"] = [9],
            ["94"] = [9],
            ["95"] = [8, 9, 10],
            ["98"] = [10],
            ["212"] = [9],
            ["213"] = [9],
            ["216"] = [8],
            ["218"] = [9],
            ["220"] = [7],
            ["234"] = [10],
            ["254"] = [9],
            ["255"] = [9],
            ["256"] = [9],
            ["880"] = [10],
            ["966"] = [9],
            ["971"] = [9],
            ["972"] = [8, 9],
            ["974"] = [8],
        };

        public static string DigitsOnly(string? value) =>
            string.IsNullOrWhiteSpace(value) ? string.Empty : Regex.Replace(value, @"\D", "");

        public static string NormalizeCallingCode(string? countryCode)
        {
            var code = (countryCode ?? string.Empty).Trim();
            if (code.StartsWith('+')) code = code[1..];
            return DigitsOnly(code);
        }

        public static string NationalNumber(string? value, string? countryCode)
        {
            var digits = DigitsOnly(value);
            var calling = NormalizeCallingCode(countryCode);
            if (!string.IsNullOrEmpty(calling) &&
                digits.StartsWith(calling) &&
                digits.Length > calling.Length)
            {
                digits = digits[calling.Length..];
            }

            if (digits.StartsWith('0') && digits.Length > 1)
            {
                var withoutTrunk = digits[1..];
                var allowed = AllowedLengths(calling);
                if (allowed.Contains(withoutTrunk.Length))
                    digits = withoutTrunk;
            }

            return digits;
        }

        public static bool IsIndian(string? countryCode, string? countryName)
        {
            if (NormalizeCallingCode(countryCode) == "91") return true;
            var name = (countryName ?? string.Empty).Trim().ToLowerInvariant();
            return name.Contains("india");
        }

        public static string FormatCallingCode(string? countryCode)
        {
            var calling = NormalizeCallingCode(countryCode);
            return string.IsNullOrEmpty(calling) ? string.Empty : $"+{calling}";
        }

        /// <returns>Error message, or null when valid.</returns>
        public static string? Validate(
            string? phone,
            string? countryCode,
            string? countryName = null,
            bool required = true)
        {
            var raw = (phone ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(raw))
                return required ? "Phone number is required" : null;

            if (Regex.IsMatch(raw, "[A-Za-z]"))
                return "Phone number cannot contain letters";
            if (Regex.IsMatch(raw, @"[^0-9+\-\s()]"))
                return "Phone number contains invalid characters";

            var calling = NormalizeCallingCode(countryCode);
            if (required && string.IsNullOrEmpty(calling))
                return "Country code is required";
            if (!string.IsNullOrEmpty(calling) && !Regex.IsMatch(calling, @"^[1-9]\d{0,3}$"))
                return "Invalid country code";

            var national = NationalNumber(raw, countryCode);
            if (string.IsNullOrEmpty(national))
                return required ? "Phone number is required" : null;

            if (IsIndian(countryCode, countryName))
            {
                if (national.Length != 10)
                    return "Indian phone number must be exactly 10 digits";
                if (!Regex.IsMatch(national, "^[6-9]"))
                    return "Indian mobile numbers must start with 6, 7, 8, or 9";
                return null;
            }

            var allowed = AllowedLengths(calling);
            if (!allowed.Contains(national.Length))
            {
                if (allowed.Length == 1)
                    return $"Phone number must be {allowed[0]} digits for the selected country";
                return $"Phone number must be {allowed[0]}–{allowed[^1]} digits for the selected country";
            }

            if (national.Length < 7 || national.Length > 15)
                return "Phone number must be between 7 and 15 digits";

            return null;
        }

        public static void EnsureValid(
            string? phone,
            string? countryCode,
            string? countryName = null,
            bool required = true)
        {
            var error = Validate(phone, countryCode, countryName, required);
            if (error != null)
                throw new ArgumentException(error);
        }

        private static int[] AllowedLengths(string callingCode) =>
            NationalLengthByCallingCode.TryGetValue(callingCode, out var lengths)
                ? lengths
                : [7, 8, 9, 10, 11, 12, 13, 14, 15];
    }

    public static class PincodeGuard
    {
        public static string? Validate(
            string? pincode,
            string? countryName,
            bool required = false,
            string? countryIso2 = null)
        {
            var value = (pincode ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(value))
                return required ? "Pincode is required" : null;

            // Selected address country only — never infer India from the caller's GPS or phone code.
            return PostalCodeRules.Validate(value, countryIso2, countryName);
        }

        public static void EnsureValid(
            string? pincode,
            string? countryName,
            bool required = false,
            string? countryIso2 = null)
        {
            var error = Validate(pincode, countryName, required, countryIso2);
            if (error != null)
                throw new ArgumentException(error);
        }
    }
}
