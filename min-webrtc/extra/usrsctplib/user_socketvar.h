#ifndef ORCHID_USER_SOCKETVAR
#define ORCHID_USER_SOCKETVAR
#ifdef __MINGW32__
#define pid_t orc_pid_t
#endif
#include_next <usrsctplib/user_socketvar.h>
#ifdef __MINGW32__
#undef pid_t
#endif
#endif//ORCHID_USER_SOCKETVAR
