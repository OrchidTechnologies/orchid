import 'package:orchid/orchid/orchid.dart';

class CalloutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const radius = 10.0; // Corner radius
    const calloutWidth = 25.0;
    const calloutHeight = 20.0;
    final calloutStart =
        size.width - 115.0; // Adjust this to position the callout

    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(calloutStart, 0)
      ..lineTo(calloutStart + (calloutWidth / 2), -calloutHeight)
      ..lineTo(calloutStart + calloutWidth, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
          size.width, size.height, size.width - radius, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
