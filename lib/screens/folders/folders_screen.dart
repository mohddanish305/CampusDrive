import 'package:flutter/material.dart';
import 'package:campusdrive/screens/folders/folder_detail_screen.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:campusdrive/models/study_item.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<StudyItem> _folders = [];
  bool _isLoading = true;

  bool _selectionMode = false;
  final Set<String> _selectedFolderIds = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseService().getItems(parentId: null);
      if (mounted) {
        setState(() {
          _folders = items
              .where((item) => item.type == FileType.folder)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading folders: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading folders: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createFolder(String name) async {
    final newFolder = StudyItem(
      id: "folder_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      path: '/$name',
      parentId: null,
      type: FileType.folder,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      isSynced: false,
    );
    await DatabaseService().insertItem(newFolder);
    _loadFolders();
  }

  void _enableSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedFolderIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedFolderIds.contains(id)) {
        _selectedFolderIds.remove(id);
        if (_selectedFolderIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedFolderIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedFolderIds.length == _folders.length) {
        _selectedFolderIds.clear();
      } else {
        for (var f in _folders) {
          _selectedFolderIds.add(f.id);
        }
      }
    });
  }

  void _deleteSelectedFolders() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Folders?"),
        content: Text(
          "Delete ${_selectedFolderIds.length} folders and all files inside? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final db = DatabaseService();
              for (String id in _selectedFolderIds) {
                // Determine logic for recursive delete if needed,
                // assuming deleteItem handles it or we accept generic delete for now.
                // Ideally DatabaseService.deleteItem should handle children or we loop.
                await db.deleteItem(id);
              }
              setState(() {
                _selectionMode = false;
                _selectedFolderIds.clear();
              });
              _loadFolders();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
            _selectedFolderIds.clear();
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
                      _selectedFolderIds.clear();
                    });
                  },
                ),
                title: Text('${_selectedFolderIds.length} selected'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedFolders,
                  ),
                ],
              )
            : AppBar(title: const Text('Manage Folders')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _folders.isEmpty
            ? const Center(child: Text("No folders yet"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folder = _folders[index];
                  return _buildFolderRow(context, folder);
                },
              ),
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
                heroTag: 'folders_fab',
                onPressed: _showCreateFolderDialog,
                backgroundColor: const Color(0xFF7C3AED),
                child: const Icon(Icons.add, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildFolderRow(BuildContext context, StudyItem folder) {
    final bool isSelected = _selectedFolderIds.contains(folder.id);

    return GestureDetector(
      onLongPress: () {
        if (!_selectionMode) _enableSelectionMode(folder.id);
      },
      onTap: () {
        if (_selectionMode) {
          _toggleSelection(folder.id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FolderDetailScreen(
                folderName: folder.name,
                folderId: folder.id,
              ),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.transparent : const Color(0xFF7C3AED),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? Icons.check_circle : Icons.folder,
              color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
            ),
          ),
          title: Text(
            folder.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Created: ${folder.createdAt.year}-${folder.createdAt.month}-${folder.createdAt.day}',
          ),
          trailing: _selectionMode
              ? null
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(folder);
                    } else if (value == 'rename') {
                      _showRenameDialog(folder);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Folder"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Folder Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _createFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(StudyItem folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Folder"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "New Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await DatabaseService().updateItem(
                  folder.copyWith(name: controller.text),
                );
                _loadFolders();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(StudyItem folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Folder?"),
        content: const Text("This will delete the folder and its contents."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().deleteItem(folder.id);
              _loadFolders();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
