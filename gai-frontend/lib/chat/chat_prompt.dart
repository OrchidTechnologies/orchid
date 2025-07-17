import 'package:orchid/chat/tool_management_panel.dart';
import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/orchid.dart';

class ChatPromptPanel extends StatefulWidget {
  final TextEditingController promptTextController;
  final VoidCallback onSubmit;
  final ValueChanged<int?> setMaxTokens;
  final NumericValueFieldController maxTokensController;

  const ChatPromptPanel({
    super.key,
    required this.promptTextController,
    required this.onSubmit,
    required this.setMaxTokens,
    required this.maxTokensController,
  });

  @override
  State<ChatPromptPanel> createState() => _ChatPromptPanelState();
}

class _ChatPromptPanelState extends State<ChatPromptPanel> {
  bool _showPromptDetails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            IconButton.filled(
              style: IconButton.styleFrom(
                  backgroundColor: OrchidColors.new_purple),
              onPressed: () {
                setState(() {
                  _showPromptDetails = !_showPromptDetails;
                });
              },
              icon: _showPromptDetails
                  ? const Icon(Icons.tune, color: Colors.white)
                  : const Icon(Icons.tune, color: Colors.white),
            ),
            Flexible(
              child: OrchidTextField(
                controller: widget.promptTextController,
                hintText: 'Enter a prompt',
                contentPadding: const EdgeInsets.only(bottom: 26, left: 16),
                style: OrchidText.body1,
                autoFocus: true,
                onSubmitted: (String s) {
                  widget.onSubmit();
                },
              ).left(16),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(
                  backgroundColor: OrchidColors.new_purple),
              onPressed: widget.onSubmit,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ).left(16),
          ],
        ).padx(8),
        if (_showPromptDetails)
          _buildPromptParamsForm(widget.setMaxTokens, widget.maxTokensController),
      ],
    );
  }

  Widget _buildPromptParamsForm(
    ValueChanged<int?> setMaxTokens,
    NumericValueFieldController maxTokensController,
  ) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          // Max tokens section
          Text(
            'Set the maximum number of tokens for the response.',
            style: OrchidText.medium_20_050,
          ).top(8),
          OrchidLabeledNumericField(
            label: 'Max Tokens',
            onChange: (value) => setMaxTokens(value?.toInt()),
            controller: maxTokensController,
          ).top(12),
          
          // Tool management section
          SizedBox(height: 16),
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: ToolManagementPanel(),
          ).top(8),
        ],
      ),
    );
  }
}
