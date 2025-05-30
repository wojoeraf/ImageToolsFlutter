import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:typed_data';
import 'dart:io';

typedef ResizeNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> src,
  ffi.Int32 srcWidth,
  ffi.Int32 srcHeight,
  ffi.Pointer<ffi.Uint8> dst,
  ffi.Int32 dstWidth,
  ffi.Int32 dstHeight,
  ffi.Int32 channels,
  ffi.Uint8 useSrgb,
);

typedef ResizeDart = int Function(
  ffi.Pointer<ffi.Uint8> src,
  int srcWidth,
  int srcHeight,
  ffi.Pointer<ffi.Uint8> dst,
  int dstWidth,
  int dstHeight,
  int channels,
  int useSrgb,
);

class ResizeFFI {
  late final ffi.DynamicLibrary _lib;
  late final ResizeDart _resize;

  ResizeFFI() {
    _lib = Platform.isWindows
        ? ffi.DynamicLibrary.open('resizeFast64.dll')
        : throw UnsupportedError('Only Windows supported in this setup.');

    _resize = _lib
        .lookup<ffi.NativeFunction<ResizeNative>>('resize_image')
        .asFunction();
  }

  int resize(Uint8List src, int srcWidth, int srcHeight,
             Uint8List dst, int dstWidth, int dstHeight,
             int channels, {int useSrgb = 1}) {
    // Validate sizes
    final expectedSrcLen = srcWidth * srcHeight * channels;
    final expectedDstLen = dstWidth * dstHeight * channels;
    print('ResizeFFI: expectedSrcLen=$expectedSrcLen, src.length=${src.length}');
    print('ResizeFFI: expectedDstLen=$expectedDstLen, dst.length=${dst.length}');
    if (src.length < expectedSrcLen) {
      throw ArgumentError('Source buffer too small: ${src.length} < $expectedSrcLen');
    }
    if (dst.length < expectedDstLen) {
      throw ArgumentError('Destination buffer too small: ${dst.length} < $expectedDstLen');
    }

    final srcPtr = malloc<ffi.Uint8>(expectedSrcLen);
    final dstPtr = malloc<ffi.Uint8>(expectedDstLen);

    try {
      final srcList = srcPtr.asTypedList(expectedSrcLen);
      final toCopy = src.length > expectedSrcLen ? src.sublist(0, expectedSrcLen) : src;
      srcList.setAll(0, toCopy);

      print('FFI resize: ${srcWidth}x${srcHeight} -> ${dstWidth}x${dstHeight}, channels=$channels');
      int result;
      try {
        result = _resize(srcPtr, srcWidth, srcHeight,
                         dstPtr, dstWidth, dstHeight,
                         channels, useSrgb);
      } catch (e) {
        print('FFI call exception: $e');
        result = -1;
      }

      final dstList = dstPtr.asTypedList(expectedDstLen);
      dst.setAll(0, dstList);

      return result;
    } finally {
      malloc.free(srcPtr);
      malloc.free(dstPtr);
    }
  }
}
