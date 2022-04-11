import 'package:orchid/orchid.dart';
import 'package:orchid/pages/dapp_settings_button.dart';
import 'dapp_header_popup_button.dart';

class DappVersionButton extends StatefulWidget {
  final int contractVersionSelected;
  final void Function(int version) selectContractVersion;
  final Set<int> contractVersionsAvailable;

  DappVersionButton({
    Key key,
    @required this.contractVersionSelected,
    @required this.selectContractVersion,
    @required this.contractVersionsAvailable,
  }) : super(key: key);

  @override
  State<DappVersionButton> createState() => _DappVersionButtonState();
}

class _DappVersionButtonState extends State<DappVersionButton> {
  bool _buttonSelected = false;

  @override
  Widget build(BuildContext context) {
    final _textStyle = OrchidText.medium_16_025.copyWith(height: 2.0);
    return DappHeaderPopupMenuButton(
      width: 48,
      height: 30,
      offset: Offset(0, widget.contractVersionsAvailable.length * -50.0 - 22.0),
      selected: _buttonSelected,
      onSelected: (item) {
        setState(() {
          _buttonSelected = false;
        });
      },
      onCanceled: () {
        setState(() {
          _buttonSelected = false;
        });
      },
      child: _buildTitle(),
      itemBuilder: (itemBuilderContext) {
        setState(() {
          _buttonSelected = true;
        });
        return DappSettingsButtonUtils.contractVersionOptionsMenuItems(
            context: context,
            available: widget.contractVersionsAvailable,
            selected: widget.contractVersionSelected,
            select: widget.selectContractVersion,
            textStyle: _textStyle);
      },
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Text(widget.contractVersionSelected == 0 ? "V0" : "V1")
          .body1
          .height(1.8),
    );
  }
}
