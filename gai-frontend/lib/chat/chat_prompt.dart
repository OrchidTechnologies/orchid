import 'package:orchid/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/orchid.dart';

// The prompt row and collapsible bid form footer
class ChatPromptPanel extends StatefulWidget {
  final TextEditingController promptTextController;
  final VoidCallback onSubmit;
  final ValueChanged<double?> setBid;
  final NumericValueFieldController bidController;

  const ChatPromptPanel({
    super.key,
    required this.promptTextController,
    required this.onSubmit,
    required this.setBid,
    required this.bidController,
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
                  ? const Icon(Icons.expand_more, color: Colors.white)
                  : const Icon(Icons.chevron_right, color: Colors.white),
            ),
            Flexible(
              child: OrchidTextField(
                controller: widget.promptTextController,
                hintText: 'Enter a prompt',
                contentPadding: EdgeInsets.only(bottom: 26, left: 16),
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
          _buildBidForm(widget.setBid, widget.bidController),
      ],
    );
  }

  Widget _buildBidForm(
    ValueChanged<double?> setBid,
    NumericValueFieldController bidController,
  ) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          Text('Your bid is the price per token in/out you will pay.',
                  style: OrchidText.medium_20_050)
              .top(8),
          OrchidLabeledNumericField(
            label: 'Bid',
            onChange: setBid,
            controller: bidController,
          ).top(12)
        ],
      ),
    );
  }
}
