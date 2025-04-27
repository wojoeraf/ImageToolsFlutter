import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';

class FileDropArea extends StatefulWidget {
  final Widget child; // Pass the FileListView (or placeholder) as child

  const FileDropArea({required this.child, super.key});

  @override
  State<FileDropArea> createState() => _FileDropAreaState();
}

class _FileDropAreaState extends State<FileDropArea> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final bool hasFiles = context.watch<AppState>().selectedFiles.isNotEmpty; // Watch for changes

    return DropTarget(
      onDragDone: (detail) {
        final paths = detail.files.map((f) => f.path).toList();
        if (paths.isNotEmpty) {
          appState.addDroppedFiles(paths);
        }
      },
      onDragEntered: (detail) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isDragging = false;
        });
      },
      child: InkWell( // Make the area clickable
         onTap: () {
            // Trigger file picker only if clicking on the background when empty
            if (!hasFiles) {
               appState.pickFiles();
            }
         },
         child: Container(
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 400), // Increased drop area height
          padding: const EdgeInsets.all(kDefaultPadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging ? Colors.blueAccent : Colors.grey.shade400,
              width: 2,
              style: BorderStyle.solid, // Dashed border is tricky, use solid
            ),
            borderRadius: BorderRadius.circular(8.0),
            color: _isDragging ? Colors.blue.withValues(alpha: (0.05 * 255)) : Theme.of(context).cardColor, // Subtle hover effect
          ),
          child: Stack( // Use Stack to overlay placeholder
            alignment: Alignment.center,
            children: [
              // Child content (e.g., FileListView) - always present but might be empty
              widget.child,

              // Placeholder - shown only when no files and not dragging
              if (!hasFiles && !_isDragging)
                const IgnorePointer( // Prevent placeholder from intercepting clicks
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Drag & Drop images/folders here',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'or click to select files',
                          style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                         SizedBox(height: 16),
                        Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.blue),
                      ],
                    ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}