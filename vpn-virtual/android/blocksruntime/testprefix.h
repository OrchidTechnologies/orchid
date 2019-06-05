#undef __APPLE_CC__
#define __APPLE_CC__ 5627
#define _BSD_SOURCE
#include <stdlib.h>
#include <stdio.h>
#ifdef _WIN32
#define random() rand()
#else /* !_WIN32 */
#ifdef __linux__
#undef __block
#endif
#include <unistd.h>
#ifdef __linux__
#define __block __attribute__((__blocks__(byref)))
#endif
#include <sys/wait.h>
#endif /* !_WIN32 */
