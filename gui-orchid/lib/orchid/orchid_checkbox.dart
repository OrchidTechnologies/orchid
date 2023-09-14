import 'package:orchid/orchid/orchid.dart';

class OrchidCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const OrchidCheckbox({
    Key? key,
    required bool value,
    required this.onChanged,
  })  : value = value,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            checkColor: MaterialStateProperty.all(Colors.black),
            fillColor: MaterialStateProperty.all(OrchidColors.tappable),
          )),
      child: Checkbox(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
