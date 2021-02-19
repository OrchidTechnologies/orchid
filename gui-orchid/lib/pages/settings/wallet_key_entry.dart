import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:rxdart/rxdart.dart';

/// A controller for the [WalletKeyEntry] supporting observation of validation
/// and triggering of save functionality.
class WalletKeyEntryController {
  BehaviorSubject<bool> readyToSave = BehaviorSubject<bool>.seeded(false);
  Future<bool> Function() save;

  void dispose() {
    readyToSave.close();
  }
}

/// A Text field customized for pasting or scanning a wallet private key and
/// interacting with the Orchid API.  Use [WalletKeyEntryController] to
/// observe the state of input validation and trigger the save operation
/// (e.g. in support of an external "save" button)
class WalletKeyEntry extends StatefulWidget {
  final WalletKeyEntryController controller;

  WalletKeyEntry({@required this.controller});

  @override
  _WalletKeyEntryState createState() => _WalletKeyEntryState();
}

class _WalletKeyEntryState extends State<WalletKeyEntry> {
  /// If non-null represents the currently saved wallet.
  OrchidWalletPublic _walletPublic;

  /// If non-null represents transient storage of a user-entered private key.
  /// This field is cleared after the data is passed to the API for storage.
  OrchidWalletPrivate _walletPrivate;

  var _textController = TextEditingController();
  var _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    widget.controller.save = _save;

    _focusNode.addListener(() {
      setState(() {}); // trigger UI update on focus change
    });

    OrchidAPI().getWallet().then((OrchidWalletPublic wallet) {
      setState(() {
        this._walletPublic = wallet;
      });
    });
  }

  /// Create the text field with QR scanning option for the private key.
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Color(0xfffbfbfe),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Color(0xffd5d7e2), width: 2.0)),
        height: 58,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  obscureText: false,
                  controller: _textController,
                  autocorrect: false,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: (_walletPublic == null || _focusNode.hasFocus)
                          ? "Paste private key here"
                          : "Linked Wallet: ${_walletPublic.id}",
                      hintStyle: AppText.textHintStyle),
                  onChanged: _keyTextChanged,
                  focusNode: _focusNode,
                ),
              ),
            ),
            Container(
                margin: EdgeInsets.only(right: 13.0),
                child: Image(image: AssetImage("assets/images/scan.png")))
          ],
        ));
  }

  // TODO:
  bool _keyTextValid(String text) {
    return text != null && text.length > 3;
  }

  bool _keyTextChanged(String text) {
    var valid = _keyTextValid(text);
    _walletPrivate = valid ? OrchidWalletPrivate(privateKey: text) : null;
    widget.controller.readyToSave.add(valid);
  }

  Future<bool> _save() async {
    assert(_walletPrivate != null);

    // dismiss the keyboard if present
    FocusScope.of(context).requestFocus(FocusNode());

    // Save the wallet
    var public = OrchidWalletPublic(
        _walletPrivate.privateKey.substring(0, 3) + "xxx...");
    var wallet = OrchidWallet(public: public, private: _walletPrivate);

    return OrchidAPI().setWallet(wallet).then((bool success) {
      // Update the UI
      setState(() {
        _textController.clear();
        _walletPrivate = null;
        widget.controller.readyToSave.add(false);
        if (success) {
          _walletPublic = public;
        }
      });
      // Chain the success future to the dialog completion.
      if (success) {
        //return _showWalletLinkedDialog(context).then((_) { return true; });
        return true;
      } else {
        return _showWalletLinkFailedDialog(context).then((_) {
          return false;
        });
      }
    });
  }

  static Future<void> _showWalletLinkedDialog(@required BuildContext context) {
    return AppDialogs.showAppDialog(
        context: context,
        title: "Wallet linked!",
        bodyText:
            "Your linked wallet will be used to pay for bandwidth on Orchid.");
  }

  static Future<void> _showWalletLinkFailedDialog(
      @required BuildContext context) {
    return AppDialogs.showAppDialog(
        context: context,
        title: "Whoops!",
        bodyText:
            "Orchid was unable to connect to an Ethereum wallet using the private key you provided.\n\nPlease check and make sure the information you entered was correct.");
  }
}
