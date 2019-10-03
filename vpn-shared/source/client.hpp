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

#include "origin.hpp"
#include "secure.hpp"

namespace orc {

class Server :
    public std::enable_shared_from_this<Server>,
    public Origin,
    public Prefixed<Secure>
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


    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }


    task<void> Swing(Sunk<Secure> *sunk, const S<Origin> &origin, const std::string &host, const std::string &port);

    Prefix<Server> *Path(Sunk<Prefix<Server>> *sunk);
    task<Beam> Call(const Tag &command, const Buffer &args);

    task<Socket> Associate(Sunk<> *sunk, const std::string &host, const std::string &port) override;
    task<Socket> Connect(U<Stream> &stream, const std::string &host, const std::string &port) override;
    task<Socket> Hop(Sunk<> *sunk, const std::function<task<std::string> (std::string)> &respond) override;
    task<Socket> Open(Sunk<Opening, BufferSewer> *sunk) override;
};

task<S<Origin>> Setup(const std::string &rpc);

}

#endif//ORCHID_CLIENT_HPP
