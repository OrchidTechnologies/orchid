import 'package:orchid/api/orchid_log.dart';

class Hex {
  static String remove0x(String text) {
    if (text.toLowerCase().startsWith("0x")) {
      text = text.substring(2);
    }
    return text;
  }

  static String? remove0xNullable(String? text) {
    if (text != null && text.toLowerCase().startsWith("0x")) {
      text = text.substring(2);
    }
    return text;
  }

  static String hex(dynamic val) {
    return '0x' + val.toRadixString(16);
  }

  static BigInt parseBigInt(String str) {
    try {
      return BigInt.parse(Hex.remove0x(str), radix: 16);
    } catch (err) {
      log("parseBigInt: $err");
      throw err;
    }
  }

  static int parseInt(String str) {
    try {
      return int.parse(remove0x(str), radix: 16);
    } catch (err) {
      log("parseInt: $err");
      throw err;
    }
  }
}

class HexStringBuffer {
  String buff;

  HexStringBuffer(String value) : this.buff = Hex.remove0x(value);

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

  BigInt takeUint256() {
    return take(64);
  }

  BigInt takeUint160() {
    return take(64);
  }

  BigInt takeUint128() {
    return take(64);
  }

  BigInt takeUint80() {
    return take(64);
  }

  BigInt takeUint64() {
    return take(64);
  }

  BigInt takeUint8() {
    return take(64);
  }
}
