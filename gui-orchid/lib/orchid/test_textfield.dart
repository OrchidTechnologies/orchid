import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/test_app.dart';

void main() {
  runApp(TestApp(scale: 5.0, content: _Test()));
}

class _Test extends StatefulWidget {
  const _Test({Key? key}) : super(key: key);

  @override
  __TestState createState() => __TestState();
}

class __TestState extends State<_Test> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  final TextEditingController controller = TextEditingController();

  final textFieldDefaultHeightNonDense = 48.0;

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = TextStyle(
      fontWeight: FontWeight.normal,
      color: Colors.white,
      fontSize: 16,
      height: 1.0,
    );
    TextStyle baloo2Style = defaultStyle.copyWith(fontFamily: 'Baloo2', height: 0.95);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildExample(defaultStyle),
          pady(24),
          buildExample(baloo2Style),
        ],
      ),
    );
  }

  Widget buildExample(TextStyle textStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textStyle.fontFamily ?? "Default",
          style: textStyle,
        ),
        pady(8),
        Stack(
          alignment: Alignment.center,
          children: [
            _buildLinesOverlay(),
            _buildTextHeightOverlay(textStyle),
            SizedBox(width: 170, child: _buildTextField(textStyle)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextHeightOverlay(TextStyle textStyle) {
    return Container(
      height: (textStyle.fontSize ?? 12.0) * (textStyle.height ?? 1.0),
      width: 150,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildLinesOverlay() {
    final dividerHeight = 0.1;
    final pad = (textFieldDefaultHeightNonDense - 3 * dividerHeight) / 2;
    return Container(
      width: 185,
      height: textFieldDefaultHeightNonDense,
      // color: Colors.grey.withOpacity(0.2),
      child: Column(
        children: [
          Container(color: Colors.white, height: dividerHeight),
          pady(pad),
          Container(color: Colors.white, height: dividerHeight),
          pady(pad),
          Container(color: Colors.white, height: dividerHeight),
        ],
      ),
    );
  }

  Widget _buildTextField(TextStyle textStyle) {
    return Theme(
      data: ThemeData(
        // platform: TargetPlatform.macOS,
      ),
      child: TextField(
        enabled: true,
        style: textStyle,
        controller: controller,
        obscureText: false,
        autocorrect: false,
        textAlign: TextAlign.left,
        // textAlignVertical: TextAlignVertical.center,
        // textAlignVertical: TextAlignVertical.top,
        textAlignVertical: TextAlignVertical.bottom,
        maxLines: 1,
        onChanged: (_) {},
        focusNode: null,
        decoration: InputDecoration(
          // isDense: true, // 48px vs 40px default height
          // contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 16, right: 16),
          // contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          // hintText: 'This is hint text...',
          hintStyle: textStyle.copyWith(color: Colors.white.withOpacity(0.3)),
          enabledBorder: OrchidTextField.textFieldEnabledBorder,
          focusedBorder: OrchidTextField.textFieldFocusedBorder,
          // suffixIcon: suffixIcon,
        ),
        // cursorHeight: 14,
        cursorColor: Colors.white,
      ),
    );
  }
}
