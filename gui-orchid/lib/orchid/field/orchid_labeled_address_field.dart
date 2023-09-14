import 'package:orchid/orchid/orchid.dart';
import 'package:browser_detector/browser_detector.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/field/value_field_controller.dart';

class OrchidLabeledAddressField extends StatefulWidget {
  final String label;
  final AddressValueFieldController? controller;
  final ValueChanged<EthereumAddress?>? onChange;
  final EdgeInsets? contentPadding;
  final bool enabled;

  OrchidLabeledAddressField({
    Key? key,
    required this.label,
    this.controller,
    this.onChange,
    this.contentPadding,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<OrchidLabeledAddressField> createState() =>
      // Either capture the supplied controller or create one statefully.
      _OrchidLabeledAddressFieldState(
          controller ?? AddressValueFieldController());
}

class _OrchidLabeledAddressFieldState extends State<OrchidLabeledAddressField> {
  final AddressValueFieldController controller;

  _OrchidLabeledAddressFieldState(this.controller);

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
  }

  @override
  Widget build(BuildContext context) {
    final showPaste = !BrowserDetector().browser.isFirefox;
    final error = controller.text.isNotEmpty && controller.value == null;

    return OrchidLabeledTextField(
      enabled: widget.enabled,
      error: error,
      label: widget.label,
      controller: controller.textController,
      hintText: '0x...',
      contentPadding: widget.contentPadding,
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

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }
}

/// Manages an Ethereum Address
class AddressValueFieldController
    extends ValueFieldController<EthereumAddress> {
  AddressValueFieldController();

  AddressValueFieldController.withListener(VoidCallback listener) {
    this.addListener(listener);
  }

  /// Return the value, or null if empty or invalid
  EthereumAddress? get value {
    final text = textController.text;
    if (text.isEmpty) {
      return null;
    }
    try {
      return EthereumAddress.from(text);
    } catch (err) {
      return null;
    }
  }

  set value(EthereumAddress? value) {
    text = value?.toString(prefix: true, elide: false) ?? '';
  }
}
