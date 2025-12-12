import 'package:flutter/material.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:uuid/uuid.dart';

class ClassEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? classItem;

  const ClassEditorScreen({super.key, this.classItem});

  @override
  State<ClassEditorScreen> createState() => _ClassEditorScreenState();
}

class _ClassEditorScreenState extends State<ClassEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  // Day dropdown

  // Note: App logic uses: 1=Mon, ..., 7=Sun.
  // Standard DateTime.weekday: 1=Mon, 7=Sun.
  // Wait, let's stick to standard DateTime.weekday.
  // Dropdown list: Mon-Sat (as requested), or Mon-Sun to be safe.
  final List<String> _displayDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  String _selectedDayStr = 'Monday';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classItem != null) {
      _subjectController.text = widget.classItem!['subject'] ?? '';
      _teacherController.text =
          widget.classItem!['description'] ??
          ''; // Teacher name stored in description

      // Parse Time
      _startTime = _parseTime(widget.classItem!['start_time']);
      _endTime = _parseTime(widget.classItem!['end_time']);

      // Parse Day
      int dayInt = widget.classItem!['day'] ?? 1;
      // DatabaseService might use 1=Mon.
      if (dayInt >= 1 && dayInt <= 7) {
        _selectedDayStr = _displayDays[dayInt - 1];
      }
    }
  }

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 9, minute: 0);
    try {
      // Handle 24-hour format "13:30"
      if (!timeStr.contains('AM') && !timeStr.contains('PM')) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // Handle 12-hour format "9:00 AM" (Legacy support)
      final parts = timeStr.split(' '); // ["9:00", "AM"]
      final hm = parts[0].split(':');
      int h = int.parse(hm[0]);
      int m = int.parse(hm[1]);
      if (parts[1] == 'PM' && h != 12) h += 12;
      if (parts[1] == 'AM' && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: m);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();

      final String subject = _subjectController.text;
      final String teacher = _teacherController.text;

      // Format as 24-hour for storage: HH:mm
      final String startStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final String endStr =
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      // Convert selected day string to int (1=Mon)
      int dayInt = _displayDays.indexOf(_selectedDayStr) + 1;

      if (widget.classItem == null) {
        // Add
        await db.insertClass({
          'id': const Uuid().v4(),
          'day': dayInt,
          'subject': subject,
          'start_time': startStr,
          'end_time': endStr,
          'room': '', // Deprecated/Removed from UI
          'description': teacher,
          'color': 0xFF7C3AED, // Default
        });
      } else {
        // Edit
        await db.insertClass({
          'id': widget.classItem!['id'],
          'day': dayInt,
          'subject': subject,
          'start_time': startStr,
          'end_time': endStr,
          'room': '',
          'description': teacher,
          'color': widget.classItem!['color'] ?? 0xFF7C3AED,
        });
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving class: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    // Keep this for UI display in the form fields (12-hour format is user-friendly)
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classItem == null ? 'Add Class' : 'Edit Class'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _teacherController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Day Dropdown
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDayStr,
                          isDense: true,
                          items: _displayDays
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedDayStr = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(_formatTime(_startTime)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time_filled),
                              ),
                              child: Text(_formatTime(_endTime)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveClass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Class',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    if (widget.classItem == null)
                      const SizedBox.shrink()
                    else
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
