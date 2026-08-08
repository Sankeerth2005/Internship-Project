/// Shared form validators — keep auth screens aligned with backend rules.
class AppValidators {
  AppValidators._();

  static final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Matches signup + backend: upper, lower, digit, special from @$!%*?&
  static final strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  static String? email(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Email is required' : null;
    if (v.length > 256) return 'Email cannot exceed 256 characters';
    if (!emailRegex.hasMatch(v)) return 'Invalid email format';
    return null;
  }

  static String? phone(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Phone number is required' : null;
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(v)) {
      return 'Phone number must be between 7 and 15 digits';
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

  static bool hasUpper(String v) => RegExp(r'[A-Z]').hasMatch(v);
  static bool hasLower(String v) => RegExp(r'[a-z]').hasMatch(v);
  static bool hasDigit(String v) => RegExp(r'[0-9]').hasMatch(v);
  static bool hasSpecial(String v) => RegExp(r'[@$!%*?&]').hasMatch(v);
  static bool hasMinLength(String v, [int min = 8]) => v.length >= min;
}
