import 'package:flutter/material.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:campusdrive/models/study_item.dart';
import 'package:campusdrive/screens/files/file_viewer_screen.dart';
import 'package:campusdrive/widgets/folder_selection_dialog.dart';
import 'package:share_plus/share_plus.dart';

class AllFilesScreen extends StatefulWidget {
  const AllFilesScreen({super.key});

  @override
  State<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends State<AllFilesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<StudyItem> _allItems = [];
  List<StudyItem> _filteredItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _sortBy = 'Date'; // Date, Name, Type

  final List<String> _filters = [
    'All',
    'Notes',
    'Assignments',
    'PDF',
    'Image',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _databaseService.getAllItems();
      // Filter out folders to show only files
      _allItems = items.where((item) => item.type != FileType.folder).toList();
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error loading all files: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilterAndSort() {
    List<StudyItem> result = List.from(_allItems);

    // Filter
    if (_selectedFilter != 'All') {
      result = result.where((item) {
        switch (_selectedFilter) {
          case 'Notes':
            return item.type == FileType.notes;
          case 'PDF':
            return item.type == FileType.pdf;
          case 'Image':
            return item.type == FileType.image;
          case 'Assignments':
            return item.type == FileType.word || item.type == FileType.pdf;
          case 'Other':
            return item.type == FileType.other ||
                item.type == FileType.excel ||
                item.type == FileType.word;
          default:
            return true;
        }
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      switch (_sortBy) {
        case 'Name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Type':
          return a.type.name.compareTo(b.type.name);
        case 'Date':
        default:
          return b.createdAt.compareTo(a.createdAt); // Newest first
      }
    });

    setState(() {
      _filteredItems = result;
    });
  }

  Future<void> _handleMenuAction(String value, StudyItem item) async {
    switch (value) {
      case 'open':
        _openFile(item);
        break;
      case 'rename':
        _showRenameDialog(item);
        break;
      case 'move':
        _showMoveDialog(item);
        break;
      case 'share':
        if (item.path.isNotEmpty) {
          // ignore: deprecated_member_use
          await Share.shareXFiles([XFile(item.path)], text: item.name);
        }
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _openFile(StudyItem item) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FileViewerScreen(item: item)),
      );
    }
  }

  Future<void> _showRenameDialog(StudyItem item) async {
    final controller = TextEditingController(text: item.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final updated = item.copyWith(
                  name: controller.text,
                  modifiedAt: DateTime.now(),
                );
                await _databaseService.updateItem(updated);
                // ignore: use_build_context_synchronously
                if (context.mounted) Navigator.pop(context);
                _loadItems();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMoveDialog(StudyItem item) async {
    final targetFolderId = await showDialog<String?>(
      context: context,
      builder: (context) =>
          FolderSelectionDialog(currentFolderId: item.parentId),
    );

    if (targetFolderId != null) {
      final newParentId = targetFolderId == 'ROOT' ? null : targetFolderId;
      final updatedItem = item.copyWith(parentId: newParentId);
      await _databaseService.updateItem(updatedItem);
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File moved')));
      }
      _loadItems();
    }
  }

  Future<void> _showDeleteConfirmation(StudyItem item) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseService.deleteItem(item.id);
              // ignore: use_build_context_synchronously
              if (context.mounted) Navigator.pop(context);
              _loadItems();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Files'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) {
              setState(() {
                _sortBy = val;
                _applyFilterAndSort();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Date', child: Text('Date Added')),
              const PopupMenuItem(value: 'Name', child: Text('Name')),
              const PopupMenuItem(value: 'Type', child: Text('File Type')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilterAndSort();
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(
                      0xFF7C3AED,
                    ).withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : Colors.grey.shade300,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No files found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildFileTile(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile(StudyItem item) {
    IconData icon;
    Color color;

    switch (item.type) {
      case FileType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case FileType.word:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case FileType.excel:
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case FileType.image:
        icon = Icons.image;
        color = Colors.purple;
        break;
      case FileType.notes:
        icon = Icons.note;
        color = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatDate(item.createdAt)} • ${_itemTypeString(item.type)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: _buildMoreMenu(item),
        onTap: () => _openFile(item),
      ),
    );
  }

  String _itemTypeString(FileType type) {
    return type.name.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMoreMenu(StudyItem item) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(value, item),
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
              Icon(Icons.drive_file_move_outline, size: 20),
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
    );
  }
}
