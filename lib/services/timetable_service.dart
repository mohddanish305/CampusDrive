import 'package:campusdrive/services/database_service.dart';

class TimetableService {
  final DatabaseService _db = DatabaseService();

  Future<void> addClass(Map<String, dynamic> classData) async {
    final db = await _db.database;
    await db.insert('timetable', classData);

    // Schedule notification 10 mins before
    // This logic needs to be robust for weekly repetition.
    // Detailed implementation omitted for brevity, simpler notify call:
    _scheduleClassAlert(classData);
  }

  Future<void> _scheduleClassAlert(Map<String, dynamic> classData) async {
    // Parse time, find next occurrence, schedule.
    // For now, just a placeholder call
    // _notifications.scheduleNotification(...);
  }

  Future<List<Map<String, dynamic>>> getClasses(int day) async {
    final db = await _db.database;
    return await db.query(
      'timetable',
      where: 'day = ?',
      whereArgs: [day],
      orderBy: 'start_time ASC',
    );
  }

  Future<void> deleteClass(String id) async {
    final db = await _db.database;
    await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }
}
