import 'package:flutter/material.dart';
import 'package:campusdrive/utils/file_helper.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:campusdrive/models/study_item.dart';
import 'package:share_plus/share_plus.dart';
import 'package:campusdrive/screens/files/file_viewer_screen.dart';
import 'package:campusdrive/widgets/folder_selection_dialog.dart';
import 'package:campusdrive/widgets/file_type_bottom_sheet.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderName;
  final String? folderId;

  const FolderDetailScreen({
    super.key,
    required this.folderName,
    this.folderId,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<StudyItem> _items = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  final Set<String> _selectedFileIds = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await DatabaseService().getItems(
      parentId: widget.folderId ?? '',
    );
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  FileType _mapFileType(String extension) {
    if (extension.contains('pdf')) return FileType.pdf;
    if (extension.contains('doc')) return FileType.word;
    if (extension.contains('xls')) return FileType.excel;
    if (extension.contains('png') || extension.contains('jpg')) {
      return FileType.image;
    }
    return FileType.other;
  }

  Color _getIconColor(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Colors.red;
      case FileType.word:
        return Colors.blue;
      case FileType.excel:
        return Colors.green;
      case FileType.image:
        return Colors.purple;
      case FileType.folder:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.word:
        return Icons.description;
      case FileType.excel:
        return Icons.table_chart;
      case FileType.image:
        return Icons.image;
      case FileType.folder:
        return Icons.folder;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _enableSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedFileIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedFileIds.contains(id)) {
        _selectedFileIds.remove(id);
        if (_selectedFileIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedFileIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedFileIds.length == _items.length) {
        _selectedFileIds.clear();
      } else {
        for (var i in _items) {
          _selectedFileIds.add(i.id);
        }
      }
    });
  }

  void _deleteSelectedFiles() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Files?"),
        content: Text(
          "Delete ${_selectedFileIds.length} items? This cannot be undone.",
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
              for (String id in _selectedFileIds) {
                await db.deleteItem(id);
              }
              setState(() {
                _selectionMode = false;
                _selectedFileIds.clear();
              });
              _loadItems();
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
            _selectedFileIds.clear();
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
                      _selectedFileIds.clear();
                    });
                  },
                ),
                title: Text('${_selectedFileIds.length} selected'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedFiles,
                  ),
                ],
              )
            : AppBar(
                title: Text(widget.folderName),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add),
                    onSelected: (value) {
                      // Handle "Create" actions (placeholders for now)
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Creating $value...')),
                        );
                      }
                      // Implement actual creation logic if available
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'note',
                        child: Text('Create Note'),
                      ),
                      const PopupMenuItem(
                        value: 'doc',
                        child: Text('Create Text Document'),
                      ),
                      const PopupMenuItem(
                        value: 'scan',
                        child: Text('Scan Document'),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      final file = await FileHelper.pickAndProcessFile();
                      if (file != null) {
                        final newItem = StudyItem(
                          id: file.id,
                          name: file.name,
                          path: file.path,
                          parentId: widget.folderId,
                          type: _mapFileType(file.type),
                          createdAt: file.addedDate,
                          modifiedAt: DateTime.now(),
                          isSynced: false,
                        );
                        await DatabaseService().insertItem(newItem);
                        _loadItems();
                      }
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                    tooltip: 'Upload',
                  ),
                ],
              ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No files yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showSelectFileTypeBottomSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Tap to add files"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildFileCard(item, index);
                },
              ),
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton(
                heroTag: 'folder_detail_fab',
                onPressed: () => _showSelectFileTypeBottomSheet(context),
                backgroundColor: const Color(0xFF7C3AED),
                child: const Icon(Icons.add, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildFileCard(StudyItem item, int index) {
    final bool isSelected = _selectedFileIds.contains(item.id);

    return GestureDetector(
      onLongPress: () {
        if (!_selectionMode) _enableSelectionMode(item.id);
      },
      onTap: () {
        if (_selectionMode) {
          _toggleSelection(item.id);
        } else {
          if (item.type == FileType.folder) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FolderDetailScreen(
                  folderName: item.name,
                  folderId: item.id,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
            );
          }
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.transparent
                  : _getIconColor(item.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSelected ? Icons.check_circle : _getIcon(item.type),
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : _getIconColor(item.type),
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
          ),
          trailing: _selectionMode
              ? null
              : PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, index, item),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Open'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 20),
                          SizedBox(width: 8),
                          Text('Move'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, int index, StudyItem item) async {
    switch (action) {
      case 'open':
        if (item.type == FileType.folder) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FolderDetailScreen(folderName: item.name, folderId: item.id),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
          );
        }
        break;
      case 'rename':
        _showRenameDialog(item);
        break;
      case 'move':
        final targetFolderId = await showDialog<String?>(
          context: context,
          builder: (context) => FolderSelectionDialog(currentFolderId: item.id),
        );

        if (targetFolderId != null) {
          final newParentId = targetFolderId == 'ROOT' ? null : targetFolderId;
          final updatedItem = item.copyWith(parentId: newParentId);
          await DatabaseService().updateItem(updatedItem);
          _loadItems();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item moved successfully')),
            );
          }
        }
        break;
      case 'share':
        if (item.path.isNotEmpty && !item.path.startsWith('/dummy')) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(item.path)]);
        } else {
          // ignore: deprecated_member_use
          await Share.share('Check out this file: ${item.name}');
        }
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showRenameDialog(StudyItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "New Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text;
              if (newName.isNotEmpty) {
                final updatedItem = item.copyWith(name: newName);
                await DatabaseService().updateItem(updatedItem);
                _loadItems();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(StudyItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete File?"),
        content: const Text("Are you sure you want to delete this file?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().deleteItem(item.id);
              _loadItems();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSelectFileTypeBottomSheet(BuildContext context) async {
    final selection = await FileTypeBottomSheet.show(context);
    if (selection == null) return;

    if (!mounted) return;

    // Future expansion: switch(selection) to support Note/Image specific logical flows
    // For now, mirroring generic behavior:
    final file = await FileHelper.pickAndProcessFile();
    if (file != null) {
      final newItem = StudyItem(
        id: file.id,
        name: file.name,
        path: file.path,
        parentId: widget.folderId,
        type: _mapFileType(file.type),
        createdAt: file.addedDate,
        modifiedAt: DateTime.now(),
        isSynced: false,
      );
      await DatabaseService().insertItem(newItem);
      _loadItems();
    }
  }
}
