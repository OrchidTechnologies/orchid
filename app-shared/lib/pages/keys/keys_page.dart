import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/common/formatting.dart';

import '../app_colors.dart';
import '../app_text.dart';
import 'import_key_page.dart';

class KeysPage extends StatefulWidget {
  @override
  _KeysPageState createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  List<StoredEthereumKey> _keys;
  int _copiedIndex;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    var keys = await UserPreferences().getKeys();
    setState(() {
      this._keys = keys;
      _sortKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.basicGradient),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            pady(16),
            Expanded(child: _buildKeyList()),
            FloatingAddButton(onPressed: _addKey),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyList() {
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            Divider(height: 0),
        key: PageStorageKey('keys list view'),
        primary: true,
        itemCount: _keys?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          StoredEthereumKey key = _keys[index];
          return Theme(
            data: ThemeData(accentColor: AppColors.purple_3),
            child: Container(
              //height: 70,
              alignment: Alignment.center,
              //decoration: BoxDecoration(color: Colors.transparent),
              child: IntrinsicHeight(
                child: _buildKeyTile(key, index),
              ),
            ),
          );
        });
  }

  ListTile _buildKeyTile(StoredEthereumKey key, int index) {
    var title = _copiedIndex == index
        ? "Copied to clipboard..."
        : "Key: ${key.keys().address.substring(0, 20) + '...'}";
    return ListTile(
        onTap: () {
          _tapKey(key, index);
        },
        key: Key(index.toString()),
        title: Text(title, style: AppText.listItem));
  }

  void _addKey() async {
    _showAddKeyChoices(
      context: context,
      child: CupertinoActionSheet(
          title: Text('Key Source', style: TextStyle(fontSize: 21)),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text("Generate"),
              onPressed: () {
                Navigator.pop(context, KeySource.Generate);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("Import"),
              onPressed: () {
                Navigator.pop(context, KeySource.Import);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          )),
    );
  }

  void _showAddKeyChoices({BuildContext context, Widget child}) {
    showCupertinoModalPopup<KeySource>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((source) {
      if (source != null) {
        _addKeyFromSource(source);
      }
    });
  }

  void _addKeyFromSource(KeySource source) async {
    StoredEthereumKey newKey;
    switch (source) {
      case KeySource.Generate:
        newKey = _generateKey();
        break;
      case KeySource.Import:
        newKey = await _importKey();
        break;
    }

    // User cancelled
    if (newKey == null) {
      return;
    }

    // Add the new key
    if (_keys == null) {
      _keys = [];
    }
    setState(() {
      _keys.add(newKey);
      _sortKeys();
    });

    _saveKeys();
  }

  void _sortKeys() {
    if (_keys == null) {
      return;
    }
    // sort time descending
    _keys.sort((a, b) {
      return -a.time.compareTo(b.time);
    });
  }

  StoredEthereumKey _generateKey() {
    var keyPair = Crypto.generateKeyPair();
    return StoredEthereumKey(
        time: DateTime.now(), imported: false, private: keyPair.private);
  }

  Future<StoredEthereumKey> _importKey() async {
    var route = MaterialPageRoute<BigInt>(
        builder: (context) => ImportKeyPage(), fullscreenDialog: true);
    var secret = await Navigator.push<BigInt>(context, route);
    return secret != null
        ? StoredEthereumKey(
            time: DateTime.now(), imported: true, private: secret)
        : null;
  }

  _saveKeys() {
    UserPreferences().setKeys(_keys);
  }

  void _tapKey(StoredEthereumKey key, int index) async {
    Clipboard.setData(ClipboardData(text: key.keys().address));
    setState(() {
      _copiedIndex = index;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _copiedIndex = null;
    });
  }
}

class FloatingAddButton extends StatelessWidget {
  const FloatingAddButton({
    Key key,
    @required this.onPressed,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

enum KeySource { Generate, Import }
