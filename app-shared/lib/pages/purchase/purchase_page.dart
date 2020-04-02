import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_purchase.dart';
import 'package:orchid/api/orchid_vpn_config.dart';
import 'package:orchid/api/pricing.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/add_hop_page.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/gradients.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:in_app_purchase/store_kit_wrappers.dart';

class PurchasePage extends StatefulWidget {
  final AddFlowCompletion onAddFlowComplete;

  const PurchasePage({Key key, @required this.onAddFlowComplete})
      : super(key: key);

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  Pricing _pricing;
  bool _purchasing = false;
  String _purchasingStatus;

  @override
  void initState() {
    ScreenOrientation.portrait();
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _pricing = await OrchidAPI().pricing().getPricing();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      // TODO: Localize
      title: "Purchase",
      child: buildPage(context),
      lightTheme: true,
    );
  }

  Widget buildPage(BuildContext context) {
    const String bullet = "•";

    return Stack(
      children: <Widget>[
        Padding(
          padding:
              const EdgeInsets.only(left: 30, right: 30, top: 16, bottom: 16),
          child: Column(
            children: <Widget>[
              pady(8),
              _buildInstructions(),
              pady(16),
              _buildPurchaseCardView(
                  pac: OrchidPurchaseAPI.pacTier1,
                  title: "Low Usage",
                  subtitle:
                      "$bullet Internet browsing\n$bullet Low video streaming",
                  gradBegin: 0,
                  gradEnd: 2),
              pady(24),
              _buildPurchaseCardView(
                  pac: OrchidPurchaseAPI.pacTier2,
                  title: "Average Usage",
                  subtitle:
                      "$bullet Internet browsing\n$bullet Moderate video streaming",
                  gradBegin: -2,
                  gradEnd: 1),
              pady(24),
              _buildPurchaseCardView(
                pac: OrchidPurchaseAPI.pacTier3,
                title: "High Usage",
                subtitle: "$bullet Video Streaming / calls\n$bullet Gaming",
                gradBegin: -1,
                gradEnd: -1,
              ),
            ],
          ),
        ),
        if (_purchasing) _progressOverlay()
      ],
    );
  }

  Widget _progressOverlay() {
    Size size = MediaQuery.of(context).size;
    return Center(
        child: Container(
            color: Colors.white60.withOpacity(0.5),
            width: size.width,
            height: size.height,
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                pady(12),
                Text(
                  _purchasingStatus ?? "",
                  style: TextStyle(fontSize: 20),
                )
              ],
            ))));
  }

  Widget _buildInstructions() {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.3,
      fontFamily: "SFProText-Semibold",
    );
    const subtitleStyle = TextStyle(
      color: Colors.grey,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      fontFamily: "SFProText-Semibold",
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text("Choose your purchase", style: titleStyle),
        pady(16),
        Text("Based on your bandwidth usage", style: subtitleStyle),
      ],
    );
  }

  Widget _buildPurchaseCardView(
      {PAC pac,
      String title,
      String subtitle,
      double gradBegin = 0.0,
      double gradEnd = 1.0}) {
    const titleStyle = TextStyle(
        color: Colors.white,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        fontFamily: "SFProText-Semibold",
        height: 22.0 / 17.0);
    const subtitleStyle = TextStyle(
      color: Colors.white,
      fontSize: 13.0,
      fontWeight: FontWeight.w300,
      letterSpacing: 0.5,
      fontFamily: "SFProText-Semibold",
    );
    const valueStyle = TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.38,
        fontFamily: "SFProText-Regular",
        height: 25.0 / 20.0);
    const valueSubtitleStyle = TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        fontFamily: "SFProText-Regular",
        height: 16.0 / 12.0);

    var usdString = pac.displayName;
    var oxtString =
        _pricing?.toOXT(pac.usdPurchasePrice)?.toStringAsFixed(2) ?? "";

    Gradient grad = VerticalLinearGradient(
        begin: Alignment(0.0, gradBegin),
        end: Alignment(0.0, gradEnd),
        colors: [Color(0xff4e71c2), Color(0xff258993)]);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _doSelectPurchase(purchase: pac);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: grad,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Row(
            children: <Widget>[
              // left side usage description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: titleStyle,
                  ),
                  pady(8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.left,
                    style: subtitleStyle,
                  )
                ],
              ),
              Spacer(),

              // right side value display
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(
                  children: <Widget>[
                    Text("$usdString",
                        style:
                            valueStyle.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                pady(2),
                Visibility(
                  visible: _pricing != null,
                  child: Text("~ $oxtString OXT", style: valueSubtitleStyle),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _doSelectPurchase({PAC purchase}) async {
    try {
      setState(() {
        _purchasing = true;
      });
      await _selectPurchase(purchase: purchase);
    } finally {
      setState(() {
        _purchasing = false;
      });
    }
  }

  Future<void> _selectPurchase({PAC purchase}) async {
    print("xxx: purchase: $purchase");

    // Make the purchase and get the store receipt
    // TODO: Localize
    setState(() {
      _purchasingStatus = "Init Purchase";
    });
    String purchaseReceipt;
    try {
      purchaseReceipt = await OrchidPurchaseAPI().purchase(purchase);
    } catch (err) {
      if (err is SKError) {
        var skerror = err as SKError;
        if (skerror.code == OrchidPurchaseAPI.SKErrorPaymentCancelled) {
          print("xxx: user cancelled");
          return null;
        }
      }
      print("xxx: Error in purchase call: $err");
      _purchaseError();
      return null;
    }

    // Submit the receipt to the PAC server and get the account response
    //String pacAccountString = "account = {curator:\"partners.orch1d.eth\", protocol: \"orchid\", funder: \"0x6dd46C5F9f19AB8790F6249322F58028a3185087\", secret: \"86ea93235a2f71fb1f63a100ef182f9dd79afdc4f264eef0eba76966cf6242ff\"};";
    setState(() {
      _purchasingStatus = "Finalize Purchase";
    });
    String pacAccountString;
    try {
      String pacServerRespose = await OrchidPACServer.submit(purchaseReceipt);
      var pacResponseJson = json.decode(pacServerRespose);
      pacAccountString = pacResponseJson['config'];
      if (pacAccountString == null) {
        throw Exception("no config in server response");
      }
    } catch (err) {
      print("xxx: error decoding server response json: $err");
      _purchaseError();
      return null;
    }

    // Parse the account response and create a hop
    setState(() {
      _purchasingStatus = "Set up Account";
    });
    ParseOrchidAccountResult parseAccountResult;
    try {
      var existingKeys = await UserPreferences().getKeys();
      parseAccountResult =
          OrchidVPNConfig.parseOrchidAccount(pacAccountString, existingKeys);
    } catch (err) {
      print("xxx: error parsing purchased orchid account: $err");
      _purchaseError();
    }
    if (parseAccountResult != null) {
      var hop = await OrchidVPNConfig.importAccountAsHop(parseAccountResult);
      widget.onAddFlowComplete(hop);
    } else {
      _purchaseError();
      return null;
    }
  }

  void _purchaseError() {
    Dialogs.showAppDialog(
        context: context,
        // TODO: Localize
        title: "Purchase Error",
        bodyText:
            "There was an error in purchasing.  Please contact Orchid Support.");
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    //_rxSubscriptions.forEach((sub) { sub.cancel(); });
  }

  S get s {
    return S.of(context);
  }
}
