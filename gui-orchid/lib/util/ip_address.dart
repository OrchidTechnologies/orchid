import 'dart:math';

class IPAddress {
  String string;

  IPAddress(this.string);

  static IPAddress random() {
    var a = Random().nextInt(255);
    var b = Random().nextInt(255);
    var c = Random().nextInt(255);
    var d = Random().nextInt(255);
    return IPAddress("$a.$b.$c.$d");
  }
}
