import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_tools/providers/app_state.dart';
import 'package:image_tools/utils/constants.dart';
import 'package:image_tools/widgets/quality_slider.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  // Remove _tempQuality state - it's not needed here

  @override
  void initState() {
    super.initState();
    final options = context.read<AppState>().processingOptions;
    _controller = TextEditingController(text: options.shortSide.toString());
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final v = int.tryParse(_controller.text);
      if (v != null && v > 0) {
        context.read<AppState>().setShortSide(v);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuality = context.read<AppState>().processingOptions.quality.toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Row(
          children: [
            // Short Side Input
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Short Side (px):', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    onFieldSubmitted: (value) {
                      final v = int.tryParse(value);
                      if (v != null && v > 0) {
                        Provider.of<AppState>(context, listen: false).setShortSide(v);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: kDefaultPadding * 2),
            // Quality Slider
            SizedBox( // Constrain width of slider container
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('JPEG Quality:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  QualitySlider(
                    initial: currentQuality,
                    onChanged: (v) {},
                    onChangeEnd: (v) {
                      context.read<AppState>().setQuality(v);
                    },
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