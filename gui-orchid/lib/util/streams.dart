import 'dart:async';

extension StreamExtensions on StreamSubscription {
  void dispose(List<StreamSubscription> disposal) {
    disposal.add(this);
  }
}

extension StreamExtensionsList on List<StreamSubscription> {
  void dispose() {
    this.forEach((sub) {
      sub.cancel();
    });
  }
}

