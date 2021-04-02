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


#ifndef ORCHID_CAPTURE_HPP
#define ORCHID_CAPTURE_HPP

#include <map>

#include "link.hpp"
#include "locked.hpp"
#include "nest.hpp"
#include "router.hpp"
#include "socket.hpp"

namespace orc {

class Base;

class Analyzer {
  public:
    virtual ~Analyzer();

    virtual void Analyze(Span<const uint8_t> span) = 0;
    virtual void AnalyzeIncoming(Span<const uint8_t> span) = 0;
};

// XXX: Transform is also a Valve, which is just wrong, right?
// this sort of doesn't matter as if Transform is Shut we fail
class Internal :
    public Valve
{
  public:
    Internal(const char *type) :
        Valve(type)
    {
    }

    ~Internal() override;

    virtual task<bool> Send(const Beam &beam) = 0;
};

class MonitorLogger
{
  public:
    virtual void AddFlow(Five const &five) = 0;
    virtual void GotHostname(Five const &five, const std::string_view hostname) = 0;
    virtual void GotProtocol(Five const &five, const std::string_view protocol, const std::string_view protocol_chain) = 0;
};

class Capture :
    public Valve,
    public BufferDrain,
    public Sunken<Pump<Buffer>>
{
  private:
    const Host local_;

    Nest up_;
    Nest down_;

    U<Analyzer> analyzer_;
    // XXX: I covered these objects, but this just feels wrong
    // I think maybe I should make Internals subclass Capture?
    U<Internal> internal_;

    // XXX: so this won't even manage its own memory correctly
    Router router_;

    struct Locked_ {
        bool connected_ = false;
    }; Locked<Locked_> locked_;

  protected:
    void Land(const Buffer &data) override;
    void Stop(const std::string &error) noexcept override;

  public:
    Capture(const Host &local);
    ~Capture() override;

    void Land(const Buffer &data, bool analyze);

    void Start(S<Base> base);
    BufferSunk &Start();
    void Start(const std::string &path);

    task<void> Shut() noexcept override;
};

}

#endif//ORCHID_CAPTURE_HPP
