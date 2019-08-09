#include <openvpn/ip/ipcommon.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/ip6.hpp>
#include <openvpn/ip/tcp.hpp>
#include <openvpn/ip/udp.hpp>

#include <openssl/ssl.h>

#include <boost/beast.hpp>

#include "buffer.hpp"
#include "monitor.hpp"
#include "socket.hpp"

using namespace openvpn;
using namespace asio::ip;
using namespace boost::beast;
using namespace boost::beast::http;


namespace orc {

typedef std::function<void (const std::string_view)> hostname_callback;
typedef std::function<void (const std::string_view)> protocol_callback;

void get_quic_SNI(const uint8_t *data, size_t len, const hostname_callback hostname_cb, const protocol_callback protocol_cb)
{
    if (len < 1) {
        return;
    }

    uint8_t flags = data[0];

    int offset = sizeof(uint8_t);

#define PUFLAGS_VRSN    0x01
#define PUFLAGS_RST     0x02
#define PUFLAGS_CID     0x08
#define PUFLAGS_PKN     0x30

    // CID
    if (flags & PUFLAGS_CID) {
        offset += 8;
    }

    if (len < offset + 5) {
        return;
    }

    // Get version
    int version = -1;
    if (flags & PUFLAGS_VRSN && data[offset] == 'Q') {
        version = (data[offset+1] - '0') * 100 +
                  (data[offset+2] - '0') * 10 +
                  (data[offset+3] - '0');
        offset += 4;
    }

    // Unsupported version
    if (version < 24) {
        return;
    }

    // Diversification only is from server to client, so we can ignore

    // Packet number size
    if ((flags & PUFLAGS_PKN) == 0) {
        offset++;
    } else {
        offset += ((flags & PUFLAGS_PKN) >> 4) * 2;
    }

    // Hash
    offset += 12;

    // Private Flags
    if (version < 34) {
        offset++;
    }

    if (offset > len) {
        return;
    }

    // several QUIC parsers I tried failed at the next section for QUIC v46:
    // https://github.com/aol/moloch/blob/master/capture/parsers/quic.c
    // https://github.com/0x4D31/quick/blob/master/chlo.go
    // and QUIC v46 does not appear to be documented:
    // https://groups.google.com/a/chromium.org/forum/#!topic/proto-quic/ic0K5ORnFOc
    // So, just search for CHLO and hope the subtag section is still parsable
    const uint8_t *b = (const uint8_t*)memmem(&data[offset], len - offset, "CHLO", strlen("CHLO"));
    if (!b) {
        return;
    }
    b += strlen("CHLO");

    const uint8_t *end = data + len;

    if ((end - b) < sizeof(uint16_t)) {
        return;
    }
    uint16_t tagLen = *(uint16_t*)b;
    b += sizeof(uint16_t);

    // Padding
    if ((end - b) < sizeof(uint16_t)) {
        return;
    }
    b += sizeof(uint16_t);

    if ((end - b) < tagLen * 8) {
        return;
    }

    const uint8_t *tagDataStart = b + tagLen * 8;
    uint32_t dlen = (end - b) - tagLen * 8;

    uint32_t start = 0;
    while (tagLen > 0) {
        const uint8_t *subTag = b;
        b += 4;

        uint32_t endOffset = *(uint32_t*)b;
        b += sizeof(uint32_t);

        if (endOffset > dlen || start > dlen || start >= endOffset) {
            return;
        }

        if (memcmp(subTag, "SNI\x00", 4) == 0) {
            const char *snidata = (const char*)(&tagDataStart[start]);
            size_t snilen = endOffset - start;
            std::string_view sni(snidata, snilen);
            Log() << "QUIC SNI(" << snilen << "): \"" << sni << "\"" << std::endl;
            hostname_cb(sni);

            std::ostringstream protocol;
            protocol << "quic v" << version;
            protocol_cb(protocol.str());
            return;
        }
        start = endOffset;
        tagLen--;
    }
}

std::string ssl_protocol_to_string(int version)
{
    switch(version) {
    case TLS1_3_VERSION: return "TLSv1.3";
    case TLS1_2_VERSION: return "TLSv1.2";
    case TLS1_1_VERSION: return "TLSv1.1";
    case TLS1_VERSION: return "TLSv1";
    case SSL3_VERSION: return "SSLv3";
    case DTLS1_BAD_VER: return "DTLSv0.9";
    case DTLS1_VERSION: return "DTLSv1";
    case DTLS1_2_VERSION: return "DTLSv1.2";
    default: return "unknown";
    }
}

void get_DTLS(const uint8_t *data, int end, const protocol_callback protocol_cb)
{
    if (end < 27) {
        return;
    }
    if (data[0] != 0x16) {
        return;
    }
    uint16_t handshake_version = ntohs(*(uint16_t*)&data[1]);
    if (handshake_version != DTLS1_VERSION && handshake_version != DTLS1_2_VERSION) {
        return;
    }
    if (data[13] != 0x01 && data[13] != 0x02) {
        return;
    }
    uint16_t client_hello_version = ntohs(*(uint16_t*)&data[25]);
    auto protocol = ssl_protocol_to_string(client_hello_version);
    Log() << "DTLS " << protocol << std::endl;
    protocol_cb(protocol);
}

void get_HTTP(const uint8_t *data, int end, const hostname_callback hostname_cb, const protocol_callback protocol_cb)
{
    request_parser<string_body> parser;
    error_code ec;
    parser.put(boost::asio::buffer(data, end), ec);
    if (ec) {
        return;
    }
    auto fields = parser.get();
    auto version = fields.version();
    std::ostringstream protocol;
    protocol << "HTTP/" << version / 10 << "." << version % 10;
    Log() << "HTTP " << protocol.str() << std::endl;
    protocol_cb(protocol.str());
    auto host_field = fields.find("Host");
    if (host_field != fields.end()) {
        // sigh https://github.com/boostorg/utility/pull/51
        auto boost_view = host_field->value();
        auto host = std::string_view(boost_view.begin(), boost_view.size());

        Log() << "HTTP Host " << host << std::endl;
        hostname_cb(host);
    }
}

void get_TLS_SNI(const uint8_t *data, int end, const hostname_callback hostname_cb, const protocol_callback protocol_cb)
{
    /*
    From https://tools.ietf.org/html/rfc5246:

    enum {
        hello_request(0), client_hello(1), server_hello(2),
        certificate(11), server_key_exchange (12),
        certificate_request(13), server_hello_done(14),
        certificate_verify(15), client_key_exchange(16),
        finished(20)
        (255)
    } HandshakeType;

    struct {
        HandshakeType msg_type;
        uint24 length;
        select (HandshakeType) {
            case hello_request:       HelloRequest;
            case client_hello:        ClientHello;
            case server_hello:        ServerHello;
            case certificate:         Certificate;
            case server_key_exchange: ServerKeyExchange;
            case certificate_request: CertificateRequest;
            case server_hello_done:   ServerHelloDone;
            case certificate_verify:  CertificateVerify;
            case client_key_exchange: ClientKeyExchange;
            case finished:            Finished;
        } body;
    } Handshake;

    struct {
        uint8 major;
        uint8 minor;
    } ProtocolVersion;

    struct {
        uint32 gmt_unix_time;
        opaque random_bytes[28];
    } Random;

    opaque SessionID<0..32>;

    uint8 CipherSuite[2];

    enum { null(0), (255) } CompressionMethod;

    struct {
        ProtocolVersion client_version;
        Random random;
        SessionID session_id;
        CipherSuite cipher_suites<2..2^16-2>;
        CompressionMethod compression_methods<1..2^8-1>;
        select (extensions_present) {
            case false:
                struct {};
            case true:
                Extension extensions<0..2^16-1>;
        };
    } ClientHello;
    */

    // skip the record header
    size_t pos = 5;

    // skip HandshakeType (you should already have verified this)
    pos += 1;

    // skip handshake length
    pos += 3;

    // protocol version
    if (pos > end - sizeof(uint16_t)) return;
    uint16_t version = ntohs(*(uint16_t*)&data[pos]);
    pos += sizeof(uint16_t);

    // skip Random
    pos += 32;

    // skip SessionID
    if (pos > end - sizeof(uint8_t)) return;
    uint8_t sessionIdLength = data[pos];
    pos += sizeof(uint8_t) + sessionIdLength;

    // skip CipherSuite
    if (pos > end - sizeof(uint16_t)) return;
    uint16_t cipherSuiteLength = ntohs(*(uint16_t*)&data[pos]);
    pos += sizeof(uint16_t) + cipherSuiteLength;

    // skip CompressionMethod
    if (pos > end - sizeof(uint8_t)) return;
    uint8_t compressionMethodLength = data[pos];
    pos += sizeof(uint8_t) + compressionMethodLength;

    // verify extensions exist
    if (pos > end - sizeof(uint16_t)) return;
    uint16_t extensionsLength = ntohs(*(uint16_t*)&data[pos]);
    pos += sizeof(uint16_t);

    // verify the extensions fit
    size_t extensionsEnd = pos + extensionsLength;
    if (extensionsEnd > end) return;
    end = extensionsEnd;

    /*
    From https://tools.ietf.org/html/rfc5246
     and http://tools.ietf.org/html/rfc6066:

    struct {
        ExtensionType extension_type;
        opaque extension_data<0..2^16-1>;
    } Extension;

    enum {
        signature_algorithms(13), (65535)
    } ExtensionType;

    enum {
        server_name(0), max_fragment_length(1),
        client_certificate_url(2), trusted_ca_keys(3),
        truncated_hmac(4), status_request(5), (65535)
    } ExtensionType;

    struct {
        NameType name_type;
        select (name_type) {
            case host_name: HostName;
        } name;
    } ServerName;

    enum {
        host_name(0), (255)
    } NameType;

    opaque HostName<1..2^16-1>;

    struct {
        ServerName server_name_list<1..2^16-1>
    } ServerNameList;
    */

    while (pos <= end - (sizeof(uint16_t) + sizeof(uint16_t))) {
        uint16_t extensionType = ntohs(*(uint16_t*)&data[pos]);
        pos += sizeof(uint16_t);
        uint16_t extensionSize = ntohs(*(uint16_t*)&data[pos]);
        pos += sizeof(uint16_t);
        if (extensionType != 0) { 
            // ExtensionType was something we are not interested in
            pos += extensionSize;
            continue;
        }

        // ExtensionType was server_name(0)

        // read ServerNameList length
        if (pos > end - sizeof(uint16_t)) return;
        uint16_t nameListLength = ntohs(*(uint16_t*)&data[pos]);
        pos += sizeof(uint16_t);

        // verify we have enough bytes and loop over SeverNameList
        size_t n = pos;
        pos += nameListLength;
        if (pos > end) return;
        while (n < pos - (sizeof(uint8_t) + sizeof(uint16_t))) {
            uint8_t nameType = data[n];
            n += sizeof(uint8_t);
            uint16_t nameLength = ntohs(*(uint16_t*)&data[n]);
            n += sizeof(uint16_t);

            // check if NameType is host_name(0)
            if (nameType == 0) {

                // verify we have enough bytes
                if (n > end - nameLength) return;

                std::string_view sni((char*)&data[n], nameLength);
                Log() << "TLS SNI(" << nameLength << "): \"" << sni << "\"" << std::endl;
                hostname_cb(sni);

                auto protocol = ssl_protocol_to_string(version);
                protocol_cb(protocol);
                return;
            }

            n += nameLength;
        }
    }
}


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
        auto flow = Five(IPCommon::TCP, {address_v4(ntohl(iphdr->saddr)), ntohs(tcphdr->source)}, {address_v4(ntohl(iphdr->daddr)), ntohs(tcphdr->dest)});
        logger.AddFlow(flow);
        auto tcpbuf = ((const uint8_t *)tcphdr) + tcphlen;
        get_HTTP(tcpbuf, tcp_payload_len, [&](auto sni) {
            logger.GotHostname(flow, sni);
        }, [&](auto protocol) {
            logger.GotProtocol(flow, protocol);
        });
        get_TLS_SNI(tcpbuf, tcp_payload_len, [&](auto sni) {
            logger.GotHostname(flow, sni);
        }, [&](auto protocol) {
            logger.GotProtocol(flow, protocol);
        });
        break;
    }
    case IPCommon::UDP: {
        if (ip_payload_len < sizeof(UDPHeader)) {
            return;
        }
        UDPHeader* udphdr = (UDPHeader*)(buf + ipv4hlen);
        auto udp_payload_len = ip_payload_len - sizeof(UDPHeader);
        Log() << "UDP(" << udp_payload_len << ") dest:" << ntohs(udphdr->dest) << std::endl;
        auto udpbuf = ((const uint8_t *)udphdr) + sizeof(UDPHeader);
        auto flow = Five(IPCommon::UDP, {address_v4(ntohl(iphdr->saddr)), ntohs(udphdr->source)}, {address_v4(ntohl(iphdr->daddr)), ntohs(udphdr->dest)});
        logger.AddFlow(flow);
        if (ntohs(udphdr->dest) == 53) {
            // TODO: verify the packet is DNS
            logger.GotProtocol(flow, "DNS");
        }
        get_DTLS(udpbuf, udp_payload_len, [&](auto protocol) {
            logger.GotProtocol(flow, protocol);
        });
        get_quic_SNI(udpbuf, udp_payload_len, [&](auto sni) {
            logger.GotHostname(flow, sni);
        }, [&](auto protocol) {
            logger.GotProtocol(flow, protocol);
        });
        break;
    }
    }
}

}