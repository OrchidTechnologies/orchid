#include <openvpn/ip/ipcommon.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/ip6.hpp>
#include <openvpn/ip/tcp.hpp>
#include <openvpn/ip/udp.hpp>

#include "buffer.hpp"
#include "monitor.hpp"
#include "socket.hpp"

// includes from wireshark
#include <epan/epan.h>
#include <wsutil/filesystem.h>
#include <wsutil/privileges.h>
#include <wsutil/report_message.h>
#include "epan/column-utils.h"
#include "epan/proto.h"
#include "file.h"
#include "frame_tvbuff.h"
#include <epan/addr_resolv.h>
#include <epan/column.h>
#include <epan/epan_dissect.h>
#include <epan/ftypes/ftypes-int.h>
#include <epan/packet.h>
#include <epan/prefs.h>
#include <epan/tap.h>
#include <version_info.h>
#include "log.h"


using namespace openvpn;
using namespace asio::ip;


namespace orc {
typedef std::function<void (const std::string_view)> hostname_callback;
typedef std::function<void (const std::string_view, const std::string_view)> protocol_callback;
}

capture_file cf;
guint32 cum_bytes;
frame_data ref_frame;
frame_data prev_dis_frame;
frame_data prev_cap_frame;
gint64 data_offset;
wtap_rec rec;
epan_dissect_t edt;

void log_func_ignore(const gchar *log_domain, GLogLevelFlags log_level,
                     const gchar *message, gpointer user_data)
{
}

// General errors and warnings are reported with an console message in Orchid.
void failure_warning_message(const char *msg_format, va_list ap)
{
    char buf[1024];
    vsnprintf(buf, sizeof(buf), msg_format, ap);
    orc::Log() << "orchid: " << buf << std::endl;
}

// Open/create errors are reported with an console message in Orchid.
void open_failure_message(const char *filename, int err, gboolean for_writing)
{
    char buf[1024];
    snprintf(buf, sizeof(buf), file_open_error_message(err, for_writing), filename);
    orc::Log() << "orchid: " << buf << std::endl;
}

// Read errors are reported with an console message in Orchid.
void read_failure_message(const char *filename, int err)
{
    orc::Log() << "An error occurred while reading from the file \"" << filename << "\" " << g_strerror(err) << std::endl;
}

// Write errors are reported with an console message in Orchid.
void write_failure_message(const char *filename, int err)
{
    orc::Log() << "An error occurred while writing to the file \"" << filename << "\" " << g_strerror(err) << std::endl;
}

const nstime_t* raw_get_frame_ts(struct packet_provider_data *prov, guint32 frame_num)
{
    if (prov->ref && prov->ref->num == frame_num)
        return &prov->ref->abs_ts;

    if (prov->prev_dis && prov->prev_dis->num == frame_num)
        return &prov->prev_dis->abs_ts;

    if (prov->prev_cap && prov->prev_cap->num == frame_num)
        return &prov->prev_cap->abs_ts;

    return NULL;
}

void tap_frame(const char *field)
{
    GString *error_string = register_tap_listener("frame", NULL, field, TL_REQUIRES_PROTO_TREE, NULL, NULL, NULL, NULL);
    if (error_string) {
        /* error, we failed to attach to the tap. complain and clean up */
        orc::Log() << "Couldn't register field (\"" << field << "\") extraction tap: " << error_string->str << std::endl;
        g_string_free(error_string, TRUE);
    }
}

void wireshark_setup()
{
    ws_init_version_info("Orchid", NULL, epan_get_compiled_version_info,  NULL);

    // Get credential information for later use.
    init_process_policies();

    // nothing more than the standard GLib handler, but without a warning
    GLogLevelFlags log_flags = (GLogLevelFlags)(G_LOG_LEVEL_WARNING | G_LOG_LEVEL_MESSAGE | G_LOG_LEVEL_INFO | G_LOG_LEVEL_DEBUG);

    g_log_set_handler(NULL, log_flags, log_func_ignore, NULL);
    g_log_set_handler(LOG_DOMAIN_CAPTURE_CHILD, log_flags, log_func_ignore, NULL);

    init_report_message(failure_warning_message, failure_warning_message,
                        open_failure_message, read_failure_message,
                        write_failure_message);

    wtap_init(FALSE);

    // Register all dissectors
    if (!epan_init(NULL, NULL, TRUE)) {
        wtap_cleanup();
        return;
    }

    // Load libwireshark settings from the current profile
    e_prefs *prefs_p = epan_load_settings();

    cap_file_init(&cf);

    disable_name_resolution();

    char *errmsg = NULL;
    prefs_set_pref(strdup("gui.column.format:\"Protocol\",\"%p\""), &errmsg);
    if (errmsg) {
        orc::Log() << __func__ << " " << errmsg << std::endl;
    }

    prefs_apply_all();

    tap_frame("frame.protocols");
    tap_frame("tls.handshake.extensions_server_name");
    tap_frame("gquic.tag.sni");
    tap_frame("gquic.version");
    tap_frame("http.host");
    tap_frame("http.request.version");

    build_column_format_array(&cf.cinfo, prefs_p->num_cols, TRUE);

    static const struct packet_provider_funcs funcs = {
        raw_get_frame_ts,
        NULL,
        NULL,
        NULL,
    };

    cf.epan = epan_new(&cf.provider, &funcs);
    cf.provider.wth = NULL;
    cf.f_datalen = 0;
    cf.filename = NULL;
    cf.is_tempfile = TRUE;
    cf.unsaved_changes = FALSE;
    cf.cd_t = WTAP_FILE_TYPE_SUBTYPE_UNKNOWN;
    cf.open_type = WTAP_TYPE_AUTO;
    cf.count = 0;
    cf.drops_known = FALSE;
    cf.drops = 0;
    cf.snap = 0;
    nstime_set_zero(&cf.elapsed_time);
    cf.provider.ref = NULL;
    cf.provider.prev_dis = NULL;
    cf.provider.prev_cap = NULL;

    wtap_rec_init(&rec);
    epan_dissect_init(&edt, cf.epan, TRUE, FALSE);
}

void wireshark_cleanup()
{
    epan_dissect_cleanup(&edt);
    wtap_rec_cleanup(&rec);
    epan_free(cf.epan);
    epan_cleanup();
    wtap_cleanup();
}

std::string get_tree_field(epan_dissect_t *edt, const char *field)
{
    header_field_info *hfi = proto_registrar_get_byname(field);
    if (!hfi) {
        orc::Log() << "Field \"" << field << "\" doesn't exist." << std::endl;
        return "";
    }
    GPtrArray *gp = proto_get_finfo_ptr_array(edt->tree, hfi->id);
    if (!gp) {
        return "";
    }
    for (guint i = 0; i < gp->len; i++) {
        field_info *finfo = (field_info *)gp->pdata[i];
        if (!finfo->value.ftype->val_to_string_repr) {
            continue;
        }
        int fs_len = fvalue_string_repr_len(&finfo->value, FTREPR_DISPLAY, finfo->hfinfo->display);
        std::string field_value;
        field_value.resize(fs_len);
        finfo->value.ftype->val_to_string_repr(&finfo->value, FTREPR_DISPLAY, finfo->hfinfo->display, &field_value[0], fs_len + 1);
        return field_value;
    }
    return "";
}

void wireshark_analyze(const uint8_t *buf, size_t packet_len, const orc::hostname_callback hostname_cb, const orc::protocol_callback protocol_cb)
{
    static bool wireshark_initialized = false;
    if (!wireshark_initialized) {
        wireshark_initialized = true;
        wireshark_setup();
    }
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    rec.ts.secs = ts.tv_sec;
    rec.ts.nsecs = ts.tv_nsec;
    rec.rec_header.packet_header.caplen = packet_len;
    rec.rec_header.packet_header.len = packet_len;
    rec.rec_header.packet_header.pkt_encap = WTAP_ENCAP_RAW_IP;
    data_offset += packet_len;

    cf.count++;

    frame_data fdata;
    frame_data_init(&fdata, cf.count, &rec, data_offset, cum_bytes);

    frame_data_set_before_dissect(&fdata, &cf.elapsed_time,
                                  &cf.provider.ref, cf.provider.prev_dis);

    if (cf.provider.ref == &fdata) {
        ref_frame = fdata;
        cf.provider.ref = &ref_frame;
    }

    epan_dissect_run_with_taps(&edt, cf.cd_t, &rec,
                               frame_tvbuff_new(&cf.provider, &fdata, buf),
                               &fdata, &cf.cinfo);
    epan_dissect_fill_in_columns(&edt, FALSE, TRUE);

    auto protocol_chain = get_tree_field(&edt, "frame.protocols");
    auto gquic_ver = get_tree_field(&edt, "gquic.version");
    auto http_ver = get_tree_field(&edt, "http.request.version");

    for (int i = 0; i < cf.cinfo.num_cols; i++) {
        col_item_t* col_item = &cf.cinfo.columns[i];
        if (col_item->col_fmt == COL_PROTOCOL) {
            if (!http_ver.empty()) {
                protocol_cb(http_ver, protocol_chain);
            } else if (!gquic_ver.empty()) {
                std::ostringstream protocol;
                protocol << col_item->col_data << " " << gquic_ver;
                protocol_cb(protocol.str(), protocol_chain);
            } else {
                protocol_cb(col_item->col_data, protocol_chain);
            }
            break;
        }
    }

    const char* hostname_keys[] = {
        "tls.handshake.extensions_server_name",
        "gquic.tag.sni",
        "http.host"
    };
    for (size_t i = 0; i < sizeof(hostname_keys) / sizeof(hostname_keys[0]); i++) {
        std::string hostname = get_tree_field(&edt, hostname_keys[i]);
        if (!hostname.empty()) {
            hostname_cb(hostname);
            break;
        }
    }

    frame_data_set_after_dissect(&fdata, &cum_bytes);
    prev_dis_frame = fdata;
    cf.provider.prev_dis = &prev_dis_frame;

    prev_cap_frame = fdata;
    cf.provider.prev_cap = &prev_cap_frame;

    epan_dissect_reset(&edt);
    frame_data_destroy(&fdata);
}

namespace orc {

void monitor(const uint8_t *buf, size_t len, MonitorLogger &logger)
{
    if (len < 1) {
        return;
    }

    if (IPCommon::version(buf[0]) != (uint8_t)IPCommon::IPv4) {
        // TODO : IPv6
        orc_assert(false);
        return;
    }

    if (len <= sizeof(IPv4Header)) {
        return;
    }

    const IPv4Header *iphdr = (const IPv4Header *)buf;

    auto ipv4hlen = IPv4Header::length(iphdr->version_len);
    auto ip_payload_len = len - ipv4hlen;

    uint16_t src_port = 0;
    uint16_t dst_port = 0;

    switch (iphdr->protocol) {
    case IPCommon::TCP: {
        if (ip_payload_len < sizeof(TCPHeader)) {
            return;
        }
        TCPHeader* tcphdr = (TCPHeader*)(buf + ipv4hlen);
        int tcphlen = TCPHeader::length(tcphdr->doff_res);
        if (tcphlen < sizeof(TCPHeader) || tcphlen > ip_payload_len) {
            return;
        }
        auto tcp_payload_len = ip_payload_len - tcphlen;
        Log() << "TCP(" << tcp_payload_len << ") dest:" << ntohs(tcphdr->dest) << std::endl;
        src_port = ntohs(tcphdr->source);
        dst_port = ntohs(tcphdr->dest);
        break;
    }
    case IPCommon::UDP: {
        if (ip_payload_len < sizeof(UDPHeader)) {
            return;
        }
        UDPHeader* udphdr = (UDPHeader*)(buf + ipv4hlen);
        auto udp_payload_len = ip_payload_len - sizeof(UDPHeader);
        Log() << "UDP(" << udp_payload_len << ") dest:" << ntohs(udphdr->dest) << std::endl;
        src_port = ntohs(udphdr->source);
        dst_port = ntohs(udphdr->dest);
        break;
    }
    }

    auto flow = Five(iphdr->protocol, {address_v4(ntohl(iphdr->saddr)), src_port}, {address_v4(ntohl(iphdr->daddr)), dst_port});
    logger.AddFlow(flow);

    wireshark_analyze(buf, len, [&](auto hostname) {
        Log() << "hostname: " << hostname << std::endl;
        logger.GotHostname(flow, hostname);
    }, [&](auto protocol, auto protocol_chain) {
        Log() << "protocol: " << protocol << " (" << protocol_chain.size() << " " << protocol_chain << ")" << std::endl;
        logger.GotProtocol(flow, protocol, protocol_chain);
    });
    
    uint8_t packet1[] = \
        "\x45\x00\x00\x7E\x00\x00\x40\x00\x40\x06\xC5\xB9\xC0\xA8\x01\x11"
        "\xAC\xD9\x06\x2E\xF9\x6E\x00\x50\xF5\x06\xBC\x17\x7A\xAD\x87\x1C"
        "\x80\x18\x08\x04\x7F\x8F\x00\x00\x01\x01\x08\x0A\x13\x3C\x93\x5B"
        "\x40\x87\xF0\x3C\x47\x45\x54\x20\x2F\x20\x48\x54\x54\x50\x2F\x31"
        "\x2E\x31\x0D\x0A\x48\x6F\x73\x74\x3A\x20\x67\x6F\x6F\x67\x6C\x65"
        "\x2E\x63\x6F\x6D\x0D\x0A\x55\x73\x65\x72\x2D\x41\x67\x65\x6E\x74"
        "\x3A\x20\x63\x75\x72\x6C\x2F\x37\x2E\x35\x34\x2E\x30\x0D\x0A\x41"
        "\x63\x63\x65\x70\x74\x3A\x20\x2A\x2F\x2A\x0D\x0A\x0D\x0A";

    wireshark_analyze(packet1, sizeof(packet1), [&](auto hostname) {
        Log() << "hostname: " << hostname << std::endl;
        logger.GotHostname(flow, hostname);
    }, [&](auto protocol, auto protocol_chain) {
        Log() << "protocol: " << protocol << " (" << protocol_chain << ")" << std::endl;
        logger.GotProtocol(flow, protocol, protocol_chain);
    });

    uint8_t packet2[] = \
        "\x60\x0E\xA8\xD4\x05\x3A\x11\x40\x26\x01\x06\x46\x02\x00\xE1\xC6"
        "\x0D\xBF\x0E\xAB\x1D\xF8\x87\xDF\x26\x07\xF8\xB0\x40\x05\x08\x02"
        "\x00\x00\x00\x00\x00\x00\x20\x04\xCB\x49\x01\xBB\x05\x3A\x55\x16"
        "\x0D\x0B\xDC\x9C\x11\x06\xE7\xD2\x8A\x51\x30\x34\x33\x01\x05\x7E"
        "\xD7\x62\xE3\xE4\xB1\x34\x8D\x49\xF7\xDC\xA0\x01\x04\x00\x43\x48"
        "\x4C\x4F\x11\x00\x00\x00\x50\x41\x44\x00\xDC\x02\x00\x00\x53\x4E"
        "\x49\x00\xEA\x02\x00\x00\x56\x45\x52\x00\xEE\x02\x00\x00\x43\x43"
        "\x53\x00\xFE\x02\x00\x00\x55\x41\x49\x44\x28\x03\x00\x00\x54\x43"
        "\x49\x44\x2C\x03\x00\x00\x50\x44\x4D\x44\x30\x03\x00\x00\x53\x4D"
        "\x48\x4C\x34\x03\x00\x00\x49\x43\x53\x4C\x38\x03\x00\x00\x4E\x4F"
        "\x4E\x50\x58\x03\x00\x00\x4D\x49\x44\x53\x5C\x03\x00\x00\x53\x43"
        "\x4C\x53\x60\x03\x00\x00\x43\x53\x43\x54\x60\x03\x00\x00\x43\x4F"
        "\x50\x54\x64\x03\x00\x00\x49\x52\x54\x54\x68\x03\x00\x00\x43\x46"
        "\x43\x57\x6C\x03\x00\x00\x53\x46\x43\x57\x70\x03\x00\x00\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D"
        "\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x2D\x77\x77\x77\x2E\x67\x6F"
        "\x6F\x67\x6C\x65\x2E\x63\x6F\x6D\x51\x30\x34\x33\x01\xE8\x81\x60"
        "\x92\x92\x1A\xE8\x7E\xED\x80\x86\xA2\x15\x82\x91\x43\x68\x72\x6F"
        "\x6D\x65\x2F\x37\x33\x2E\x30\x2E\x33\x36\x38\x33\x2E\x38\x36\x20"
        "\x49\x6E\x74\x65\x6C\x20\x4D\x61\x63\x20\x4F\x53\x20\x58\x20\x31"
        "\x30\x5F\x31\x34\x5F\x36\x00\x00\x00\x00\x58\x35\x30\x39\x01\x00"
        "\x00\x00\x1E\x00\x00\x00\xC0\x13\x32\x45\x36\x10\x08\x59\x4F\xBE"
        "\xE0\x03\xA1\xAC\x82\xFC\x48\xD7\x87\x87\xF8\x31\x95\xC3\x71\x21"
        "\x52\x9D\x83\xF3\xB9\x95\x64\x00\x00\x00\x01\x00\x00\x00\x4E\x53"
        "\x54\x50\xB7\x63\x00\x00\x00\x00\xF0\x00\x00\x00\x60\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
        "\x00\x00";

    wireshark_analyze(packet2, sizeof(packet2), [&](auto hostname) {
        Log() << "hostname: " << hostname << std::endl;
        logger.GotHostname(flow, hostname);
    }, [&](auto protocol, auto protocol_chain) {
        Log() << "protocol: " << protocol << " (" << protocol_chain << ")" << std::endl;
        logger.GotProtocol(flow, protocol, protocol_chain);
    });

    uint8_t packet3[] = \
        "\x45\x00\x01\x11\x00\x00\x40\x00\x40\x06\xCB\x26\xC0\xA8\x01\x11"
        "\xAC\xD9\x00\x2E\xC4\x29\x01\xBB\x1C\xE4\x8E\x79\x1D\xD5\xAF\x62"
        "\x80\x18\x08\x04\xC8\xE7\x00\x00\x01\x01\x08\x0A\x0C\xBA\x90\x2E"
        "\x25\x2E\x1C\x14\x16\x03\x01\x00\xD8\x01\x00\x00\xD4\x03\x03\x93"
        "\x2E\xAA\xFA\x54\x35\x8D\x1F\x96\xAA\xAA\x4D\xB0\x1A\x32\x48\xC5"
        "\x43\x70\x57\xA2\x80\xFF\xFB\x5B\xE8\x3A\xEF\x5E\x8C\x73\x7D\x00"
        "\x00\x54\xC0\x30\xC0\x2C\xC0\x28\xC0\x24\xC0\x14\xC0\x0A\x00\x9F"
        "\x00\x6B\x00\x39\xCC\xA9\xCC\xA8\xCC\xAA\xFF\x85\x00\xC4\x00\x88"
        "\x00\x81\x00\x9D\x00\x3D\x00\x35\x00\xC0\x00\x84\xC0\x2F\xC0\x2B"
        "\xC0\x27\xC0\x23\xC0\x13\xC0\x09\x00\x9E\x00\x67\x00\x33\x00\xBE"
        "\x00\x45\x00\x9C\x00\x3C\x00\x2F\x00\xBA\x00\x41\xC0\x12\xC0\x08"
        "\x00\x16\x00\x0A\x00\xFF\x01\x00\x00\x57\x00\x00\x00\x0F\x00\x0D"
        "\x00\x00\x0A\x67\x6F\x6F\x67\x6C\x65\x2E\x63\x6F\x6D\x00\x0B\x00"
        "\x02\x01\x00\x00\x0A\x00\x08\x00\x06\x00\x1D\x00\x17\x00\x18\x00"
        "\x0D\x00\x1C\x00\x1A\x06\x01\x06\x03\xEF\xEF\x05\x01\x05\x03\x04"
        "\x01\x04\x03\xEE\xEE\xED\xED\x03\x01\x03\x03\x02\x01\x02\x03\x00"
        "\x10\x00\x0E\x00\x0C\x02\x68\x32\x08\x68\x74\x74\x70\x2F\x31\x2E"
        "\x31";

    wireshark_analyze(packet3, sizeof(packet3), [&](auto hostname) {
        Log() << "hostname: " << hostname << std::endl;
        logger.GotHostname(flow, hostname);
    }, [&](auto protocol, auto protocol_chain) {
        Log() << "protocol: " << protocol << " (" << protocol_chain << ")" << std::endl;
        logger.GotProtocol(flow, protocol, protocol_chain);
    });
    Log() << "whut" << std::endl;
    logger.GotProtocol(flow, "fake", "no");
    logger.GotProtocol(flow, "good", "yes:yes:yes:yes:yes:yes");
        Log() << "whyyyy" << std::endl;
}

}