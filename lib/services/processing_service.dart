import 'dart:async';
import 'package:image_tools/models/file_item.dart';
import 'package:image_tools/models/processing_options.dart';
import 'package:image_tools/services/image_processor.dart'; 

class ProcessingService {

  Future<void> processImages({
    required List<FileItem> filesToProcess,
    required String outputFolder,
    required ProcessingOptions options,
    required Function(int processedCount, int totalCount, String? message) onProgress,
    required Function(int successCount) onComplete,
    required Function(String errorMsg) onError,
  }) async {
    final int totalFiles = filesToProcess.length;
    if (totalFiles == 0) {
      onComplete(0);
      return;
    }

    // Process sequentially on main isolate using FFI
    int processedCount = 0;
    int successCount = 0;
    onProgress(0, totalFiles, 'Starting processing...');
    final imageProcessor = ImageProcessor();
    for (final file in filesToProcess) {
      final resultPath = await imageProcessor.processImage(file, outputFolder, options);
      if (resultPath != null) {
        successCount++;
      }
      processedCount++;
      onProgress(processedCount, totalFiles, 'Processed $processedCount of $totalFiles');
    }
    imageProcessor.dispose();
    onComplete(successCount);
  }
}