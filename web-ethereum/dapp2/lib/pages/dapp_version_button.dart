import 'package:orchid/api/orchid_urls.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/pages/dapp_settings_button.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../orchid/menu/orchid_popup_menu_button.dart';

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
    return OrchidPopupMenuButton(
      width: 48,
      height: 30,
      // offset: Offset(0, widget.contractVersionsAvailable.length * -50.0 - 22.0),
      offset: Offset(0, 2 * -50.0 - 22.0),
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
        return _contractOptionsMenuItems(
            context: context,
            available: widget.contractVersionsAvailable,
            selected: widget.contractVersionSelected,
            // select: widget.selectContractVersion,
            textStyle: _textStyle);
      },
    );
  }

  static List<PopupMenuEntry> _contractOptionsMenuItems({
    @required BuildContext context,
    @required Set<int> available,
    @required int selected,
    @required TextStyle textStyle,
  }) {
    assert(selected < 2);
    List<PopupMenuItem> list = [];
    list.add(
      DappSettingsButtonUtils.listMenuItem(
        context: context,
        textStyle: textStyle,
        selected: false,
        body: Row(
          children: [
            Icon(Icons.launch, color: Colors.white),
            Text("View Contract on Etherscan", style: textStyle).left(12),
          ],
        ),
        onTap: () {
          launchUrlString(selected == 1
              ? OrchidUrls.contractV1EtherscanUrl
              : OrchidUrls.contractV0EtherscanUrl);
        },
      ),
    );
    list.add(
      DappSettingsButtonUtils.listMenuItem(
        context: context,
        textStyle: textStyle,
        selected: false,
        body: Row(
          children: [
            Icon(Icons.launch, color: Colors.white),
            Text("View Contract on Github", style: textStyle).left(12),
          ],
        ),
        onTap: () {
          launchUrlString(selected == 1
              ? OrchidUrls.contractV1GithubUrl
              : OrchidUrls.contractV0GithubUrl);
        },
      ),
    );
    return list;
  }

  Widget _buildTitle() {
    return Center(
      child: Text(widget.contractVersionSelected == 0 ? "V0" : "V1")
          .body1
          .height(1.8),
    );
  }
}
