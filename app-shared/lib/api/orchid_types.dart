import 'package:flutter/foundation.dart';
import 'package:orchid/util/ip_address.dart';

/// Physical layer level network connectivity type.
enum NetworkConnectivityType { Unknown, Wifi, Mobile, NoConnectivity }

/// The connection states of the Orchid network client.
enum OrchidConnectionState { NotConnected, Connecting, Connected }

/// The synchronization states of the Orchid network client.
enum OrchidSyncState { Required, InProgress, Complete }

/// The current status and progress (if indicated) of synchronization of the Orchid network client.
@immutable
class OrchidSyncStatus {
  final OrchidSyncState state;
  final double progress;

  // A value from 0.0 - 1.0 indicating sync progress
  OrchidSyncStatus({@required this.state, @required this.progress});
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
  final OrchidNodeLocation location;

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

