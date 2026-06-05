import 'phone_number_utils.dart';

class Validators {
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? loginIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone number is required';
    }

    final String normalized = value.trim();
    if (normalized.contains('@')) {
      return email(normalized);
    }

    if (!PhoneNumberUtils.isValidKenyanMobile(normalized)) {
      return 'Use 07xxxxxxxx or 01xxxxxxxx';
    }

    return null;
  }

  static String? kenyanPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (!PhoneNumberUtils.isValidKenyanMobile(value)) {
      return 'Use 07xxxxxxxx or 01xxxxxxxx';
    }

    return null;
  }
}
