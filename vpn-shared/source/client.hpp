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


#ifndef ORCHID_CLIENT_HPP
#define ORCHID_CLIENT_HPP

#include <rtc_base/openssl_identity.h>
#include <rtc_base/ssl_fingerprint.h>

#include "http.hpp"
#include "secure.hpp"
#include "socket.hpp"
#include "task.hpp"
#include "trace.hpp"

namespace orc {

class Server;

class Origin {
  public:
    virtual task<Socket> Hop(Sunk<> *sunk, const std::string &host, const std::string &port, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) = 0;

    virtual task<Socket> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) = 0;

    task<std::string> Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data);
};

class Server :
    public std::enable_shared_from_this<Server>,
    public Origin,
    public Router<Secure>
{
  private:
    U<rtc::SSLFingerprint> remote_;

    U<rtc::OpenSSLIdentity> local_;

    Socket socket_;

  protected:
    virtual Secure *Inner() = 0;

  public:
    Server(U<rtc::SSLFingerprint> remote) :
        remote_(std::move(remote)),
        local_(rtc::OpenSSLIdentity::GenerateWithExpiration("WebRTC", rtc::KeyParams(rtc::KT_DEFAULT), 60*60*24))
    {
    }

    task<void> Connect() {
        co_return co_await Inner()->Connect();
    }


    task<void> Send(const Buffer &data) {
        co_return co_await Inner()->Send(data);
    }


    task<void> Swing(Sunk<Secure> *sunk, const S<Origin> &origin, const std::string &host, const std::string &port);

    U<Route<Server>> Path(BufferDrain *drain);
    task<Beam> Call(const Tag &command, const Buffer &data);

    task<Socket> Hop(Sunk<> *sunk, const std::string &host, const std::string &port, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) override;
    task<Socket> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) override;
};

class Local final :
    public Origin
{
  public:
    virtual ~Local() {
    }

    task<Socket> Hop(Sunk<> *sunk, const std::string &host, const std::string &port, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) override;
    task<Socket> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) override;
};

S<Local> GetLocal();

task<S<Origin>> Setup();

}

#endif//ORCHID_CLIENT_HPP
