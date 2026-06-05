import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatAmount(num amount) {
    return NumberFormat.currency(
      locale: 'en_KE',
      symbol: 'KES ',
      decimalDigits: 2,
    ).format(amount);
  }
}
