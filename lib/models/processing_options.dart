import 'package:flutter/material.dart';
import 'package:image_tools/utils/constants.dart';

class ProcessingOptions {
  final int shortSide;
  final int quality;

  ProcessingOptions({
    this.shortSide = kDefaultShortSide,
    this.quality = kDefaultQuality,
  });

  // Target size computed based on shortSide and original image ratio inside ImageProcessor

  @override
  String toString() {
    return 'ProcessingOptions{shortSide: $shortSide, quality: $quality}';
  }
}