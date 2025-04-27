import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:image_tools/utils/constants.dart';

class FileItem {
  final String absolutePath; // Always store the absolute path
  final String filename;
  final String extension;
  final String? relativePath; // Path relative to the dropped/selected folder root
  final bool isRaw;
  String? groupKey; // For grouping in the UI (e.g., folder name or 'Files')

  FileItem({
    required this.absolutePath,
    this.relativePath, // Can be null for single files
  }) : filename = p.basename(absolutePath),
       extension = p.extension(absolutePath).toLowerCase().replaceAll('.', ''),
       isRaw = kRawExtensions.contains(p.extension(absolutePath).toLowerCase().replaceAll('.', ''))
  {
     _setGroupKey();
  }

  // Determine the group key for UI display
  void _setGroupKey() {
    if (relativePath != null && relativePath!.contains(p.separator)) {
      // Use the first directory component of the relative path
      groupKey = p.split(relativePath!).first;
    } else {
      // If no relative path or it's just the filename, group under 'Files'
      groupKey = 'Files';
    }
  }

  // Equality and HashCode for Set operations (based on absolute path)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileItem &&
          runtimeType == other.runtimeType &&
          absolutePath == other.absolutePath;

  @override
  int get hashCode => absolutePath.hashCode;

  @override
  String toString() {
    return 'FileItem{absolutePath: $absolutePath, relativePath: $relativePath, groupKey: $groupKey}';
  }
}