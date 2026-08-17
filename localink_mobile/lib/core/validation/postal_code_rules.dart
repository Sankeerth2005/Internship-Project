/// Country-aware postal/pincode format rules keyed by ISO 3166-1 alpha-2.
/// Flutter screens must reuse this via [AppValidators.pincode] — do not copy regexes.
class PostalCodeRules {
  PostalCodeRules._();

  static const _fallbackMin = 3;
  static const _fallbackMax = 10;
  static final _fallbackCharset = RegExp(r'^[A-Za-z0-9\-\s]+$');

  /// ISO2 → unanchored-except-full-string pattern. Matched case-insensitively.
  static const Map<String, String> patternsByIso2 = {
    'IN': r'^[0-9]{6}$',
    'US': r'^[0-9]{5}(-[0-9]{4})?$',
    'GB': r'^(GIR\s?0AA|[A-Z]{1,2}[0-9][A-Z0-9]?\s?[0-9][A-Z]{2})$',
    'CA': r'^[ABCEGHJ-NPRSTVXY][0-9][ABCEGHJ-NPRSTV-Z]\s?[0-9][ABCEGHJ-NPRSTV-Z][0-9]$',
    'AU': r'^[0-9]{4}$',
    'NZ': r'^[0-9]{4}$',
    'DE': r'^[0-9]{5}$',
    'FR': r'^[0-9]{5}$',
    'IT': r'^[0-9]{5}$',
    'ES': r'^[0-9]{5}$',
    'NL': r'^[0-9]{4}\s?[A-Z]{2}$',
    'BE': r'^[0-9]{4}$',
    'CH': r'^[0-9]{4}$',
    'AT': r'^[0-9]{4}$',
    'SE': r'^[0-9]{3}\s?[0-9]{2}$',
    'NO': r'^[0-9]{4}$',
    'DK': r'^[0-9]{4}$',
    'FI': r'^[0-9]{5}$',
    'IE': r'^[A-Z][0-9]{2}\s?[A-Z0-9]{4}$',
    'PT': r'^[0-9]{4}-?[0-9]{3}$',
    'PL': r'^[0-9]{2}-?[0-9]{3}$',
    'CZ': r'^[0-9]{3}\s?[0-9]{2}$',
    'SK': r'^[0-9]{3}\s?[0-9]{2}$',
    'HU': r'^[0-9]{4}$',
    'RO': r'^[0-9]{6}$',
    'BG': r'^[0-9]{4}$',
    'GR': r'^[0-9]{3}\s?[0-9]{2}$',
    'TR': r'^[0-9]{5}$',
    'RU': r'^[0-9]{6}$',
    'UA': r'^[0-9]{5}$',
    'CN': r'^[0-9]{6}$',
    'JP': r'^[0-9]{3}-?[0-9]{4}$',
    'KR': r'^[0-9]{5}$',
    'SG': r'^[0-9]{6}$',
    'MY': r'^[0-9]{5}$',
    'TH': r'^[0-9]{5}$',
    'ID': r'^[0-9]{5}$',
    'PH': r'^[0-9]{4}$',
    'VN': r'^[0-9]{5,6}$',
    'PK': r'^[0-9]{5}$',
    'BD': r'^[0-9]{4}$',
    'LK': r'^[0-9]{5}$',
    'NP': r'^[0-9]{5}$',
    'SA': r'^[0-9]{5}(-[0-9]{4})?$',
    'IL': r'^[0-9]{5,7}$',
    'KW': r'^[0-9]{5}$',
    'BH': r'^[0-9]{3,4}$',
    'OM': r'^[0-9]{3}$',
    'JO': r'^[0-9]{5}$',
    'LB': r'^[0-9]{4}(\s?[0-9]{4})?$',
    'EG': r'^[0-9]{5}$',
    'MA': r'^[0-9]{5}$',
    'TN': r'^[0-9]{4}$',
    'DZ': r'^[0-9]{5}$',
    'ZA': r'^[0-9]{4}$',
    'NG': r'^[0-9]{6}$',
    'KE': r'^[0-9]{5}$',
    'GH': r'^[A-Z]{2}-?[0-9]{3,4}-?[0-9]{4}$',
    'BR': r'^[0-9]{5}-?[0-9]{3}$',
    'MX': r'^[0-9]{5}$',
    'AR': r'^([A-Z][0-9]{4}[A-Z]{3}|[0-9]{4})$',
    'CL': r'^[0-9]{7}$',
    'CO': r'^[0-9]{6}$',
    'PE': r'^[0-9]{5}$',
    'VE': r'^[0-9]{4}$',
    'UY': r'^[0-9]{5}$',
    'PY': r'^[0-9]{4}$',
    'EC': r'^[0-9]{6}$',
    'BO': r'^[0-9]{4}$',
    'HK': r'^[0-9]{6}$',
    'TW': r'^[0-9]{3,5}$',
    'MO': r'^[0-9]{6}$',
    'MM': r'^[0-9]{5}$',
    'KH': r'^[0-9]{5,6}$',
    'LA': r'^[0-9]{5}$',
    'IR': r'^[0-9]{5,10}$',
    'IQ': r'^[0-9]{5}$',
    'AF': r'^[0-9]{4}$',
    'UZ': r'^[0-9]{6}$',
    'KZ': r'^[0-9]{6}$',
    'BY': r'^[0-9]{6}$',
    'LT': r'^[A-Z]{2}-?[0-9]{5}$',
    'LV': r'^(LV-)?[0-9]{4}$',
    'EE': r'^[0-9]{5}$',
    'SI': r'^[0-9]{4}$',
    'HR': r'^[0-9]{5}$',
    'RS': r'^[0-9]{5}$',
    'BA': r'^[0-9]{5}$',
    'MK': r'^[0-9]{4}$',
    'AL': r'^[0-9]{4}$',
    'IS': r'^[0-9]{3}$',
    'LU': r'^[0-9]{4}$',
    'MT': r'^[A-Z]{3}\s?[0-9]{4}$',
    'CY': r'^[0-9]{4}$',
    'GE': r'^[0-9]{4}$',
    'AM': r'^[0-9]{4}$',
    'AZ': r'^[0-9]{4}$',
    'MD': r'^[A-Z]{2}-?[0-9]{4}$',
    'PR': r'^[0-9]{5}(-[0-9]{4})?$',
  };

  static const Map<String, String> messagesByIso2 = {
    'IN': 'Indian pincode must be exactly 6 digits',
    'US': 'Enter a valid US ZIP code (12345 or 12345-6789)',
    'GB': 'Enter a valid UK postcode',
    'CA': 'Enter a valid Canadian postal code',
  };

  static const String genericCountryMessage =
      'Enter a valid postal code for the selected country';

  /// CSC / common names → ISO2. Resolution uses the selected address country, never GPS.
  static const Map<String, String> aliasesToIso2 = {
    'india': 'IN',
    'united states': 'US',
    'united states of america': 'US',
    'usa': 'US',
    'united kingdom': 'GB',
    'great britain': 'GB',
    'uk': 'GB',
    'england': 'GB',
    'scotland': 'GB',
    'wales': 'GB',
    'canada': 'CA',
    'australia': 'AU',
    'new zealand': 'NZ',
    'germany': 'DE',
    'france': 'FR',
    'italy': 'IT',
    'spain': 'ES',
    'netherlands': 'NL',
    'the netherlands': 'NL',
    'belgium': 'BE',
    'switzerland': 'CH',
    'austria': 'AT',
    'sweden': 'SE',
    'norway': 'NO',
    'denmark': 'DK',
    'finland': 'FI',
    'ireland': 'IE',
    'portugal': 'PT',
    'poland': 'PL',
    'czech republic': 'CZ',
    'czechia': 'CZ',
    'slovakia': 'SK',
    'hungary': 'HU',
    'romania': 'RO',
    'bulgaria': 'BG',
    'greece': 'GR',
    'turkey': 'TR',
    'russia': 'RU',
    'ukraine': 'UA',
    'china': 'CN',
    'japan': 'JP',
    'south korea': 'KR',
    'korea': 'KR',
    'singapore': 'SG',
    'malaysia': 'MY',
    'thailand': 'TH',
    'indonesia': 'ID',
    'philippines': 'PH',
    'vietnam': 'VN',
    'pakistan': 'PK',
    'bangladesh': 'BD',
    'sri lanka': 'LK',
    'nepal': 'NP',
    'saudi arabia': 'SA',
    'israel': 'IL',
    'united arab emirates': 'AE',
    'uae': 'AE',
    'qatar': 'QA',
    'kuwait': 'KW',
    'bahrain': 'BH',
    'oman': 'OM',
    'jordan': 'JO',
    'lebanon': 'LB',
    'egypt': 'EG',
    'morocco': 'MA',
    'tunisia': 'TN',
    'algeria': 'DZ',
    'south africa': 'ZA',
    'nigeria': 'NG',
    'kenya': 'KE',
    'ghana': 'GH',
    'brazil': 'BR',
    'mexico': 'MX',
    'argentina': 'AR',
    'chile': 'CL',
    'colombia': 'CO',
    'peru': 'PE',
    'venezuela': 'VE',
    'uruguay': 'UY',
    'paraguay': 'PY',
    'ecuador': 'EC',
    'bolivia': 'BO',
    'hong kong': 'HK',
    'taiwan': 'TW',
    'macau': 'MO',
    'macao': 'MO',
    'myanmar': 'MM',
    'cambodia': 'KH',
    'laos': 'LA',
    'iran': 'IR',
    'iraq': 'IQ',
    'afghanistan': 'AF',
    'uzbekistan': 'UZ',
    'kazakhstan': 'KZ',
    'belarus': 'BY',
    'lithuania': 'LT',
    'latvia': 'LV',
    'estonia': 'EE',
    'slovenia': 'SI',
    'croatia': 'HR',
    'serbia': 'RS',
    'bosnia and herzegovina': 'BA',
    'north macedonia': 'MK',
    'albania': 'AL',
    'iceland': 'IS',
    'luxembourg': 'LU',
    'malta': 'MT',
    'cyprus': 'CY',
    'georgia': 'GE',
    'armenia': 'AM',
    'azerbaijan': 'AZ',
    'moldova': 'MD',
    'puerto rico': 'PR',
  };

  static String? resolveIso2({String? countryIso2, String? countryName}) {
    final iso = (countryIso2 ?? '').trim().toUpperCase();
    if (_isIso2(iso)) return iso;

    final name = (countryName ?? '').trim();
    if (name.isEmpty) return null;
    if (_isIso2(name.toUpperCase()) && name.length == 2) return name.toUpperCase();

    final alias = aliasesToIso2[name.toLowerCase()];
    if (alias != null) return alias;
    return null;
  }

  static bool _isIso2(String value) =>
      value.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(value);

  /// Returns an error message, or null when the format is valid for [iso2].
  static String? validate(
    String value, {
    String? countryIso2,
    String? countryName,
  }) {
    final v = value.trim();
    if (v.isEmpty) return null;

    final iso = resolveIso2(countryIso2: countryIso2, countryName: countryName);
    if (iso == null) return _fallbackValidate(v);

    final pattern = patternsByIso2[iso];
    if (pattern == null) return _fallbackValidate(v);

    if (!RegExp(pattern, caseSensitive: false).hasMatch(v)) {
      return messagesByIso2[iso] ?? genericCountryMessage;
    }
    return null;
  }

  static String? fallbackValidate(String value) => _fallbackValidate(value.trim());

  static String? _fallbackValidate(String v) {
    if (v.length < _fallbackMin || v.length > _fallbackMax) {
      return 'Pincode must be between 3 and 10 characters';
    }
    if (!_fallbackCharset.hasMatch(v)) {
      return 'Pincode contains invalid characters';
    }
    return null;
  }
}
