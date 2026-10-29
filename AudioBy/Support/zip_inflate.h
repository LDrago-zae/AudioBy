#ifndef ZIP_INFLATE_H
#define ZIP_INFLATE_H

#include <stdint.h>

int audioby_raw_inflate(const uint8_t *src, int src_len, uint8_t *dst, int dst_len);

#endif
