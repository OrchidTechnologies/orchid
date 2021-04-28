// XXX: soralog/util.hpp needs a Win32 [gs]etThreadName
#include <pthread.h>
#include <array>
#include <string>
#ifdef _WIN32
#define __linux__
#endif
#include_next <soralog/util.hpp>
#ifdef _WIN32
#undef __linux__
#endif
