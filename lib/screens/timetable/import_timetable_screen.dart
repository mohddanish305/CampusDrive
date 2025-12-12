import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:campusdrive/utils/timetable_utils.dart';

class ImportTimetableScreen extends StatefulWidget {
  const ImportTimetableScreen({super.key});

  @override
  State<ImportTimetableScreen> createState() => _ImportTimetableScreenState();
}

class _ImportTimetableScreenState extends State<ImportTimetableScreen> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isValid = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _parsedClasses = [];
  bool _isImporting = false;

  // Mapping for Day name to Int
  final Map<String, int> _dayMap = {
    'MON': 1,
    'MONDAY': 1,
    'TUE': 2,
    'TUESDAY': 2,
    'WED': 3,
    'WEDNESDAY': 3,
    'THU': 4,
    'THURSDAY': 4,
    'FRI': 5,
    'FRIDAY': 5,
    'SAT': 6,
    'SATURDAY': 6,
    'SUN': 7,
    'SUNDAY': 7,
  };

  void _validateJson(String text) {
    if (text.isEmpty) {
      setState(() {
        _isValid = false;
        _errorMessage = '';
        _parsedClasses = [];
      });
      return;
    }

    try {
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic> || !data.containsKey('classes')) {
        throw const FormatException(
          'Missing "classes" root key or invalid format.',
        );
      }

      final List<dynamic> classesList = data['classes'];
      if (classesList.isEmpty) {
        throw const FormatException('Classes list is empty.');
      }

      List<Map<String, dynamic>> validated = [];

      for (var item in classesList) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid class entry format.');
        }

        // Check keys
        if (!item.containsKey('subjectName') ||
            !item.containsKey('teacherName') ||
            !item.containsKey('day') ||
            !item.containsKey('startTime') ||
            !item.containsKey('endTime')) {
          throw const FormatException(
            'Missing required fields in a class entry.',
          );
        }

        // Validate Day
        String dayStr = item['day'].toString().toUpperCase();
        if (!_dayMap.containsKey(dayStr)) {
          throw FormatException('Invalid day: $dayStr. Use MON, TUE, etc.');
        }

        validated.add({
          'subject': item['subjectName'],
          'description':
              item['teacherName'], // Mapping teacherName to description as per DB
          'day': _dayMap[dayStr],
          'start_time': TimetableUtils.normalizeTo24Hour(item['startTime']),
          'end_time': TimetableUtils.normalizeTo24Hour(item['endTime']),
          'room': '',
          'color': 0xFF7C3AED, // Default color
        });
      }

      setState(() {
        _isValid = true;
        _errorMessage = '';
        _parsedClasses = validated;
      });
    } catch (e) {
      setState(() {
        _isValid = false;
        _errorMessage = e.toString().replaceAll("FormatException:", "").trim();
        if (_errorMessage.isEmpty) _errorMessage = "Invalid JSON format.";
        _parsedClasses = [];
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        _jsonController.text = content;
        _validateJson(content);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _importTimetable() async {
    setState(() => _isImporting = true);
    try {
      final db = DatabaseService();
      await db.clearTimetable(); // Clear existing

      int count = 0;
      for (var cls in _parsedClasses) {
        cls['id'] = const Uuid().v4();
        await db.insertClass(cls);
        count++;
      }

      debugPrint('Timetable imported: $count classes inserted.'); // Debug log

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Timetable imported! ($count classes)')),
        );
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _pasteSample() {
    const sample = '''
{
  "classes": [
    {
      "subjectName": "Artificial Intelligence",
      "teacherName": "Mr. T. Ramakrishna",
      "day": "MON",
      "startTime": "09:40 AM",
      "endTime": "10:30 AM"
    },
    {
      "subjectName": "Machine Learning",
      "teacherName": "Mr. V. Sudhakar",
      "day": "MON",
      "startTime": "10:30 AM",
      "endTime": "11:20 AM"
    }
  ]
}
''';
    _jsonController.text = sample;
    _validateJson(sample);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Timetable'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Upload a JSON file or paste JSON text",
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // File Import Area
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF), // Light purple bg
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7C3AED),
                    style: BorderStyle.none,
                  ), // Or dashed border library
                ),
                // Dashed border simulation with CustomPaint is overkill, standard border is fine or dotted via library.
                // Let's stick to simple design.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload_file, size: 40, color: Color(0xFF7C3AED)),
                    SizedBox(height: 8),
                    Text(
                      "Drop JSON file here or Browse",
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Text Area
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Or paste JSON text",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _pasteSample,
                  child: const Text(
                    "Paste sample",
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jsonController,
              maxLines: 8,
              onChanged: _validateJson,
              decoration: InputDecoration(
                hintText: '{"classes": [{"subjectName": "...", ...}]}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey.shade50,
                filled: true,
              ),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
            ),

            const SizedBox(height: 20),

            // Validation Message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isValid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "JSON looks good ✅",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Preview (Draft)
            if (_isValid && _parsedClasses.isNotEmpty) ...[
              const Text(
                "Preview (First 3 items)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._parsedClasses
                  .take(3)
                  .map(
                    (e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(e['day'].toString())),
                        title: Text(e['subject']),
                        subtitle: Text(
                          "${e['start_time']} - ${e['end_time']} • ${e['description']}",
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
            ],

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isValid && !_isImporting)
                        ? _importTimetable
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Import Timetable"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
