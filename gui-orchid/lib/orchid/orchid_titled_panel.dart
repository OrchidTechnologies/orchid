import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/orchid_panel.dart';

class OrchidTitledPanel extends StatelessWidget {
  final Widget title;
  final Widget body;
  final bool highlight;
  final bool opaque;

  OrchidTitledPanel({
    Key? key,
    required String titleText,
    required Widget body,
    VoidCallback? onBack,
    VoidCallback? onDismiss,
    bool highlight = true,
    bool opaque = true,
  }) : this.title(
          title: OrchidTitledPanelTitle(
              titleText: titleText, onBack: onBack, onDismiss: onDismiss),
          body: body,
          highlight: highlight,
          opaque: opaque,
        );

  OrchidTitledPanel.title({
    Key? key,
    required this.title,
    required this.body,
    this.highlight = true,
    this.opaque = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return opaque ? _buildOpaquePanel() : _buildPanel();
  }

  Container _buildOpaquePanel() {
    return Container(
      color: Colors.black,
      child: Container(
        color: OrchidColors.dark_background.withOpacity(0.25),
        child: _buildPanel(),
      ),
    );
  }

  Widget _buildPanel() {
    return OrchidPanel(
      highlight: highlight,
      child: AnimatedSize(
          alignment: Alignment.topCenter,
          duration: millis(250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              title,
              Flexible(child: SingleChildScrollView(child: body)),
            ],
          )),
    );
  }
}

class OrchidTitledPanelTitle extends StatelessWidget {
  final String titleText;
  final VoidCallback? onBack;
  final VoidCallback? onDismiss;

  const OrchidTitledPanelTitle({
    Key? key,
    required this.titleText,
    this.onBack,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = OrchidText.title.withHeight(2.0);
    return Opacity(
      opacity: 0.99,
      child: Container(
        width: double.infinity,
        height: 52,
        color: Colors.white.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            (onBack != null
                    ? IconButton(
                        onPressed: onBack,
                        icon: Icon(Icons.chevron_left),
                        color: Colors.white,
                      )
                    : Container())
                .width(48),
            Flexible(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(titleText).withStyle(style))),
            (onDismiss != null
                    ? IconButton(
                        onPressed: onDismiss,
                        icon: Icon(Icons.close),
                        color: Colors.white,
                      )
                    : Container())
                .width(48),
          ],
        ),
      ),
    );
  }
}
