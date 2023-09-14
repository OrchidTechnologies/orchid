import 'dart:async';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/vpn/monitoring/http_unix_client.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:rxdart/rxdart.dart';

/// Status monitoring from the Orchid VPN extension.
class OrchidRoutingStatus {
  static OrchidRoutingStatus _shared = OrchidRoutingStatus._init();
  static String socketName = 'orchid.sock';

  /// The app-level tunnel connected state indicating whether the extension
  /// has connected to an Orchid server and is ready to send protected traffic.
  final BehaviorSubject<bool> connected = BehaviorSubject.seeded(false);

  Timer? _timer;

  OrchidRoutingStatus._init();

  void beginPollingStatus() {
    log("vpn: begin polling orchid routing status");
    if (OrchidAPI.mockAPI) {
      return;
    }
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(Duration(seconds: 1), _update);
  }

  factory OrchidRoutingStatus() {
    return _shared;
  }

  /// Set the state back to false and trigger a refresh.
  void invalidate() {
    _update(null);
  }

  void _update(_) async {
    String socketPath = (await OrchidAPI().groupContainerPath()) + '/' + socketName;
    var client = HttpUnixClient(socketPath);
    try {
      // log("status: checking /connected: client = $client");
      var response = await client.get(Uri(path: "/connected"));
      bool newConnectionStatus = (response.body ?? "").toLowerCase() == "true";
      //log("status: newConnectionStatus = $newConnectionStatus");
      if (newConnectionStatus != connected.value) {
        log("status: tunnel connection status: $newConnectionStatus");
        connected.add(newConnectionStatus);
      }
      client.close();
    } catch (err) {
      // Log connect attempt errors if we believe the tunnel is alive.
      if (OrchidAPI().vpnExtensionStatus.value == OrchidVPNExtensionState.Connected) {
        log("status: vpn connected but error checking tunnel status: $err");
      }

      // If we can't connect to the socket presume we are not connected.
      if (connected.value) {
        connected.add(false);
      }

      if (client != null) {
        try {
          client.close();
        } catch (err) {}
      }
    }
  }

  void dispose() {
    // silence warnings
    connected.close();
    _timer?.cancel();
  }
}
