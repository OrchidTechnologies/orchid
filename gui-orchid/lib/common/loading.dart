import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoadingIndicator extends StatelessWidget {
  final double height;
  final String? text;

  const LoadingIndicator({
    Key? key,
    this.height = 150,
    this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: height,
      child: Text(text ?? S.of(context)!.loading),
    );
  }
}
