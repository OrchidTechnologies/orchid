#include_next <netinet/sctp_var.h>
#undef sctp_sbspace_sub
#define sctp_sbspace_sub(a,b) -1
