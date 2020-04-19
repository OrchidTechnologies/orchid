import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:typed_data';

class Images {

  static Future<ui.Image> loadImage(String imageName) async {
    final ByteData data = await rootBundle.load(imageName);
    var img = new Uint8List.view(data.buffer);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}

