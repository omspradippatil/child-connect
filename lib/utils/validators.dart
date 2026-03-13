class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _phonePattern = RegExp(r'^[0-9]{10,15}$');

  static String? requiredText(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? name(String? value, {String fieldName = 'Name'}) {
    final requiredError = requiredText(value, fieldName: fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredText(value, fieldName: 'Email');
    if (requiredError != null) {
      return requiredError;
    }

    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? password(String? value, {bool strict = true}) {
    final requiredError = requiredText(value, fieldName: 'Password');
    if (requiredError != null) {
      return requiredError;
    }

    final minLength = strict ? 8 : 4;
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    return null;
  }

  static String? phone(String? value) {
    final requiredError = requiredText(value, fieldName: 'Phone');
    if (requiredError != null) {
      return requiredError;
    }

    final normalized = value!.replaceAll(RegExp(r'\s+'), '');
    if (!_phonePattern.hasMatch(normalized)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? minLength(String? value, int min, String fieldName) {
    final requiredError = requiredText(value, fieldName: fieldName);
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }

    return null;
  }
}
