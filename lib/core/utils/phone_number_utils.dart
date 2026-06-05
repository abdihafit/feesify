class PhoneNumberUtils {
  static final RegExp _kenyanPhonePattern = RegExp(r'^(07|01)\d{8}$');

  static String normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  static bool isValidKenyanMobile(String value) {
    return _kenyanPhonePattern.hasMatch(normalize(value));
  }

  static bool looksLikePhone(String value) {
    final String normalized = normalize(value);
    return RegExp(r'^\d+$').hasMatch(normalized);
  }
}
