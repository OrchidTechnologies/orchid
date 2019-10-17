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

#include <boost/program_options/variables_map.hpp>

#include "link.hpp"
#include "socket.hpp"

namespace orc {

namespace po = boost::program_options;

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

    virtual task<void> Send(Beam beam) = 0;
};

class MonitorLogger
{
  public:
    virtual void AddFlow(Five const &five) = 0;
    virtual void GotHostname(Five const &five, const std::string_view hostname) = 0;
    virtual void GotProtocol(Five const &five, const std::string_view protocol, const std::string_view protocol_chain) = 0;
};

class Hole {
  public:
    virtual ~Hole() = default;

    virtual void Drop(Beam data) = 0;
};

class Capture :
    public Hole,
    public BufferDrain
{
  private:
    uint32_t local_;
    U<Internal> internal_;

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) override;

  public:
    Capture(const std::string &local);
    ~Capture() override;

    void Drop(Beam data) override;

    task<void> Start(S<Origin> origin);
    task<Sunk<> *> Start();
    task<void> Start(boost::program_options::variables_map &args);
    task<void> Start(const std::string &config);
};

void Store(po::variables_map &args, const std::string &path);

}

#endif//ORCHID_CAPTURE_HPP
