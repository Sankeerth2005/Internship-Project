import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/features/auth/data/models/location_models.dart';

void main() {
  final countries = [
    Country(name: 'India', iso2: 'IN', phoneCode: '91', emoji: '🇮🇳'),
    Country(name: 'United Arab Emirates', iso2: 'AE', phoneCode: '971', emoji: '🇦🇪'),
    Country(name: 'United States', iso2: 'US', phoneCode: '1', emoji: '🇺🇸'),
    Country(name: 'Canada', iso2: 'CA', phoneCode: '1', emoji: '🇨🇦'),
    Country(name: 'United Kingdom', iso2: 'GB', phoneCode: '44', emoji: '🇬🇧'),
  ];

  group('CountryLookup', () {
    test('maps unique phone code +91 to India', () {
      final country = CountryLookup.resolve(
        countries: countries,
        phoneCode: '+91',
        countryName: 'India',
      );
      expect(country?.iso2, 'IN');
      expect(CountryLookup.flagEmoji(country), '🇮🇳');
    });

    test('maps +971 to UAE even if country name is also present', () {
      final country = CountryLookup.resolve(
        countries: countries,
        phoneCode: '971',
        countryName: 'United Arab Emirates',
      );
      expect(country?.iso2, 'AE');
      expect(CountryLookup.flagEmoji(country), '🇦🇪');
    });

    test('disambiguates shared +1 using country name', () {
      final us = CountryLookup.resolve(
        countries: countries,
        phoneCode: '+1',
        countryName: 'United States',
      );
      final ca = CountryLookup.resolve(
        countries: countries,
        phoneCode: '+1',
        countryName: 'Canada',
      );
      expect(us?.iso2, 'US');
      expect(ca?.iso2, 'CA');
    });

    test('does not assume India when phone code and country are missing', () {
      final country = CountryLookup.resolve(
        countries: countries,
        phoneCode: '',
        countryName: '',
      );
      expect(country, isNull);
      expect(CountryLookup.flagEmoji(country), isNull);
    });

    test('falls back to country name for legacy records without phone code', () {
      final country = CountryLookup.resolve(
        countries: countries,
        phoneCode: '',
        countryName: 'United Kingdom',
      );
      expect(country?.iso2, 'GB');
      expect(CountryLookup.flagEmoji(country), '🇬🇧');
    });

    test('does not pick a country when shared calling code cannot be disambiguated', () {
      final country = CountryLookup.resolve(
        countries: countries,
        phoneCode: '+1',
        countryName: '',
      );
      expect(country, isNull);
    });
  });
}
