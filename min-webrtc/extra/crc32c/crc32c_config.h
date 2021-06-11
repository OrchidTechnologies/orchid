#ifndef CRC32C_CRC32C_CONFIG_H_
#define CRC32C_CRC32C_CONFIG_H_

#define HAVE_BUILTIN_PREFETCH 1

// XXX: am I really not using sse?
//#define HAVE_SSE42 1

#ifdef __aarch64__
// XXX: I need to pass clang -mcrc
//#define HAVE_ARM64_CRC32C 1
#endif

#define HAVE_WEAK_GETAUXVAL 1

#endif//CRC32C_CRC32C_CONFIG_H_
