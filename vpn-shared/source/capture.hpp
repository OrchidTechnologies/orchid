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


#ifndef ORCHID_CAPTURE_HPP
#define ORCHID_CAPTURE_HPP

#include <map>

#include "link.hpp"
#include "nest.hpp"
#include "socket.hpp"

namespace orc {

class Origin;

class Analyzer {
  public:
    virtual ~Analyzer();

    virtual void Analyze(Span<const uint8_t> span) = 0;
    virtual void AnalyzeIncoming(Span<const uint8_t> span) = 0;
};

class Internal {
  public:
    virtual ~Internal();

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
    public BufferDrain
{
  private:
    Host local_;
    Nest nest_;
    U<Analyzer> analyzer_;
    U<Internal> internal_;

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) override;

  public:
    Capture(const Host &local);
    virtual ~Capture();

    void Land(const Buffer &data, bool analyze);

    task<void> Start(S<Origin> origin);
    task<Sunk<> *> Start();
    task<void> Start(const std::string &path);
};

}

#endif//ORCHID_CAPTURE_HPP
