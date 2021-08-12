/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#include <deque>
#include <vector>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

#include <boost/process/async_pipe.hpp>

#include <lib.hpp>

#include "file.hpp"
#include "fit.hpp"
#include "load.hpp"
#include "log.hpp"
#include "sequence.hpp"
#include "sfu.hpp"
#include "site.hpp"

namespace orc {

const char Tables_[] = {
#include "mediasoup.hpp"
, 0x00};

const uint8_t Payloads_[] = {
    100, 101, 102, 103, 104, 105, 106, 107,
    108, 109, 110, 111, 112, 113, 114, 115,
    116, 117, 118, 119, 120, 121, 122, 123,
    124, 125, 126, 127,  96,  97,  98,  99,
};

template <typename Type_>
bool In(const Type_ &data, const std::initializer_list<const char *> &values) {
    for (const auto &value : values)
        if (data == value)
            return true;
    return false;
}

template <typename Type_>
Type_ Next(std::deque<Type_> &values) {
    const auto value(values.front());
    values.pop_front();
    return value;
}


enum class Kind {
    Audio, Video
};

inline std::string Str(Kind kind) { switch (kind) {
    case Kind::Audio: return "audio";
    case Kind::Video: return "video";
    default: orc_assert(false);
} }

inline Kind ToKind(const std::string &kind) {
    if (false);
    else if (kind == "audio")
        return Kind::Audio;
    else if (kind == "video")
        return Kind::Video;
    else orc_assert(false);
}


// XXX: this is a stupid way of doing this
static uint32_t Ssrc_(13371337);

struct Codec {
    Kind kind_;
    std::string type_;
    uint64_t rate_;
    uint64_t channels_;
    std::map<std::string, unsigned> parameters_;

    std::vector<std::pair<std::string, std::string>> feedbacks_;
    std::optional<uint8_t> payload_;

    bool rtx() const {
        return boost::algorithm::ends_with(type_, "/rtx");
    }


    Codec(Kind kind, std::string type, decltype(rate_) rate, decltype(channels_) channels, decltype(parameters_) parameters) :
        kind_(kind),
        type_(std::move(type)),
        rate_(rate),
        channels_(channels),
        parameters_(std::move(parameters))
    {
    }

    Codec(const boost::json::object &object, const std::optional<Kind> &kind) :
        kind_(kind ? *kind : ToKind(Str(object.at("kind")))),
        type_(Str(object.at("mimeType"))),
        rate_(Num<decltype(rate_)>(object.at("clockRate")))
    {
        if (const auto channels = object.if_contains("channels"))
            // XXX: this should be as_uint64()
            channels_ = channels->as_int64();
        else
            channels_ = 0;

        if (const auto parameters = object.if_contains("parameters"))
            for (const auto &parameter : parameters->as_object())
                parameters_.try_emplace(Str(parameter.key()), Num<unsigned>(parameter.value()));

        if (const auto feedbacks = object.if_contains("rtcpFeedback"))
            for (const auto &value : feedbacks->as_array()) {
                const auto &feedback(value.as_object());
                feedbacks_.emplace_back(Str(feedback.at("type")), [&]() -> std::string {
                    const auto parameter = feedback.find("parameter");
                    if (parameter == feedback.end())
                        return {};
                    return Str(parameter->value());
                }());
            }

        if (const auto payload = object.if_contains(
            kind ? "payloadType" : "preferredPayloadType"
        ))
            payload_ = Num<uint8_t>(*payload);
    }

    boost::json::object Json(bool preferred) const {
        boost::json::object object;

        if (preferred)
            object["kind"] = Str(kind_);

        object["mimeType"] = type_;
        object["clockRate"] = rate_;

        if (channels_ != 0)
            object["channels"] = channels_;

        if (!parameters_.empty()) {
            boost::json::object parameters;
            for (const auto &[name, value] : parameters_)
                parameters[name] = value;
            object["parameters"] = std::move(parameters);
        }

        if (!feedbacks_.empty()) {
            boost::json::array feedbacks;
            for (const auto &[type, parameter] : feedbacks_) {
                boost::json::object feedback({{"type", type}});
                if (!parameter.empty())
                    feedback["parameter"] = parameter;
                feedbacks.emplace_back(std::move(feedback));
            }
            object["rtcpFeedback"] = std::move(feedbacks);
        }

        if (payload_)
            object[preferred ? "preferredPayloadType" : "payloadType"] = *payload_;

        return object;
    }


    auto tuple() const {
        // XXX: figure out how to use std::reference_wrapper<std::string>
        std::map<std::string, unsigned> parameters;
        // XXX: this might should also take into account profile-level-id ?
        // XXX: h264 has some kind of library that provides an isSameProfile also :/
        for (const auto &[name, value] : parameters_)
            if (In(name, {"apt", "profile-id", "packetization-mode"}))
                parameters.try_emplace(name, value);
        return std::make_tuple(kind_, std::ref(type_), rate_, channels_, std::move(parameters));
    }

    bool operator <(const Codec &rhs) const {
        return tuple() < rhs.tuple();
    }


    void Merge(const Codec &codec, std::deque<uint8_t> &payloads) {
        for (const auto &[name, value] : codec.parameters_)
            parameters_.try_emplace(name, value);

        feedbacks_ = codec.feedbacks_;

        if (!payload_)
            payload_ = codec.payload_ ?
                *codec.payload_ : Next(payloads);
    }
};

struct Extension {
    Kind kind_;
    std::string direction_;

    std::string uri_;
    uint16_t id_;
    bool encrypt_;


    Extension(const boost::json::object &object, const std::optional<Kind> &kind) {
        if (kind)
            kind_ = *kind;
        else {
            kind_ = ToKind(Str(object.at("kind")));
            direction_ = Str(object.at("direction"));
        }

        uri_ = Str(object.at("uri"));
        id_ = Num<uint16_t>(object.at(kind ? "id" : "preferredId"));
        encrypt_ = object.at(kind ? "encrypt" : "preferredEncrypt").as_bool();
    }

    boost::json::object Json(bool preferred) const {
        boost::json::object object;

        if (preferred) {
            object["kind"] = Str(kind_);
            object["direction"] = direction_;
        }

        object["uri"] = uri_;
        object[preferred ? "preferredId" : "id"] = id_;
        object[preferred ? "preferredEncrypt" : "encrypt"] = encrypt_;

        return object;
    }


    auto tuple() const {
        return std::tie(kind_, id_, uri_);
    }

    bool operator <(const Extension &extension) const {
        return tuple() < extension.tuple();
    }
};

struct Capabilities {
    std::multiset<Extension> extensions_;
    std::set<Codec> codecs_;

    Capabilities(const boost::json::object &object, const std::optional<Kind> &kind) {
        for (const auto &codec : object.at("codecs").as_array())
            codecs_.emplace(Codec(codec.as_object(), kind));
        for (const auto &extension : object.at("headerExtensions").as_array())
            extensions_.emplace(Extension(extension.as_object(), kind));
    }

    Capabilities(std::multiset<Extension> extensions) :
        extensions_(std::move(extensions))
    {
    }

    Capabilities(const Capabilities &supported, std::vector<Codec> limited) :
        Capabilities(supported.extensions_)
    {
        std::deque payloads(Payloads_, Payloads_ + sizeof(Payloads_) / sizeof(Payloads_[0]));

        for (auto &codec : limited) {
            auto before(supported.codecs_.find(codec));
            orc_assert(before != supported.codecs_.end());
            codec.Merge(*before, payloads);
            const auto after(codecs_.emplace(std::move(codec)).first);

            if (after->kind_ == Kind::Video)
                codecs_.emplace(Codec({
                    {"kind", "video"},
                    {"mimeType", "video/rtx"},
                    {"clockRate", after->rate_},
                    {"parameters", {{"apt", after->payload_.value()}}},
                    {"preferredPayloadType", Next(payloads)},
                }, {}));
        }
    }

    Capabilities(Kind kind, const Capabilities &provided, const Capabilities &supported, std::map<uint8_t, uint8_t> &payloads) {
        for (const auto &extension : supported.extensions_)
            if (extension.kind_ == kind && In(extension.direction_, {"sendrecv", "sendonly"}))
                extensions_.emplace(extension);

        const auto remap([&](const Codec &before) {
            const auto after(supported.codecs_.find(before));
            orc_assert(after != supported.codecs_.end());
            const auto payload(after->payload_.value());
            payloads.try_emplace(before.payload_.value(), payload);
            return after;
        });

        for (const auto &codec : provided.codecs_)
            if (!codec.rtx()) {
                Codec after(*remap(codec));
                after.parameters_ = codec.parameters_;
                const auto rtx(supported.codecs_.find({codec.kind_, Str(codec.kind_) + "/rtx", codec.rate_, codec.channels_, {{"apt", after.payload_.value()}}}));
                codecs_.emplace(std::move(after));
                if (rtx != supported.codecs_.end())
                    codecs_.emplace(*rtx);
            }

        for (const auto &codec : provided.codecs_)
            if (codec.rtx()) {
                auto copy(codec);
                auto &apt(copy.parameters_.at("apt"));
                // XXX: is apt really uint8_t?
                apt = payloads.at(Fit(apt));
                remap(copy);
            }
    }

    Capabilities(const Capabilities &provided, const Capabilities &supported) {
        for (const auto &extension : provided.extensions_)
            if (supported.extensions_.find(extension) != supported.extensions_.end())
                extensions_.emplace(extension);

        for (const auto &codec : provided.codecs_) {
            const auto before(supported.codecs_.find(codec));
            if (before == supported.codecs_.end())
                continue;
            // XXX: filter extraneous rtx codecs
            Codec after(*before);
            after.feedbacks_ = before->feedbacks_;
            // XXX: "reduce codecs' RTCP feedback"
            codecs_.emplace(std::move(after));
        }
    }

    boost::json::object Json(bool preferred) const {
        boost::json::array codecs;
        for (const auto &codec : codecs_)
            codecs.emplace_back(codec.Json(preferred));

        boost::json::array extensions;
        for (const auto &extension : extensions_)
            extensions.emplace_back(extension.Json(preferred));

        return {
            {"codecs", std::move(codecs)},
            {"headerExtensions", std::move(extensions)},
        };
    }
};

struct Parameters :
    public Capabilities
{
    boost::json::array encodings_;
    boost::json::object rtcp_;

    Parameters(const boost::json::object &object, const std::optional<Kind> &kind, std::string &cname) :
        Capabilities(object, kind)
    {
        encodings_ = object.at("encodings").as_array();

        rtcp_ = object.at("rtcp").as_object();
        if (cname.empty())
            if (const auto &value = rtcp_.if_contains("cname"))
                cname = Str(*value);
        if (cname.empty())
            cname = Unique::New().str().substr(0, 8);
        rtcp_["cname"] = cname;
    }

    Parameters(Kind kind, const Parameters &provided, const Capabilities &supported, std::map<uint8_t, uint8_t> &payloads) :
        Capabilities(kind, provided, supported, payloads),
        rtcp_({
            {"cname", provided.rtcp_.at("cname")},
            {"reducedSize", true},
            {"mux", true},
        })
    {
    }

    Parameters(const Parameters &consumable, const Capabilities &supported) :
        Capabilities(consumable, supported),
        rtcp_(consumable.rtcp_)
    {
        std::string scalability;
        unsigned bitrate(0);

        for (const auto &encoding : consumable.encodings_) {
            const auto &object(encoding.as_object());
            if (scalability.empty())
                if (const auto value = object.if_contains("scalabilityMode"))
                    scalability = Str(*value);
            if (const auto value = object.if_contains("maxBitrate"))
                bitrate = std::max(bitrate, Num<decltype(bitrate)>(*value));
        }

        const auto encodings(consumable.encodings_.size());
        if (encodings != 1) {
            const auto matches("^[LS]([1-9]\\d{0,1})T([1-9]\\d{0,1})(_KEY)?"_ctre.match(scalability));
            std::ostringstream value;
            value << 'S' << encodings << 'T' << matches.get<2>();
            scalability = value.str();
        }

        bool rtx(false);
        for (const auto &codec : codecs_)
            if (!rtx && codec.rtx())
                rtx = true;

        boost::json::object encoding;
        encoding["ssrc"] = ++Ssrc_;
        if (rtx)
            encoding["rtx"] = {{"ssrc", ++Ssrc_}};
        if (bitrate != 0)
            encoding["maxBitrate"] = bitrate;
        if (!scalability.empty())
            encoding["scalabilityMode"] = scalability;

        encodings_.emplace_back(std::move(encoding));
    }

    boost::json::object Json(std::optional<std::string> mid) const {
        auto object(Capabilities::Json(false));
        object["encodings"] = encodings_;
        object["rtcp"] = rtcp_;
        if (mid)
            object["mid"] = *mid;
        return object;
    }
};

struct Transportation {
    std::string cname_;
};

struct Production {
    Kind kind_;
    std::map<uint8_t, uint8_t> payloads_;
    Parameters consumable_;
    std::vector<uint32_t> ssrcs_;
    std::string type_;

    Production(Kind kind, const Parameters &provided, const Capabilities &supported) :
        kind_(kind),
        consumable_(kind_, provided, supported, payloads_)
    {
        for (const auto &value : provided.encodings_) {
            boost::json::object encoding(value.as_object());

            encoding.erase("rid");
            encoding.erase("rtx");
            encoding.erase("codecPayloadType");

            const auto ssrc(++Ssrc_);
            ssrcs_.emplace_back(ssrc);
            encoding["ssrc"] = ssrc;

            consumable_.encodings_.emplace_back(std::move(encoding));
        }
    }
};


// XXX: maybe rename to Duplex
class Bypass :
    public Link<Buffer>,
    public Sunken<Pump<Buffer>>
{
  public:
    const U<Stream> stream_;

  public:
    Bypass(BufferDrain &drain, U<Stream> stream) :
        Link<Buffer>(typeid(*this).name(), drain),
        stream_(std::move(stream))
    {
    }

    task<void> Shut() noexcept override {
        stream_->Shut();
        co_await Sunken::Shut();
        co_await Link::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await stream_->Send(data);
    }
};

class Netstring :
    public Link<Buffer>,
    public Sunken<Pump<Buffer>>
{
  private:
    std::string data_;

  protected:
    // XXX: this is horrible; I just wanted it to work
    void Land(const Buffer &data) override {
        data_ += data.str();
        for (;;) {
            const auto colon(data_.find(':'));
            if (colon == std::string::npos)
                return;
            const auto size(To<size_t>(data_.substr(0, colon)));
            const auto comma(colon + size + 1);
            if (data_.size() <= comma)
                return;
            orc_assert(data_[comma] == ',');
            Link::Land(Subset(data_).subset(colon + 1, size));
            data_ = data_.substr(comma + 1);
        }
    }

  public:
    Netstring(BufferDrain &drain) :
        Link<Buffer>(typeid(*this).name(), drain)
    {
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Link::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner().Send(Tie(std::to_string(data.size()), ':', data, ','));
    }
};

void Worker::Land(Pipe<Buffer> *pipe, const Buffer &data) {
    auto result(ParseB(data.str()).as_object());
    const auto id(result.find("id"));
    if (id != result.end()) {
        const auto locked(locked_());
        const auto transfer(locked->transfers_.find(id->value().as_int64()));
        orc_assert(transfer != locked->transfers_.end());
        transfer->second = std::move(result);
    } else {
        std::cerr << result << std::endl;
    }
}

void Worker::Stop() noexcept {
    orc_insist(false);
}

S<Worker> Worker::New() {
    const auto worker(Break<Worker>());

    std::vector<int> handles;

    const auto handle([&](bool ro) {
        auto file(std::make_unique<File<boost::process::async_pipe>>(Context()));
        auto handle(ro ? std::move(**file).source() : std::move(**file).sink());
#ifdef _WIN32
        // XXX: there is no .release() on boost::asio::windows::basic_stream_handle
        HANDLE copy;
        orc_assert(DuplicateHandle(GetCurrentProcess(), handle.native_handle(), GetCurrentProcess(), &copy, 0, FALSE, DUPLICATE_SAME_ACCESS) != 0);
        handles.emplace_back(_open_osfhandle(reinterpret_cast<intptr_t>(copy), ro ? _O_RDONLY : 0));
#else
        handles.emplace_back(handle.release());
#endif
        return file;
    });

    for (unsigned lane(0); lane != 2; ++lane) {
        auto &bonding(worker->Bond());
        auto &netstring(bonding.Wire<BufferSink<Netstring>>());
        auto &bypass(netstring.Wire<BufferSink<Bypass>>(handle(true)));
        auto &inverted(bypass.Wire<Inverted>(handle(false)));
        inverted.Open();
    }

    worker->Open(handles[0], handles[1], handles[2], handles[3]);
    return worker;
}

void Worker::Open(int rcfd, int wcfd, int rpfd, int wpfd) {
    thread_ = std::thread([=]() {
        std::vector<const char *> args{};
        args.emplace_back("");
        args.emplace_back("--rtcMinPort=32768");
        args.emplace_back("--rtcMaxPort=65535");
        // NOLINTNEXTLINE (cppcoreguidelines-pro-type-const-cast)
        orc_assert(run_worker(args.size(), const_cast<char **>(args.data()), "0.9", rcfd, wcfd, rpfd, wpfd) == 0);
    });
}

task<void> Worker::Shut() noexcept {
    thread_.join();
    co_await Bonded::Shut();
}

task<boost::json::object> Worker::Call(const std::string &method, boost::json::object internal, boost::json::object data) {
    boost::json::object request({
        {"method", method},
        {"internal", std::move(internal)},
        {"data", std::move(data)},
    });

    const auto transfer([&]() {
        const auto locked(locked_());
        const auto id(++locked->id_);
        request["id"] = id;
        const auto transfer(locked->transfers_.try_emplace(id));
        orc_assert(transfer.second);
        return transfer.first;
    }());

    co_await send_->Send(Subset(UnparseB(request)));
    const auto result(co_await *transfer->second);
    locked_()->transfers_.erase(transfer);

    const auto accepted(result.find("accepted"));
    orc_assert(accepted != result.end());
    orc_assert(accepted->value().as_bool());

    const auto response(result.find("data"));
    if (response == result.end())
        co_return boost::json::object({});
    co_return response->value().as_object();
}

task<void> Worker::CreateRouter(const Unique &router) {
    co_await Call("worker.createRouter", {{"routerId", router.str()}});
}

template <typename Type_, typename Code_>
boost::json::array MapJ(Type_ &&values, Code_ code) {
    boost::json::array reduced;
    for (auto &&value : values)
        reduced.emplace_back(code(value));
    return reduced;
}

int TestWorker(const asio::ip::address &bind, uint16_t port, const std::string &key, const std::string &certificates, const std::string &params) {
    Capabilities supported(Capabilities(ParseB(Tables_).as_object(), {}), {
        Codec(Kind::Audio, "audio/opus", 48000, 2, {}),
        Codec(Kind::Video, "video/VP8", 90000, 0, {{"x-google-start-bitrate", 1000}}),
    });

    const auto worker(Worker::New());
    const auto router(Unique::New());
    Wait(worker->CreateRouter(router));

    std::map<Unique, Transportation> transportations;
    std::map<Unique, Production> productions;
    uint32_t mid(10000000);

    Site site;

    #define cors {"Access-Control-Allow-Origin", "*"}

    site(http::verb::options, "/ms/(.*)"_ctre, [&](Matches1 matches, Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"access-control-allow-headers", "content-type"}, cors,
        }, {});
    });

    site(http::verb::get, "/ms/capabilities", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"}, cors,
        }, UnparseB(supported.Json(true)));
    });

    site(http::verb::get, "/ms/transport", [&](Request request) -> task<Response> {
        const auto transport(Unique::New());

        auto result(co_await worker->Call("router.createWebRtcTransport", {
            {"routerId", router.str()},
            {"transportId", transport.str()},
        }, {
            {"listenIps", {{
                {"ip", "10.0.0.146"},
                {"announcedIp", "13.56.96.53"},
            }}},
            {"enableUdp", true},
            {"enableTcp", false},
            {"preferUdp", false},
            {"preferTcp", false},
            {"initialAvailableOutgoingBitrate", 1000000},
            {"enableSctp", false},
            {"numSctpStreams", {{"OS", 1024}, {"MIS", 1024}}},
            {"maxSctpMessageSize", 262144},
            {"sctpSendBufferSize", 262144},
            {"isDataChannel", true},
        }));

        transportations.try_emplace(transport, Transportation{});

        // id, dtlsParameters, iceCandidates, iceParameters
        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"}, cors,
        }, UnparseB(result));
    });

    site(http::verb::post, "/ms/connect/(.*)"_ctre, [&](Matches1 matches, Request request) -> task<Response> {
        const Unique transport(matches.get<1>().str());

        co_await worker->Call("transport.connect", {
            {"routerId", router.str()},
            {"transportId", transport.str()},
        }, {{"dtlsParameters", ParseB(request.body())}});

        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"}, cors,
        }, UnparseB({}));
    });

    site(http::verb::post, "/ms/produce/(.*)"_ctre, [&](Matches1 matches, Request request) -> task<Response> {
        const Unique transport(matches.get<1>().str());
        const auto producer(Unique::New());

        const auto transportation(transportations.find(transport));
        orc_assert(transportation != transportations.end());

        const auto body(ParseB(request.body()).as_object());
        const auto kind(ToKind(Str(body.at("kind"))));
        const auto &parameters(body.at("rtpParameters").as_object());
        const auto mid(Str(parameters.at("mid")));
        const Parameters provided(parameters, kind, transportation->second.cname_);
        Production production(kind, provided, supported);


        boost::json::object data;

        data["kind"] = Str(kind);
        data["rtpParameters"] = provided.Json(mid);

        data["rtpMapping"] = {
            {"codecs", MapJ(production.payloads_, [&](const auto &_) { auto &&[before, after] = _;
                return boost::json::object({{"payloadType", before}, {"mappedPayloadType", after}});
            })},
            {"encodings", MapJ(Zip(provided.encodings_, production.ssrcs_), [&](const auto &_) { auto &&[value, ssrc] = _;
                const auto &object(value.as_object());
                boost::json::object encoding;
                encoding["mappedSsrc"] = ssrc;
		if (const auto value = object.if_contains("rid"))
                    encoding["rid"] = *value;
		if (const auto value = object.if_contains("ssrc"))
                    encoding["ssrc"] = *value;
		if (const auto value = object.if_contains("scalabilityMode"))
                    encoding["scalabilityMode"] = *value;
                return encoding;
            })},
        };

        data["paused"] = false;

        const auto result(co_await worker->Call("transport.produce", {
            {"routerId", router.str()},
            {"transportId", transport.str()},
            {"producerId", producer.str()},
        }, std::move(data)));

        production.type_ = Str(result.at("type"));
        productions.try_emplace(producer, std::move(production));

        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"}, cors,
        }, UnparseB({{"id", producer.str()}}));
    });

    site(http::verb::post, "/ms/consume/(.*)/(.*)"_ctre, [&](Matches2 matches, Request request) -> task<Response> {
        const Unique transport(matches.get<1>().str());
        const Unique producer(matches.get<2>().str());
        const auto consumer(Unique::New());

        const auto production(productions.find(producer));
        orc_assert(production != productions.end());

        Capabilities supported(ParseB(request.body()).as_object(), std::nullopt);
        Parameters consuming(production->second.consumable_, supported);
        auto dumped(consuming.Json(Str(++mid)));

        auto result(co_await worker->Call("transport.consume", {
            {"routerId", router.str()},
            {"transportId", transport.str()},
            {"producerId", producer.str()},
            {"consumerId", consumer.str()},
        }, {
            {"kind", Str(production->second.kind_)},
            {"rtpParameters", dumped},
            {"type", production->second.type_},
            {"consumableRtpEncodings", production->second.consumable_.encodings_},
            {"paused", true},
        }));

        //std::cerr << result << std::endl;

        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"}, cors,
        }, UnparseB({
            {"id", consumer.str()},
            {"kind", Str(production->second.kind_)},
            {"rtpParameters", std::move(dumped)},
        }));
    });

    site(http::verb::get, "/ms/resume/(.*)/(.*)/(.*)"_ctre, [&](Matches3 matches, Request request) -> task<Response> {
        const Unique transport(matches.get<1>().str());
        const Unique producer(matches.get<2>().str());
        const Unique consumer(matches.get<3>().str());

        auto result(co_await worker->Call("consumer.resume", {
            {"routerId", router.str()},
            {"transportId", transport.str()},
            {"producerId", producer.str()},
            {"consumerId", consumer.str()},
        }, {}));

        //std::cerr << result << std::endl;

        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"}, cors,
        }, UnparseB({}));
    });

    site(http::verb::get, "/test/(.*)"_ctre, [&](Matches1 matches, Request request) -> task<Response> {
        const auto file(matches.get<1>().str());
        const auto period(file.rfind('.'));
        orc_assert(period != std::string::npos);
        co_return Respond(request, http::status::ok, {
            {"content-type", [&]() {
                const auto ext(file.substr(period + 1));
                if (false);
                else if (ext == "css") return "text/css";
                else if (ext == "html") return "text/html";
                else if (ext == "js") return "text/javascript";
                else if (ext == "png") return "image/png";
                else orc_assert(false);
            }()},
        }, Load("test/" + file));
    });

    site(http::verb::post, "/", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::not_found, {
            {"content-type", "text/plain"},
        }, {});
    });

    site.Run(bind, port, key, certificates, params);
    Thread().join();
    return 0;
}

}
