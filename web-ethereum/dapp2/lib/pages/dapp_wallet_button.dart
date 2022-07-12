import 'dart:ui';

import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/api/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/orchid/orchid_wallet_identicon.dart';

class DappWalletButton extends StatelessWidget {
  final OrchidWeb3Context web3Context;
  final VoidCallback onDisconnect;
  final bool showBalance;
  final VoidCallback onPressed;

  /// If true only the first four chars are shown, else elided first and last four.
  final bool minimalAddress;

  DappWalletButton({
    Key key,
    @required this.web3Context,
    @required this.onDisconnect,
    @required this.showBalance,
    @required this.onPressed,
    this.minimalAddress = false,
  }) : super(key: key);

  final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: RoundedRect(
        borderColor: Colors.white,
        backgroundColor: OrchidColors.new_purple,
        child: _buildTitle(context),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (web3Context == null) {
      return Row(
        children: [
          Text("...").title,
        ],
      );
    }
    final balanceText =
        web3Context.wallet?.balance?.formatCurrency(locale: context.locale);
    var addressText = web3Context.walletAddress.toString(elide: true);
    if (minimalAddress) {
      addressText = addressText.substring(0, 7);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: OrchidWalletIdenticon(address: web3Context.walletAddress),
        ).left(16),
        Text(
          addressText,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: _textStyle,
        ).left(16),
        if (showBalance)
          SizedBox(
            width: 20,
            height: 20,
            child: web3Context.wallet?.balance?.type?.icon ?? padx(20),
          ).left(16),
        if (showBalance)
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
}
