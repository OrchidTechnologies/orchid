import 'package:orchid/common/rounded_rect.dart';
import 'package:orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/orchid/account/account_card.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/util/units.dart';

/// A typed text field for display and entry of a numeric token value.
/// The field has a field label and displays the token symbol as a suffix.
/// The field can optionally display a USD price after the token symbol.
class LabeledTokenValueField extends StatelessWidget {
  final TokenValueFieldController controller;
  final TokenType type;
  final USD usdPrice;
  final String label;
  final double labelWidth;
  final bool enabled;
  final bool readOnly;
  final VoidCallback onClear;
  final String hintText;
  final Widget trailing;

  LabeledTokenValueField({
    Key key,
    @required this.type,
    @required this.controller,
    this.enabled = true,
    this.label,
    this.labelWidth,
    this.onClear,
    this.usdPrice,
    this.readOnly,
    this.hintText,
    this.trailing,
  }) : super(key: key) {
    controller.type = type;
  }

  @override
  Widget build(BuildContext context) {
    return RoundedRect(
      radius: 12,
      backgroundColor: OrchidColors.dark_background_2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label ?? '',
                style: enabled ? OrchidText.body1 : OrchidText.body1.inactive,
              ).top(5).height(24),
              trailing ?? Container(),
            ],
          ),
          TokenValueWidgetRow(
            enabled: enabled,
            context: context,
            child: Expanded(
              child: OrchidTextField(
                contentPadding: EdgeInsets.only(bottom: 12),
                suffixIconPadding: EdgeInsets.zero,
                style: OrchidText.extra_large,
                textAlignVertical: TextAlignVertical.center,
                hintText: hintText ?? '0.0',
                controller: controller._textController,
                numeric: true,
                readOnly: readOnly ?? false,
                enabled: enabled ?? true,
                onClear: onClear,
                border: false,
                cursorHeight: 16,
              ),
            ),
            price: usdPrice,
            tokenAmount: controller.value,
          ),
        ],
      ).pady(8).padx(16),
    );
  }
}

class TokenValueFieldController implements Listenable {
  final _textController = TextEditingController();
  TokenType type;

  TokenValueFieldController();

  /// Return the value, zero if empty, or null if invalid
  Token get value {
    if (type == null) {
      return null;
    }
    final text = _textController.text;
    if (text == null || text == '') {
      return type.zero;
    }
    try {
      var value = double.parse(
        // Allow comma as decimal separator for localization
        text.replaceAll(',', '.'),
      );
      return type.fromDouble(value);
    } catch (err) {
      return null;
    }
  }

  set value(Token value) {
    _textController.text = value.floatValue.toString();
  }

  bool get hasValue {
    final text = _textController.text;
    return text != null && text != '';
  }

  bool get hasNoValue {
    return !hasValue;
  }

  void clear() {
    _textController.clear();
  }

  @override
  void addListener(VoidCallback listener) {
    _textController.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _textController.removeListener(listener);
  }
}
