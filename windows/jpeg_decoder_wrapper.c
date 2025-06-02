// jpeg_decoder_wrapper.c
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include "turbojpeg.h"

#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Test function to verify TurboJPEG is working
DLL_EXPORT
int test_turbojpeg() {
    tjhandle handle = tjInitDecompress();
    if (handle) {
        tjDestroy(handle);
        return 1; // TurboJPEG is working
    }
    return 0; // TurboJPEG failed to initialize
}

// Returns 1 on success, 0 on error.
DLL_EXPORT
int decode_jpeg(
    uint8_t* jpegBuf,
    int jpegSize,
    uint8_t* outputBuf,
    int* width,
    int* height,
    int* channels
) {
    if (!jpegBuf || jpegSize <= 0 || !outputBuf || !width || !height || !channels) return 0;

    // Debug output (will be visible in debug builds)
    #ifdef _DEBUG
    printf("decode_jpeg called with jpegSize=%d\n", jpegSize);
    #endif

    tjhandle handle = tjInitDecompress();
    if (!handle) {
        #ifdef _DEBUG
        printf("tjInitDecompress failed\n");
        #endif
        return 0;
    }

    int subsamp, colorspace;
    if (tjDecompressHeader3(handle, jpegBuf, jpegSize, width, height, &subsamp, &colorspace) != 0) {
        tjDestroy(handle);
        return 0;
    }

    *channels = 3; // We decode into RGB
    int pixelFormat = TJPF_RGB;
    int pitch = (*width) * (*channels);

    int flags = TJFLAG_FASTDCT; // fast, still high quality
    if (tjDecompress2(handle, jpegBuf, jpegSize, outputBuf, *width, pitch, *height, pixelFormat, flags) != 0) {
        tjDestroy(handle);
        return 0;
    }

    tjDestroy(handle);
    return 1;
}

#ifdef __cplusplus
}
#endif
