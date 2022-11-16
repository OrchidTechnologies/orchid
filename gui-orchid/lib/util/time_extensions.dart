import 'package:intl/intl.dart';

extension DurationExtensions on Duration {}

Duration seconds(int seconds) {
  return Duration(seconds: seconds);
}

Duration millis(int millis) {
  return Duration(milliseconds: millis);
}

extension DateTimeExtensions on DateTime {
  String toCountdownString() {
    var unlockIn = this.difference(DateTime.now());
    return '${unlockIn.inHours}:'
        +'${unlockIn.inMinutes.remainder(60)}:'.padLeft(2, '0')
        +'${unlockIn.inSeconds.remainder(60)}'.padLeft(2, '0');
  }

  String toShortString() {
    return DateFormat('MM/dd/yyyy HH:mm:ss').format(this);
  }

  String toShortDateString() {
    return DateFormat('MM/dd/yyyy').format(this);
  }
}
