import 'package:flutter/material.dart';
import 'package:campusdrive/models/study_item.dart';
import 'package:campusdrive/services/database_service.dart';

class FolderSelectionDialog extends StatefulWidget {
  final String? currentFolderId;

  const FolderSelectionDialog({super.key, this.currentFolderId});

  @override
  State<FolderSelectionDialog> createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  List<StudyItem> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final allItems = await DatabaseService().getAllItems();
    final folders = allItems
        .where(
          (item) =>
              item.type == FileType.folder && item.id != widget.currentFolderId,
        )
        .toList();

    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Move to..."),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _folders.isEmpty
            ? const Text("No other folders available.")
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _folders.length + 1, // +1 for "Root"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.home, color: Colors.purple),
                      title: const Text("Home (Root)"),
                      onTap: () => Navigator.pop(context, 'ROOT'),
                    );
                  }
                  final folder = _folders[index - 1];
                  return ListTile(
                    leading: const Icon(Icons.folder, color: Colors.orange),
                    title: Text(folder.name),
                    onTap: () => Navigator.pop(context, folder.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
