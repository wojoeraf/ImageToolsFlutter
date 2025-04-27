import 'dart:io';
import 'dart:isolate'; // Import isolate for compute
import 'package:flutter/foundation.dart'; // For compute
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:image_tools/models/file_item.dart';
import 'package:image_tools/models/processing_options.dart';
import 'package:image_tools/services/raw_processor.dart';
import 'package:image_tools/utils/file_utils.dart';

class ImageProcessor {
  // Keep RawProcessor instance if needed across multiple calls (manage lifecycle)
  // Or create on demand if processing is infrequent
  // final RawProcessor _rawProcessor = RawProcessor();

  /// Processes a single image file (standard or RAW).
  /// Runs potentially long operations (decoding, resizing, encoding) via compute.
  /// Returns the path to the saved output file, or null on failure.
  Future<String?> processImage(FileItem fileItem, String outputFolder, ProcessingOptions options) async {
    try {
      // Use compute to run the blocking _processImageInternal function
      return await compute(_processImageInternal, {
        'filePath': fileItem.absolutePath,
        'isRaw': fileItem.isRaw,
        'outputFolder': outputFolder,
        'targetWidth': options.targetSize.width.toInt(),
        'targetHeight': options.targetSize.height.toInt(),
        'quality': options.quality,
      });
    } catch (e, s) {
      print("Error invoking compute for ${fileItem.filename}: $e\n$s");
      return null;
    }
  }

  // Static or top-level function required for compute
  static Future<String?> _processImageInternal(Map<String, dynamic> params) async {
     final String filePath = params['filePath'];
     final bool isRaw = params['isRaw'];
     final String outputFolder = params['outputFolder'];
     final int targetWidth = params['targetWidth'];
     final int targetHeight = params['targetHeight'];
     final int quality = params['quality'];
     final String filename = p.basename(filePath);

     // Create RawProcessor instance *inside* the isolate/compute function
     // Or find a way to pass the necessary handle if state is needed.
     // FFI handles might not be directly transferable between isolates easily.
     // Creating a new instance per compute call is often safer for FFI.
    //  final rawProcessor = RawProcessor(); // Create instance here

      img.Image? image;

     try {
       // 1. Load Image
       if (isRaw) {
          print("Processing RAW: $filename");
          // image = await rawProcessor.processRawFile(filePath);
          return null;
          // if (image == null) {
          //    print("Failed to decode RAW: $filename");
          //    return null;
          // }
       } else {
          print("Processing standard: $filename");
          final fileBytes = await File(filePath).readAsBytes();
          image = img.decodeImage(fileBytes); // Use image package for standard formats
          if (image == null) {
              print("Failed to decode standard image: $filename");
              return null;
          }
       }
        // rawProcessor.dispose(); // Dispose if created per call

        // 2. Resize Image (maintaining aspect ratio)
        final img.Image resizedImage = img.copyResize(
           image,
           width: targetWidth, // Specify max width
           height: targetHeight, // Specify max height
           maintainAspect: true, // Let the package handle aspect ratio
           interpolation: img.Interpolation.average, // Or cubic, linear
        );

       // 3. Encode as JPG
       final jpgBytes = img.encodeJpg(resizedImage, quality: quality);

       // 4. Save to Output Folder
       final outputFilename = generateOutputFilename(filename); // Get base name + .jpg
       final outputPath = p.join(outputFolder, outputFilename);

       await File(outputPath).writeAsBytes(jpgBytes);
       print("Saved: $outputPath");
       return outputPath; // Success

     } catch (e, s) {
        print("Error processing $filename: $e\n$s");
        // rawProcessor.dispose(); // Ensure disposal on error too
        return null; // Failure
     }
  }

   void dispose() {
     // Dispose RawProcessor if it's held as a member
     // _rawProcessor.dispose();
   }
}