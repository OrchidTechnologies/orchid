import 'package:orchid/orchid/orchid.dart';
import 'themes.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/all.dart';

class UserScriptEditor extends StatefulWidget {
  final String language;
  final String theme;
  final String? initialScript;
  final Function(String?) onScriptChanged;

  const UserScriptEditor({
    Key? key,
    required this.language,
    required this.theme,
    required this.initialScript,
    required this.onScriptChanged,
  }) : super(key: key);

  @override
  _UserScriptEditorState createState() => _UserScriptEditorState();
}

class _UserScriptEditorState extends State<UserScriptEditor> {
  CodeController? _codeController;

  @override
  void initState() {
    super.initState();

    _codeController = CodeController(
      text: widget.initialScript,
      patternMap: {
        r"\B#[a-zA-Z0-9]+\b": const TextStyle(color: Colors.red),
        r"\B@[a-zA-Z0-9]+\b": const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.blue,
        ),
        r"\B![a-zA-Z0-9]+\b":
            const TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
      },
      stringMap: {
        "bev": const TextStyle(color: Colors.indigo),
      },
      language: allLanguages[widget.language],
    );
  }

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styles = THEMES[widget.theme];

    if (styles == null) {
      return _buildCodeField();
    }

    return CodeTheme(
      data: CodeThemeData(styles: styles),
      child: _buildCodeField(),
    );
  }

  Widget _buildCodeField() {
    return CodeField(
      controller: _codeController!,
      textStyle: const TextStyle(fontFamily: 'SourceCode'),
      onChanged: (text) {
        widget.onScriptChanged(text);
      },
    );
  }
}
