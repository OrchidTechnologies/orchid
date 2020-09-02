import 'dart:async';

import 'package:orchid/api/monitoring/http_unix_client.dart';
import 'package:orchid/api/orchid_types.dart';

import 'package:rxdart/rxdart.dart';
import '../orchid_api.dart';
import '../orchid_log_api.dart';

class OrchidStatus {
  static OrchidStatus _shared = OrchidStatus._init();
  static String socketName = 'orchid.sock';

  /// The app-level tunnel connected state
  /// See also OrchidAPI connectionStatus for the system VPN state.
  final BehaviorSubject<bool> connected = BehaviorSubject.seeded(false);

  Timer _timer;

  OrchidStatus._init();

  void beginPollingStatus() {
    log("status: begin polling status");
    if (OrchidAPI.mockAPI) {
      return;
    }
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(Duration(seconds: 1), _update);
  }

  factory OrchidStatus() {
    return _shared;
  }

  void _update(_) async {
    String socketPath = (await OrchidAPI().groupContainerPath()) + '/' + socketName;
    var client = HttpUnixClient(socketPath);
    try {
      // log("status: checking /connected: client = $client");
      var response = await client.get("/connected");
      bool newConnectionStatus = (response.body ?? "").toLowerCase() == "true";
      //log("status: newConnectionStatus = $newConnectionStatus");
      if (newConnectionStatus != connected.value) {
        log("status: tunnel connection status: $newConnectionStatus");
        connected.add(newConnectionStatus);
      }
      client.close();
    } catch (err) {
      // Log connect attempt errors if we believe the tunnel is alive.
      if (OrchidAPI().vpnConnectionStatus.value == OrchidVPNConnectionState.Connected) {
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
    _timer.cancel();
  }
}
