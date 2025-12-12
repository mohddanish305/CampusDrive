import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:campusdrive/services/database_service.dart';
import 'package:uuid/uuid.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final QuillController _controller = QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final db = await _db.database;
      final results = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [widget.noteId],
      );
      if (results.isNotEmpty) {
        final note = results.first;
        _titleController.text = note['title'] as String;
        try {
          final json = jsonDecode(note['content_json'] as String);
          _controller.document = Document.fromJson(json);
        } catch (e) {
          // Handle legacy or plain text if any
        }
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveNote() async {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final id = widget.noteId ?? const Uuid().v4();
    final note = {
      'id': id,
      'title': _titleController.text,
      'content_json': content,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (widget.noteId == null) {
      note['created_at'] = DateTime.now().millisecondsSinceEpoch;
      await _db.insertNote(note);
    } else {
      await _db.updateNote(note);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Title',
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: _saveNote, icon: const Icon(Icons.save)),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [QuillSimpleToolbar(controller: _controller)]),
          ),
          Expanded(child: QuillEditor.basic(controller: _controller)),
        ],
      ),
    );
  }
}
