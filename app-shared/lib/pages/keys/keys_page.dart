import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../app_text.dart';
import 'add_key_page.dart';

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
    return TitledPage(
      title: "Keys",
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
    var route = MaterialPageRoute<StoredEthereumKey>(
        builder: (context) => AddKeyPage(), fullscreenDialog: true);
    StoredEthereumKey key = await Navigator.push(context, route);

    // User cancelled
    if (key == null) {
      return;
    }

    // Add the new key
    if (_keys == null) {
      _keys = [];
    }
    setState(() {
      _keys.add(key);
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
  final EdgeInsetsGeometry padding;

  const FloatingAddButton({
    Key key,
    @required this.onPressed,
    this.padding,
  }) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(24.0),
      child: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: onPressed,
      ),
    );
  }
}

enum KeySource { Generate, Import }
