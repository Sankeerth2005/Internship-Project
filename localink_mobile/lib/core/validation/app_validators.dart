import 'postal_code_rules.dart';

/// Shared form validators — keep Flutter screens aligned with backend rules.
/// Postal format lives in [PostalCodeRules]; screens must call [pincode] rather than copy regexes.
class AppValidators {
  AppValidators._();

  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final nameRegex = RegExp(r"^[a-zA-Z\s\-\.']+$");

  /// Matches signup + backend: upper, lower, digit, special from @$!%*?&
  static final strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  static final _digitsOnly = RegExp(r'[^0-9]');

  /// ITU-based national-number length ranges keyed by calling code (no '+').
  /// Unknown codes fall back to E.164 7–15 digits.
  static const Map<String, List<int>> nationalLengthByCallingCode = {
    '1': [10],
    '7': [10],
    '20': [10],
    '27': [9],
    '30': [10],
    '31': [9],
    '32': [8, 9],
    '33': [9],
    '34': [9],
    '36': [9],
    '39': [9, 10],
    '40': [9],
    '41': [9],
    '43': [10, 11, 12, 13],
    '44': [10],
    '45': [8],
    '46': [7, 8, 9, 10],
    '47': [8],
    '48': [9],
    '49': [10, 11],
    '51': [9],
    '52': [10],
    '53': [8],
    '54': [10],
    '55': [10, 11],
    '56': [9],
    '57': [10],
    '58': [10],
    '60': [9, 10],
    '61': [9],
    '62': [9, 10, 11, 12],
    '63': [10],
    '64': [8, 9, 10],
    '65': [8],
    '66': [9],
    '81': [10],
    '82': [9, 10],
    '84': [9, 10],
    '86': [11],
    '90': [10],
    '91': [10],
    '92': [10],
    '93': [9],
    '94': [9],
    '95': [8, 9, 10],
    '98': [10],
    '212': [9],
    '213': [9],
    '216': [8],
    '218': [9],
    '220': [7],
    '234': [10],
    '254': [9],
    '255': [9],
    '256': [9],
    '880': [10],
    '966': [9],
    '971': [9],
    '972': [8, 9],
    '974': [8],
  };

  static String digitsOnly(String? value) =>
      (value ?? '').replaceAll(_digitsOnly, '');

  static String normalizeCallingCode(String? countryCode) {
    var code = (countryCode ?? '').trim();
    if (code.startsWith('+')) code = code.substring(1);
    return digitsOnly(code);
  }

  /// Strips a matching calling-code prefix so we never store +91 + 91xxxxxxxxxx.
  static String nationalNumber(String? value, String? countryCode) {
    var digits = digitsOnly(value);
    final calling = normalizeCallingCode(countryCode);
    if (calling.isNotEmpty &&
        digits.startsWith(calling) &&
        digits.length > calling.length) {
      digits = digits.substring(calling.length);
    }
    if (digits.startsWith('0') && digits.length > 1) {
      // Drop a single trunk prefix (e.g. 09876… → 9876…) when remaining length is valid.
      final withoutTrunk = digits.substring(1);
      final allowed = _allowedLengths(calling);
      if (allowed.contains(withoutTrunk.length)) {
        digits = withoutTrunk;
      }
    }
    return digits;
  }

  static List<int> _allowedLengths(String callingCode) =>
      nationalLengthByCallingCode[callingCode] ?? const [7, 8, 9, 10, 11, 12, 13, 14, 15];

  static bool isIndianCallingCode(String? countryCode, {String? countryName}) {
    final calling = normalizeCallingCode(countryCode);
    if (calling == '91') return true;
    final name = (countryName ?? '').trim().toLowerCase();
    return name == 'india' || name.contains('india');
  }

  static String? name(String? value, {bool required = true, String label = 'Name'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? '$label is required' : null;
    if (v.length < 2 || v.length > 100) {
      return '$label must be between 2 and 100 characters';
    }
    if (!nameRegex.hasMatch(v)) {
      return '$label can only contain letters, spaces, hyphens, dots, and apostrophes';
    }
    return null;
  }

  static String? email(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Email is required' : null;
    if (v.length > 256) return 'Email cannot exceed 256 characters';
    if (!emailRegex.hasMatch(v)) return 'Invalid email format';
    return null;
  }

  static String? phone(
    String? value, {
    bool required = true,
    String? countryCode,
    String? countryName,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return required ? 'Phone number is required' : null;
    if (RegExp(r'[A-Za-z]').hasMatch(raw)) {
      return 'Phone number cannot contain letters';
    }
    if (RegExp(r'[^0-9+\-\s()]').hasMatch(raw)) {
      return 'Phone number contains invalid characters';
    }

    final calling = normalizeCallingCode(countryCode);
    final national = nationalNumber(raw, countryCode);
    if (national.isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    if (isIndianCallingCode(countryCode, countryName: countryName)) {
      if (national.length != 10) {
        return 'Indian phone number must be exactly 10 digits';
      }
      if (!RegExp(r'^[6-9]').hasMatch(national)) {
        return 'Indian mobile numbers must start with 6, 7, 8, or 9';
      }
      return null;
    }

    final allowed = _allowedLengths(calling);
    if (!allowed.contains(national.length)) {
      if (allowed.length == 1) {
        return 'Phone number must be ${allowed.first} digits for the selected country';
      }
      return 'Phone number must be ${allowed.first}–${allowed.last} digits for the selected country';
    }
    if (national.length < 7 || national.length > 15) {
      return 'Phone number must be between 7 and 15 digits';
    }
    return null;
  }

  static String? callingCode(String? value, {bool required = true}) {
    final v = normalizeCallingCode(value);
    if (v.isEmpty) return required ? 'Country code is required' : null;
    if (!RegExp(r'^[1-9]\d{0,3}$').hasMatch(v)) {
      return 'Invalid country code';
    }
    return null;
  }

  static String? password(
    String? value, {
    bool requireStrong = true,
  }) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8 || value.length > 128) {
      return 'Password must be between 8 and 128 characters';
    }
    if (!requireStrong) return null;

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Must contain at least one number';
    }
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
      return 'Must contain at least one special character (@\$!%*?&)';
    }
    if (!strongPasswordRegex.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number, and special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? street(String? value, {bool required = false, int maxLength = 500}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Street address is required' : null;
    if (v.length > maxLength) {
      return 'Street address cannot exceed $maxLength characters';
    }
    return null;
  }

  static String? pincode(
    String? value, {
    bool required = false,
    String? countryName,
    String? countryCode, // kept for call-site compatibility; format uses ISO2/name only
    String? countryIso2,
    String? asyncError,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Pincode is required' : null;
    if (asyncError != null && asyncError.isNotEmpty) return asyncError;

    // Format depends on the selected address country (ISO2 / name), never GPS or phone calling code.
    return PostalCodeRules.validate(
      v,
      countryIso2: countryIso2,
      countryName: countryName,
    );
  }

  static String? requiredSelection(Object? value, String label) {
    if (value == null) return '$label is required';
    if (value is String && value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? website(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Website is required' : null;
    if (v.length > 500) return 'Website cannot exceed 500 characters';
    final uri = Uri.tryParse(v.startsWith('http') ? v : 'https://$v');
    if (uri == null || uri.host.isEmpty) return 'Enter a valid website URL';
    return null;
  }

  static String? businessName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Business name is required';
    if (v.length < 2 || v.length > 200) {
      return 'Business name must be between 2 and 200 characters';
    }
    return null;
  }

  static String? description(String? value, {bool required = false, int maxLength = 2000}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Description is required' : null;
    if (v.length > maxLength) {
      return 'Description cannot exceed $maxLength characters';
    }
    return null;
  }

  static bool hasUpper(String v) => RegExp(r'[A-Z]').hasMatch(v);
  static bool hasLower(String v) => RegExp(r'[a-z]').hasMatch(v);
  static bool hasDigit(String v) => RegExp(r'[0-9]').hasMatch(v);
  static bool hasSpecial(String v) => RegExp(r'[@$!%*?&]').hasMatch(v);
  static bool hasMinLength(String v, [int min = 8]) => v.length >= min;
}
