import 'package:flutter_test/flutter_test.dart';
import 'package:localink_mobile/core/validation/app_validators.dart';

void main() {
  group('AppValidators.phone', () {
    test('rejects empty when required', () {
      expect(AppValidators.phone('', countryCode: '91'), 'Phone number is required');
    });

    test('accepts valid Indian mobile', () {
      expect(
        AppValidators.phone('9876543210', countryCode: '91', countryName: 'India'),
        isNull,
      );
    });

    test('rejects short Indian number', () {
      expect(
        AppValidators.phone('98765', countryCode: '91'),
        'Indian phone number must be exactly 10 digits',
      );
    });

    test('rejects Indian number starting with 5', () {
      expect(
        AppValidators.phone('5876543210', countryCode: '91'),
        contains('start with 6'),
      );
    });

    test('rejects letters', () {
      expect(
        AppValidators.phone('98abc43210', countryCode: '91'),
        'Phone number cannot contain letters',
      );
    });

    test('strips matching country code prefix', () {
      expect(
        AppValidators.nationalNumber('+919876543210', '91'),
        '9876543210',
      );
      expect(
        AppValidators.phone('+919876543210', countryCode: '+91'),
        isNull,
      );
    });

    test('US numbers must be 10 digits', () {
      expect(AppValidators.phone('2025550123', countryCode: '1'), isNull);
      expect(
        AppValidators.phone('202555012', countryCode: '1'),
        contains('10 digits'),
      );
    });

    test('revalidation after country change', () {
      expect(AppValidators.phone('9876543210', countryCode: '91'), isNull);
      expect(
        AppValidators.phone('9876543210', countryCode: '33'),
        contains('9 digits'),
      );
    });
  });

  group('AppValidators.pincode', () {
    test('Indian pincode must be 6 digits', () {
      expect(
        AppValidators.pincode('560001', required: true, countryName: 'India'),
        isNull,
      );
      expect(
        AppValidators.pincode('56000', required: true, countryName: 'India'),
        'Indian pincode must be exactly 6 digits',
      );
      expect(
        AppValidators.pincode('560001', required: true, countryIso2: 'IN'),
        isNull,
      );
    });

    test('does not apply Indian rules from a +91 phone code when country is not India', () {
      expect(
        AppValidators.pincode(
          'SW1A 1AA',
          countryName: 'United Kingdom',
          countryIso2: 'GB',
          countryCode: '91',
        ),
        isNull,
      );
      expect(
        AppValidators.pincode(
          '500035',
          countryName: 'United Kingdom',
          countryIso2: 'GB',
          countryCode: '91',
        ),
        'Enter a valid UK postcode',
      );
    });

    test('US ZIP and ZIP+4', () {
      expect(
        AppValidators.pincode('10001', countryIso2: 'US'),
        isNull,
      );
      expect(
        AppValidators.pincode('10001-1234', countryName: 'United States'),
        isNull,
      );
      expect(
        AppValidators.pincode('1000', countryIso2: 'US'),
        'Enter a valid US ZIP code (12345 or 12345-6789)',
      );
    });

    test('UK and Canadian postal formats', () {
      expect(
        AppValidators.pincode('SW1A 1AA', countryIso2: 'GB'),
        isNull,
      );
      expect(
        AppValidators.pincode('K1A 0B1', countryIso2: 'CA'),
        isNull,
      );
      expect(
        AppValidators.pincode('123456', countryIso2: 'CA'),
        'Enter a valid Canadian postal code',
      );
    });

    test('unknown country uses 3–10 alphanumeric fallback', () {
      expect(
        AppValidators.pincode('AB12', countryName: 'Atlantis'),
        isNull,
      );
      expect(
        AppValidators.pincode('12', countryName: 'Atlantis'),
        'Pincode must be between 3 and 10 characters',
      );
    });

    test('async error is returned until cleared', () {
      expect(
        AppValidators.pincode(
          '560001',
          countryName: 'India',
          asyncError: 'Invalid or unverified pincode',
        ),
        'Invalid or unverified pincode',
      );
      expect(
        AppValidators.pincode('560001', countryName: 'India', asyncError: null),
        isNull,
      );
    });
  });

  group('AppValidators.name / email / password', () {
    test('rejects whitespace-only name', () {
      expect(AppValidators.name('   '), 'Name is required');
    });

    test('email trims and validates', () {
      expect(AppValidators.email('  user@example.com  '), isNull);
      expect(AppValidators.email('not-an-email'), 'Invalid email format');
    });

    test('password confirmation', () {
      expect(AppValidators.confirmPassword('Abcd1234!', 'Abcd1234!'), isNull);
      expect(AppValidators.confirmPassword('other', 'Abcd1234!'), 'Passwords do not match');
    });
  });
}
