
import 'package:flutter/material.dart';
import '../app_colors.dart';

typedef WrappedSwitchCallback = void Function(bool status);

class WrappedSwitchController {
  // The value published by the containing view and subscribed to by the switch.
  ValueNotifier<bool> controlledState;

  // Callback to indicate user interactive state change to the containing view.
  // Note: We could use another ValueNotifier here but the meaning of the value 
  // Note: after firing would be ambiguous.
  WrappedSwitchCallback onChange;

  WrappedSwitchController({bool initialValue = false}) {
    this.controlledState = ValueNotifier<bool>(initialValue);
  }
}

class WrappedSwitch extends StatefulWidget {
  final WrappedSwitchController controller;

  const WrappedSwitch({Key key, this.controller}) : super(key: key);
  @override
  _WrappedSwitchState createState() => _WrappedSwitchState();
}

class _WrappedSwitchState extends State<WrappedSwitch> {

  // Workaround for dragged switch state issue
  // https://github.com/flutter/flutter/issues/46046
  int _switchKey = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.controlledState.addListener(_valueChanged);
  }

  // The desired switch state specified by the containing view changed
  void _valueChanged() {
    setState(() {
      _switchKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
        key: Key(_switchKey.toString()),
        activeColor: AppColors.purple_5,
        value: widget.controller.controlledState.value,
        onChanged: widget.controller.onChange
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.controlledState.removeListener(_valueChanged);
  }
}

