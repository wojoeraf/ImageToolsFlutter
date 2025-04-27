import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Center the button
      children: [
        ElevatedButton.icon(
          icon: appState.isProcessing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow),
          label: Text(appState.isProcessing ? 'Processing...' : 'Start Processing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: appState.canStartProcessing
              ? () => Provider.of<AppState>(context, listen: false).startProcessing()
              : null,
        ),
        // Add other buttons if needed (e.g., Cancel)
      ],
    );
  }
}