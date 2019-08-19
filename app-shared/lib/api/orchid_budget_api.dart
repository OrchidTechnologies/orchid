import 'dart:async';
import 'dart:math';
import 'package:orchid/api/etherscan_io.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'orchid_api.dart';

// Placeholder API for funds and budgeting
class OrchidBudgetAPI {
  static OrchidBudgetAPI _shared = OrchidBudgetAPI._init();

  /// The latest N funding events for the user's primary pot address.
  BehaviorSubject<List<LotteryPotUpdateEvent>> events = BehaviorSubject();

  /// A total balance in OXT of the user's funded lottery pots.
  Observable<double> balance;

  Timer _pollTimer;

  OrchidBudgetAPI._init() {
    this.balance = events.map((events) {
      return (events != null && events.length > 0) ? events.first.balance : 0.0;
    });
  }

  factory OrchidBudgetAPI() {
    return _shared;
  }

  void applicationReady() {
    // Inactive
    return;

    // On first launch, generate the user's primary lottery pot keypair.
    UserPreferences().getLotteryPotsPrimaryAddress().then((String address) {
      if (address == null) {
        // TODO: Generating a fake random pot address.
        var address = OrchidBudgetAPI._generateFakeRandomPotAddress();
        UserPreferences().setLotteryPotsPrimaryAddress(address);
        OrchidAPI().logger().write("First Launch. Generated primary lottery pot address: $address");
      } else {
        OrchidAPI().logger().write("Primary lottery pot address: $address");
        poll();
      }
    });

    _pollTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      poll();
    });
  }

  /// Prompt an update of the lottery pot events and balance.
  Future<bool> poll() async {
    OrchidAPI().logger().write("polling lottery pot events...");
    String potAddress = await getLotteryPotsPrimaryAddress();
    var potEvents = await EtherscanIO.getLotteryPotUpdateEvents(potAddress);
    OrchidAPI().logger().write("got pot events: ${potEvents.length}");
    events.add(potEvents);
    return true;
  }

  Future<String> getLotteryPotsPrimaryAddress() async {
    return UserPreferences().getLotteryPotsPrimaryAddress();
  }

  Future<String> getFundingURL() async {
    String potAddress = await getLotteryPotsPrimaryAddress();
    if (potAddress.startsWith("0x")) {
      potAddress = potAddress.substring(2);
    }
    return "http://pat.net/orchid?pot=$potAddress&amount=2";
  }

  // TODO: Generating a fake random pot address.
  static String _generateFakeRandomPotAddress() {
    String sb = "0x";
    var rand = Random(DateTime.now().millisecondsSinceEpoch);
    for (var i=0; i<40; i++) {
      sb += "0123456789ABCDEF"[rand.nextInt(16)];
    }
    return sb;
  }

  // Currently unused
  void dispose() {
    _pollTimer.cancel();
  }

}

