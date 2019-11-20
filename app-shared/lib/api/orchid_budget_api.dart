import 'dart:async';
import 'dart:math';
import 'package:orchid/api/etherscan_io.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/util/units.dart';
import 'package:rxdart/rxdart.dart';
import 'orchid_api.dart';

// Placeholder API for funds and budgeting
class OrchidBudgetAPI {
  // Development time feature flag for the budget functionality
  // Remove when features are complete.
  static const bool featureEnabled = false;

  static OrchidBudgetAPI _shared = OrchidBudgetAPI._init();

  /// The latest N funding events for the user's primary pot address.
  BehaviorSubject<List<LotteryPotUpdateEvent>> fundingEvents =
      BehaviorSubject();

  /// A total balance in OXT of the user's funded lottery pots.
  Observable<LotteryPot> potStatus;

  Timer _pollTimer;

  OrchidBudgetAPI._init() {
    this.potStatus = fundingEvents.map((events) {
      return (events != null && events.length > 0)
          ? LotteryPot(
              deposit: events.first.escrow, balance: events.first.balance)
          : LotteryPot(deposit: OXT(0), balance: OXT(0));
    });
  }

  factory OrchidBudgetAPI() {
    return _shared;
  }

  void applicationReady() async {
    if (!OrchidBudgetAPI.featureEnabled) {
      return;
    }

    // On first launch, generate the user's primary lottery pot keypair.
    UserPreferences().getLotteryPotsPrimaryAddress().then((String address) {
      if (address == null) {
        // TODO: Generating a fake random pot address.
        var address = OrchidBudgetAPI._generateFakeRandomPotAddress();
        UserPreferences().setLotteryPotsPrimaryAddress(address);
        OrchidAPI().logger().write(
            "First Launch. Generated primary lottery pot address: $address");
      } else {
        OrchidAPI().logger().write("Primary lottery pot address: $address");
        poll();
      }
    });

    _pollTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      poll();
    });
  }

  /// Prompt an update of the lottery pot events and balance.
  Future<bool> poll() async {
    OrchidAPI().logger().write("polling lottery pot events...");
    String signerAddress = await getSignerKey();
    var potEvents = await EtherscanIO.getLotteryPotUpdateEvents(signerAddress);
    OrchidAPI().logger().write("got pot events: ${potEvents.length}");
    fundingEvents.add(potEvents);
    return true;
  }

  Future<String> getSignerKey() async {
    // TODO:
    if (OrchidAPI.mockAPI) {
      return "A3D8F4933B73DACC0702C52503D0DC6BDE0984DA";
    }
    return UserPreferences().getLotteryPotsPrimaryAddress();
  }

  Future<String> getFundingURL({OXT amount, OXT deposit}) async {
    String potAddress = await getSignerKey();
    // Remove hex prefix which, while valid, causes issues in some browsers.
    if (potAddress.startsWith("0x")) {
      potAddress = potAddress.substring(2);
    }
    const hosting = "http://pat.net/orchid/"; // TODO:
    return "$hosting?pot=$potAddress&amount=$amount&escrow=$deposit";
  }

  /// Get the current budget or null if none is defined.
  Future<Budget> getBudget() async {
    Budget userBudget = await UserPreferences().getBudget();
    if (userBudget == null) {
      // Temporary: always return the recommended budget.
      // We should probably return null and let the UI decide.
      return (await getBudgetRecommendations()).recommended;
    }
    return userBudget;
  }

  /// Set the current budget
  Future<bool> setBudget(Budget budget) async {
    return UserPreferences().setBudget(budget);
  }

  /// Return recommended budget configurations for low, average, and high usage.
  Future<BudgetRecommendation> getBudgetRecommendations() async {
    return BudgetRecommendation(
      lowUsage:
          Budget(deposit: OXT(10.0), spendRate: OXT(2.50), term: Months(1)),
      averageUsage:
          Budget(deposit: OXT(10.0), spendRate: OXT(5.00), term: Months(1)),
      highUsage:
          Budget(deposit: OXT(10.0), spendRate: OXT(10.00), term: Months(1)),

      // TODO: Recommendation should be based on user history.
      recommended:
          Budget(deposit: OXT(10.0), spendRate: OXT(5.00), term: Months(1)),
    );
  }

  // TODO: Generating a fake random pot address.
  static String _generateFakeRandomPotAddress() {
    String sb = "0x";
    var rand = Random(DateTime.now().millisecondsSinceEpoch);
    for (var i = 0; i < 40; i++) {
      sb += "0123456789ABCDEF"[rand.nextInt(16)];
    }
    return sb;
  }

  // Currently unused
  void dispose() {
    _pollTimer.cancel();
  }
}

/// Lottery pot balance and deposit amounts.
class LotteryPot {
  OXT deposit;
  OXT balance;

  LotteryPot({this.deposit, this.balance});
}

/// A budget representing a deposit, spend rate, and term.
class Budget {
  OXT deposit;
  OXT spendRate; // OXT per Month
  Months term;

  Budget({this.deposit, this.spendRate, this.term});

  Budget.fromJson(Map<String, dynamic> json)
      : deposit = OXT(json['deposit']),
        spendRate = OXT(json['spendRate']),
        term = Months(json['term']);

  Map<String, dynamic> toJson() => {
        'deposit': deposit.value,
        'spendRate': spendRate.value,
        'term': term.value
      };

  bool operator ==(o) =>
      o is Budget &&
      o.deposit == deposit &&
      o.spendRate == spendRate &&
      o.term == term;

// todo: hash
}

/// A set of recommended budgets including low, average, and high usage scenarios
/// as well as a custom budget recommendation based on the user's history.
class BudgetRecommendation {
  final Budget lowUsage;
  final Budget averageUsage;
  final Budget highUsage;
  final Budget recommended;

  const BudgetRecommendation(
      {this.lowUsage, this.averageUsage, this.highUsage, this.recommended});
}
