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


#include <sstream>

#include "baton.hpp"
#include "bearer.hpp"
#include "chain.hpp"
#include "load.hpp"
#include "local.hpp"
#include "sequence.hpp"
#include "sleep.hpp"
#include "task.hpp"
#include "ticket.hpp"
#include "translate.hpp"
#include "transport.hpp"

namespace orc {

task<Object> Scope(const S<Base> &base, const Object &secrets, const std::string &scope) {
    // XXX: I need a urlencoded form escape implementation
    co_return Parse((co_await base->Fetch("POST", {{"https", "oauth2.googleapis.com", "443"}, "/token"}, {
        {"content-type", "application/x-www-form-urlencoded"},
    }, "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=" +
        Bearer("https://oauth2.googleapis.com/token", secrets, {{"scope", scope}})
    )).ok()).as_object();
}

class Google {
  private:
    const S<Base> base_;
    const Object secrets_;
    mutable Object token_;

  public:
    Google(S<Base> base, Object secrets) :
        base_(std::move(base)),
        secrets_(std::move(secrets))
    {
    }

    task<Any> operator ()(const std::string &method, const std::string &path, const std::string &type, const std::string &body) const;

    task<Any> operator ()(const std::string &method, const std::string &path) const {
        co_return co_await operator ()(method, path, "application/json", {});
    }
};

task<Any> Google::operator ()(const std::string &method, const std::string &path, const std::string &type, const std::string &body) const {
    if (token_.empty()) // XXX: check expiration time and re-authorize if required
        token_ = co_await Scope(base_, secrets_, "https://www.googleapis.com/auth/androidpublisher");
    co_return Parse((co_await base_->Fetch(method, {{"https", "androidpublisher.googleapis.com", "443"}, path}, {
        {"content-type", type},
        {"authorization", {"Bearer " + Str(token_.at("access_token"))}},
    }, body)).ok());
}

class Apple {
  private:
    const S<Base> base_;

    const std::string iss_;
    const std::string kid_;
    const std::string key_;

  public:
    Apple(S<Base> base, std::string iss, std::string kid) :
        base_(std::move(base)),
        iss_(std::move(iss)),
        kid_(std::move(kid)),
        key_(Load("AuthKey_" + kid_ + ".p8"))
    {
    }

    task<Any> operator ()(const std::string &method, const std::string &path, const std::string &body, http::status status) const;
};

task<Any> Apple::operator ()(const std::string &method, const std::string &path, const std::string &body, http::status status) const {
    auto data((co_await base_->Fetch(method, {{"https", "api.appstoreconnect.apple.com", "443"}, path}, {
        {"content-type", "application/json"},
        {"authorization", "Bearer " + Bearer("appstoreconnect-v1", iss_, "ES256", kid_, key_)},
    }, body)).is(status));

    if (status != http::status::no_content)
        co_return Parse(std::move(data)).as_object().at("data");
    else {
        orc_assert(data.empty());
        co_return nullptr;
    }
}

struct Platform {
    std::string name_;
    unsigned count_;
};

std::string Slash(const std::vector<std::string> &parts) {
    std::ostringstream slashed;
    for (const auto &part : parts)
        slashed << '/' << part;
    return slashed.str();
}

task<void> RunApple(const S<Base> &base, const std::string &root, const std::string &iss, const std::string &kid, const std::string &app) {
    Apple apple(base, iss, kid);

    *co_await Parallel(Map([&](const Platform &platform) -> task<void> {
        const auto version$(Str(One((co_await apple("GET", Slash({"v1/apps", app, "appStoreVersions"}) + "?filter[appStoreState]=PREPARE_FOR_SUBMISSION&filter[platform]=" + platform.name_, {}, http::status::ok)).as_array()).at("id")));
        *co_await Parallel(Map([&](const Any &localization) -> task<void> {
            const auto locale(Str(localization.at("attributes").at("locale")));
            orc_assert(locale.size() >= 2);

            const auto localization$(Str(localization.at("id")));
            *co_await Parallel(Map([&](const Any &screenshots) -> task<void> {
                const auto screenshots$(Str(screenshots.at("id")));

                *co_await Parallel(Map([&](const Any &screenshot) -> task<void> {
                    const auto screenshot$(Str(screenshot.at("id")));
                    orc_assert(co_await apple("DELETE", Slash({"v1/appScreenshots", screenshot$}), {}, http::status::no_content) == nullptr);
                }, (co_await apple("GET", Slash({"v1/appScreenshotSets", screenshots$, "appScreenshots"}), {}, http::status::ok)).as_array()));

                const auto folder(root + "/" + Str(screenshots.at("attributes").at("screenshotDisplayType")) + "/" + locale.substr(0, 2) + "/");
                for (size_t i(0); i != platform.count_; ++i) {
                    const auto file(folder + std::to_string(i) + ".png");
                    std::cout << file << std::endl;
                    const auto data(Load(file));

                    const auto reservation((co_await apple("POST", "/v1/appScreenshots", Unparse({
                        {"data", {
                            {"type", "appScreenshots"},
                            {"attributes", {
                                {"fileSize", data.size()},
                                {"fileName", file},
                            }},
                            {"relationships", {
                                {"appScreenshotSet", {
                                    {"data", {
                                        {"type", "appScreenshotSets"},
                                        {"id", screenshots$},
                                    }},
                                }},
                            }},
                        }},
                    }), http::status::created)).as_object());

                    *co_await Parallel(Map([&](const Any &upload) -> task<void> {
                        std::map<std::string, std::string> headers;
                        for (const auto &header : upload.at("requestHeaders").as_array())
                            headers.try_emplace(Str(header.at("name")), Str(header.at("value")));
                        orc_assert((co_await base->Fetch(Str(upload.at("method")), Str(upload.at("url")), headers, data.substr(
                            Num<size_t>(upload.at("offset")), Num<size_t>(upload.at("length"))
                        ))).ok().empty());
                    }, reservation.at("attributes").at("uploadOperations").as_array()));

                    const auto screenshot$(Str(reservation.at("id")));
                    const auto delivery((co_await apple("PATCH", Slash({"v1/appScreenshots", screenshot$}), Unparse({
                        {"data", {
                            {"type", "appScreenshots"},
                            {"id", screenshot$},
                            {"attributes", {
                                {"uploaded", true},
                                {"sourceFileChecksum", Hash5(Subset(data)).hex(false)},
                            }},
                        }},
                    }), http::status::ok)).at("attributes").at("assetDeliveryState").as_object());

                    orc_assert(delivery.at("errors").as_array().size() == 0);
                    orc_assert(delivery.at("warnings") == nullptr);
                    orc_assert(delivery.at("state") == "UPLOAD_COMPLETE");
                }
            }, (co_await apple("GET", "/v1/appStoreVersionLocalizations/" + localization$ + "/appScreenshotSets", {}, http::status::ok)).as_array()));
        }, (co_await apple("GET", "/v1/appStoreVersions/" + version$ + "/appStoreVersionLocalizations", {}, http::status::ok)).as_array()));
    }, std::vector<Platform>{Platform{"MAC_OS", 3}, Platform{"IOS", 6}}));
}

task<void> RunGoogle(const S<Base> &base, const std::string &root, const std::string &package$) {
    const auto edits(Slash({"androidpublisher/v3/applications", package$, "edits"}));

    Google google(base, Parse(Load("client_secrets.json")).as_object());
    const auto edit$(Str((co_await google("POST", edits)).as_object().at("id")));

    *co_await Parallel(Map([&](const Any &listing) -> task<void> {
        const auto language$(Str(listing.as_object().at("language")));
        orc_assert(language$.size() >= 2);
        *co_await Parallel(Map([&](const Platform &platform) -> task<void> {
            co_await google("DELETE", edits + Slash({edit$, "listings", language$, platform.name_}));
            const auto folder(root + Slash({platform.name_, language$.substr(0, 2)}));
            for (size_t i(0); i != platform.count_; ++i) {
                const auto file(folder + Slash({std::to_string(i) + ".png"}));
                std::cout << file << std::endl;
                co_await google("POST", "/upload" + edits + Slash({edit$, "listings", language$, platform.name_}) + "?uploadType=media", "image/png", Load(file));
            }
        }, std::vector<Platform>{Platform{"featureGraphic", 1}, Platform{"phoneScreenshots", 6}}));
    }, (co_await google("GET", edits + Slash({edit$, "listings"}))).at("listings").as_array()));

    co_await google("POST", edits + Slash({edit$}) + ":commit");
}

task<void> Main(int argc, const char *const argv[]) {
    Initialize();

    orc_assert(argc == 5);
    const std::string iss(argv[1]);
    const std::string kid(argv[2]);
    const std::string app(argv[3]);
    const std::string package$(argv[4]);

    const S<Base> base(Break<Local>());
    const std::string root("/mnt/orchid/final");

    *co_await Parallel(RunApple(base, root, iss, kid, app), RunGoogle(base, root, package$));

    _exit(0);
}

}

int main(int argc, const char *const argv[]) { try {
    orc::Wait(orc::Main(argc, argv));
    return 0;
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
