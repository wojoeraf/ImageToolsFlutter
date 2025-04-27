import 'package:flutter/material.dart';
import 'package:image_tools/widgets/action_buttons.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';
import 'package:image_tools/widgets/file_drop_area.dart';
import 'package:image_tools/widgets/output_folder_selector.dart';
import 'package:image_tools/widgets/settings_panel.dart';
import 'package:image_tools/widgets/progress_indicator_widget.dart';
import 'package:image_tools/widgets/file_list_view.dart'; // Import FileListView

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/img/logo.png', // Make sure path is correct in pubspec.yaml
              height: 65, // Adjust size as needed
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported), // Fallback icon
            ),
            const SizedBox(width: 5),
            const Text('Photographers Toolbox'),
          ],
        ),
        elevation: 4.0, // Add shadow like the original header
      ),
      body: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. File Selection Area
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selection Header (Select... / Remove)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Opacity(
                          opacity: appState.selectedFiles.isNotEmpty ? 1.0 : 0.4,
                          child: PopupMenuButton<String>(
                            enabled: appState.selectedFiles.isNotEmpty,
                            tooltip: 'Selection Options',
                            onSelected: (result) {
                              switch (result) {
                                case 'selectAll':
                                  appState.selectAll();
                                  break;
                                case 'deselectAll':
                                  appState.deselectAll();
                                  break;
                                case 'selectRaw':
                                  appState.selectRawFiles();
                                  break;
                                case 'selectNonRaw':
                                  appState.selectNonRawFiles();
                                  break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'selectAll', child: Text('Select All')),
                              PopupMenuItem(value: 'deselectAll', child: Text('Deselect All')),
                              PopupMenuDivider(),
                              PopupMenuItem(value: 'selectRaw', child: Text('Select RAW Files')),
                              PopupMenuItem(value: 'selectNonRaw', child: Text('Select Non-RAW Files')),
                            ],
                            child: const Chip(
                              avatar: Icon(Icons.checklist_rtl, size: 18),
                              label: Text('Select...'),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          onPressed: appState.canRemoveSelected ? appState.removeSelected : null,
                        ),
                      ],
                    ),
                  ),
                  // Drop Area (only this region is draggable)
                  Expanded(
                    child: FileDropArea(
                      child: Column(
                        children: [
                          // Feedback message
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              appState.feedbackMessage,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                          // File List
                          const Expanded(child: FileListView()),
                        ],
                      ),
                    ),
                  ),
                  // Action Buttons (Add Files / Add Folder)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Add Files'),
                          onPressed: appState.pickFiles,
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                          label: const Text('Add Folder'),
                          onPressed: appState.pickFolder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kDefaultPadding),

            // 2. Output Folder Selector
            const OutputFolderSelector(),
            const SizedBox(height: kDefaultPadding),

            // 3. Settings Panel
            const SettingsPanel(),
            const SizedBox(height: kDefaultPadding),

            // 4. Action Buttons
            const ActionButtons(),
            const SizedBox(height: kDefaultPadding),

            // 5. Progress Indicator
            const ProgressIndicatorWidget(),
            const SizedBox(height: kDefaultPadding / 2),

            // 6. Status Message
            Center(
              child: Text(
                appState.statusMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
             const SizedBox(height: kDefaultPadding), // Bottom padding
          ],
        ),
      ),
       // Optional Footer
      bottomNavigationBar: Container(
         color: Theme.of(context).colorScheme.surfaceContainerHighest, // Similar to bg-white shadow
         padding: const EdgeInsets.all(kDefaultPadding / 2),
         child: Text(
             '© ${DateTime.now().year} Honigbart Studios',
             textAlign: TextAlign.center,
             style: Theme.of(context).textTheme.bodySmall,
         ),
      ),
    );
  }
}