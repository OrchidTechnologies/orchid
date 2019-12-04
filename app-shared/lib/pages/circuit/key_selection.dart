import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';

typedef KeySelectionCallback = void Function(StoredEthereumKey key);

class KeySelection extends StatefulWidget {
  final KeySelectionCallback onSelection;
  final StoredEthereumKeyRef initialSelection;
  final bool enabled;

  KeySelection(
      {Key key,
      @required this.onSelection,
      this.initialSelection,
      this.enabled = false})
      : super(key: key);

  @override
  _KeySelectionState createState() => _KeySelectionState();
}

class _KeySelectionState extends State<KeySelection> {
  List<StoredEthereumKey> _keys = [];
  StoredEthereumKey _selectedKey;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    var keys = await UserPreferences().getKeys();

    this._keys = keys;

    // If an initial key selection is provided use it
    if (widget.initialSelection != null) {
      this._selectedKey = widget.initialSelection?.getFrom(_keys);
    }

    // Update all state
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Container(
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: DropdownButton<StoredEthereumKey>(
            hint: Text("Choose key"),
            isExpanded: true,
            icon: !widget.enabled ? Icon(Icons.add, size: 0) : null,
            underline: !widget.enabled ? Container() : null,
            value: _selectedKey,
            items: _keys != null
                ? _keys.map((key) {
                    var address = key.keys().address;
                    return new DropdownMenuItem<StoredEthereumKey>(
                      value: key,
                      child: Text(address,
                          overflow: TextOverflow.ellipsis, style: TextStyle()),
                    );
                  }).toList()
                : [],
            onChanged: (key) {
              setState(() {
                _selectedKey = key;
              });
              widget.onSelection(key);
            },
          ),
        ),
      ),
    );
  }
}
