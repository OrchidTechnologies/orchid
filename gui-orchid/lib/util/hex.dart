
class Hex {
  static String removePrefix(String text) {
    if (text != null && text.toLowerCase().startsWith("0x")) {
      text = text.substring(2);
    }
    return text;
  }
}

class HexStringBuffer {
  String buff;

  HexStringBuffer(String value) {
    this.buff = Hex.removePrefix(value);
  }

  BigInt take(int chars) {
    if (buff.length < chars) {
      throw Exception("buffer length");
    }
    var value = BigInt.parse(buff.substring(0, chars), radix: 16);
    this.buff = buff.substring(chars);
    return value;
  }
}
