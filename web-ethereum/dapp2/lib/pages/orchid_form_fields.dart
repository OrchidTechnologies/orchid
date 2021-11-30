import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';

class OrchidFormFields {}

class LabeledTokenValueField extends StatelessWidget {
  final TokenValueFieldController controller;
  final TokenType type;
  final String label;
  final double labelWidth;

  LabeledTokenValueField({
    Key key,
    @required this.type,
    @required this.controller,
    @required this.label,
    this.labelWidth,
  }) : super(key: key) {
    controller.type = type;
  }

  @override
  Widget build(BuildContext context) {
    var tokenText = Text(type.symbol ?? "").button.height(1.5);
    return Row(
      children: [
        SizedBox(width: labelWidth ?? 80, child: Text(label).button),
        Flexible(
          child: OrchidTextField(
            hintText: '0.0',
            margin: EdgeInsets.zero,
            controller: controller._textController,
            numeric: true,
          ),
        ),
        // padx(4),
        tokenText,
      ],
    );
  }
}

class TokenValueFieldController implements Listenable {
  final _textController = TextEditingController();
  TokenType type;

  TokenValueFieldController();

  /// Return the value or null if invalid
  Token get value {
    if (type == null) {
      return null;
    }
    var text = _textController.text;
    if (text == null || text == "") {
      return type.zero;
    }
    try {
      var value = double.parse(text);
      return type.fromDouble(value);
    } catch (err) {
      return null;
    }
  }

  void clear() {
    _textController.text = '';
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
