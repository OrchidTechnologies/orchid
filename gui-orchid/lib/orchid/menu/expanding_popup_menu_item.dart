import 'package:orchid/orchid/orchid.dart';

class ExpandingPopupMenuItem extends StatelessWidget {
  final bool expanded;
  final String title;
  final String? currentSelectionText;
  final double expandedHeight;
  final Widget expandedContent;
  final TextStyle textStyle;
  final double collapsedHeight;

  const ExpandingPopupMenuItem({
    Key? key,
    required this.expanded,
    required this.title,
    this.currentSelectionText,
    required this.expandedHeight,
    required this.expandedContent,
    required this.textStyle,
    this.collapsedHeight = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: collapsedHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: textStyle),
              Row(
                children: [
                  if (currentSelectionText != null)
                    Text(currentSelectionText ?? '', style: textStyle).right(8),
                  Icon(expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: Colors.white),
                ],
              ),
            ],
          ),
        ),
        AnimatedContainer(
          height: expanded ? expandedHeight : 0,
          duration: Duration(milliseconds: 250),
          child: expanded
              ? SingleChildScrollView(child: expandedContent)
              : Container(),
        ),
      ],
    );
  }
}

