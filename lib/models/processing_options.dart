import 'package:flutter/material.dart';
import 'package:image_tools/utils/constants.dart';

class ProcessingOptions {
  final String resolutionKey;
  final int quality;

  ProcessingOptions({
    this.resolutionKey = kDefaultResolutionKey,
    this.quality = kDefaultQuality,
  });

  Size get targetSize => kResolutions[resolutionKey] ?? kResolutions[kDefaultResolutionKey]!;

  @override
  String toString() {
    return 'ProcessingOptions{resolutionKey: $resolutionKey, quality: $quality}';
  }
}