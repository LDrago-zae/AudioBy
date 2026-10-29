#include "zip_inflate.h"
#include <zlib.h>

int audioby_raw_inflate(const uint8_t *src, int src_len, uint8_t *dst, int dst_len) {
    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.opaque = Z_NULL;
    stream.next_in = (Bytef *)src;
    stream.avail_in = (uInt)src_len;
    stream.next_out = dst;
    stream.avail_out = (uInt)dst_len;
    if (inflateInit2(&stream, -15) != Z_OK) {
        return -1;
    }
    int result = inflate(&stream, Z_FINISH);
    int written = (int)stream.total_out;
    inflateEnd(&stream);
    if (result != Z_STREAM_END) {
        return -1;
    }
    return written;
}
