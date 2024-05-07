#include "src/base/win32-headers.h"
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0602
#include <windows.h>
#undef RotateLeft32
#undef RotateRight32
