import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';

class QRCode {
  // Return the scan or null if the user cancels the operation.
  // Throws an exception on various other error states.
  static Future<String> scan() async {
    try {
      return await BarcodeScanner.scan();
    } on PlatformException catch (e) {
      print("barcode platform exception: $e");
      if (e.code == BarcodeScanner.UserCanceled) {
        return null;
      }
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        // 'The user did not grant the camera permission!';
        // TODO: Offer to send the user back to settings?
      } else {
        // 'Unknown error
      }
    } on FormatException {
      // 'null (User returned using the "back"-button before scanning anything. Result)'
      print("barcode format exception");
    } catch (e) {
      // 'Unknown error
      print("barcode unknown exception: $e");
    }
    throw Exception("scan failed");
  }
}
