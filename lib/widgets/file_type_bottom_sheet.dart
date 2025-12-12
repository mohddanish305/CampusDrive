import 'package:flutter/material.dart';

enum FileTypeSelection {
  pdf,
  doc,
  excel,
  image,
  other, // Keeping internally if needed, but UI might hide it or show it as legacy
}

class FileTypeBottomSheet extends StatelessWidget {
  const FileTypeBottomSheet({super.key});

  static Future<FileTypeSelection?> show(BuildContext context) {
    return showModalBottomSheet<FileTypeSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const FileTypeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select File Type',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 0.9, // Adjust for better icon/text fit
            children: [
              _buildOption(
                context,
                'PDF',
                Icons.picture_as_pdf,
                Colors.red,
                FileTypeSelection.pdf,
              ),
              _buildOption(
                context,
                'DOC',
                Icons.description,
                Colors.blue,
                FileTypeSelection.doc,
              ),
              _buildOption(
                context,
                'Excel',
                Icons.table_chart,
                Colors.green,
                FileTypeSelection.excel,
              ),

              // Considering PPT as requested but using just 'image' for now as per instructions "Excel, PowerPoint, Image".
              // Wait, previous request said "PDF, Word, Excel, PowerPoint (PPT), Image".
              // I need to add PPT. But I don't have a specific enum for it in my global `FileType` (maybe?).
              // Let's check `StudyItem` model.
              // Re-reading `FolderDetailScreen`: `FileType` has `pdf`, `word`, `excel`, `image`, `other`, `folder`.
              // I should probably map PPT to `other` or just not support it technically yet if DB/Model doesn't support it,
              // OR purely use this for the picker which likely just filters extensions.
              // For now, I will stick to what the user asked: PDF, Word, Excel, PPT, Image.
              // I'll return a custom enum or string, but the listener will handle it.
              // Since `FileType` enum in `study_item.dart` governs the app, let's see if I should update it.
              // For now, I'll stick to the existing types but adding PPT visual which might map to 'other' or 'word' logic if needed,
              // OR just return the selection and let the caller decide.
              _buildOption(
                context,
                'PPT',
                Icons.slideshow,
                Colors.orange,
                FileTypeSelection
                    .other, // Mapping to 'other' for now if no PPT type exists
              ),
              _buildOption(
                context,
                'Image',
                Icons.image,
                Colors.purple,
                FileTypeSelection.image,
              ),
              // Removed "Other" as requested.
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    FileTypeSelection type,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
