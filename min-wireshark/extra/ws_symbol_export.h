#ifdef __MINGW32__
// XXX: we should be able to just use -DENABLE_STATIC, but that is ignored for __GNUC__ and needs to be fixed upstream
// vpn/wsk/wireshark/epan/conversation.c:1616:15: error: dllimport cannot be applied to non-inline function definition
#define WS_DLL_PUBLIC_DEF
#define WS_DLL_LOCAL
#define WS_DLL_PUBLIC extern
#else
#include_next "ws_symbol_export.h"
#endif
