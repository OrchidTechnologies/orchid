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
#include "socket.hpp"

namespace orc {

class Origin;

class Analyzer {
  public:
    virtual ~Analyzer();

    virtual void Analyze(Span<> span) = 0;
    virtual void AnalyzeIncoming(Span<> span) = 0;
};

class Internal {
  public:
    virtual ~Internal();

    virtual task<void> Send(Beam beam) = 0;
};

class MonitorLogger
{
  public:
    virtual void AddFlow(Five const &five) = 0;
    virtual void GotHostname(Five const &five, const std::string &hostname) = 0;
};

class Flow;

class Capture :
    public Sync,
    public BufferDrain
{
  public:
    U<Analyzer> analyzer_;

    uint32_t local_;
    U<Internal> internal_;

  protected:
    virtual Link *Inner() = 0;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) override;

  public:
    Capture(const std::string &local);
    ~Capture() override;

    void Send(const Buffer &data) override;

    task<void> Start(S<Origin> origin);
    task<void> Start(std::string ovpnfile, std::string username, std::string password);
};

}

#endif//ORCHID_CAPTURE_HPP
