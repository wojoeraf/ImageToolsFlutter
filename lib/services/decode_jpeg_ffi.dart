import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

late final ffi.DynamicLibrary _lib = _loadLibrary();

ffi.DynamicLibrary _loadLibrary() {
  if (Platform.isWindows) {
    // Try different possible locations for the DLL
    final possiblePaths = [
      'jpeg_decoder_wrapper.dll', // Current directory
      path.join(Directory.current.path, 'jpeg_decoder_wrapper.dll'),
      path.join(Platform.resolvedExecutable, '..', 'jpeg_decoder_wrapper.dll'),
      path.join(Platform.resolvedExecutable, '..', '..', 'jpeg_decoder_wrapper.dll'),
    ];
    
    for (final dllPath in possiblePaths) {
      try {
        print('Trying to load DLL from: $dllPath');
        return ffi.DynamicLibrary.open(dllPath);
      } catch (e) {
        print('Failed to load from $dllPath: $e');
        continue;
      }
    }
    throw Exception('Could not find jpeg_decoder_wrapper.dll in any expected location');
  } else {
    throw UnsupportedError('This library only supports Windows');
  }
}

typedef _TestTurboJpegNative = ffi.Int32 Function();
typedef _TestTurboJpegDart = int Function();

typedef _DecodeJpegNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> jpegBuf,
  ffi.Int32 jpegSize,
  ffi.Pointer<ffi.Uint8> outputBuf,
  ffi.Pointer<ffi.Int32> width,
  ffi.Pointer<ffi.Int32> height,
  ffi.Pointer<ffi.Int32> channels,
);
typedef _DecodeJpegDart = int Function(
  ffi.Pointer<ffi.Uint8> jpegBuf,
  int jpegSize,
  ffi.Pointer<ffi.Uint8> outputBuf,
  ffi.Pointer<ffi.Int32> width,
  ffi.Pointer<ffi.Int32> height,
  ffi.Pointer<ffi.Int32> channels,
);

final _testTurboJpeg =
    _lib.lookupFunction<_TestTurboJpegNative, _TestTurboJpegDart>('test_turbojpeg');

final _decodeJpeg =
    _lib.lookupFunction<_DecodeJpegNative, _DecodeJpegDart>('decode_jpeg');

Future<DecodedImage?> decodeJpegFile(String path) async {
  final fileBytes = await File(path).readAsBytes();
  final jpegSize = fileBytes.length;
  final jpegPtr = malloc<ffi.Uint8>(jpegSize);
  final widthPtr = malloc<ffi.Int32>();
  final heightPtr = malloc<ffi.Int32>();
  final channelsPtr = malloc<ffi.Int32>();

  try {
    final jpegList = jpegPtr.asTypedList(jpegSize);
    jpegList.setAll(0, fileBytes);

    // Estimate max output size (you could do smarter after header parse)
    const maxOutputSize = 10000 * 10000 * 3;
    final outputPtr = malloc<ffi.Uint8>(maxOutputSize);

    final result = _decodeJpeg(
      jpegPtr,
      jpegSize,
      outputPtr,
      widthPtr,
      heightPtr,
      channelsPtr,
    );

    if (result == 0) {
      malloc.free(outputPtr);
      return null; // decoding failed
    }

    final width = widthPtr.value;
    final height = heightPtr.value;
    final channels = channelsPtr.value;
    final outputLen = width * height * channels;

    final rawBytes = Uint8List.fromList(outputPtr.asTypedList(outputLen));
    malloc.free(outputPtr);

    return DecodedImage(
      width: width,
      height: height,
      channels: channels,
      bytes: rawBytes,
    );
  } finally {
    malloc.free(jpegPtr);
    malloc.free(widthPtr);
    malloc.free(heightPtr);
    malloc.free(channelsPtr);
  }
}

class DecodedImage {
  final int width;
  final int height;
  final int channels;
  final Uint8List bytes;

  DecodedImage({
    required this.width,
    required this.height,
    required this.channels,
    required this.bytes,
  });

  @override
  String toString() => 'DecodedImage: ${width}x$height @ $channels ch';
}

// Test function to check if turbojpeg.dll is being used
void testTurboJpegIntegration() {
  try {
    print('=== Testing TurboJPEG Integration ===');
    
    // Try to load the library
    print('Loading jpeg_decoder_wrapper.dll...');
    final lib = _loadLibrary();
    print('✓ Successfully loaded jpeg_decoder_wrapper.dll');
    
    // Try to lookup the functions
    print('Looking up decode_jpeg function...');
    final decodeFunc = lib.lookupFunction<_DecodeJpegNative, _DecodeJpegDart>('decode_jpeg');
    print('✓ Successfully found decode_jpeg function');
    
    print('Looking up test_turbojpeg function...');
    final testFunc = lib.lookupFunction<_TestTurboJpegNative, _TestTurboJpegDart>('test_turbojpeg');
    print('✓ Successfully found test_turbojpeg function');
    
    // Test TurboJPEG integration
    print('Testing TurboJPEG initialization...');
    final turboJpegResult = testFunc();
    if (turboJpegResult == 1) {
      print('✓ TurboJPEG is working correctly!');
    } else {
      print('✗ TurboJPEG initialization failed - this indicates the DLL is not properly linked');
    }
    
    // Check if turbojpeg.dll is in the same directory
    final executableDir = path.dirname(Platform.resolvedExecutable);
    final turboJpegPath = path.join(executableDir, 'turbojpeg.dll');
    final turboJpegExists = File(turboJpegPath).existsSync();
    print('TurboJPEG DLL at $turboJpegPath: ${turboJpegExists ? "✓ Found" : "✗ Not found"}');
    
    // List all DLLs in the executable directory
    print('\nDLLs in executable directory ($executableDir):');
    try {
      final dir = Directory(executableDir);
      final dlls = dir.listSync().where((f) => f.path.endsWith('.dll')).toList();
      for (final dll in dlls) {
        print('  - ${path.basename(dll.path)}');
      }
    } catch (e) {
      print('  Could not list directory: $e');
    }
    
  } catch (e) {
    print('✗ Error during integration test: $e');
  }
}

// Quick test
Future<void> main() async {
  // First test the integration
  testTurboJpegIntegration();
  
  print('\n=== Testing JPEG Decoding ===');
  const file = 'testdata/sample.jpg'; // replace with your file
  
  // Check if test file exists
  if (!File(file).existsSync()) {
    print('✗ Test file $file does not exist');
    return;
  }
  
  final img = await decodeJpegFile(file);
  if (img != null) {
    print('✓ Successfully decoded: $img');
  } else {
    print('✗ Failed to decode image');
  }
}
