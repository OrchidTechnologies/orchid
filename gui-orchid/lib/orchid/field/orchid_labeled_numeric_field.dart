import 'package:orchid/orchid/orchid.dart';
import 'package:browser_detector/browser_detector.dart';
import 'package:flutter/services.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/field/value_field_controller.dart';

class OrchidLabeledNumericField extends StatefulWidget {
  final String label;
  final NumericValueFieldController? controller;
  final ValueChanged<double?>? onChange;
  final bool integer;
  final bool enabled;
  final bool showPaste;
  final Color? backgroundColor;

  OrchidLabeledNumericField({
    Key? key,
    required this.label,
    this.controller,
    this.onChange,
    this.integer = false,
    this.enabled = true,
    this.showPaste = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<OrchidLabeledNumericField> createState() =>
      // Either capture the supplied controller or create one statefully.
      _OrchidLabeledNumericFieldState(
          controller ?? NumericValueFieldController());
}

class _OrchidLabeledNumericFieldState extends State<OrchidLabeledNumericField> {
  final NumericValueFieldController controller;

  _OrchidLabeledNumericFieldState(this.controller);

  @override
  Widget build(BuildContext context) {
    final showPaste = widget.showPaste && !BrowserDetector().browser.isFirefox;
    final error = controller.text.isNotEmpty && controller.value == null;

    return OrchidLabeledTextField(
      enabled: widget.enabled,
      error: error,
      label: widget.label,
      controller: controller.textController,
      hintText: widget.integer ? '0' : '0.0',
      numeric: true,
      decimal: !widget.integer,
      onChanged: (_) => _onChange(),
      onClear: _onChange,
      backgroundColor: widget.backgroundColor,
      trailing: showPaste
          ? IconButton(
                  icon: Icon(Icons.paste, color: Colors.white),
                  onPressed: _onPaste)
              .bottom(4)
              .right(4)
          : null,
    );
  }

  void _onPaste() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    controller.text = data?.text ?? '';
  }

  void _onChange() {
    setState(() {});
    widget.onChange?.call(controller.value);
  }
}

class NumericValueFieldController extends ValueFieldController<double> {
  NumericValueFieldController();

  NumericValueFieldController.withListener(VoidCallback listener) {
    this.addListener(listener);
  }

  /// Return the value, or null if empty or invalid
  double? get value {
    final text = textController.text;
    if (text.isEmpty) {
      return null;
    }
    try {
      return double.parse(text);
    } catch (err) {
      return null;
    }
  }

  int? get intValue {
    final text = textController.text;
    if (text.isEmpty) {
      return null;
    }
    try {
      return int.parse(text);
    } catch (err) {
      return null;
    }
  }

  set value(double? value) {
    text = value?.toString() ?? '';
  }
}

