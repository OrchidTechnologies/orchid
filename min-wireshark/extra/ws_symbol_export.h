#ifdef __MINGW32__
#define WS_DLL_PUBLIC_DEF
#define WS_DLL_LOCAL
#define WS_DLL_PUBLIC extern
#else
#include_next "ws_symbol_export.h"
#endif
