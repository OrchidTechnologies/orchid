
class Hex {
  static String remove0x(String text) {
    if (text != null && text.toLowerCase().startsWith("0x")) {
      text = text.substring(2);
    }
    return text;
  }
}

class HexStringBuffer {
  String buff;

  HexStringBuffer(String value) {
    this.buff = Hex.remove0x(value);
  }

  void skip(int chars) {
    if (buff.length < chars) {
      throw Exception("buffer length");
    }
    this.buff = buff.substring(chars);
  }

  BigInt take(int chars) {
    if (buff.length < chars) {
      throw Exception("buffer length");
    }
    var value = BigInt.parse(buff.substring(0, chars), radix: 16);
    this.buff = buff.substring(chars);
    return value;
  }

  int takeMethodId() {
    return take(8).toInt();
  }
  BigInt takeBytes32() {
    return take(64);
  }
  BigInt takeAddress() {
    return take(64);
  }
  BigInt takeUint128() {
    return take(64);
  }
  BigInt takeUint256() {
    return take(64);
  }
  BigInt takeUint8() {
    return take(64);
  }
}
