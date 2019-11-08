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

#ifndef ORCHID_LWIP_SOCKET_SERVER_H_
#define ORCHID_LWIP_SOCKET_SERVER_H_

#include <memory>
#include <set>
#include <vector>

#include "rtc_base/critical_section.h"
#include "rtc_base/net_helpers.h"
#include "rtc_base/socket_server.h"
#include "rtc_base/system/rtc_export.h"

typedef int SOCKET;

using namespace rtc;

namespace orc {

// Event constants for the Dispatcher class.
enum DispatcherEvent {
  DE_READ = 0x0001,
  DE_WRITE = 0x0002,
  DE_CONNECT = 0x0004,
  DE_CLOSE = 0x0008,
  DE_ACCEPT = 0x0010,
};

class Signaler;

class Dispatcher {
 public:
  virtual ~Dispatcher() {}
  virtual uint32_t GetRequestedEvents() = 0;
  virtual void OnPreEvent(uint32_t ff) = 0;
  virtual void OnEvent(uint32_t ff, int err) = 0;
  virtual int GetDescriptor() = 0;
  virtual bool IsDescriptorClosed() = 0;
};

// A socket server that provides the real sockets of the underlying OS.
class RTC_EXPORT LwipSocketServer : public SocketServer {
 public:
  LwipSocketServer();
  ~LwipSocketServer() override;

  // SocketFactory:
  rtc::Socket* CreateSocket(int family, int type) override;
  AsyncSocket* CreateAsyncSocket(int family, int type) override;

  // Internal Factory for Accept (virtual so it can be overwritten in tests).
  virtual AsyncSocket* WrapSocket(SOCKET s);

  // SocketServer:
  bool Wait(int cms, bool process_io) override;
  void WakeUp() override;

  void Add(Dispatcher* dispatcher);
  void Remove(Dispatcher* dispatcher);
  void Update(Dispatcher* dispatcher);

 private:
  typedef std::set<Dispatcher*> DispatcherSet;

  void AddRemovePendingDispatchers();

  bool WaitSelect(int cms, bool process_io);
  static bool InstallSignal(int signum, void (*handler)(int));

  DispatcherSet dispatchers_;
  DispatcherSet pending_add_dispatchers_;
  DispatcherSet pending_remove_dispatchers_;
  bool processing_dispatchers_ = false;
  Signaler* signal_wakeup_;
  CriticalSection crit_;
  bool fWait_;
};

class LwipSocket : public AsyncSocket, public sigslot::has_slots<> {
 public:
  LwipSocket(LwipSocketServer* ss, SOCKET s = INVALID_SOCKET);
  ~LwipSocket() override;

  // Creates the underlying OS socket (same as the "socket" function).
  virtual bool Create(int family, int type);

  SocketAddress GetLocalAddress() const override;
  SocketAddress GetRemoteAddress() const override;

  int Bind(const SocketAddress& bind_addr) override;
  int Connect(const SocketAddress& addr) override;

  int GetError() const override;
  void SetError(int error) override;

  ConnState GetState() const override;

  int GetOption(Option opt, int* value) override;
  int SetOption(Option opt, int value) override;

  int Send(const void* pv, size_t cb) override;
  int SendTo(const void* buffer,
             size_t length,
             const SocketAddress& addr) override;

  int Recv(void* buffer, size_t length, int64_t* timestamp) override;
  int RecvFrom(void* buffer,
               size_t length,
               SocketAddress* out_addr,
               int64_t* timestamp) override;

  int Listen(int backlog) override;
  AsyncSocket* Accept(SocketAddress* out_addr) override;

  int Close() override;

  SocketServer* socketserver() { return ss_; }

 protected:
  int DoConnect(const SocketAddress& connect_addr);

  // Make virtual so ::accept can be overwritten in tests.
  virtual SOCKET DoAccept(SOCKET socket, sockaddr* addr, socklen_t* addrlen);

  // Make virtual so ::send can be overwritten in tests.
  virtual int DoSend(SOCKET socket, const char* buf, int len, int flags);

  // Make virtual so ::sendto can be overwritten in tests.
  virtual int DoSendTo(SOCKET socket,
                       const char* buf,
                       int len,
                       int flags,
                       const struct sockaddr* dest_addr,
                       socklen_t addrlen);

  void OnResolveResult(AsyncResolverInterface* resolver);

  void UpdateLastError();
  void MaybeRemapSendError();

  uint8_t enabled_events() const { return enabled_events_; }
  virtual void SetEnabledEvents(uint8_t events);
  virtual void EnableEvents(uint8_t events);
  virtual void DisableEvents(uint8_t events);

  static int TranslateOption(Option opt, int* slevel, int* sopt);

  LwipSocketServer* ss_;
  SOCKET s_;
  bool udp_;
  CriticalSection crit_;
  int error_ RTC_GUARDED_BY(crit_);
  ConnState state_;
  AsyncResolver* resolver_;

#if !defined(NDEBUG)
  std::string dbg_addr_;
#endif

 private:
  uint8_t enabled_events_ = 0;
};

class SocketDispatcher : public Dispatcher, public LwipSocket {
 public:
  explicit SocketDispatcher(LwipSocketServer* ss);
  SocketDispatcher(SOCKET s, LwipSocketServer* ss);
  ~SocketDispatcher() override;

  bool Initialize();

  virtual bool Create(int type);
  bool Create(int family, int type) override;

  int GetDescriptor() override;
  bool IsDescriptorClosed() override;

  uint32_t GetRequestedEvents() override;
  void OnPreEvent(uint32_t ff) override;
  void OnEvent(uint32_t ff, int err) override;

  int Close() override;
};

}  // namespace rtc

#endif  // ORCHID_LWIP_SOCKET_SERVER_H_
