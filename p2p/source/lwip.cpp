/*
 *  Copyright 2004 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#include "lwip.hpp"
#include "log.hpp"

#include <lwip/opt.h>
#include <lwip/sockets.h>
#include <lwip/sys.h>

#ifndef TCP_NODELAY
#define TCP_NODELAY    0x01    /* don't delay send to coalesce packets */
#endif

/* commands for fnctl */
#ifndef F_GETFL
#define F_GETFL 3
#endif
#ifndef F_SETFL
#define F_SETFL 4
#endif

/* File status flags and file access modes for fnctl,
   these are bits in an int. */
#ifndef O_NONBLOCK
#define O_NONBLOCK  1 /* nonblocking I/O */
#endif

#if defined(_MSC_VER) && _MSC_VER < 1300
#pragma warning(disable : 4786)
#endif

#ifdef MEMORY_SANITIZER
#include <sanitizer/msan_interface.h>
#endif

#include <string.h>
#include <signal.h>
#include <unistd.h>


#include <errno.h>

#include <algorithm>
#include <map>

#include "rtc_base/arraysize.h"
#include "rtc_base/byte_order.h"
#include "rtc_base/checks.h"
#include "rtc_base/logging.h"
#include "rtc_base/network_monitor.h"
#include "rtc_base/null_socket_server.h"
#include "rtc_base/time_utils.h"


#define LAST_SYSTEM_ERROR (errno)

#define IP_MTU 14  // Until this is integrated from linux/in.h to netinet/in.h
typedef void* SockOptArg;

using namespace rtc;

namespace orc {

int64_t GetSocketRecvTimestamp(int socket) {
  return -1;
}

LwipSocket::LwipSocket(LwipSocketServer* ss, SOCKET s)
    : ss_(ss),
      s_(s),
      error_(0),
      state_((s == INVALID_SOCKET) ? CS_CLOSED : CS_CONNECTED),
      resolver_(nullptr) {
  if (s_ != INVALID_SOCKET) {
    SetEnabledEvents(DE_READ | DE_WRITE);

    int type = SOCK_STREAM;
    socklen_t len = sizeof(type);
    const int res =
        ::lwip_getsockopt(s_, SOL_SOCKET, SO_TYPE, (SockOptArg)&type, &len);
    RTC_DCHECK_EQ(0, res);
    udp_ = (SOCK_DGRAM == type);
  }
}

LwipSocket::~LwipSocket() {
  Close();
}

bool LwipSocket::Create(int family, int type) {
  Close();
  s_ = ::lwip_socket(family, type, 0);
  udp_ = (SOCK_DGRAM == type);
  family_ = family;
  UpdateLastError();
  if (udp_) {
    SetEnabledEvents(DE_READ | DE_WRITE);
  }
  return s_ != INVALID_SOCKET;
}

SocketAddress LwipSocket::GetLocalAddress() const {
  sockaddr_storage addr_storage = {0};
  socklen_t addrlen = sizeof(addr_storage);
  sockaddr* addr = reinterpret_cast<sockaddr*>(&addr_storage);
  int result = ::lwip_getsockname(s_, addr, &addrlen);
  SocketAddress address;
  if (result >= 0) {
    SocketAddressFromSockAddrStorage(addr_storage, &address);
  } else {
    RTC_LOG(LS_WARNING) << "GetLocalAddress: unable to get local addr, socket="
                        << s_;
  }
  return address;
}

SocketAddress LwipSocket::GetRemoteAddress() const {
  sockaddr_storage addr_storage = {0};
  socklen_t addrlen = sizeof(addr_storage);
  sockaddr* addr = reinterpret_cast<sockaddr*>(&addr_storage);
  int result = ::lwip_getpeername(s_, addr, &addrlen);
  SocketAddress address;
  if (result >= 0) {
    SocketAddressFromSockAddrStorage(addr_storage, &address);
  } else {
    RTC_LOG(LS_WARNING)
        << "GetRemoteAddress: unable to get remote addr, socket=" << s_;
  }
  return address;
}

int LwipSocket::Bind(const SocketAddress& bind_addr) {
  SocketAddress copied_bind_addr = bind_addr;
  // If a network binder is available, use it to bind a socket to an interface
  // instead of bind(), since this is more reliable on an OS with a weak host
  // model.
  if (ss_->network_binder() && !bind_addr.IsAnyIP()) {
    NetworkBindingResult result =
        ss_->network_binder()->BindSocketToNetwork(s_, bind_addr.ipaddr());
    if (result == NetworkBindingResult::SUCCESS) {
      // Since the network binder handled binding the socket to the desired
      // network interface, we don't need to (and shouldn't) include an IP in
      // the bind() call; bind() just needs to assign a port.
      copied_bind_addr.SetIP(GetAnyIP(copied_bind_addr.ipaddr().family()));
    } else if (result == NetworkBindingResult::NOT_IMPLEMENTED) {
      RTC_LOG(LS_INFO) << "Can't bind socket to network because "
                          "network binding is not implemented for this OS.";
    } else {
      if (bind_addr.IsLoopbackIP()) {
        // If we couldn't bind to a loopback IP (which should only happen in
        // test scenarios), continue on. This may be expected behavior.
        RTC_LOG(LS_VERBOSE) << "Binding socket to loopback address "
                            << bind_addr.ipaddr().ToString()
                            << " failed; result: " << static_cast<int>(result);
      } else {
        RTC_LOG(LS_WARNING) << "Binding socket to network address "
                            << bind_addr.ipaddr().ToString()
                            << " failed; result: " << static_cast<int>(result);
        // If a network binding was attempted and failed, we should stop here
        // and not try to use the socket. Otherwise, we may end up sending
        // packets with an invalid source address.
        // See: https://bugs.chromium.org/p/webrtc/issues/detail?id=7026
        return -1;
      }
    }
  }
  sockaddr_storage addr_storage;
  size_t len = copied_bind_addr.ToSockAddrStorage(&addr_storage);
  sockaddr* addr = reinterpret_cast<sockaddr*>(&addr_storage);
  int err = ::lwip_bind(s_, addr, static_cast<int>(len));
  UpdateLastError();
#if !defined(NDEBUG)
  if (0 == err) {
    dbg_addr_ = "Bound @ ";
    dbg_addr_.append(GetLocalAddress().ToString());
  }
#endif
  return err;
}

int LwipSocket::Connect(const SocketAddress& addr) {
  // TODO(pthatcher): Implicit creation is required to reconnect...
  // ...but should we make it more explicit?
  if (state_ != CS_CLOSED) {
    SetError(EALREADY);
    return SOCKET_ERROR;
  }
  if (addr.IsUnresolvedIP()) {
    RTC_LOG(LS_VERBOSE) << "Resolving addr in LwipSocket::Connect";
    resolver_ = new AsyncResolver();
    resolver_->SignalDone.connect(this, &LwipSocket::OnResolveResult);
    resolver_->Start(addr);
    state_ = CS_CONNECTING;
    return 0;
  }

  return DoConnect(addr);
}

int LwipSocket::DoConnect(const SocketAddress& connect_addr) {
  if ((s_ == INVALID_SOCKET) && !Create(connect_addr.family(), SOCK_STREAM)) {
    return SOCKET_ERROR;
  }
  sockaddr_storage addr_storage;
  size_t len = connect_addr.ToSockAddrStorage(&addr_storage);
  sockaddr* addr = reinterpret_cast<sockaddr*>(&addr_storage);
  int err = ::lwip_connect(s_, addr, static_cast<int>(len));
  UpdateLastError();
  uint8_t events = DE_READ | DE_WRITE;
  if (err == 0) {
    state_ = CS_CONNECTED;
  } else if (IsBlockingError(GetError())) {
    state_ = CS_CONNECTING;
    events |= DE_CONNECT;
  } else {
    return SOCKET_ERROR;
  }

  EnableEvents(events);
  return 0;
}

int LwipSocket::GetError() const {
  CritScope cs(&crit_);
  return error_;
}

void LwipSocket::SetError(int error) {
  CritScope cs(&crit_);
  error_ = error;
}

AsyncSocket::ConnState LwipSocket::GetState() const {
  return state_;
}

int LwipSocket::GetOption(Option opt, int* value) {
  int slevel;
  int sopt;
  if (TranslateOption(opt, &slevel, &sopt) == -1)
    return -1;
  socklen_t optlen = sizeof(*value);
  int ret = ::lwip_getsockopt(s_, slevel, sopt, (SockOptArg)value, &optlen);
  return ret;
}

int LwipSocket::SetOption(Option opt, int value) {
  int slevel;
  int sopt;
  if (TranslateOption(opt, &slevel, &sopt) == -1)
    return -1;
  return ::lwip_setsockopt(s_, slevel, sopt, (SockOptArg)&value, sizeof(value));
}

int LwipSocket::Send(const void* pv, size_t cb) {
  int sent = DoSend(
      s_, reinterpret_cast<const char*>(pv), static_cast<int>(cb),
      0
  );
  UpdateLastError();
  MaybeRemapSendError();
  // We have seen minidumps where this may be false.
  RTC_DCHECK(sent <= static_cast<int>(cb));
  if ((sent > 0 && sent < static_cast<int>(cb)) ||
      (sent < 0 && IsBlockingError(GetError()))) {
    EnableEvents(DE_WRITE);
  }
  return sent;
}

int LwipSocket::SendTo(const void* buffer,
                           size_t length,
                           const SocketAddress& addr) {
  sockaddr_storage saddr;
  size_t len = addr.ToSockAddrStorage(&saddr);
  int sent =
      DoSendTo(s_, static_cast<const char*>(buffer), static_cast<int>(length),
               0,
               reinterpret_cast<sockaddr*>(&saddr), static_cast<int>(len));
  UpdateLastError();
  MaybeRemapSendError();
  // We have seen minidumps where this may be false.
  RTC_DCHECK(sent <= static_cast<int>(length));
  if ((sent > 0 && sent < static_cast<int>(length)) ||
      (sent < 0 && IsBlockingError(GetError()))) {
    EnableEvents(DE_WRITE);
  }
  return sent;
}

int LwipSocket::Recv(void* buffer, size_t length, int64_t* timestamp) {
  int received =
      ::lwip_recv(s_, static_cast<char*>(buffer), static_cast<int>(length), 0);
  if ((received == 0) && (length != 0)) {
    // Note: on graceful shutdown, recv can return 0.  In this case, we
    // pretend it is blocking, and then signal close, so that simplifying
    // assumptions can be made about Recv.
    RTC_LOG(LS_WARNING) << "EOF from socket; deferring close event";
    // Must turn this back on so that the select() loop will notice the close
    // event.
    EnableEvents(DE_READ);
    SetError(EWOULDBLOCK);
    return SOCKET_ERROR;
  }
  if (timestamp) {
    *timestamp = GetSocketRecvTimestamp(s_);
  }
  UpdateLastError();
  int error = GetError();
  bool success = (received >= 0) || IsBlockingError(error);
  if (udp_ || success) {
    EnableEvents(DE_READ);
  }
  if (!success) {
    RTC_LOG_F(LS_VERBOSE) << "Error = " << error;
  }
  return received;
}

int LwipSocket::RecvFrom(void* buffer,
                             size_t length,
                             SocketAddress* out_addr,
                             int64_t* timestamp) {
  sockaddr_storage addr_storage;
  socklen_t addr_len = sizeof(addr_storage);
  sockaddr* addr = reinterpret_cast<sockaddr*>(&addr_storage);
  int received = ::lwip_recvfrom(s_, static_cast<char*>(buffer),
                            static_cast<int>(length), 0, addr, &addr_len);
  if (timestamp) {
    *timestamp = GetSocketRecvTimestamp(s_);
  }
  UpdateLastError();
  if ((received >= 0) && (out_addr != nullptr))
    SocketAddressFromSockAddrStorage(addr_storage, out_addr);
  int error = GetError();
  bool success = (received >= 0) || IsBlockingError(error);
  if (udp_ || success) {
    EnableEvents(DE_READ);
  }
  if (!success) {
    RTC_LOG_F(LS_VERBOSE) << "Error = " << error;
  }
  return received;
}

int LwipSocket::Listen(int backlog) {
  int err = ::lwip_listen(s_, backlog);
  UpdateLastError();
  if (err == 0) {
    state_ = CS_CONNECTING;
    EnableEvents(DE_ACCEPT);
#if !defined(NDEBUG)
    dbg_addr_ = "Listening @ ";
    dbg_addr_.append(GetLocalAddress().ToString());
#endif
  }
  return err;
}

AsyncSocket* LwipSocket::Accept(SocketAddress* out_addr) {
  // Always re-subscribe DE_ACCEPT to make sure new incoming connections will
  // trigger an event even if DoAccept returns an error here.
  EnableEvents(DE_ACCEPT);
  sockaddr_storage addr_storage;
  socklen_t addr_len = sizeof(addr_storage);
  sockaddr* addr = reinterpret_cast<sockaddr*>(&addr_storage);
  SOCKET s = DoAccept(s_, addr, &addr_len);
  UpdateLastError();
  if (s == INVALID_SOCKET)
    return nullptr;
  if (out_addr != nullptr)
    SocketAddressFromSockAddrStorage(addr_storage, out_addr);
  return ss_->WrapSocket(s);
}

int LwipSocket::Close() {
  if (s_ == INVALID_SOCKET)
    return 0;
  int err = ::lwip_close(s_);
  UpdateLastError();
  s_ = INVALID_SOCKET;
  state_ = CS_CLOSED;
  SetEnabledEvents(0);
  if (resolver_) {
    resolver_->Destroy(false);
    resolver_ = nullptr;
  }
  return err;
}

SOCKET LwipSocket::DoAccept(SOCKET socket,
                                sockaddr* addr,
                                socklen_t* addrlen) {
  return ::lwip_accept(socket, addr, addrlen);
}

int LwipSocket::DoSend(SOCKET socket, const char* buf, int len, int flags) {
  return ::lwip_send(socket, buf, len, flags);
}

int LwipSocket::DoSendTo(SOCKET socket,
                             const char* buf,
                             int len,
                             int flags,
                             const struct sockaddr* dest_addr,
                             socklen_t addrlen) {
  return ::lwip_sendto(socket, buf, len, flags, dest_addr, addrlen);
}

void LwipSocket::OnResolveResult(AsyncResolverInterface* resolver) {
  if (resolver != resolver_) {
    return;
  }

  int error = resolver_->GetError();
  if (error == 0) {
    error = DoConnect(resolver_->address());
  } else {
    Close();
  }

  if (error) {
    SetError(error);
    SignalCloseEvent(this, error);
  }
}

void LwipSocket::UpdateLastError() {
  SetError(LAST_SYSTEM_ERROR);
}

void LwipSocket::MaybeRemapSendError() {
}

void LwipSocket::SetEnabledEvents(uint8_t events) {
  enabled_events_ = events;
}

void LwipSocket::EnableEvents(uint8_t events) {
  enabled_events_ |= events;
}

void LwipSocket::DisableEvents(uint8_t events) {
  enabled_events_ &= ~events;
}

int LwipSocket::TranslateOption(Option opt, int* slevel, int* sopt) {
  switch (opt) {
    case OPT_DONTFRAGMENT:
      RTC_LOG(LS_WARNING) << "Socket::OPT_DONTFRAGMENT not supported.";
      return -1;
    case OPT_RCVBUF:
      *slevel = SOL_SOCKET;
      *sopt = SO_RCVBUF;
      break;
    case OPT_SNDBUF:
      *slevel = SOL_SOCKET;
      *sopt = SO_SNDBUF;
      break;
    case OPT_NODELAY:
      *slevel = IPPROTO_TCP;
      *sopt = TCP_NODELAY;
      break;
    case OPT_DSCP:
      RTC_LOG(LS_WARNING) << "Socket::OPT_DSCP not supported.";
      return -1;
    case OPT_RTP_SENDTIME_EXTN_ID:
      return -1;  // No logging is necessary as this not a OS socket option.
    default:
      RTC_NOTREACHED();
      return -1;
  }
  return 0;
}

SocketDispatcher::SocketDispatcher(LwipSocketServer* ss)
    : LwipSocket(ss)
{
}

SocketDispatcher::SocketDispatcher(SOCKET s, LwipSocketServer* ss)
    : LwipSocket(ss, s)
{
}

SocketDispatcher::~SocketDispatcher() {
  Close();
}

bool SocketDispatcher::Initialize() {
  RTC_DCHECK(s_ != INVALID_SOCKET);
// Must be a non-blocking
  ::lwip_fcntl(s_, F_SETFL, ::lwip_fcntl(s_, F_GETFL, 0) | O_NONBLOCK);
  ss_->Add(this);
  return true;
}

bool SocketDispatcher::Create(int type) {
  return Create(AF_INET, type);
}

bool SocketDispatcher::Create(int family, int type) {
  // Change the socket to be non-blocking.
  if (!LwipSocket::Create(family, type))
    return false;

  if (!Initialize())
    return false;

  return true;
}


int SocketDispatcher::GetDescriptor() {
  return s_;
}

bool SocketDispatcher::IsDescriptorClosed() {
  if (udp_) {
    // The MSG_PEEK trick doesn't work for UDP, since (at least in some
    // circumstances) it requires reading an entire UDP packet, which would be
    // bad for performance here. So, just check whether |s_| has been closed,
    // which should be sufficient.
    return s_ == INVALID_SOCKET;
  }
  // We don't have a reliable way of distinguishing end-of-stream
  // from readability.  So test on each readable call.  Is this
  // inefficient?  Probably.
  char ch;
  ssize_t res = ::lwip_recv(s_, &ch, 1, MSG_PEEK);
  if (res > 0) {
    // Data available, so not closed.
    return false;
  } else if (res == 0) {
    // EOF, so closed.
    return true;
  } else {  // error
    switch (errno) {
      // Returned if we've already closed s_.
      case EBADF:
      // Returned during ungraceful peer shutdown.
      case ECONNRESET:
        return true;
      // The normal blocking error; don't log anything.
      case EWOULDBLOCK:
      // Interrupted system call.
      case EINTR:
        return false;
      default:
        // Assume that all other errors are just blocking errors, meaning the
        // connection is still good but we just can't read from it right now.
        // This should only happen when connecting (and at most once), because
        // in all other cases this function is only called if the file
        // descriptor is already known to be in the readable state. However,
        // it's not necessary a problem if we spuriously interpret a
        // "connection lost"-type error as a blocking error, because typically
        // the next recv() will get EOF, so we'll still eventually notice that
        // the socket is closed.
        RTC_LOG_ERR(LS_WARNING) << "Assuming benign blocking error";
        return false;
    }
  }
}

uint32_t SocketDispatcher::GetRequestedEvents() {
  return enabled_events();
}

void SocketDispatcher::OnPreEvent(uint32_t ff) {
  if ((ff & DE_CONNECT) != 0)
    state_ = CS_CONNECTED;

  if ((ff & DE_CLOSE) != 0)
    state_ = CS_CLOSED;
}

void SocketDispatcher::OnEvent(uint32_t ff, int err) {
  // Make sure we deliver connect/accept first. Otherwise, consumers may see
  // something like a READ followed by a CONNECT, which would be odd.
  if ((ff & DE_CONNECT) != 0) {
    DisableEvents(DE_CONNECT);
    SignalConnectEvent(this);
  }
  if ((ff & DE_ACCEPT) != 0) {
    DisableEvents(DE_ACCEPT);
    SignalReadEvent(this);
  }
  if ((ff & DE_READ) != 0) {
    DisableEvents(DE_READ);
    SignalReadEvent(this);
  }
  if ((ff & DE_WRITE) != 0) {
    DisableEvents(DE_WRITE);
    SignalWriteEvent(this);
  }
  if ((ff & DE_CLOSE) != 0) {
    // The socket is now dead to us, so stop checking it.
    SetEnabledEvents(0);
    SignalCloseEvent(this, err);
  }
}

int SocketDispatcher::Close() {
  if (s_ == INVALID_SOCKET)
    return 0;

  ss_->Remove(this);
  return LwipSocket::Close();
}

class EventDispatcher : public Dispatcher {
 public:
  EventDispatcher(LwipSocketServer* ss) : ss_(ss), fSignaled_(false) {
    afd_[0] = ::lwip_socket(PF_INET, SOCK_DGRAM, 0);
    if (afd_[0] < 0)
      RTC_LOG(LERROR) << "pipe 1 failed";
    afd_[1] = ::lwip_socket(PF_INET, SOCK_DGRAM, 0);
    if (afd_[1] < 0)
      RTC_LOG(LERROR) << "pipe 2 failed";
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = 0;
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    int r = ::lwip_bind(afd_[0], (const struct sockaddr *)&addr, sizeof(addr));
    if (r < 0)
        RTC_LOG(LERROR) << "pipe bind failed";
    socklen_t addrlen = sizeof(addr);
    r = ::lwip_getsockname(afd_[0], (struct sockaddr *)&addr, &addrlen);
    if (r < 0)
        RTC_LOG(LERROR) << "pipe getsockaddr failed";
    r = ::lwip_connect(afd_[1], (const struct sockaddr *)&addr, addrlen);
    if (r < 0)
        RTC_LOG(LERROR) << "pipe connect failed";
    ss_->Add(this);
  }

  ~EventDispatcher() override {
    ss_->Remove(this);
    ::lwip_close(afd_[0]);
    ::lwip_close(afd_[1]);
  }

  virtual void Signal() {
    CritScope cs(&crit_);
    if (!fSignaled_) {
      const uint8_t b[1] = {0};
      const ssize_t res = ::lwip_send(afd_[1], b, sizeof(b), 0);
      RTC_DCHECK_EQ(1, res);
      fSignaled_ = true;
    }
  }

  uint32_t GetRequestedEvents() override { return DE_READ; }

  void OnPreEvent(uint32_t ff) override {
    // It is not possible to perfectly emulate an auto-resetting event with
    // pipes.  This simulates it by resetting before the event is handled.

    CritScope cs(&crit_);
    if (fSignaled_) {
      uint8_t b[4];  // Allow for reading more than 1 byte, but expect 1.
      const ssize_t res = ::lwip_recv(afd_[0], b, sizeof(b), 0);
      RTC_DCHECK_EQ(1, res);
      fSignaled_ = false;
    }
  }

  void OnEvent(uint32_t ff, int err) override { RTC_NOTREACHED(); }

  int GetDescriptor() override { return afd_[0]; }

  bool IsDescriptorClosed() override { return false; }

 private:
  LwipSocketServer* ss_;
  int afd_[2];
  bool fSignaled_;
  RecursiveCriticalSection crit_;
};

// Sets the value of a boolean value to false when signaled.
class Signaler : public EventDispatcher {
 public:
  Signaler(LwipSocketServer* ss, bool* pf) : EventDispatcher(ss), pf_(pf) {}
  ~Signaler() override {}

  void OnEvent(uint32_t ff, int err) override {
    if (pf_)
      *pf_ = false;
  }

 private:
  bool* pf_;
};

LwipSocketServer::LwipSocketServer()
    :
      fWait_(false) {
  signal_wakeup_ = new Signaler(this, &fWait_);
}

LwipSocketServer::~LwipSocketServer() {
  delete signal_wakeup_;
  RTC_DCHECK(dispatchers_.empty());
}

void LwipSocketServer::WakeUp() {
  signal_wakeup_->Signal();
}

Socket* LwipSocketServer::CreateSocket(int family, int type) {
  LwipSocket* socket = new LwipSocket(this);
  if (socket->Create(family, type)) {
    return socket;
  } else {
    delete socket;
    return nullptr;
  }
}

AsyncSocket* LwipSocketServer::CreateAsyncSocket(int family, int type) {
  SocketDispatcher* dispatcher = new SocketDispatcher(this);
  if (dispatcher->Create(family, type)) {
    return dispatcher;
  } else {
    delete dispatcher;
    return nullptr;
  }
}

AsyncSocket* LwipSocketServer::WrapSocket(SOCKET s) {
  SocketDispatcher* dispatcher = new SocketDispatcher(s, this);
  if (dispatcher->Initialize()) {
    return dispatcher;
  } else {
    delete dispatcher;
    return nullptr;
  }
}

void LwipSocketServer::Add(Dispatcher* pdispatcher) {
  CritScope cs(&crit_);
  if (processing_dispatchers_) {
    // A dispatcher is being added while a "Wait" call is processing the
    // list of socket events.
    // Defer adding to "dispatchers_" set until processing is done to avoid
    // invalidating the iterator in "Wait".
    pending_remove_dispatchers_.erase(pdispatcher);
    pending_add_dispatchers_.insert(pdispatcher);
  } else {
    dispatchers_.insert(pdispatcher);
  }
}

void LwipSocketServer::Remove(Dispatcher* pdispatcher) {
  CritScope cs(&crit_);
  if (processing_dispatchers_) {
    // A dispatcher is being removed while a "Wait" call is processing the
    // list of socket events.
    // Defer removal from "dispatchers_" set until processing is done to avoid
    // invalidating the iterator in "Wait".
    if (!pending_add_dispatchers_.erase(pdispatcher) &&
        dispatchers_.find(pdispatcher) == dispatchers_.end()) {
      RTC_LOG(LS_WARNING) << "LwipSocketServer asked to remove a unknown "
                          << "dispatcher, potentially from a duplicate call to "
                          << "Add.";
      return;
    }

    pending_remove_dispatchers_.insert(pdispatcher);
  } else if (!dispatchers_.erase(pdispatcher)) {
    RTC_LOG(LS_WARNING)
        << "LwipSocketServer asked to remove a unknown "
        << "dispatcher, potentially from a duplicate call to Add.";
    return;
  }
}

void LwipSocketServer::Update(Dispatcher* pdispatcher) {
}

void LwipSocketServer::AddRemovePendingDispatchers() {
  if (!pending_add_dispatchers_.empty()) {
    for (Dispatcher* pdispatcher : pending_add_dispatchers_) {
      dispatchers_.insert(pdispatcher);
    }
    pending_add_dispatchers_.clear();
  }

  if (!pending_remove_dispatchers_.empty()) {
    for (Dispatcher* pdispatcher : pending_remove_dispatchers_) {
      dispatchers_.erase(pdispatcher);
    }
    pending_remove_dispatchers_.clear();
  }
}

bool LwipSocketServer::Wait(int cmsWait, bool process_io) {
  return WaitSelect(cmsWait, process_io);
}

static void ProcessEvents(Dispatcher* dispatcher,
                          bool readable,
                          bool writable,
                          bool check_error) {
  int errcode = 0;
  // TODO(pthatcher): Should we set errcode if getsockopt fails?
  if (check_error) {
    socklen_t len = sizeof(errcode);
    ::lwip_getsockopt(dispatcher->GetDescriptor(), SOL_SOCKET, SO_ERROR, &errcode,
                 &len);
  }

  uint32_t ff = 0;

  // Check readable descriptors. If we're waiting on an accept, signal
  // that. Otherwise we're waiting for data, check to see if we're
  // readable or really closed.
  // TODO(pthatcher): Only peek at TCP descriptors.
  if (readable) {
    if (dispatcher->GetRequestedEvents() & DE_ACCEPT) {
      ff |= DE_ACCEPT;
    } else if (errcode || dispatcher->IsDescriptorClosed()) {
      ff |= DE_CLOSE;
    } else {
      ff |= DE_READ;
    }
  }

  // Check writable descriptors. If we're waiting on a connect, detect
  // success versus failure by the reaped error code.
  if (writable) {
    if (dispatcher->GetRequestedEvents() & DE_CONNECT) {
      if (!errcode) {
        ff |= DE_CONNECT;
      } else {
        ff |= DE_CLOSE;
      }
    } else {
      ff |= DE_WRITE;
    }
  }

  // Tell the descriptor about the event.
  if (ff != 0) {
    dispatcher->OnPreEvent(ff);
    dispatcher->OnEvent(ff, errcode);
  }
}

bool LwipSocketServer::WaitSelect(int cmsWait, bool process_io) {
  // Calculate timing information

  struct timeval* ptvWait = nullptr;
  struct timeval tvWait;
  int64_t stop_us;
  if (cmsWait != kForever) {
    // Calculate wait timeval
    tvWait.tv_sec = cmsWait / 1000;
    tvWait.tv_usec = (cmsWait % 1000) * 1000;
    ptvWait = &tvWait;

    // Calculate when to return
    stop_us = rtc::TimeMicros() + cmsWait * 1000;
  }

  // Zero all fd_sets. Don't need to do this inside the loop since
  // select() zeros the descriptors not signaled

  fd_set fdsRead;
  FD_ZERO(&fdsRead);
  fd_set fdsWrite;
  FD_ZERO(&fdsWrite);
// Explicitly unpoison these FDs on MemorySanitizer which doesn't handle the
// inline assembly in FD_ZERO.
// http://crbug.com/344505
#ifdef MEMORY_SANITIZER
  __msan_unpoison(&fdsRead, sizeof(fdsRead));
  __msan_unpoison(&fdsWrite, sizeof(fdsWrite));
#endif

  fWait_ = true;

  while (fWait_) {
    int fdmax = -1;
    {
      CritScope cr(&crit_);
      // TODO(jbauch): Support re-entrant waiting.
      RTC_DCHECK(!processing_dispatchers_);
      for (Dispatcher* pdispatcher : dispatchers_) {
        // Query dispatchers for read and write wait state
        RTC_DCHECK(pdispatcher);
        if (!process_io && (pdispatcher != signal_wakeup_))
          continue;
        int fd = pdispatcher->GetDescriptor();
        // "select"ing a file descriptor that is equal to or larger than
        // FD_SETSIZE will result in undefined behavior.
        RTC_DCHECK_LT(fd, FD_SETSIZE);
        if (fd > fdmax)
          fdmax = fd;

        uint32_t ff = pdispatcher->GetRequestedEvents();
        if (ff & (DE_READ | DE_ACCEPT))
          FD_SET(fd, &fdsRead);
        if (ff & (DE_WRITE | DE_CONNECT))
          FD_SET(fd, &fdsWrite);
      }
    }

    // Wait then call handlers as appropriate
    // < 0 means error
    // 0 means timeout
    // > 0 means count of descriptors ready
    int n = ::lwip_select(fdmax + 1, &fdsRead, &fdsWrite, nullptr, ptvWait);

    // If error, return error.
    if (n < 0) {
      if (errno != EINTR) {
        RTC_LOG_E(LS_ERROR, EN, errno) << "select";
        return false;
      }
      // Else ignore the error and keep going. If this EINTR was for one of the
      // signals managed by this LwipSocketServer, the
      // PosixSignalDeliveryDispatcher will be in the signaled state in the next
      // iteration.
    } else if (n == 0) {
      // If timeout, return success
      return true;
    } else {
      // We have signaled descriptors
      CritScope cr(&crit_);
      processing_dispatchers_ = true;
      for (Dispatcher* pdispatcher : dispatchers_) {
        int fd = pdispatcher->GetDescriptor();

        bool readable = FD_ISSET(fd, &fdsRead);
        if (readable) {
          FD_CLR(fd, &fdsRead);
        }

        bool writable = FD_ISSET(fd, &fdsWrite);
        if (writable) {
          FD_CLR(fd, &fdsWrite);
        }

        // The error code can be signaled through reads or writes.
        ProcessEvents(pdispatcher, readable, writable, readable || writable);
      }

      processing_dispatchers_ = false;
      // Process deferred dispatchers that have been added/removed while the
      // events were handled above.
      AddRemovePendingDispatchers();
    }

    // Recalc the time remaining to wait. Doing it here means it doesn't get
    // calced twice the first time through the loop
    if (ptvWait) {
      ptvWait->tv_sec = 0;
      ptvWait->tv_usec = 0;
      int64_t time_left_us = stop_us - rtc::TimeMicros();
      if (time_left_us > 0) {
        ptvWait->tv_sec = time_left_us / rtc::kNumMicrosecsPerSec;
        ptvWait->tv_usec = time_left_us % rtc::kNumMicrosecsPerSec;
      }
    }
  }

  return true;
}

}  // namespace orc
