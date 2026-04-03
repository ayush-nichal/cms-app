class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!emailRegex.hasMatch(value)) return 'Invalid email format';
    return null;
  }

  static String? minLength(String? value, int min, String fieldName) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, String fieldName) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Password must contain at least one uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Password must contain at least one number';
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final numRegex = RegExp(r'^[0-9]{10,15}$');
    if (!numRegex.hasMatch(value.trim())) return 'Phone number must be 10-15 digits';
    return null;
  }
}
