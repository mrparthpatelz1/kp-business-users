import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AppDateUtils {
  /// Detects date-only strings like "2026-02-18" (no time component).
  static bool _isDateOnly(String dateStr) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr.trim());
  }

  /// Parses a timestamp string and converts to local time.
  /// For date-only strings, returns the date without timezone conversion.
  static DateTime? _parseTimestamp(String dateStr) {
    try {
      // Date-only strings (YYYY-MM-DD) should NOT be timezone-converted
      if (_isDateOnly(dateStr)) {
        return DateTime.parse(dateStr);
      }

      DateTime date = DateTime.parse(dateStr);
      if (dateStr.contains('Z') || dateStr.contains('+')) {
        date = date.toLocal();
      } else {
        // No timezone marker — treat as UTC and convert to local
        date = DateTime.parse('${dateStr.replaceAll(' ', 'T')}Z').toLocal();
      }
      return date;
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return null;
    }
  }

  static String formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = _parseTimestamp(dateStr);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);
    final minutes = diff.inMinutes;

    if (minutes < 1) {
      return 'Just now';
    } else if (minutes < 60) {
      return '${minutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Formats as dd-MM-yyyy (e.g. 18-02-2026)
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = _parseTimestamp(dateStr);
    if (date == null) return '';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  /// Formats as dd/MM/yyyy (e.g. 18/02/2026)
  static String formatDateSlash(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = _parseTimestamp(dateStr);
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formats as MMM d, yyyy (e.g. Feb 18, 2026)
  static String formatDateFull(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = _parseTimestamp(dateStr);
    if (date == null) return '';
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Formats as HH:mm (e.g. 22:50)
  static String formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = _parseTimestamp(dateStr);
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }
}
