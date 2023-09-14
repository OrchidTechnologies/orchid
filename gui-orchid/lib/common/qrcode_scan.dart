import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScanner extends StatelessWidget {
  final Function(String) onCode;

  const QRCodeScanner({
    Key? key,
    required this.onCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      // allowDuplicates: false,
      onDetect: (capture) {
        if (capture.barcodes.isEmpty) {
          log('XXX: QRScanner, failed to scan');
        } else {
          final String? code = capture.barcodes.first.rawValue;
          if (code == null) {
            log('XXX: QRScanner, empty code');
          } else {
            log('XXX: QRScanner, found: $code');
            onCode(code);
          }
        }
      },
    );
  }

  // dialogue version
  static void scan(
    BuildContext context,
    Function(String) onCode,
  ) {
    var size = MediaQuery.of(context).size;
    AppDialogs.showAppDialog(
      context: context,
      title: "Scan QR Code",
      body: SizedBox(
          width: size.width,
          height: size.height * 0.5,
          child: QRCodeScanner(onCode: (String code) {
            onCode(code);
            Navigator.of(context).pop();
          })),
    );
  }
}
