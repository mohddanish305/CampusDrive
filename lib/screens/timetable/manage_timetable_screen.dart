import 'package:flutter/material.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:campusdrive/screens/timetable/class_editor_screen.dart';
import 'package:campusdrive/screens/timetable/import_timetable_screen.dart';
import 'package:campusdrive/utils/timetable_utils.dart';

class ManageTimetableScreen extends StatefulWidget {
  const ManageTimetableScreen({super.key});

  @override
  State<ManageTimetableScreen> createState() => _ManageTimetableScreenState();
}

class _ManageTimetableScreenState extends State<ManageTimetableScreen> {
  bool _isLoading = true;
  Map<int, List<Map<String, dynamic>>> _groupedClasses = {};

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final db = DatabaseService();
    Map<int, List<Map<String, dynamic>>> tempGrouped = {};

    for (int i = 1; i <= 7; i++) {
      final classes = await db.getClassesForDay(i);
      if (classes.isNotEmpty) {
        List<Map<String, dynamic>> sorted = List.from(classes);
        TimetableUtils.sortClassesByTime(sorted);
        tempGrouped[i] = sorted;
      }
    }

    if (mounted) {
      setState(() {
        _groupedClasses = tempGrouped;
        _isLoading = false;
      });
    }
  }

  void _enableSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      int totalClasses = 0;
      _groupedClasses.forEach((_, list) => totalClasses += list.length);

      if (_selectedIds.length == totalClasses) {
        _selectedIds.clear();
      } else {
        _groupedClasses.forEach((_, list) {
          for (var cls in list) {
            _selectedIds.add(cls['id']);
          }
        });
      }
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected?'),
        content: Text(
          'Delete ${_selectedIds.length} classes? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final db = DatabaseService();
              for (String id in _selectedIds) {
                await db.deleteClass(id);
              }
              setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              });
              _loadClasses();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectionMode) {
          setState(() {
            _selectionMode = false;
            _selectedIds.clear();
          });
        }
      },
      child: Scaffold(
        appBar: _selectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
                title: Text('${_selectedIds.length} selected'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelected,
                  ),
                ],
              )
            : AppBar(title: const Text('Manage Timetable')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (!_selectionMode)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ImportTimetableScreen(),
                            ),
                          );
                          if (result == true) _loadClasses();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.upload_file, color: Color(0xFF7C3AED)),
                              SizedBox(width: 8),
                              Text(
                                "Import from JSON",
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _groupedClasses.isEmpty
                        ? const Center(child: Text("No classes added yet."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 7, // Mon-Sun
                            itemBuilder: (context, index) {
                              final dayIndex = index + 1;
                              final classes = _groupedClasses[dayIndex];

                              if (classes == null || classes.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      _days[index].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.grey,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  ...classes.map((cls) => _buildClassRow(cls)),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassEditorScreen(),
                    ),
                  );
                  if (result == true) _loadClasses();
                },
                backgroundColor: const Color(0xFF7C3AED),
                child: const Icon(Icons.add, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildClassRow(Map<String, dynamic> cls) {
    final bool isSelected = _selectedIds.contains(cls['id']);

    return GestureDetector(
      onLongPress: () {
        if (!_selectionMode) _enableSelectionMode(cls['id']);
      },
      onTap: () {
        if (_selectionMode) {
          _toggleSelection(cls['id']);
        } // Normal tap handled in trailing menu for edit/delete, or here if we want tap-to-edit when not selecting.
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.grey,
                  ),
                ),
              // Time Column
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Text(
                      TimetableUtils.formatTime12H(
                        cls['start_time'].toString(),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '|',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      TimetableUtils.formatTime12H(cls['end_time'].toString()),
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls['subject'] ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (cls['description'] != null &&
                        cls['description'].toString().isNotEmpty)
                      Text(
                        cls['description'], // Teacher Name
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Menu
              if (!_selectionMode)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassEditorScreen(classItem: cls),
                        ),
                      );
                      if (result == true) _loadClasses();
                    } else if (val == 'delete') {
                      _showDeleteConfirmation(cls['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Class?'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DatabaseService().deleteClass(id);
              _loadClasses();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
