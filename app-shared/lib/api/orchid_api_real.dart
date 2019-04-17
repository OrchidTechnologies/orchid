import 'dart:async';

import 'package:flutter/services.dart';

import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/util/ip_address.dart';

import 'package:rxdart/rxdart.dart';

class RealOrchidAPI implements OrchidAPI {
    static final RealOrchidAPI _singleton = RealOrchidAPI._internal();
    static const _platform = const MethodChannel("orchid.com/feedback");

    factory RealOrchidAPI() {
	return _singleton;
    }

    RealOrchidAPI._internal() {
	_platform.setMethodCallHandler((MethodCall call) async {
	    switch (call.method) {
		case 'status':
                    switch (call.arguments) {
                        case 'Invalid':
                            connectionStatus.add(OrchidConnectionState.NotConnected);
                            break;
                        case 'Disconnected':
                            connectionStatus.add(OrchidConnectionState.NotConnected);
                            break;
                        case 'Connecting':
                            connectionStatus.add(OrchidConnectionState.Connecting);
                            break;
                        case 'Connected':
                            connectionStatus.add(OrchidConnectionState.Connected);
                            break;
                        case 'Disconnecting':
                            connectionStatus.add(OrchidConnectionState.NotConnected);
                            break;
                        case 'Reasserting':
                            connectionStatus.add(OrchidConnectionState.Connecting);
                            break;
                    }
                break;

                case 'route':
                    routeStatus.add(call.arguments.map((route) => OrchidNode(
                        ip: IPAddress(route),
                        location: OrchidNodeLocation(),
                    )).toList());
                break;
	    }
        });

	networkingPermissionStatus.add(true);
    }

    final connectionStatus = BehaviorSubject<OrchidConnectionState>();
    final syncStatus = BehaviorSubject<OrchidSyncStatus>();
    final routeStatus = BehaviorSubject<OrchidRoute>();
    final networkingPermissionStatus = BehaviorSubject<bool>();
    final log = PublishSubject<String>();

    @override
    Future<bool> requestVPNPermission() {
        return Future<bool>.value(true);
    }

    Future<void> revokeVPNPermission() async { }

    @override
    Future<bool> setWallet(OrchidWallet wallet) {
        return Future<bool>.value(false);
    }

    @override
    Future<void> clearWallet() async { }


    @override
    Future<OrchidWalletPublic> getWallet() {
        return Future<OrchidWalletPublic>.value(null);
    }

    @override
    Future<bool> setExitVPNConfig(VPNConfig vpnConfig) {
        return Future<bool>.value(false);
    }

    @override
    Future<VPNConfigPublic> getExitVPNConfig() {
        return Future<VPNConfigPublic>.value(null);
    }

    @override
    Future<void> setLogging(bool enabled) async {
    }

    @override
    Future<void> setConnected(bool connect) async {
        if (connect)
            await _platform.invokeMethod('connect');
        else
            await _platform.invokeMethod('disconnect');
    }

    @override
    Future<void> reroute() async {
        await _platform.invokeMethod('reroute');
    }
}
