import 'dart:io';
import 'package:flutter/material.dart';
import 'package:campusdrive/models/study_item.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:excel/excel.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:archive/archive.dart';

class FileViewerScreen extends StatefulWidget {
  final StudyItem item;

  const FileViewerScreen({super.key, required this.item});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  // For Excel
  Excel? _excelFile;
  // For DOCX (Text extraction)
  String? _docxText;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final file = File(widget.item.path);
      if (!await file.exists()) {
        throw Exception("File not found");
      }

      if (widget.item.type == FileType.excel) {
        final bytes = await file.readAsBytes();
        _excelFile = Excel.decodeBytes(bytes);
      } else if (widget.item.type == FileType.word) {
        // Attempt text extraction from DOCX (simple mock or basic unzip)
        // Since we don't have a reliable render package, we will show text content if possible.
        // Or if it's binary DOC, we can't do much.
        if (widget.item.path.endsWith('.docx')) {
          try {
            _docxText = await _extractDocxText(file);
          } catch (e) {
            _docxText = "Could not extract text from DOCX. Use generic view.";
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Simple DOCX text extractor (unzip document.xml and remove tags)
  Future<String> _extractDocxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final content = String.fromCharCodes(file.content as List<int>);
        // Naive XML tag removal
        return content.replaceAll(RegExp(r'<[^>]*>'), '');
      }
    }
    return "No extracted text found.";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text("Error: $_errorMessage"));
    }

    switch (widget.item.type) {
      case FileType.pdf:
        return SfPdfViewer.file(
          File(widget.item.path),
          canShowScrollHead: true,
          canShowScrollStatus: true,
        );

      case FileType.image:
        return PhotoView(
          imageProvider: FileImage(File(widget.item.path)),
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        );

      case FileType.excel:
        return _buildExcelViewer(context);

      case FileType.word:
        return _buildDocViewer(context);

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("Preview not available for this file type."),
              const SizedBox(height: 16),
              // No open button as requested (all internal)
            ],
          ),
        );
    }
  }

  Widget _buildExcelViewer(BuildContext context) {
    if (_excelFile == null || _excelFile!.tables.isEmpty) {
      return const Center(child: Text("Empty or invalid Excel file"));
    }

    // Just show the first sheet for now
    final table = _excelFile!.tables.values.first;

    // Convert to Syncfusion DataGridSource
    return SfDataGridTheme(
      data: SfDataGridThemeData(
        headerColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFF7C3AED).withValues(alpha: 0.1),
        gridLineColor: Theme.of(context).dividerColor,
        headerHoverColor: Theme.of(context).hoverColor,
      ),
      child: SfDataGrid(
        source: _ExcelDataSource(table),
        columnWidthMode: ColumnWidthMode.auto,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
        columns: List.generate(table.maxColumns, (index) {
          return GridColumn(
            columnName: 'Col $index',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Col ${index + 1}', // Simple column headers A, B, C...
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDocViewer(BuildContext context) {
    if (_docxText != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(_docxText!),
      );
    }

    return const Center(
      child: Text(
        "DOCX Preview not fully supported. (Only Text Extraction implemented)",
      ),
    );
  }
}

class _ExcelDataSource extends DataGridSource {
  final Sheet sheet;
  List<DataGridRow> _dataGridRows = [];

  _ExcelDataSource(this.sheet) {
    _dataGridRows = sheet.rows.map<DataGridRow>((row) {
      return DataGridRow(
        cells: row.map<DataGridCell>((cell) {
          return DataGridCell(
            columnName: 'Col ${row.indexOf(cell)}',
            value: cell?.value?.toString() ?? '',
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8.0),
          child: Text(cell.value.toString(), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
    );
  }
}
