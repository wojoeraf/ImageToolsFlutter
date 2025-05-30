#include <stdint.h> // Standard integer types

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h" // Correct header

#ifdef __cplusplus
extern "C" {
#endif

__declspec(dllexport)
int resize_image(
    uint8_t* src, int src_width, int src_height,
    uint8_t* dst, int dst_width, int dst_height,
    int channels
) {
    return stbir_resize_uint8_linear(
        src, src_width, src_height, 0,
        dst, dst_width, dst_height, 0,
        (stbir_pixel_layout)channels
    );
}

#ifdef __cplusplus
}
#endif
