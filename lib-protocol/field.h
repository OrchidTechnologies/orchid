#if defined(__ANDROID__) && defined(__arm__) || defined(_WIN32) && !defined(__SIZEOF_INT128__)
#define USE_FIELD_10X26
#define USE_SCALAR_8X32
#else
#define USE_FIELD_5X52
#define USE_SCALAR_4X64
#define HAVE___INT128
#endif
