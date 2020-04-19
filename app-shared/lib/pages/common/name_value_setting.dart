import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/page_tile.dart';

/// A configurable setting widget representing a name-value pair with an optional
/// user readable label and option list of allowed values.
class NameValueSetting extends StatefulWidget {
  // The name of the name-value pair.
  final String name;

  // The value of the name-value pair.
  String initialValue;

  // An optional label for the field.  If null the [name] field will be used.
  String label;

  // An optional list of allowed values for [value].
  final List<String> options;

  // Callback for changes in this value
  Function({String name, String value}) onChanged;

  NameValueSetting(
      {@required this.name, this.initialValue, this.label, this.options, this.onChanged}) {
    // Default to [name] if label is not specified.
    if (label == null) {
      label = name;
    }
    // Default to the first option.
    if (initialValue == null && options != null) {
      initialValue = options[0];
    }
  }

  NameValueSetting cloneWith(Function({String name, String value}) onChanged) {
    return NameValueSetting(
        name: this.name,
        initialValue: this.initialValue,
        label: this.label,
        options: this.options,
        onChanged: onChanged);
  }

  @override
  _NameValueSettingState createState() => _NameValueSettingState();
}

class _NameValueSettingState extends State<NameValueSetting> {
  String _lastValue;
  TextEditingController _controller = TextEditingController();
  FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _lastValue = widget.initialValue;
    _controller.text = widget.initialValue;
    // Save text field values on focus change
    _focus.addListener(() {
      if (!_focus.hasFocus && _controller.text != _lastValue) {
        if (widget.onChanged != null) {
          widget.onChanged(name: widget.name, value: _controller.text);
        }
        _lastValue = _controller.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.options != null &&
        widget.options.contains(widget.initialValue)) {
      return buildChoiceEntry(context);
    } else {
      return buildTextEntry(context);
    }
  }

  Widget buildTextEntry(BuildContext context) {
    return PageTile(
      color: Colors.transparent,
      title: widget.label,
      trailing: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTextField.textFieldEnabledDecoration,
          width: 220,
          height: 36,
          child: TextField(
            controller: _controller,
            decoration: null,
            maxLines: null,
            focusNode: _focus,
          )), onTap: () {},
    );
  }

  Widget buildChoiceEntry(BuildContext context) {
    List<DropdownMenuItem<String>> items = widget.options.map((value) {
      return DropdownMenuItem<String>(child: Text(value), value: value);
    }).toList();

    return PageTile(
      color: Colors.transparent,
      title: widget.label,
      trailing: Container(
        height: 36,
        decoration: AppTextField.textFieldEnabledDecoration,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _lastValue,
            items: items,
            onChanged: (String value) {
              if (value != _lastValue) {
                widget.onChanged(name: widget.name, value: value);
                setState(() {
                  _lastValue = value;
                });
              }
            },
          ),
        ),
      ), onTap: () {},
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
