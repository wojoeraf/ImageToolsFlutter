import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';

class OutputFolderSelector extends StatelessWidget {
  const OutputFolderSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final String folderText = appState.outputFolder ?? 'No folder selected.';
    final bool canSelect = appState.canSelectOutputFolder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Output Folder:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    folderText,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            ElevatedButton(
              onPressed: canSelect ? () => Provider.of<AppState>(context, listen: false).selectOutputFolder() : null,
              child: const Text('Select Folder'),
            ),
          ],
        ),
      ),
    );
  }
}