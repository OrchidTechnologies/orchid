import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/services.dart';

class TapToCopyText extends StatefulWidget {
  /// The text to display and copy on tap
  final String text;

  /// Text that overrides what is displayed (e.g. to elide or obfuscate)
  final String? displayText;

  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final EdgeInsets? padding;
  final Widget? displayWidget;

  // Callback to be used in lieu of the default copy functionality
  final void Function(String text)? onTap;
  final void Function(String text)? onLongPress;

  const TapToCopyText(
    this.text, {
    Key? key,
    this.displayText,
    this.displayWidget,
    this.style,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.overflow,
    this.textAlign,
  }) : super(key: key);

  @override
  _TapToCopyTextState createState() => _TapToCopyTextState();

  static copyTextToClipboard(String text) async {
    return Clipboard.setData(ClipboardData(text: text));
  }
}

class _TapToCopyTextState extends State<TapToCopyText> {
  bool _tapped = false;

  String get _display =>
      _tapped ? context.s.copied : (widget.displayText ?? widget.text);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: (widget.displayWidget != null && !_tapped)
          ? widget.displayWidget
          : Padding(
              padding:
                  widget.padding ?? const EdgeInsets.only(top: 16, bottom: 16),
              child: Text(
                _display,
                textAlign: widget.textAlign ?? TextAlign.center,
                overflow: widget.overflow ?? TextOverflow.ellipsis,
                softWrap: false,
                style: widget.style,
              ),
            ),
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!(widget.text);
        } else {
          _doCopy();
        }
      },
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!(widget.text);
        } else {
          _doCopy();
        }
      },
    );
  }

  void _doCopy() async {
    TapToCopyText.copyTextToClipboard(widget.text);
    setState(() {
      _tapped = true;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _tapped = false;
    });
  }
}
