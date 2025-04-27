import 'dart:async';
import 'dart:isolate';
import 'package:image_tools/models/file_item.dart';
import 'package:image_tools/models/processing_options.dart';
import 'package:image_tools/services/image_processor.dart'; // Needed for _processImageInternal if static
import 'package:collection/collection.dart'; // For chunking list

const int kBatchSize = 5; // Process 5 images concurrently per isolate batch

class ProcessingService {

  // Function to run in the isolate
  static Future<void> _isolateEntry(Map<String, dynamic> message) async {
    final SendPort sendPort = message['sendPort'];
    final List<FileItem> batchFiles = message['batchFiles'];
    final String outputFolder = message['outputFolder'];
    final ProcessingOptions options = message['options'];
    final int batchNumber = message['batchNumber']; // For tracking

    final List<String?> results = [];
    final imageProcessor = ImageProcessor(); // Create instance inside isolate

    print("[Isolate Batch ${batchNumber+1}] Starting processing for ${batchFiles.length} files.");

    for (final file in batchFiles) {
      final resultPath = await imageProcessor.processImage(file, outputFolder, options);
      results.add(resultPath);
    }

    imageProcessor.dispose(); // Clean up processor if needed

    print("[Isolate Batch ${batchNumber+1}] Finished. Results: ${results.nonNulls.length} successful.");
    // Send results back
    sendPort.send({
      'type': 'batchComplete',
      'batchNumber': batchNumber,
      'results': results, // List of output paths (or nulls for failures)
    });
  }

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

    final ReceivePort receivePort = ReceivePort();
    final List<Future<void>> isolateFutures = [];
    final List<Isolate> isolates = [];
    int processedCount = 0;
    int successCount = 0;
    int completedBatches = 0;

    final List<List<FileItem>> batches = filesToProcess.slices(kBatchSize).toList();
    final int totalBatches = batches.length;

    onProgress(0, totalFiles, "Starting processing in $totalBatches batches...");

    StreamSubscription? receiveSubscription;

    receiveSubscription = receivePort.listen((dynamic message) {
      if (message is Map<String, dynamic>) {
        if (message['type'] == 'batchComplete') {
          completedBatches++;
          final List<String?> batchResults = message['results'];
          final int batchSuccessCount = batchResults.nonNulls.length;
          final int batchTotalInThisBatch = batchResults.length; // Actual count in this batch

          successCount += batchSuccessCount;
          processedCount += batchTotalInThisBatch; // Increment by batch size processed

          print("Batch ${message['batchNumber']+1}/$totalBatches complete. Success: $batchSuccessCount/${batchTotalInThisBatch}. Total processed: $processedCount/$totalFiles");

          onProgress(processedCount, totalFiles, "Batch ${completedBatches}/$totalBatches complete...");

          if (completedBatches == totalBatches) {
            print("All batches completed. Total success: $successCount/$totalFiles");
            receiveSubscription?.cancel();
            receivePort.close();
            isolates.forEach((iso) => iso.kill(priority: Isolate.immediate)); // Clean up isolates
            onComplete(successCount);
          }
        } else {
           print("Received unknown message from isolate: $message");
        }
      }
    });

    // Spawn isolates for each batch
    try {
      for (int i = 0; i < batches.length; i++) {
          final batch = batches[i];
           print("Spawning isolate for batch ${i+1}...");
          final isolate = await Isolate.spawn(
              _isolateEntry,
              {
                'sendPort': receivePort.sendPort,
                'batchFiles': batch,
                'outputFolder': outputFolder,
                'options': options,
                'batchNumber': i,
              },
              onError: receivePort.sendPort, // Send errors to the same port for handling
              onExit: receivePort.sendPort, // Handle unexpected exits
              errorsAreFatal: false, // Don't kill main isolate on error
          );
          isolates.add(isolate);
      }
    } catch (e, s) {
       print("Error spawning isolates: $e\n$s");
       receiveSubscription?.cancel();
       receivePort.close();
       isolates.forEach((iso) => iso.kill(priority: Isolate.immediate));
       onError("Failed to start processing isolates: $e");
    }
  }
}