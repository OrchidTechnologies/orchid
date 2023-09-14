import 'package:orchid/orchid/orchid.dart';

/// A text editing controller that manages a typed value
abstract class ValueFieldController<T> {
  final textController = TextEditingController();

  T? get value;

  set value(T? value);

  String get text => textController.text;

  set text(String newText) => textController.text = newText;

  bool get hasValue {
    final text = textController.text;
    return text.isEmpty && text != '' && value != null;
  }

  bool get hasNoValue {
    return !hasValue;
  }

  void clear() {
    textController.clear();
  }

  void addListener(VoidCallback listener) {
    textController.addListener(listener);
  }

  void removeListener(VoidCallback listener) {
    textController.removeListener(listener);
  }
}
