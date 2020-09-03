#include_next <usrsctp.h>
#define usrsctp_socket(a, b, c, d, e, f, g) \
    usrsctp_socket(a, b, c, d, (int (*)(struct socket *, uint32_t, void *)) e, f, g)
