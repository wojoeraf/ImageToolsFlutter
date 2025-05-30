import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

final _lib = ffi.DynamicLibrary.open('jpeg_decoder_wrapper.dll');

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

// Quick test
Future<void> main() async {
  const file = 'testdata/sample.jpg'; // replace with your file
  final img = await decodeJpegFile(file);
  if (img != null) {
    print('Decoded: $img');
  } else {
    print('Failed to decode image');
  }
}
