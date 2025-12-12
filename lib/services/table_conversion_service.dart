import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TableConversionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<List<List<String>>> convertToTable(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Naive implementation:
    // 1. Group text blocks by vertical position (rows)
    // 2. Sort blocks in each row by horizontal position (columns)
    
    List<TextBlock> blocks = recognizedText.blocks;
    
    // Sort by Y coordinate to find rows
    blocks.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    List<List<String>> table = [];
    List<TextBlock> currentRow = [];
    double lastTop = -1;
    const double rowThreshold = 20.0; // pixel tolerance for same row

    for (var block in blocks) {
      if (lastTop == -1 || (block.boundingBox.top - lastTop).abs() < rowThreshold) {
        currentRow.add(block);
      } else {
        // Sort current row by X
        currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        table.add(currentRow.map((b) => b.text).toList());
        currentRow = [block];
      }
      lastTop = block.boundingBox.top;
    }
    
    // Add last row
    if (currentRow.isNotEmpty) {
      currentRow.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      table.add(currentRow.map((b) => b.text).toList());
    }
    
    return table;
  }
}
