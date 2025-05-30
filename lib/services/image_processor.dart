import 'dart:io';
import 'dart:isolate'; // Import isolate for compute
import 'dart:typed_data'; // Import typed data for FFI
import 'package:flutter/foundation.dart'; // For compute
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:image_tools/models/file_item.dart';
import 'package:image_tools/models/processing_options.dart';
import 'package:image_tools/services/raw_processor.dart';
import 'package:image_tools/services/resize_ffi.dart'; // Import ResizeFFI
import 'package:image_tools/utils/file_utils.dart';

class ImageProcessor {
  // Keep RawProcessor instance if needed across multiple calls (manage lifecycle)
  // Or create on demand if processing is infrequent
  // final RawProcessor _rawProcessor = RawProcessor();

  /// Processes a single image file (standard or RAW).
  /// Runs potentially long operations (decoding, resizing, encoding) via compute.
  /// Returns the path to the saved output file, or null on failure.
  Future<String?> processImage(
      FileItem fileItem, String outputFolder, ProcessingOptions options) async {
    try {
      // Pass shortSide instead of fixed resolution
      return await _processImageInternal({
        'filePath': fileItem.absolutePath,
        'isRaw': fileItem.isRaw,
        'outputFolder': outputFolder,
        'shortSide': options.shortSide,
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
        print('ImageProcessor: read fileBytes.length=${fileBytes.length}');
        image = img.decodeImage(fileBytes); // Use image package for standard formats
        print('ImageProcessor: decodeImage returned image=$image');
        if (image != null) {
          print('ImageProcessor: image dimensions=${image.width}x${image.height}');
        }
        if (image == null) {
          print("Failed to decode standard image: $filename");
          return null;
        }
      }
      // rawProcessor.dispose(); // Dispose if created per call

      // Compute target dimensions based on shortSide and aspect ratio
      final int shortSide = params['shortSide'];
      late int targetWidth;
      late int targetHeight;
      if (image.width <= image.height) {
        targetWidth = shortSide;
        targetHeight = (image.height / image.width * shortSide).round();
      } else {
        targetHeight = shortSide;
        targetWidth = (image.width / image.height * shortSide).round();
      }
      print('ImageProcessor: computed target=${targetWidth}x$targetHeight');

      // 2. Resize Image using FFI (RGBA channels)
      late final ResizeFFI resizeFfi;
      try {
        resizeFfi = ResizeFFI();
      } catch (e) {
        print('ResizeFFI init error: $e');
        return null;
      }

      final int channels = image.numChannels;

      if (channels != 1 && channels != 3 && channels != 4) {
        throw Exception('Unsupported channel count: $channels');
      }

      final Uint8List inputBytes = image.getBytes();
      final Uint8List outputBytes =
          Uint8List(targetWidth * targetHeight * channels);

      int result;
      print('ImageProcessor: invoking FFI resize, inputBytes.length=${inputBytes.length}, dims=${image.width}x${image.height}, outputBytes.length=${outputBytes.length}, target=${targetWidth}x${targetHeight}, channels=$channels');
      try {
        result = resizeFfi.resize(
          inputBytes,
          image.width,
          image.height,
          outputBytes,
          targetWidth,
          targetHeight,
          channels,
          useSrgb: 1,
        );
      } catch (e, s) {
        print('ImageProcessor FFI call threw: $e\n$s');
        rethrow;
      }

      // If FFI resize fails, fallback to Dart
      late img.Image resizedImage;
      if (result == 1) {
        // Use FFI resized buffer
        resizedImage = img.Image.fromBytes(
          width: targetWidth,
          height: targetHeight,
          bytes: outputBytes.buffer,
          numChannels: channels,
        );
      } else {
        print('FFI resize failed with code $result, falling back to Dart resize');
        resizedImage = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
        );
      }

      // 3. Encode as JPG
      final jpgBytes = img.encodeJpg(resizedImage, quality: quality);

      // 4. Save to Output Folder
      final outputFilename = generateOutputFilename(filename);
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
