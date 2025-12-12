import 'package:flutter/material.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:campusdrive/models/study_item.dart';
import 'package:campusdrive/screens/folders/folder_detail_screen.dart';
import 'package:campusdrive/screens/files/file_viewer_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StudyItem> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }
    _performSearch(_searchController.text);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await DatabaseService().getItems(searchQuery: query);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search files, folders...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty && _searchController.text.isNotEmpty
          ? const Center(child: Text('No results found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                return _buildResultCard(item);
              },
            ),
    );
  }

  Widget _buildResultCard(StudyItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getIcon(item.type), color: _getIconColor(item.type)),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item.type == FileType.folder ? 'Folder' : 'File'),
        onTap: () {
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
        },
      ),
    );
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
}
