import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final options = appState.processingOptions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Wrap( // Use Wrap for responsiveness
          spacing: kDefaultPadding * 2, // Horizontal spacing
          runSpacing: kDefaultPadding, // Vertical spacing
          children: [
            // Resolution Dropdown
            SizedBox( // Constrain width of dropdown container
               width: 250,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Resolution:', style: Theme.of(context).textTheme.titleSmall),
                   const SizedBox(height: 4),
                   DropdownButtonFormField<String>(
                     value: options.resolutionKey,
                     items: kResolutions.keys.map((String key) {
                       final size = kResolutions[key]!;
                       return DropdownMenuItem<String>(
                         value: key,
                         child: Text('$key (${size.width.toInt()}x${size.height.toInt()})'),
                       );
                     }).toList(),
                     onChanged: (String? newValue) {
                       if (newValue != null) {
                         Provider.of<AppState>(context, listen: false).setResolution(newValue);
                       }
                     },
                     decoration: const InputDecoration(
                       contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                       isDense: true, // Compact dropdown
                     ),
                   ),
                 ],
               ),
            ),

            // Quality Slider
             SizedBox( // Constrain width of slider container
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('JPEG Quality:', style: Theme.of(context).textTheme.titleSmall),
                     const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: options.quality.toDouble(),
                            min: 10,
                            max: 100,
                            divisions: 90, // 100 - 10
                            label: options.quality.round().toString(),
                            onChanged: (double value) {
                              Provider.of<AppState>(context, listen: false).setQuality(value);
                            },
                          ),
                        ),
                        Text(options.quality.round().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
             ),
          ],
        ),
      ),
    );
  }
}