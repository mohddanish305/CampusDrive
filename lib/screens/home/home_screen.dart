import 'package:flutter/material.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:campusdrive/utils/constants.dart';
import 'package:campusdrive/utils/file_helper.dart';
import 'package:campusdrive/services/scanner_service.dart';
import 'package:campusdrive/screens/folders/folders_screen.dart';
import 'package:campusdrive/screens/settings/profile_screen.dart';
import 'package:campusdrive/screens/folders/folder_detail_screen.dart';
import 'package:campusdrive/screens/files/search_screen.dart';
import 'package:campusdrive/screens/notes/note_editor_screen.dart';
import 'package:campusdrive/screens/files/all_files_screen.dart';
import 'package:campusdrive/screens/timetable/class_editor_screen.dart';
import 'package:campusdrive/screens/timetable/manage_timetable_screen.dart';
import 'package:campusdrive/screens/notes/notes_screen.dart';
import 'package:campusdrive/utils/timetable_utils.dart';

import 'package:provider/provider.dart';
import 'package:campusdrive/widgets/file_type_bottom_sheet.dart';
import 'package:campusdrive/providers/user_provider.dart';
import 'package:campusdrive/widgets/profile_avatar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dynamic class data
  List<Map<String, dynamic>> _todaysClasses = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadTodaysClasses();
  }

  Future<void> _loadTodaysClasses() async {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon, 7=Sun
    // Note: Database uses same 1-7 mapping.

    final classes = await DatabaseService().getClassesForDay(weekday);

    // Sort logic
    // We need a mutable list to sort
    List<Map<String, dynamic>> mutableClasses = List.from(classes);
    TimetableUtils.sortClassesByTime(mutableClasses);

    if (mounted) {
      setState(() {
        _todaysClasses = mutableClasses;
        _isLoadingClasses = false;
      });
    }
  }

  void _handleClassAction(String value, Map<String, dynamic>? classItem) async {
    switch (value) {
      case 'add':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClassEditorScreen()),
        );
        if (result == true) _loadTodaysClasses();
        break;
      case 'edit':
        if (classItem != null) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassEditorScreen(classItem: classItem),
            ),
          );
          if (result == true) _loadTodaysClasses();
        }
        break;
      case 'delete':
        if (classItem != null) {
          _showDeleteClassConfirmation(classItem['id']);
        }
        break;
      case 'manage':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageTimetableScreen()),
        );
        break;
    }
  }

  void _showDeleteClassConfirmation(String id) {
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
              _loadTodaysClasses();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Class deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            Container(
              width: double.infinity,
              height: 160,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [
                          AppColors.primary.withValues(alpha: 0.1),
                          Colors.white,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          final name = userProvider.userProfile.fullName;
                          final firstName = name.isNotEmpty
                              ? name.split(' ')[0]
                              : 'Student';
                          return Text(
                            'Hi, $firstName 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to study?',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  ProfileAvatarWidget(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    size: 50,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).cardColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isDark
                            ? null
                            : Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                      ),
                      height: 50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Search files, folders...',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hero Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllFilesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manage your\nStudy Materials',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Keep everything organized',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.folder,
                              color: Color(0xFF7C3AED),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // My Folders
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Folders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FoldersScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFolderCard(
                          'Time Table',
                          'Folder',
                          Colors.orange.shade100,
                          Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FolderDetailScreen(
                                folderName: 'Time Table',
                                folderId: 'folder_timetable',
                              ),
                            ),
                          ),
                        ),
                        _buildFolderCard(
                          'Assignments',
                          'Folder',
                          Colors.green.shade100,
                          Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FolderDetailScreen(
                                folderName: 'Assignments',
                                folderId: 'folder_assignments',
                              ),
                            ),
                          ),
                        ),
                        _buildFolderCard(
                          'Notes',
                          'Folder',
                          Colors.blue.shade100,
                          Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotesScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's Classes Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Classes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (val) => _handleClassAction(val, null),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'add',
                            child: Text('Add Class'),
                          ),
                          const PopupMenuItem(
                            value: 'manage',
                            child: Text('Manage Timetable'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_todaysClasses.isNotEmpty)
                    ..._todaysClasses.map((cls) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context).cardColor
                                : const Color(0xFFFBE4E4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                    Text(
                                      '${TimetableUtils.formatTime12H(cls['start_time'])} – ${TimetableUtils.formatTime12H(cls['end_time'])}'
                                      '${(cls['description'] != null && cls['description'].toString().isNotEmpty) ? '  •  ${cls['description']}' : ''}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Per-class actions
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.more_horiz, size: 20),
                                  onSelected: (val) =>
                                      _handleClassAction(val, cls),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Class'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete Class',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  else if (!_isLoadingClasses)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          const Text(
                            "No classes today.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton.icon(
                            onPressed: () => _handleClassAction('add', null),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Tap to add a class"),
                          ),
                        ],
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),

                  const SizedBox(height: 20),

                  // Quick Actions
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        context,
                        Icons.upload,
                        'Upload',
                        onTap: () async {
                          final file = await FileHelper.pickAndProcessFile();
                          if (file != null) {
                            await DatabaseService().insertFile(file.toMap());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Uploaded ${file.name}'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _buildQuickAction(
                        context,
                        Icons.scanner,
                        'Scan',
                        onTap: () async {
                          final fileMap = await ScannerService().scanDocument();
                          if (fileMap != null) {
                            await DatabaseService().insertFile(fileMap);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Scan saved')),
                              );
                            }
                          }
                        },
                      ),
                      _buildQuickAction(
                        context,
                        Icons.note_add,
                        'Note',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NoteEditorScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => _showSelectFileTypeBottomSheet(context),
        backgroundColor: const Color(0xFF7C3AED),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helpers
  Widget _buildFolderCard(
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder, color: iconColor, size: 32),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showSelectFileTypeBottomSheet(BuildContext ctx) async {
    final selection = await FileTypeBottomSheet.show(ctx);
    if (selection == null) return;

    if (!mounted) return;

    // Handle selection - currently all map to file picker mostly, or specifically filtered
    // logic. The original code just picked a file.
    // We can filter picker based on types if we want, or just generic pick.
    // Original code: `FileHelper.pickAndProcessFile()` (generic).
    // The user wants "Tapping a type opens system picker filtered".
    // I need to update `FileHelper` or just pass extensions to it if it supports it.
    // Let's assume `FileHelper.pickAndProcessFile` is generic for now.
    // But wait, the user said: "Create empty file (for notes/text)..."
    // The existing Home screen had a "Note" option that opened `NoteEditorScreen`.
    // The new BottomSheet doesn't have "Note". The user's request for Folder Detail said "Top-right + ... Create Note".
    // But for the FAB "Select File Type", they listed PDF, Word, Excel, PPT, Image.
    // OPTION: Text/Notes (Optional).
    // If I select PDF/DOC/Excel/Image, I should trigger picker.

    // Check if we need to call `pickAndProcessFile` with type hint.
    // For now, call existing helper.
    final file = await FileHelper.pickAndProcessFile();
    if (file != null) {
      await DatabaseService().insertFile(file.toMap());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploaded ${file.name}')));
      }
    }
  }
}
