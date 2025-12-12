class TimetableUtils {
  /// Parses a time string (e.g., "09:40", "9:40", "01:30 PM", "13:30")
  /// into minutes from midnight.
  static int parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      timeStr = timeStr.trim().toUpperCase();
      bool isPm = timeStr.contains('PM');
      bool isAm = timeStr.contains('AM');

      // Remove suffixes
      String cleanTime = timeStr.replaceAll(RegExp(r'[A-Z\s]'), '');
      List<String> parts = cleanTime.split(':');

      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      // Handle 12-hour format
      // AM/PM adjustment
      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      // Heuristic: If NO AM/PM suffix is found, but the hour is between 1 and 6,
      // treat it as PM (13:00 - 18:00).
      // This matches the user's rule: "The app must ALWAYS assume that times after 01:00 PM are PM values."
      if (!isPm && !isAm) {
        if (hour >= 1 && hour <= 6) {
          hour += 12;
        }
      }

      return hour * 60 + minute;
    } catch (e) {
      return 0; // Fallback
    }
  }

  /// Sorts a list of class entries by startTime.
  static void sortClassesByTime(List<Map<String, dynamic>> classes) {
    classes.sort((a, b) {
      return parseTimeToMinutes(
        a['start_time'].toString(),
      ).compareTo(parseTimeToMinutes(b['start_time'].toString()));
    });
  }

  /// Standardize time string to "HH:MM" (24-hour).
  static String normalizeTo24Hour(String timeStr) {
    int minutes = parseTimeToMinutes(timeStr);
    int h = minutes ~/ 60;
    int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Convert 24-hour time string (e.g., "13:30") to 12-hour format (e.g., "01:30 PM").
  static String formatTime12H(String time24h) {
    if (time24h.isEmpty) return "";
    try {
      final parts = time24h.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);

      String period = h >= 12 ? 'PM' : 'AM';
      int h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);

      return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24h; // Fallback
    }
  }
}
