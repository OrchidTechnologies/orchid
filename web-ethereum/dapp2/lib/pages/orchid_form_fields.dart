import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/util/localization.dart';
import 'package:orchid/util/units.dart';

/// A typed text field for display and entry of a numeric token value.
/// The field has a prefix label and displays the token symbol as a suffix.
/// The field can optionally display a USD price after the token symbol.
class LabeledTokenValueField extends StatelessWidget {
  final TokenValueFieldController controller;
  final TokenType type;
  final USD usdPrice;
  final String label;
  final double labelWidth;
  final bool enabled;
  final VoidCallback onClear;

  LabeledTokenValueField({
    Key key,
    @required this.type,
    @required this.controller,
    this.label,
    this.enabled,
    this.labelWidth,
    this.onClear,
    this.usdPrice,
  }) : super(key: key) {
    controller.type = type;
  }

  @override
  Widget build(BuildContext context) {
    final usdValue = (usdPrice != null && controller.value != null)
        ? USD(controller.value.floatValue * usdPrice.value)
        : null;
    final usdText = usdValue != null
        ? "(${usdValue.formatCurrency(locale: context.locale)} USD)"
        : null;

    return Row(
      children: [
        // label
        SizedBox(width: labelWidth ?? 80, child: Text(label ?? '').button),

        // text field
        Flexible(
          child: OrchidTextField(
            hintText: '0.0',
            margin: EdgeInsets.zero,
            controller: controller._textController,
            numeric: true,
            enabled: enabled ?? true,
            onClear: onClear,
          ),
        ),

        // token symbol suffix
        Text(type.symbol ?? '').button, //.height(1.5),

        // USD price annotation
        if (usdText != null)
          SizedBox(
            width: 130,
            child: Text(
              usdText ?? '',
              overflow: TextOverflow.visible,
              softWrap: false,
            ).button.left(8),
          )
      ],
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
