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


#ifndef ORCHID_SECURE_HPP
#define ORCHID_SECURE_HPP

#include <openssl/ssl.h>

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/async_mutex.hpp>

#include "link.hpp"

namespace orc {

class Secure final :
    public Link
{
  private:
    bool server_;
    Sink<> sink_;
    std::function<bool ()> verify_;

    bool eof_ = false;
    const Buffer *data_ = NULL;
    void (Secure::*land_)() = NULL;

    cppcoro::async_mutex send_;

    cppcoro::async_manual_reset_event opened_;
    cppcoro::async_manual_reset_event closed_;

    SSL *ssl_;

  private:
    static BIO_METHOD *Method();

    int Write(BIO *bio, const char *data, int size);
    int Read(BIO *bio, char *data, int size);
    long Control(BIO *bio, int command, long arg1, void *arg2);
    int Destroy(BIO *bio);

    void Active();
    void Server();
    void Client();

  public:
    Secure(bool server, U<Link> link, decltype(verify_) verify);

    task<void> _();

    virtual ~Secure();

    task<void> Send(const Buffer &data) override;
};

}

#endif//ORCHID_SECURE_HPP
