import 'dart:math';
import 'package:intl/intl.dart';

class Helpers {
  // Generate random 6-digit password
  static String generateRandomPassword() {
    Random random = Random();
    int password = 100000 + random.nextInt(900000);
    return password.toString();
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format time
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
  }

  // Format time to 12-hour format
  static String formatTime12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  // Check if date is second Sunday of month
  static bool isSecondSunday(DateTime date) {
    if (date.weekday != DateTime.sunday) return false;

    int dayOfMonth = date.day;
    return dayOfMonth >= 8 && dayOfMonth <= 14;
  }

  // Get next second Sunday
  static DateTime getNextSecondSunday() {
    DateTime now = DateTime.now();
    DateTime firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

    // Find first Sunday
    int daysUntilSunday = (DateTime.sunday - firstDayOfNextMonth.weekday) % 7;
    DateTime firstSunday = firstDayOfNextMonth.add(Duration(days: daysUntilSunday));

    // Second Sunday is 7 days after first Sunday
    DateTime secondSunday = firstSunday.add(Duration(days: 7));

    return secondSunday;
  }

  // Calculate password active times
  static Map<String, DateTime> calculatePasswordTimes(
    String scheduledDate,
    String startTime,
    String endTime,
  ) {
    // Parse scheduled date (YYYY-MM-DD)
    final dateParts = scheduledDate.split('-');
    int year = int.parse(dateParts[0]);
    int month = int.parse(dateParts[1]);
    int day = int.parse(dateParts[2]);

    // Parse start time (HH:mm)
    final startParts = startTime.split(':');
    int startHour = int.parse(startParts[0]);
    int startMinute = int.parse(startParts[1]);

    // Parse end time (HH:mm)
    final endParts = endTime.split(':');
    int endHour = int.parse(endParts[0]);
    int endMinute = int.parse(endParts[1]);

    // Create DateTime objects
    DateTime classStart = DateTime(year, month, day, startHour, startMinute);
    DateTime classEnd = DateTime(year, month, day, endHour, endMinute);

    // Password active from 5 minutes before class
    DateTime passwordActiveFrom = classStart.subtract(Duration(minutes: 5));

    return {
      'passwordActiveFrom': passwordActiveFrom,
      'passwordActiveUntil': classEnd,
    };
  }

  // Check if class is currently active
  static bool isClassActive(DateTime activeFrom, DateTime activeUntil) {
    DateTime now = DateTime.now();
    return now.isAfter(activeFrom) && now.isBefore(activeUntil);
  }
}
