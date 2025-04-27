import 'package:flutter/material.dart';

// Target resolutions: (width, height)
const Map<String, Size> kResolutions = {
  '4k': Size(3840, 2160),
  'WQHD': Size(2560, 1440),
  'FullHD': Size(1920, 1080),
};

const String kDefaultResolutionKey = 'FullHD';
const int kDefaultQuality = 85;

// Allowed file extensions (lowercase)
const Set<String> kAllowedExtensions = {
  // Standard
  'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'tif',
  // RAW
  'arw', 'raw', 'cr2', 'nef', 'dng',
};

const Set<String> kRawExtensions = {
  'arw', 'raw', 'cr2', 'nef', 'dng',
};

// UI Constants
const double kDefaultPadding = 16.0;