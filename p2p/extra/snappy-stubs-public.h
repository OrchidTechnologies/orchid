#ifndef THIRD_PARTY_SNAPPY_OPENSOURCE_SNAPPY_STUBS_PUBLIC_H_
#define THIRD_PARTY_SNAPPY_OPENSOURCE_SNAPPY_STUBS_PUBLIC_H_

#include <cstddef>

#ifndef _WIN32
#include <sys/uio.h>
#else
#if 0
#define SNAPPY_MAJOR ${PROJECT_VERSION_MAJOR}
#define SNAPPY_MINOR ${PROJECT_VERSION_MINOR}
#define SNAPPY_PATCHLEVEL ${PROJECT_VERSION_PATCH}
#define SNAPPY_VERSION \
    ((SNAPPY_MAJOR << 16) | (SNAPPY_MINOR << 8) | SNAPPY_PATCHLEVEL)
#endif

namespace snappy {
struct iovec {
    void *iov_base;
    size_t iov_len;
}; }
#endif

#endif//THIRD_PARTY_SNAPPY_OPENSOURCE_SNAPPY_STUBS_PUBLIC_H_
