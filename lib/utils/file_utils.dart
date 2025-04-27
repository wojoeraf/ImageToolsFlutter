import 'package:path/path.dart' as p;
import 'package:image_tools/utils/constants.dart';

bool isAllowedExtension(String filePath) {
  final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
  return kAllowedExtensions.contains(ext);
}

bool isRawExtension(String filePath) {
   final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
   return kRawExtensions.contains(ext);
}

// Generates a safe output filename (e.g., replacing spaces) - adjust as needed
String generateOutputFilename(String inputBasename, {String extension = '.jpg'}) {
  // Basic example: remove extension and append .jpg
  final base = p.basenameWithoutExtension(inputBasename);
  // You might want more robust sanitization (remove invalid chars, etc.)
  return '$base$extension';
}