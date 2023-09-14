import 'package:orchid/orchid/orchid.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/account/account_finder.dart';
import 'add_hop_page.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';

typedef HopCompletion = void Function(UniqueHop);

class CircuitUtils {
  // Show the add hop flow and save the result if completed successfully.
  static void addHop(BuildContext context, {required HopCompletion onComplete}) async {
    // Create a nested navigation context for the flow. Performing a pop() from
    // this outer context at any point will properly remove the entire flow
    // (possibly multiple screens) with one appropriate animation.
    Navigator addFlow = Navigator(
      onGenerateRoute: (RouteSettings settings) {
        var addFlowCompletion = (CircuitHop? result) {
          Navigator.pop(context, result);
        };
        var editor = AddHopPage(onAddFlowComplete: addFlowCompletion);
        var route = MaterialPageRoute<CircuitHop>(
            builder: (context) => editor, settings: settings);
        return route;
      },
    );
    var route = MaterialPageRoute<CircuitHop>(
        builder: (context) => addFlow, fullscreenDialog: true);
    _pushNewHopEditorRoute(context, route, onComplete);
  }

  // Push the specified hop editor to create a new hop, await the result, and
  // save it to the circuit.
  // Note: The paradigm here of the hop editors returning newly created or edited hops
  // Note: on the navigation stack decouples them but makes them more dependent on
  // Note: this update and save logic. We should consider centralizing this logic and
  // Note: relying on observation with `OrchidAPI.circuitConfigurationChanged` here.
  // Note: e.g.
  // Note: void _AddHopExternal(CircuitHop hop) async {
  // Note:   var circuit = await UserPreferences().getCircuit() ?? Circuit([]);
  // Note:   circuit.hops.add(hop);
  // Note:   await UserPreferences().setCircuit(circuit);
  // Note:   OrchidAPI().updateConfiguration();
  // Note:   OrchidAPI().circuitConfigurationChanged.add(null);
  // Note: }
  static void _pushNewHopEditorRoute(BuildContext context,
      MaterialPageRoute route, HopCompletion? onComplete) async {
    var hop = await Navigator.push(context, route);
    if (hop == null) {
      return; // user cancelled
    }
    var uniqueHop =
        UniqueHop(hop: hop, key: DateTime.now().millisecondsSinceEpoch);
    addHopToCircuit(uniqueHop.hop);
    if (onComplete != null) {
      onComplete(uniqueHop);
    }
  }

  static Future<void> addHopToCircuit(CircuitHop hop) async {
    var circuit = UserPreferencesVPN().circuit.get()!;
    circuit.hops.add(hop);
    await UserPreferencesVPN().saveCircuit(circuit);
  }

  static Future<bool> defaultCircuitFromMostEfficientAccountIfNeeded(
      Set<Account> accounts) async {
    var sorted = await Account.sortAccountsByEfficiency(accounts);
    if (sorted.isNotEmpty) {
      return await CircuitUtils.defaultCircuitIfNeededFrom(sorted.first);
    }
    return false;
  }

  /// If the circuit is empty create a default single hop circuit using the
  /// supplied account.
  /// Returns true if a circuit was created.
  static Future<bool> defaultCircuitIfNeededFrom(Account? account) async {
    var circuit = UserPreferencesVPN().circuit.get()!;
    if (circuit.hops.isEmpty && account != null) {
      log("circuit: creating default circuit from account: $account");
      await UserPreferencesVPN().saveCircuit(
        Circuit([OrchidHop.fromAccount(account)]),
      );
      return true;
    }
    return false;
  }

  static void showDefaultCircuitCreatedDialog(BuildContext context) {
    final s = context.s;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => AppDialogs.showAppDialog(
        context: context,
        title: s.circuitGenerated,
        bodyText: s.usingYourOrchidAccount,
      ),
    );
  }

  /// As part of new user onboarding we scan for accounts continually until
  /// the first one is found and create a default single hop route from it.
  /*
  Future<void> _scanForAccountsIfNeeded() async {
    // If cached discovered accounts is empty should start the search.
    if ((UserPreferences().cachedDiscoveredAccounts.get()).isNotEmpty) {
      log("connect: Found cached accounts, not starting account finder.");
      return;
    }

    log("connect: No accounts in cache, starting account finder.");
    AccountFinder.shared = AccountFinder()
        .withPollingInterval(Duration(seconds: 20))
        .find((accounts) async {
      var created =
          await CircuitUtils.defaultCircuitFromMostEfficientAccountIfNeeded(
              accounts);
      log("connect: default circuit: $created");
      if (created) {
        CircuitUtils.showDefaultCircuitCreatedDialog(context);
      }
    });
    // As an optimization we listen for PAC purchases and increase the rate
    // UserPreferences().pacTransaction.stream().listen((event) { });
  }
   */

  static Future<void> findAccountsAndDefaultCircuitIfNeeded(
      BuildContext context) async {
    log("connect: No accounts in cache, starting account finder.");
    AccountFinder.shared = AccountFinder()
        .withPollingInterval(Duration(seconds: 20))
        .find(callback: (accounts) async {
      var created =
          await CircuitUtils.defaultCircuitFromMostEfficientAccountIfNeeded(
              accounts);
      log("connect: default circuit: $created");
      if (created) {
        CircuitUtils.showDefaultCircuitCreatedDialog(context);
      }
    });
  }
}
