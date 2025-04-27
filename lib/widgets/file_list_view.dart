import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/models/file_item.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';
import 'package:path/path.dart' as p;

class FileListView extends StatelessWidget {
  const FileListView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final files = appState.selectedFiles;
    final checkedFiles = appState.checkedFilePaths;

    if (files.isEmpty) {
      // The placeholder is handled by FileDropArea, so return empty container
      return Container();
    }

    // Group files by their groupKey
    final Map<String, List<FileItem>> groupedFiles = {};
    for (final file in files) {
      final key = file.groupKey ?? 'Files'; // Default group if somehow null
      if (!groupedFiles.containsKey(key)) {
        groupedFiles[key] = [];
      }
      groupedFiles[key]!.add(file);
    }

    // Sort group keys (e.g., 'Files' first, then alphabetically)
    final sortedKeys = groupedFiles.keys.toList()
      ..sort((a, b) {
        if (a == 'Files') return -1;
        if (b == 'Files') return 1;
        return a.compareTo(b);
      });

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final groupKey = sortedKeys[index];
        final itemsInGroup = groupedFiles[groupKey]!;
        final isFolderGroup = groupKey != 'Files';

        if (!isFolderGroup) {
          return Column(
            children: itemsInGroup.map((file) =>
              _buildFileRow(context, file, checkedFiles, appState)
            ).toList(),
          );
        } else {
          final int checkedCountInGroup = itemsInGroup.where((f) => checkedFiles.contains(f.absolutePath)).length;
          final bool? tristateValue = (checkedCountInGroup == 0)
              ? false
              : (checkedCountInGroup == itemsInGroup.length ? true : null);

          return ExpansionTile(
            key: ValueKey(groupKey),
            leading: Checkbox(
              value: tristateValue,
              tristate: true,
              onChanged: (bool? newValue) =>
                  appState.toggleGroupCheck(groupKey, newValue ?? false),
            ),
            title: Row(
              children: [
                const Icon(Icons.folder_outlined, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    groupKey,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            children: itemsInGroup.map((file) =>
              _buildFileRow(context, file, checkedFiles, appState)
            ).toList(),
          );
        }
      },
    );
  }

  // Builds a single row for a file item
  Widget _buildFileRow(BuildContext context, FileItem file, Set<String> checkedFiles, AppState appState) {
     final bool isChecked = checkedFiles.contains(file.absolutePath);
     return ListTile(
        dense: true, // Make rows more compact
        leading: Checkbox(
           value: isChecked,
           onChanged: (bool? value) {
              appState.toggleFileCheck(file.absolutePath, value ?? false);
           },
        ),
        title: Row(
           children: [
              _getFileIcon(file),
              const SizedBox(width: 8),
              Expanded(child: Text(file.filename, overflow: TextOverflow.ellipsis)),
           ],
        ),
        onTap: () { // Allow tapping row to toggle checkbox
            appState.toggleFileCheck(file.absolutePath, !isChecked);
        },
     );
  }

  // Helper to get appropriate icon based on file type
  Icon _getFileIcon(FileItem file) {
    if (file.isRaw) {
      return const Icon(Icons.camera_outlined, color: Colors.orange, size: 20); // RAW icon
    }
    // Add checks for common image types if desired
    // else if (['jpg', 'jpeg', 'png'].contains(file.extension)) {
    //   return const Icon(Icons.image_outlined, color: Colors.green, size: 20); // Standard image
    // }
    else {
      return const Icon(Icons.insert_drive_file_outlined, color: Colors.blueGrey, size: 20); // Generic file
    }
  }
}