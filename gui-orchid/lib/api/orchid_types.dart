import 'package:flutter/foundation.dart';
import 'package:orchid/util/ip_address.dart';
import 'package:orchid/util/location.dart';

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

/// A route through the Orchid network comprising one or more nodes.
@immutable
class OrchidRoute {
  final List<OrchidNode> nodes;

  OrchidRoute(this.nodes);
}

/// A node in the Orchid network.
@immutable
class OrchidNode {
  final IPAddress ip;
  final Location location;

  OrchidNode({this.ip, this.location});
}

/// Represents the physical location of a node in the Orchid network.
@immutable
class OrchidNodeLocation {
  // TODO
}

/// User visible information for a configured wallet.
class OrchidWalletPublic {
  // A user visible identifier for this wallet.
  final String id;

  OrchidWalletPublic(this.id);
}

/// Information comprising the private portion of a wallet.
@immutable
class OrchidWalletPrivate {
  final String privateKey;

  OrchidWalletPrivate({this.privateKey});
}

/// Information comprising a wallet.
@immutable
class OrchidWallet {
  final OrchidWalletPrivate private;
  final OrchidWalletPublic public;

  OrchidWallet({this.private, this.public});
}

/// User visible information for a configured VPN configuration.
@immutable
class VPNConfigPublic {
  // A user visible identifier for this VPN
  String id;

  // The user login name
  String userName;

  // A full vpn configuration file or null if no configuration is required.
  String vpnConfig;

  VPNConfigPublic({this.id, this.userName, this.vpnConfig});
}

/// Information comprising the private portion of an external VPN configuration.
class VPNConfigPrivate {
  // The user login password.
  String userPassword;

  VPNConfigPrivate({this.userPassword});
}

/// Information comprising a user provided external VPN configuration.
class VPNConfig {
  VPNConfigPrivate private;
  VPNConfigPublic public;

  VPNConfig({this.private, this.public});
}
