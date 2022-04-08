#include <netinet/sctp_os.h>
#include <netinet/sctp_var.h>
#include <netinet/sctp_sysctl.h>
#include <netinet/sctp_pcb.h>
#include <netinet/sctp_header.h>
#include <netinet/sctputil.h>
#include <netinet/sctp_output.h>
#include <netinet/sctp_input.h>
#include <netinet/sctp_indata.h>
#include <netinet/sctp_uio.h>
#include <netinet/sctp_timer.h>
#include <netinet/sctp_auth.h>
#include <netinet/sctp_asconf.h>

extern "C" const struct sctp_cc_functions sctp_cc_functions[] = {{
    .sctp_set_initial_cc_param = [](struct sctp_tcb *stcb, struct sctp_nets *net) {
	net->cwnd = -1; net->ssthresh = stcb->asoc.peers_rwnd; },
    .sctp_cwnd_update_after_sack = [](struct sctp_tcb *, struct sctp_association *, int, int, int) {},
    .sctp_cwnd_update_exit_pf = [](struct sctp_tcb *, struct sctp_nets *) {},
    .sctp_cwnd_update_after_fr = [](struct sctp_tcb *, struct sctp_association *) {},
    .sctp_cwnd_update_after_timeout = [](struct sctp_tcb *, struct sctp_nets *) {},
    .sctp_cwnd_update_after_ecn_echo = [](struct sctp_tcb *, struct sctp_nets *, int, int) {},
    .sctp_cwnd_update_after_packet_dropped = [](struct sctp_tcb *, struct sctp_nets *, struct sctp_pktdrop_chunk *, uint32_t *, uint32_t *) {},
    .sctp_cwnd_update_after_output = [](struct sctp_tcb *, struct sctp_nets *, int) {},
}};
