import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'orchid_web3_stake_v0.dart';

class StakeDetailPoller extends ChangeNotifier {
  final OrchidWeb3Context web3Context;
  final EthereumAddress stakee;
  final EthereumAddress staker; // wallet

  // The total stake staked for the stakee by all stakers.
  Token? currentStakeTotal;

  // The amount and delay staked for the stakee by the current staker (wallet).
  StakeResult? currentStakeStaker;

  // The amount and expiration of the pulled stake pending withdrawal for the first n indexes.
  List<StakePendingResult>? currentStakePendingStaker;

  // Manage polling state
  static int nextId = 0;
  final int id;
  final Duration pollingPeriod;
  Timer? _timer;
  bool _pollInProgress = false;
  bool _isCancelled = false;
  DateTime? lastUpdate;

  StakeDetailPoller({
    required this.web3Context,
    required this.staker,
    required this.stakee,
    this.pollingPeriod = const Duration(seconds: 30),
  }) : this.id = nextId++ {
    log("XXX: StakeDetailPoller $id created.");
  }

  /// Start periodic polling
  Future<void> startPolling() async {
    _timer = Timer.periodic(pollingPeriod, (_) {
      _pollStake();
    });
    return _pollStake(); // kick one off immediately
  }

  /// Load data once
  Future<void> pollOnce() async {
    return _pollStake();
  }

  /// Load data updating caches
  Future<void> refresh() async {
    return _pollStake(refresh: true);
  }

  Future<void> _pollStake({bool refresh = false}) async {
    if (_isCancelled || _pollInProgress) {
      log("XXX: call to _pollStake with cancelled timer or poll in progress, pollInProgress=$_pollInProgress");
      return;
    }
    _pollInProgress = true;
    try {
      await _pollStakeImpl(refresh);
    } catch (err) {
      log("Error polling stake details: $err");
    } finally {
      _pollInProgress = false;
      lastUpdate = DateTime.now();
    }
  }

  // 'refresh' can be used to defeat caching, if any.
  Future<void> _pollStakeImpl(bool refresh) async {
    final orchidWeb3 = OrchidWeb3StakeV0(web3Context);

    // Get the total stake for all stakers (heft)
    try {
      currentStakeTotal = await orchidWeb3.orchidGetTotalStake(stakee);
      log("XXX: heft = $currentStakeTotal");
    } catch (err) {
      log("Error getting heft for stakee: $err");
      currentStakeTotal = null;
    }
    this.notifyListeners();

    // Get the stake for this staker (wallet)
    try {
      currentStakeStaker = await orchidWeb3.orchidGetStakeForStaker(
        staker: staker,
        stakee: stakee,
      );
      log("XXX: staker stake = $currentStakeStaker");
    } catch (err, stack) {
      log("Error getting stake for staker: $err");
      log(stack.toString());
      currentStakeStaker = null;
    }
    this.notifyListeners();

    // Get the pending stake withdrawals for this staker (wallet)
    try {
      List<StakePendingResult> pendingList = [];
      for (var i = 0; i < 3; i++) {
        final pending = await orchidWeb3.orchidGetPendingWithdrawal(
          staker: staker,
          index: i,
        );
        pendingList.add(pending);
      }
      currentStakePendingStaker = pendingList;
      log("XXX: pending = $currentStakePendingStaker");
    } catch (err, stack) {
      log("Error getting stake for staker: $err");
      log(stack.toString());
      currentStakePendingStaker = null;
    }
    this.notifyListeners();
  }

  void cancel() {
    _isCancelled = true;
    _timer?.cancel();
    log("XXX: stake detail $id poller cancelled");
  }

  void dispose() {
    cancel();
    super.dispose();
  }

  @override
  String toString() {
    return 'StakeDetailPoller{id: $id, stakee: $stakee, staker: $staker, currentStakeTotal: $currentStakeTotal, currentStakeStaker: $currentStakeStaker, currentStakePendingStaker: $currentStakePendingStaker}';
  }
}

