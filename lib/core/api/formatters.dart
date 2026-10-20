import 'dart:math';
import 'package:intl/intl.dart';

/// Formats integer paisa into currency string according to PK locale (e.g. Rs 1,250 or Rs 1,250.50).
String rupees(int paisa) => NumberFormat.currency(
  locale: 'en_PK',
  symbol: 'Rs ',
  decimalDigits: paisa % 100 == 0 ? 0 : 2,
).format(paisa / 100);

String formatPkr(int paisa) => rupees(paisa);

/// Parses a decimal string exactly into integer paisa without floating point inaccuracy.
/// e.g. '1250.50' -> 125050
int? parsePaisa(String input) {
  final match = RegExp(r'^\s*(\d+)(?:\.(\d{1,2}))?\s*$').firstMatch(input);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return null;
  final fractional = (match.group(2) ?? '').padRight(2, '0');
  final cents = int.tryParse(fractional);
  if (cents == null) return null;
  return whole * 100 + cents;
}

/// Generates an RFC 4122 compliant UUID v4 to be used as a stable Idempotency-Key.
String generateIdempotencyKey() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10xx
  return [
    bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    bytes.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    bytes.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    bytes.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    bytes.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
  ].join('-');
}

/// Formats a date into YYYY-MM-DD for Asia/Karachi (UTC+5).
/// Contract specifies: Dates are YYYY-MM-DD in the organization's time zone (Asia/Karachi).
/// Send them as plain strings and don't convert them through client DateTime time zones.
String formatKarachiDate([DateTime? date]) {
  final d = (date ?? DateTime.now()).toUtc().add(const Duration(hours: 5));
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

