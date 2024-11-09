import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/orchid/test_app.dart';
import 'orchid_labeled_token_value_field.dart';

// Note: This redundant import of material is required in the main dart file.
import 'package:flutter/material.dart';


void main() {
  runApp(TestApp(scale: 1.0, content: _Test()));
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
    controller.addListener(() {
      print(controller.value?.intValue);
    });
  }

  static final tokenType = Tokens.OXT;
  final controller = TypedTokenValueFieldController(type: tokenType);
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
            SizedBox(width: 450, child: _buildTextField(textStyle)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(TextStyle textStyle) {
    return OrchidLabeledTokenValueField(
      type: tokenType,
      controller: controller,
      label: s.balanceToDeposit1,
      // labelWidth: 180,
    );
  }
}
