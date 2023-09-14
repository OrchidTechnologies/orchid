import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/orchid/menu/orchid_popup_menu_button.dart';
import 'package:orchid/orchid/orchid_identicon.dart';
import 'package:orchid/dapp/orchid/dapp_wallet_info_panel.dart';

// Head button widget that displays the wallet address and balance.
// When pressed it shows a pop down menu with connection details.
class DappWalletInfoButton extends StatefulWidget {
  final OrchidWeb3Context? web3Context;
  final VoidCallback onDisconnect;
  final bool showBalance;
  final VoidCallback disconnect;

  /// If true only the first four chars are shown, else elided first and last four.
  final bool minimalAddress;

  DappWalletInfoButton({
    Key? key,
    required this.web3Context,
    required this.onDisconnect,
    required this.showBalance,
    this.minimalAddress = false,
    required this.disconnect,
  }) : super(key: key);

  @override
  State<DappWalletInfoButton> createState() => _DappWalletInfoButtonState();
}

class _DappWalletInfoButtonState extends State<DappWalletInfoButton> {
  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
  final _height = 50.0;
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    return OrchidPopupMenuButton<String>(
      height: 40,
      selected: _buttonSelected,
      // backgroundColor: _buttonSelected ? null : widget.backgroundColor,
      onSelected: (String item) {
        setState(() {
          _buttonSelected = false;
        });
      },
      onCanceled: () {
        setState(() {
          _buttonSelected = false;
        });
      },
      itemBuilder: (itemBuilderContext) {
        setState(() {
          _buttonSelected = true;
        });

        return [
          _buildHeaderItem(),
          PopupMenuDivider(height: 1.0),
          PopupMenuItem<String>(
            height: _height,
            onTap: widget.disconnect,
            child: _buildDisconnectButton(),
          ),
        ];
      },
      child: FittedBox(fit: BoxFit.scaleDown, child: buildMain()),
    );
  }

  PopupMenuItem<String> _buildHeaderItem() {
    return PopupMenuItem<String>(
      enabled: false,
      child: DappWalletInfoPanel(web3Context: widget.web3Context),
    );
  }

  Widget buildMain() {
    return RoundedRect(
      borderColor: Colors.white,
      backgroundColor: OrchidColors.new_purple,
      child: _buildTitle(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.web3Context?.walletAddress == null || widget.web3Context?.wallet == null) {
      return Row(
        children: [
          Text("...").title,
        ],
      );
    }
    final balanceText = widget.web3Context!.wallet!.balance?.formatCurrency(locale: context.locale);
    var addressText = widget.web3Context!.walletAddress!.toString(elide: true);
    if (widget.minimalAddress) {
      addressText = addressText.substring(0, 7);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: OrchidIdenticon(address: widget.web3Context!.walletAddress),
        ).left(16),
        Text(
          addressText,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: _textStyle,
        ).left(16),
        if (widget.showBalance)
          SizedBox(
            width: 20,
            height: 20,
            child: widget.web3Context!.wallet!.balance?.type.icon ?? padx(20),
          ).left(16),
        if (widget.showBalance)
          SizedBox(
            width: 108,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: balanceText != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        balanceText,
                        style: _textStyle,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                    )
                  : Container(),
            ),
          ).left(8),
        padx(16),
      ],
    );
  }

  Widget _buildDisconnectButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.power_settings_new_rounded, color: Colors.white),
        Text(
          "Disconnect",
          style: _textStyle,
        ).left(8).top(8),
      ],
    );
  }
}
