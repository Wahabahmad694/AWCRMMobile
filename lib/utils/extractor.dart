import 'package:intl/intl.dart';

class Extractor {
  Extractor._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MM-dd');

  /// Safely converts dynamic value to int (handles int, double, num, String, null)
  static int asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null) return asDouble.round();
    }
    return fallback;
  }

  /// Safely converts dynamic value to nullable int
  static int? asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == 'null') return null;
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null) return asDouble.round();
    }
    return null;
  }

  /// Safely converts dynamic value to double
  static double asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  /// Safely converts dynamic value to bool
  static bool asBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return fallback;
  }

  /// Converts paisa integer to PKR formatted string: 12550 -> "Rs 125.50"
  static String formatPkr(dynamic paisa) {
    if (paisa == null) return 'Rs 0.00';
    num val;
    if (paisa is num) {
      val = paisa;
    } else {
      val = num.tryParse(paisa.toString()) ?? 0;
    }
    final rupees = val / 100.0;
    return 'Rs ${_currencyFormat.format(rupees)}';
  }

  /// Converts rupees decimal string or number to paisa integer
  static int toPaisa(dynamic amount) {
    if (amount == null) return 0;
    if (amount is int) return amount * 100;
    if (amount is double) return (amount * 100).round();
    final parsed = double.tryParse(amount.toString().replaceAll(',', '').trim());
    if (parsed == null) return 0;
    return (parsed * 100).round();
  }

  /// Format date string or DateTime into "20 Oct 2026"
  static String formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      if (date is DateTime) return _dateFormat.format(date.toLocal());
      final parsed = DateTime.parse(date.toString());
      return _dateFormat.format(parsed.toLocal());
    } catch (_) {
      return date.toString();
    }
  }

  /// Format date string or DateTime into "20 Oct 2026, 03:30 PM"
  static String formatDateTime(dynamic date) {
    if (date == null) return '—';
    try {
      if (date is DateTime) return _dateTimeFormat.format(date.toLocal());
      final parsed = DateTime.parse(date.toString());
      return _dateTimeFormat.format(parsed.toLocal());
    } catch (_) {
      return date.toString();
    }
  }

  /// Format short date "10-20" for chart axis
  static String formatShortDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is DateTime) return _shortDateFormat.format(date.toLocal());
      final parsed = DateTime.parse(date.toString());
      return _shortDateFormat.format(parsed.toLocal());
    } catch (_) {
      return date.toString();
    }
  }

  /// Safely extracts items list from envelope data
  static List<Map<String, dynamic>> extractItems(dynamic responseData) {
    if (responseData == null) return [];
    if (responseData is List) {
      return responseData.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    if (responseData is Map) {
      if (responseData['items'] is List) {
        return (responseData['items'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      if (responseData['data'] is List) {
        return (responseData['data'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      if (responseData['rows'] is List) {
        return (responseData['rows'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    }
    return [];
  }

  /// Safely extracts total count
  static int? extractTotal(dynamic responseData) {
    if (responseData is! Map) return null;
    final meta = responseData['meta'] is Map ? responseData['meta'] as Map : null;
    final pagination = responseData['pagination'] is Map ? responseData['pagination'] as Map : null;
    if (meta != null && meta['total'] != null) return asNullableInt(meta['total']);
    if (pagination != null && pagination['total'] != null) return asNullableInt(pagination['total']);
    if (responseData['total'] != null) return asNullableInt(responseData['total']);
    return null;
  }
}
