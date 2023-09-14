import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef WrappedSwitchCallback = void Function(bool status);

class WrappedSwitchController {
  // The value published by the containing view and subscribed to by the switch.
  // This allows programmatic control of the switch.
  WrappedSwitchValueNotifier controlledState;

  // Callback indicating that a user interaction has changed the switch value.
  // This allows observation of user input actions driving the switch.
  // Note: We could use another ValueNotifier here but there would then be
  // Note: ambiguity between the controlled and user driven values.
  WrappedSwitchCallback? onChange;

  WrappedSwitchController({bool initialValue = false})
      : this.controlledState = WrappedSwitchValueNotifier(initialValue);
}

class WrappedSwitch extends StatefulWidget {
  final WrappedSwitchController controller;

  const WrappedSwitch({Key? key, required this.controller}) : super(key: key);

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
    widget.controller.controlledState.addListener(_controlledValueChanged);
  }

  // The desired switch state specified by the containing view changed
  void _controlledValueChanged() {
    print("switch value changed");
    setState(() {
      _switchKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    //print("building switch with value: ${widget.controller.controlledState.value}, key=$_switchKey");
    return Switch(
      key: Key(_switchKey.toString()),
      activeColor: Colors.deepPurple,
      value: widget.controller.controlledState.value,
      onChanged: widget.controller.onChange,
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.controlledState.removeListener(_controlledValueChanged);
  }
}

/// This is just a ValueNotifier that fires on every set rather than comparing
/// new values for equality first.
class WrappedSwitchValueNotifier extends ChangeNotifier
    implements ValueListenable<bool> {
  bool _value;

  WrappedSwitchValueNotifier(this._value);

  @override
  bool get value => _value;

  set value(bool newValue) {
    _value = newValue;
    notifyListeners();
  }
}
