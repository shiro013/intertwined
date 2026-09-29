
class Validators {
  Validators._();

  static String? requiredField(String? value, {String fieldName = 'Field ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? minLength(String? value, int min, {String fieldName = 'Field ini'}) {
    final requiredError = requiredField(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < min) {
      return '$fieldName minimal $min karakter';
    }
    return null;
  }
}
