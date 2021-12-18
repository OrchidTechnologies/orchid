import 'package:flutter/foundation.dart';

/// The connection states of the system VPN facility.
enum OrchidVPNExtensionState {
  Invalid,
  NotConnected,
  Connecting,
  Connected,
  Disconnecting
}

/// The connection states of Orchid routing.
enum OrchidVPNRoutingState {
  VPNNotConnected,
  VPNConnecting,
  VPNConnected,

  // This state indicates that both the system VPN facility and our app extension
  // are reporting the connected state.  The former represents the OS API for
  // managing the VPN extension, the latter is status retrieved over a local socket
  // connection to our running extension.
  OrchidConnected,

  VPNDisconnecting
}
