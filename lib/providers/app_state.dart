import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb, compute
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:image_tools/models/file_item.dart';
import 'package:image_tools/models/processing_options.dart';
import 'package:image_tools/services/processing_service.dart';
import 'package:image_tools/utils/constants.dart';
import 'package:image_tools/utils/file_utils.dart';

enum ProcessingState { idle, processing, success, error }

class AppState extends ChangeNotifier {
  final ProcessingService _processingService = ProcessingService();

  // --- State Variables ---
  List<FileItem> _selectedFiles = [];
  String? _outputFolder;
  ProcessingOptions _processingOptions = ProcessingOptions();
  ProcessingState _processingState = ProcessingState.idle;
  double _progress = 0.0; // 0.0 to 1.0
  String _statusMessage = '';
  String _feedbackMessage = ''; // For file selection feedback

  // Selection state for the UI checkboxes
  final Set<String> _checkedFilePaths = {}; // Store absolute paths of checked files
  final Set<String> _checkedGroupKeys = {}; // Store group keys of checked folders

  // --- Getters ---
  List<FileItem> get selectedFiles => List.unmodifiable(_selectedFiles);
  String? get outputFolder => _outputFolder;
  ProcessingOptions get processingOptions => _processingOptions;
  ProcessingState get processingState => _processingState;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String get feedbackMessage => _feedbackMessage;
  Set<String> get checkedFilePaths => Set.unmodifiable(_checkedFilePaths);
  Set<String> get checkedGroupKeys => Set.unmodifiable(_checkedGroupKeys);
  bool get isProcessing => _processingState == ProcessingState.processing;
  bool get canStartProcessing => _selectedFiles.isNotEmpty && _outputFolder != null && !isProcessing;
  bool get canSelectOutputFolder => _selectedFiles.isNotEmpty && !isProcessing;
  bool get canRemoveSelected => (_checkedFilePaths.isNotEmpty || _checkedGroupKeys.isNotEmpty) && !isProcessing;

  // --- File Selection & Management ---

  void clearFeedback() {
    _feedbackMessage = '';
    notifyListeners();
  }

  Future<void> pickFiles() async {
    clearFeedback();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: kAllowedExtensions.toList(),
      );

      if (result != null) {
        final filesToAdd = result.paths
            .where((path) => path != null)
            .map((path) => FileItem(absolutePath: path!)) // No relative path for single files
            .toList();
        _addFilesToList(filesToAdd);
      }
    } catch (e) {
      _statusMessage = "Error picking files: $e";
      _processingState = ProcessingState.error;
      notifyListeners();
    }
  }

  Future<void> pickFolder() async {
     clearFeedback();
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Image Folder',
      );

      if (selectedDirectory != null) {
        _feedbackMessage = "Scanning folder...";
        notifyListeners(); // Show scanning message

        // Use compute to scan directory off the main thread
        List<FileItem> foundFiles = await compute(_scanDirectory, selectedDirectory);

        _feedbackMessage = ""; // Clear scanning message
        _addFilesFromFolderToList(foundFiles, p.basename(selectedDirectory));
      }
    } catch (e) {
       _feedbackMessage = "";
      _statusMessage = "Error picking or scanning folder: $e";
      _processingState = ProcessingState.error;
      notifyListeners();
    }
  }

  // Helper function to be run in compute/isolate
  static Future<List<FileItem>> _scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<FileItem> files = [];
    if (await directory.exists()) {
       await for (var entity in directory.list(recursive: true, followLinks: false)) {
         if (entity is File) {
           String ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
           if (kAllowedExtensions.contains(ext)) {
              // Calculate relative path
              String relativePath = p.relative(entity.path, from: directoryPath);
              files.add(FileItem(absolutePath: entity.path, relativePath: relativePath));
           }
         }
       }
    }
    return files;
  }


  void addDroppedFiles(List<String> paths) async {
    clearFeedback();
    List<FileItem> filesToAdd = [];
    List<String> foldersToScan = [];

    for (final path in paths) {
      FileSystemEntityType type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.file) {
        String ext = p.extension(path).toLowerCase().replaceAll('.', '');
        if (kAllowedExtensions.contains(ext)) {
          filesToAdd.add(FileItem(absolutePath: path)); // No relative path for dropped files
        }
      } else if (type == FileSystemEntityType.directory) {
        foldersToScan.add(path);
      }
    }

    // Add single files first
     _addFilesToList(filesToAdd);

    // Then scan folders
    if (foldersToScan.isNotEmpty) {
       _feedbackMessage = "Scanning dropped folders...";
       notifyListeners();
       try {
         for (final folderPath in foldersToScan) {
            List<FileItem> foundFiles = await compute(_scanDirectory, folderPath);
            _addFilesFromFolderToList(foundFiles, p.basename(folderPath));
         }
         _feedbackMessage = ""; // Clear scanning message
       } catch (e) {
           _feedbackMessage = "";
           _statusMessage = "Error scanning dropped folder: $e";
           _processingState = ProcessingState.error;
           notifyListeners();
       }

    }
  }

  void _addFilesToList(List<FileItem> newFiles) {
    int skippedCount = 0;
    List<FileItem> uniqueNewFiles = [];
    final existingPaths = _selectedFiles.map((f) => f.absolutePath).toSet();

    for (final file in newFiles) {
      if (!existingPaths.contains(file.absolutePath)) {
        uniqueNewFiles.add(file);
        existingPaths.add(file.absolutePath); // Add to set immediately
      } else {
        skippedCount++;
      }
    }

    if (uniqueNewFiles.isNotEmpty) {
      _selectedFiles.addAll(uniqueNewFiles);
      // Optional: Sort files after adding? e.g., by group then filename
      _selectedFiles.sort((a, b) {
         int groupComp = (a.groupKey ?? 'ZZZ').compareTo(b.groupKey ?? 'ZZZ');
         if (groupComp != 0) return groupComp;
         return a.filename.compareTo(b.filename);
      });
    }

    if (skippedCount > 0) {
      _feedbackMessage = "$skippedCount file${skippedCount > 1 ? 's' : ''} skipped (already added).";
    } else if (uniqueNewFiles.isNotEmpty) {
       _feedbackMessage = "${uniqueNewFiles.length} file${uniqueNewFiles.length > 1 ? 's' : ''} added.";
    } else {
       _feedbackMessage = "No new files added.";
    }

    notifyListeners();
  }

   // Special handling for adding files from a folder scan
   void _addFilesFromFolderToList(List<FileItem> folderFiles, String folderName) {
      if (folderFiles.isEmpty) {
         _feedbackMessage = "No processable files found in folder '$folderName'.";
         notifyListeners();
         return;
      }

      int removedCount = 0;
      final Set<String> incomingPaths = folderFiles.map((f) => f.absolutePath).toSet();
      final String folderGroupKey = folderFiles.first.groupKey ?? folderName; // Use group key from first item

      // 1. Remove any existing files that are now covered by this folder scan OR have the same group key
      final filteredExisting = _selectedFiles.where((f) {
         bool isInIncoming = incomingPaths.contains(f.absolutePath);
         bool isInSameGroup = f.groupKey == folderGroupKey;
         if (isInIncoming || isInSameGroup) {
            removedCount++;
            // Also remove from checked sets if it was checked
            _checkedFilePaths.remove(f.absolutePath);
            return false; // Remove this file
         }
         return true; // Keep this file
      }).toList();

      _selectedFiles = filteredExisting;

      // 2. Add the new files from the folder scan
       _selectedFiles.addAll(folderFiles);
      _selectedFiles.sort((a, b) {
         int groupComp = (a.groupKey ?? 'ZZZ').compareTo(b.groupKey ?? 'ZZZ');
         if (groupComp != 0) return groupComp;
         return a.filename.compareTo(b.filename);
      });

      // Update feedback message
      String removedMsg = removedCount > 0 ? "$removedCount existing file${removedCount > 1 ? 's' : ''} replaced. " : "";
      _feedbackMessage = "${folderFiles.length} file${folderFiles.length > 1 ? 's' : ''} added from '$folderName'. $removedMsg".trim();

      // Clear checked state for the folder group just added/replaced
      _checkedGroupKeys.remove(folderGroupKey);

      notifyListeners();
   }

  void removeSelected() {
    if (!canRemoveSelected) return;

    final Set<String> pathsToRemove = Set.from(_checkedFilePaths);

    // Add all file paths belonging to checked groups
    for (final groupKey in _checkedGroupKeys) {
      for (final file in _selectedFiles) {
        if (file.groupKey == groupKey) {
          pathsToRemove.add(file.absolutePath);
        }
      }
    }

    if (pathsToRemove.isEmpty) return;

    _selectedFiles.removeWhere((file) => pathsToRemove.contains(file.absolutePath));

    // Clear check states
    _checkedFilePaths.clear();
    _checkedGroupKeys.clear();
    _feedbackMessage = "${pathsToRemove.length} item${pathsToRemove.length > 1 ? 's' : ''} removed.";

    notifyListeners();
  }

  void toggleFileCheck(String absolutePath, bool isChecked) {
    if (isChecked) {
      _checkedFilePaths.add(absolutePath);
    } else {
      _checkedFilePaths.remove(absolutePath);
    }
    notifyListeners();
  }

  void toggleGroupCheck(String groupKey, bool isChecked) {
    if (isChecked) {
      _checkedGroupKeys.add(groupKey);
      // Check all files within this group
      for (final file in _selectedFiles) {
        if (file.groupKey == groupKey) {
          _checkedFilePaths.add(file.absolutePath);
        }
      }
    } else {
      _checkedGroupKeys.remove(groupKey);
      // Uncheck all files within this group
      for (final file in _selectedFiles) {
        if (file.groupKey == groupKey) {
          _checkedFilePaths.remove(file.absolutePath);
        }
      }
    }
    notifyListeners();
  }

  void selectAll() {
      _checkedGroupKeys.clear();
      _checkedFilePaths.clear();
      for(final file in _selectedFiles) {
          _checkedFilePaths.add(file.absolutePath);
      }
       // Optionally check group keys too, though checking all files is sufficient
      final allGroupKeys = _selectedFiles.map((f) => f.groupKey).where((k) => k != null).toSet();
      _checkedGroupKeys.addAll(allGroupKeys.cast<String>());

      notifyListeners();
  }

   void deselectAll() {
      _checkedFilePaths.clear();
      _checkedGroupKeys.clear();
      notifyListeners();
   }

    // --- Selection Menu Logic ---
    // (Implement specific selection logic like select RAW/Non-RAW etc.)
    // Example:
    void selectRawFiles() {
        _checkedFilePaths.clear(); // Start fresh or add to existing? Decide policy.
        _checkedGroupKeys.clear();
        for (final file in _selectedFiles) {
            if (file.isRaw) {
                _checkedFilePaths.add(file.absolutePath);
            }
        }
        notifyListeners();
    }
     void selectNonRawFiles() {
        _checkedFilePaths.clear();
        _checkedGroupKeys.clear();
        for (final file in _selectedFiles) {
            if (!file.isRaw) {
                _checkedFilePaths.add(file.absolutePath);
            }
        }
        notifyListeners();
    }

    // Add similar functions for RAW/Non-RAW within folders, single files etc.
    // based on the logic in your JS `selection-logic.js`


  // --- Output Folder ---

  Future<void> selectOutputFolder() async {
    if (!canSelectOutputFolder) return;
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Output Folder',
        initialDirectory: _selectedFiles.isNotEmpty
          ? p.dirname(_selectedFiles.first.absolutePath)
          : null,
      );
      if (selectedDirectory != null) {
        _outputFolder = selectedDirectory;
        _statusMessage = ''; // Clear previous errors if any
        _processingState = ProcessingState.idle;
      } else {
         // User cancelled - don't change existing folder if any
         // _outputFolder = null; // Uncomment if cancellation should clear the selection
      }
    } catch (e) {
      _outputFolder = null;
      _statusMessage = "Error selecting output folder: $e";
      _processingState = ProcessingState.error;
    }
    notifyListeners();
  }

  // --- Settings ---

  void setResolution(String resolutionKey) {
    if (kResolutions.containsKey(resolutionKey)) {
      _processingOptions = ProcessingOptions(
        resolutionKey: resolutionKey,
        quality: _processingOptions.quality,
      );
      notifyListeners();
    }
  }

  void setQuality(double quality) {
    _processingOptions = ProcessingOptions(
      resolutionKey: _processingOptions.resolutionKey,
      quality: quality.round(),
    );
    notifyListeners();
  }

  // --- Processing ---

  Future<void> startProcessing() async {
    if (!canStartProcessing) return;

    _processingState = ProcessingState.processing;
    _progress = 0.0;
    _statusMessage = 'Initializing...';
    notifyListeners();

    // Optional: Clear output folder contents (use with caution!)
    // Be very careful with deleting files! Add confirmation?
    // try {
    //   final dir = Directory(_outputFolder!);
    //   if (await dir.exists()) {
    //     await for (final entity in dir.list()) {
    //       await entity.delete();
    //     }
    //   }
    // } catch (e) {
    //    _statusMessage = 'Error clearing output folder: $e';
    //    _processingState = ProcessingState.error;
    //    notifyListeners();
    //    return;
    // }


    try {
      await _processingService.processImages(
        filesToProcess: _selectedFiles,
        outputFolder: _outputFolder!,
        options: _processingOptions,
        onProgress: (processedCount, totalCount, message) {
          _progress = totalCount > 0 ? processedCount / totalCount : 0.0;
          _statusMessage = message ?? 'Processing $processedCount of $totalCount...';
          notifyListeners();
        },
        onComplete: (successCount) {
          _processingState = ProcessingState.success;
          _statusMessage = 'Processing complete. $successCount image${successCount != 1 ? 's' : ''} processed.';
          _progress = 1.0;
          notifyListeners();
        },
        onError: (errorMsg) {
          _processingState = ProcessingState.error;
          _statusMessage = 'Error during processing: $errorMsg';
          notifyListeners();
        },
      );
    } catch (e) {
       _processingState = ProcessingState.error;
       _statusMessage = 'Failed to start processing: $e';
       notifyListeners();
    }
  }
}