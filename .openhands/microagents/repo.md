# Repository Microagent: Image Batch Processor

This repository contains the code for an image batch processing application, built primarily for Windows desktop using Flutter and Dart. Its core functionality currently focuses on efficient batch resizing and format conversion, leveraging native code and optimized libraries for performance.

## General Setup:
To work on this project, you will need the Flutter SDK installed and configured for desktop development (specifically Windows, but Linux and macOS are also supported).
Important note: You are on a linux container and therefore you can only create certain os related files but not run or build them. The human developer will do so later. Your job is to make sure the files are created and filled with correct code.
You will need a C++ compiler installed on your system as the project includes native C++ components linked via FFI.

The native components (C/C++ wrappers and libraries) are compiled as part of the standard Flutter desktop build process.

*   Build for Windows (Debug): `flutter build windows`
*   Build for Windows (Profile): `flutter build windows --profile`
*   Build for Windows (Release): `flutter build windows --release`
*   Run locally (Debug): `flutter run -d windows`

IMPORTANT: Before making any changes to the codebase, ALWAYS run `flutter pub get` if dependencies have changed.

Before pushing any changes, you MUST ensure that any lint errors or simple test errors have been fixed.

*   Run Dart analysis/linting: `flutter analyze`
*   Run Dart unit tests: `flutter test`

The `flutter analyze` and `flutter test` commands MUST pass successfully before pushing any changes to the repository. This is a mandatory requirement to maintain code quality and consistency.

If `flutter analyze` reports errors, fix them. If `flutter test` fails, fix the code or the tests.

## Repository Structure
The core application logic is in the `lib/` directory. Platform-specific code and build configurations are in the respective platform directories (`windows/`, `linux/`, `macos/`). Build outputs are in `build/` and `.dart_tool/`.

*   `lib/`: Contains the main Dart/Flutter application source code.
    *   `lib/main.dart`: Application entry point.
    *   `lib/models/`: Data structures used within the app (e.g., `file_item.dart`, `processing_options.dart`).
    *   `lib/providers/`: State management using providers (`app_state.dart`).
    *   `lib/screens/`: Top-level UI screens (`home_screen.dart`).
    *   `lib/services/`: Core application logic, including image processing orchestration (`image_processor.dart`, `processing_service.dart`) and Dart FFI interfaces (`decode_jpeg_ffi.dart`, `resize_ffi.dart`).
    *   `lib/utils/`: Utility functions and constants (`file_utils.dart`, `constants.dart`).
    *   `lib/widgets/`: Reusable UI components (e.g., file list, settings panel, buttons).
    *   `lib/wrappers/`: C/C++ wrapper code specifically designed to be called via Dart FFI (`resize_wrapper.c`, `libraries/stb_image_resize2.h`).
*   `windows/`: Windows-specific native code and CMake/Visual Studio build configuration. Includes the C++ runner application (`windows/runner/`) and Windows-specific FFI implementations (`windows/jpeg_decoder_wrapper.c`), linking against native libraries (`windows/lib/turbojpeg.lib`, `windows/turbojpeg.dll`, `windows/turbojpeg.h`).
*   `linux/`: Linux-specific build setup and potentially native libraries (e.g., `libraw.so`).
*   `macos/`: macOS-specific build setup and potentially native libraries (e.g., `libraw.dylib`).
*   `assets/`: Application assets, such as images (`assets/img/logo.png`).
*   `test/`: Dart/Flutter unit and widget tests (`widget_test.dart`).
*   `testdata/`: Sample files used for testing or development (`sample.jpg`).
*   `build/`, `.dart_tool/`: Directories containing generated build artifacts, caches, and temporary files. These are build outputs and typically should not be manually modified.
*   `.git/`: Git version control metadata.
*   `.vscode/`, `.idea/`: IDE configuration files.
*   `pubspec.yaml`, `pubspec.lock`: Dart/Flutter project dependencies.
*   `analysis_options.yaml`, `devtools_options.yaml`: Dart analysis and devtools configuration.
*   `.flutter-plugins`, `.flutter-plugins-dependencies`: Files generated by Flutter to track plugins.

## Testing:
Tests for the Dart/Flutter code are located in the `test/` directory.

*   To run all tests: `flutter test`
*   To run tests in a specific file: `flutter test path/to/your_test_file.dart`

Native C/C++ code testing is not explicitly configured in the provided structure but would typically require separate native test runners or integration tests via the Flutter application.

## Implementation Details:
This section details specific architectural choices and how different parts of the application interact.

*   **User Interface:** The UI is built using Flutter widgets defined in `lib/screens/` and `lib/widgets/`.
*   **State Management:** Application state, such as the list of files and processing options, is managed using the provider package, centered around the `AppState` class in `lib/providers/app_state.dart`.
*   **Image Processing Pipeline:** The high-level processing logic resides in `lib/services/processing_service.dart` and `lib/services/image_processor.dart`. This code orchestrates reading files, applying transformations, and saving outputs.
*   **Native Interoperability (FFI):** Performance-critical image operations, like decoding and resizing, are offloaded to native C/C++ code via Dart's Foreign Function Interface (FFI).
    *   Dart FFI bindings are defined in files like `lib/services/decode_jpeg_ffi.dart` and `lib/services/resize_ffi.dart`. These files describe the signatures of the native functions.
    *   The actual C/C++ implementations of the wrapper functions that interface with optimized libraries are located in `lib/wrappers/resize_wrapper.c` (using `stb_image_resize2.h`) and `windows/jpeg_decoder_wrapper.c` (using the TurboJPEG library).
    *   The project incorporates pre-built native libraries like TurboJPEG (for JPEG decoding/encoding) and `stb_image_resize2` (for resizing). `libraw` is also present in platform directories, suggesting potential support for RAW image formats via native means.
*   **Build Process:** Flutter's desktop build system uses CMake (on Windows/Linux) or Xcode (on macOS) to compile the native runner application and any FFI-linked C/C++ code defined within the project or its dependencies, bundling them with the compiled Dart code and assets.