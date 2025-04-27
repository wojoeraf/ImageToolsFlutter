import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool showProgress = appState.isProcessing || appState.processingState == ProcessingState.success;

    // Use Visibility to hide/show the progress bar area smoothly
    return Visibility(
      visible: showProgress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: appState.progress,
              minHeight: 8, // Make it a bit thicker
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            // Text showing percentage or specific status message during processing
            Text(
              appState.isProcessing
                ? '${(appState.progress * 100).toStringAsFixed(0)}%'
                : '', // Don't show percentage when done/idle
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      // Reserve space even when hidden to prevent layout jumps
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
    );
  }
}