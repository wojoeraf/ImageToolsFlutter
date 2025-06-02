# TurboJPEG Integration Fix

## Problem
The `decode_jpeg_ffi.dart` file was not properly using the Windows-specific `turbojpeg.dll` because:

1. The `jpeg_decoder_wrapper.dll` was not properly linked with `turbojpeg.dll` at build time
2. The CMakeLists.txt did not include proper build rules for the wrapper DLL
3. The DLL installation rules were missing, so `turbojpeg.dll` was not copied to the output directory
4. The Dart FFI code used a simple relative path that might not resolve correctly

## Solution

### 1. Updated CMakeLists.txt
- Added proper CMake target for building `jpeg_decoder_wrapper.dll`
- Linked the wrapper DLL with `turbojpeg.lib` at build time
- Added installation rules to copy both `jpeg_decoder_wrapper.dll` and `turbojpeg.dll` to the output directory

### 2. Enhanced Dart FFI Code
- Added robust DLL loading that tries multiple possible paths
- Added comprehensive testing functions to verify TurboJPEG integration
- Added debug output to help diagnose loading issues

### 3. Added Build Scripts
- `build_wrapper.bat`: Manual build script using Visual Studio compiler
- `check_dependencies.ps1`: PowerShell script to verify DLL dependencies

### 4. Enhanced C Wrapper
- Added `test_turbojpeg()` function to verify TurboJPEG initialization
- Added debug output for troubleshooting

## How to Build

### Option 1: Using CMake (Recommended)
```bash
cd windows
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

### Option 2: Using Visual Studio Command Prompt
```cmd
cd windows
build_wrapper.bat
```

## How to Test

Run the test function in `decode_jpeg_ffi.dart`:
```bash
cd ImageToolsFlutter
flutter run lib/services/decode_jpeg_ffi.dart
```

Or use the PowerShell script to check dependencies:
```powershell
cd windows
.\check_dependencies.ps1
```

## Expected Output

When working correctly, the test should show:
```
=== Testing TurboJPEG Integration ===
Loading jpeg_decoder_wrapper.dll...
✓ Successfully loaded jpeg_decoder_wrapper.dll
Looking up decode_jpeg function...
✓ Successfully found decode_jpeg function
Looking up test_turbojpeg function...
✓ Successfully found test_turbojpeg function
Testing TurboJPEG initialization...
✓ TurboJPEG is working correctly!
TurboJPEG DLL at [path]: ✓ Found
```

## Troubleshooting

1. **DLL not found**: Ensure both `jpeg_decoder_wrapper.dll` and `turbojpeg.dll` are in the same directory as the executable
2. **TurboJPEG initialization failed**: The wrapper DLL is not properly linked with TurboJPEG - rebuild using the provided scripts
3. **Function not found**: The wrapper DLL was not built with the correct exports - check the build process

## Files Modified/Added

- `CMakeLists.txt`: Added proper build and installation rules
- `decode_jpeg_ffi.dart`: Enhanced with robust loading and testing
- `jpeg_decoder_wrapper.c`: Added test function and debug output
- `build_wrapper.bat`: Manual build script
- `check_dependencies.ps1`: Dependency checking script
- `README_TURBOJPEG.md`: This documentation