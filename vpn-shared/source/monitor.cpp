/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


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

void wireshark_epan_new()
{
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

    epan_dissect_init(&edt, cf.epan, TRUE, FALSE);
}

void wireshark_epan_free()
{
    epan_dissect_cleanup(&edt);
    epan_free(cf.epan);
}

void wireshark_setup()
{
    setenv("WIRESHARK_DEBUG_WMEM_OVERRIDE", "simple", 1);

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

    wtap_rec_init(&rec);

    wireshark_epan_new();
}

void wireshark_cleanup()
{
    wireshark_epan_free();
    wtap_rec_cleanup(&rec);
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
    if (cf.count > 100) {
        wireshark_epan_free();
        wireshark_epan_new();
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

void monitor(Span<const uint8_t> span, MonitorLogger &logger)
{
    if (IPCommon::version(span.cast<const uint8_t>()) != uint8_t(IPCommon::IPv4)) {
        // TODO : IPv6
        //orc_assert(false);
        return;
    }

    auto iphdr = &span.cast<const IPv4Header>();
    auto ipv4hlen = IPv4Header::length(iphdr->version_len);

    uint16_t src_port = 0;
    uint16_t dst_port = 0;

    switch (iphdr->protocol) {
    case IPCommon::TCP: {
        auto tcphdr = &span.cast<const TCPHeader>(ipv4hlen);
        auto tcpbuf = span + (ipv4hlen + TCPHeader::length(tcphdr->doff_res));
        if (Verbose)
            Log() << "TCP(" << tcpbuf.size() << ") dest:" << ntohs(tcphdr->dest) << std::endl;
        src_port = ntohs(tcphdr->source);
        dst_port = ntohs(tcphdr->dest);
        break;
    }
    case IPCommon::UDP: {
        auto udphdr = &span.cast<const UDPHeader>(ipv4hlen);
        auto udpbuf = span + (ipv4hlen + sizeof(UDPHeader));
        if (Verbose)
            Log() << "UDP(" << udpbuf.size() << ") dest:" << ntohs(udphdr->dest) << std::endl;
        src_port = ntohs(udphdr->source);
        dst_port = ntohs(udphdr->dest);
        break;
    }
    }

    auto flow = Five(iphdr->protocol, {address_v4(ntohl(iphdr->saddr)), src_port}, {address_v4(ntohl(iphdr->daddr)), dst_port});
    logger.AddFlow(flow);

    wireshark_analyze(span.data(), span.size(), [&](auto hostname) {
        if (Verbose)
            Log() << "hostname: " << hostname << std::endl;
        logger.GotHostname(flow, hostname);
    }, [&](auto protocol, auto protocol_chain) {
        if (Verbose)
            Log() << "protocol: " << protocol << " (" << protocol_chain << ")" << std::endl;
        logger.GotProtocol(flow, protocol, protocol_chain);
    });
}

}