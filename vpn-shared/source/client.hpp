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


#ifndef ORCHID_CLIENT_HPP
#define ORCHID_CLIENT_HPP

#include <atomic>

#include <rtc_base/rtc_certificate.h>
#include <rtc_base/ssl_fingerprint.h>

#include "base.hpp"
#include "bond.hpp"
#include "float.hpp"
#include "jsonrpc.hpp"
#include "locked.hpp"
#include "nest.hpp"
#include "oracle.hpp"
#include "provider.hpp"
#include "signed.hpp"
#include "ticket.hpp"

// XXX: move this somewhere and maybe find a library
namespace gsl { template <typename Type_> using owner = Type_; }

namespace orc {

struct Currency;
struct Market;
class Shopper;

class Client :
    public Pump<Buffer>,
    public Bonded
{
  private:
    const rtc::scoped_refptr<rtc::RTCCertificate> local_;

    const S<Updated<Prices>> oracle_;

    struct Pending {
        Beam command_;
        Float amount_;
    };

    struct Locked_ {
        uint64_t updated_ = 0;

        uint64_t output_ = 0;
        uint64_t input_ = 0;

        std::map<Bytes32, Pending> pending_;
        Float spent_ = 0;

        int64_t serial_ = -1;
        Float balance_ = 0;
    }; Locked<Locked_> locked_;

    Nest nest_;
    Socket socket_;

    void Transfer(size_t size, bool send);

    task<void> Submit();
    task<void> Submit(const Bytes32 &ticket, const Buffer &command);

  protected:
    task<void> Submit(const Bytes32 &ticket, const Buffer &command, const Float &amount);

    virtual task<void> Submit(const Float &amount) = 0;
    virtual void Invoice(const Bytes32 &id, const Buffer &data);

    void Land(Pipe *pipe, const Buffer &data) override;
    void Stop() noexcept override;

  public:
    Client(BufferDrain &drain, S<Updated<Prices>> oracle);

    task<void> Open(const Provider &provider, const S<Base> &base);
    task<void> Shut() noexcept override;

    task<void> Send(const Buffer &data) override;

    virtual Address Recipient() = 0;

    void Update();
    uint64_t Benefit();
    Float Spent();
    Float Balance();
};

Float Ratio(const uint128_t &face, const Float &amount, const Market &market, const Currency &currency, const uint64_t &gas);

}

#endif//ORCHID_CLIENT_HPP
