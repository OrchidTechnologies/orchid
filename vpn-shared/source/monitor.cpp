
#include <openvpn/ip/ipcommon.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/ip6.hpp>
#include <openvpn/ip/tcp.hpp>
#include <openvpn/ip/udp.hpp>

#include "buffer.hpp"
#include "monitor.hpp"
#include "socket.hpp"

using namespace openvpn;
using namespace asio::ip;


namespace orc {

typedef std::function<void (std::string)> sni_callback;

#define MAX_DNSMSG_SIZE 	512			/**< Maximum size of DNS message */
#define MAX_DOMAINNAME_LEN	50			/**< Maximum size of domain name */
#define MAX_QNAME_LEN		128			/**< Maximum size of qname */

struct DNSHeader {
    unsigned short id; // identification number
    unsigned char rd :1; // recursion desired
    unsigned char tc :1; // truncated message
    unsigned char aa :1; // authoritive answer
    unsigned char opcode :4; // purpose of message
    unsigned char qr :1; // query/response flag
    unsigned char rcode :4; // response code
    unsigned char cd :1; // checking disabled
    unsigned char ad :1; // authenticated data
    unsigned char z :1; // its z! reserved
    unsigned char ra :1; // recursion available
    unsigned short q_count; // number of question entries
    unsigned short ans_count; // number of answer entries
    unsigned short auth_count; // number of authority entries
    unsigned short add_count; // number of resource entries
};


int parse_name(const uint8_t* dns_buf, char* cp, char* qname, u_int qname_maxlen)
{
    u_int slen;
    int clen = 0;
    int indirect = 0;
    int nseg = 0;

    for (;;) {
        slen = *cp++;
        if (!indirect) clen++;
        
        if ((slen & 0xc0) == 0xc0) {
            cp = (char *)&dns_buf[((slen & 0x3f)<<8) + *cp];
            if (!indirect) clen++;
            indirect = 1;
            slen = *cp++;
        }

        if (slen == 0)
            break;

        if (!indirect) clen += slen;

        if ((qname_maxlen -= slen+1) < 0) {
            return 0;
        }
        while (slen-- != 0) *qname++ = (char)*cp++;
        *qname++ = '.';

        nseg++;
    }

    if (nseg == 0) *qname++ = '.';
    else --qname;

    *qname = '\0';
    return clen;
}

const u_char * dns_parse_question(const uint8_t* dns_buf, const u_char * cp)
{
    char name[MAX_QNAME_LEN];

    int len = parse_name(dns_buf, (char*)cp, name, sizeof(name));
    if (!len) {
        return 0;
    }

    cp += len;
    cp += 2;
    cp += 2;
    Log() << "DNS (Q)NAME field value: " << name << std::endl;
    return cp;
}

void get_DNS_questions(const uint8_t *data, int end)
{
    if (sizeof(DNSHeader) > end) {
        return;
    }
    DNSHeader *dnshdr = (DNSHeader*)data;
    if (dnshdr->qr) {
        return;
    }
    const uint8_t *cur_ptr = data + sizeof(DNSHeader);
    for (size_t i = 0; i < ntohs(dnshdr->q_count); i++) {
        // Question section
        cur_ptr = dns_parse_question(data, cur_ptr);
        if (!cur_ptr) {
            return;
        }
    }
}

void get_quic_SNI(const uint8_t *data, size_t len, const sni_callback callback)
{
    // CID
    if (len < 1) {
        return;
    }
    int offset = 1;
    if (data[0] & 0x08) {
        offset += 8;
    }

    if (len < offset + 5) {
        return;
    }

    // Get version
    int version = -1;
    if (data[0] & 0x01 && data[offset] == 'Q') {
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
    if ((data[0] & 0x30) == 0) {
        offset++;
    } else {
        offset += ((data[0] & 0x30) >> 4) * 2;
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
            std::string sni(snidata, snilen);
            Log() << "QUIC SNI(" << snilen << "): \"" << sni << "\"" << std::endl;
            callback(sni);
        }
        start = endOffset;
        tagLen--;
    }
}

void get_TLS_SNI(const uint8_t *data, int end, const sni_callback callback)
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

    // skip protocol version (you should already have verified this)
    pos += 2;

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

                std::string sni((char*)&data[n], nameLength);
                Log() << "TLS SNI(" << nameLength << "): \"" << sni << "\"" << std::endl;
                callback(sni);
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
        if (tcphlen <= sizeof(TCPHeader) || tcphlen > ip_payload_len) {
            return;
        }
        auto tcp_payload_len = ip_payload_len - tcphlen;
        Log() << "TCP(" << tcp_payload_len << ") dest:" << ntohs(tcphdr->dest) << std::endl;
        auto flow = Five(IPCommon::TCP, {address_v4(ntohl(iphdr->daddr)), ntohs(tcphdr->dest)}, {address_v4(ntohl(iphdr->saddr)), ntohs(tcphdr->source)});
        logger.AddFlow(flow);
        auto tcpbuf = ((const uint8_t *)tcphdr) + tcphlen;
        get_TLS_SNI(tcpbuf, tcp_payload_len, [&](auto sni) {
            logger.GotHostname(flow, sni);
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
        auto flow = Five(IPCommon::UDP, {address_v4(ntohl(iphdr->daddr)), ntohs(udphdr->dest)}, {address_v4(ntohl(iphdr->saddr)), ntohs(udphdr->source)});
        logger.AddFlow(flow);
        if (ntohs(udphdr->dest) == 53) {
            get_DNS_questions(udpbuf, udp_payload_len);
        }
        get_quic_SNI(udpbuf, udp_payload_len, [&](auto sni) {
            logger.GotHostname(flow, sni);
        });
        break;
    }
    }
}

}