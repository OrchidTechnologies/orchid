import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/orchid/account/account_finder.dart';
import 'package:orchid/pages/account_manager/scan_paste_identity.dart';
import 'package:orchid/pages/circuit/chain_selection.dart';
import 'package:orchid/util/localization.dart';
import 'funder_selection.dart';
import 'key_selection.dart';
import 'model/orchid_hop.dart';

/// Allow selection or manual entry of all components of an OrchidAccount
class OrchidAccountEntry extends StatefulWidget {
  final OrchidHop initialSelectionsFromHop;
  final StoredEthereumKeyRef initialKeySelection;

  /// Callback fires on changes with either a valid account or null if the form state is invalid or
  /// incomplete. The account has not been persisted.
  final void Function(Account account) onChange;

  OrchidAccountEntry({
    @required this.onChange,
    this.initialSelectionsFromHop,
    this.initialKeySelection,
  });

  @override
  _OrchidAccountEntryState createState() => _OrchidAccountEntryState();
}

class _OrchidAccountEntryState extends State<OrchidAccountEntry> {
  // Signer key selection
  KeySelectionItem _initialSelectedKeyItem;
  KeySelectionItem _selectedKeyItem;

  // Funder account selection
  var _pastedFunderField = TextEditingController();
  Chain _pastedFunderChainSelection;
  FunderSelectionItem _initialSelectedFunderItem;
  FunderSelectionItem _selectedFunderItem;

  bool _updatingAccounts = false;

  @override
  void initState() {
    super.initState();

    // Init the UI from a supplied keyref and/or hop
    final hop = widget.initialSelectionsFromHop;
    setState(() {
      final keyRef = widget.initialKeySelection ?? hop?.keyRef;
      _initialSelectedKeyItem =
          keyRef != null ? KeySelectionItem(keyRef: keyRef) : null;
      _selectedKeyItem = _initialSelectedKeyItem;

      _initialSelectedFunderItem = hop?.funder != null
          ? FunderSelectionItem(funderAccount: hop.account)
          : null;
      _selectedFunderItem = _initialSelectedFunderItem;
    });

    _pastedFunderField.addListener(_textFieldChanged);

    updateAccounts();
  }

  void updateAccounts() async {
    setState(() {
      _updatingAccounts = true;
    });
    AccountFinder().find((accounts) async {
      if (mounted) {
        setState(() {
          _updatingAccounts = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        pady(8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Signer
            _buildSelectSignerField(),
            // Funder
            if (_selectedKeyItem?.keyRef != null)
              _buildSelectFunderField().top(16),
          ],
        ).pady(24),

        // Updating spinner
        if (_updatingAccounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: _buildUpdatingAccounts(),
          ),
      ],
    );
  }

  Widget _buildUpdatingAccounts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
            width: 20,
            height: 20,
            child: OrchidCircularProgressIndicator(
              value: null, // indeterminate animation
            )),
        padx(16),
        Text(s.updatingAccounts,
            style: OrchidText.caption.copyWith(height: 1.7)),
      ],
    );
  }

  // Build the signer key (identity) entry dropdown selector
  Widget _buildSelectSignerField() {
    final pasteOnly = OrchidPlatform.doesNotSupportScanning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          s.orchidIdentity + ':',
          style: OrchidText.title.copyWith(
              color:
                  _keyRefValid() ? OrchidColors.valid : OrchidColors.invalid),
        ),
        pady(8),
        Row(
          children: <Widget>[
            Expanded(
              child: KeySelectionDropdown(
                  key: ValueKey(_selectedKeyItem?.toString() ??
                      _initialSelectedKeyItem.toString()),
                  enabled: true,
                  initialSelection: _selectedKeyItem ?? _initialSelectedKeyItem,
                  onSelection: _onKeySelected),
            ),
          ],
        ),

        // Show the import key field if the user has selected the option
        Visibility(
          visible:
              _selectedKeyItem?.option == KeySelectionDropdown.importKeyOption,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ScanOrPasteOrchidIdentity(
              onChange: (result) async {
                log("XXX: import identity = $result");
                // TODO: Saving the key should be deferred until the caller of this form
                // TODO: decides to save the account.  Doing so will require extending the
                // TODO: return data and modifying KeySelectionDropdown to handle transient keys.
                if (result.isNew) {
                  await UserPreferences().addKey(result.signer);
                }
                setState(() {
                  _selectedKeyItem =
                      KeySelectionItem(keyRef: result.signer.ref());
                });
              },
              pasteOnly: pasteOnly,
            ),
          ),
        )
      ],
    );
  }

  /// Select a funder account address for the selected signer identity
  Column _buildSelectFunderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.funderAddress + ':',
            style: OrchidText.title.copyWith(
                color: _funderValid()
                    ? OrchidColors.valid
                    : OrchidColors.invalid)),
        pady(8),

        Row(
          children: <Widget>[
            Expanded(
              child: FunderSelectionDropdown(
                  signer: _selectedKeyItem?.keyRef,
                  key: ValueKey(_selectedKeyItem?.toString() ??
                      _initialSelectedKeyItem.toString()),
                  enabled: true,
                  initialSelection:
                      _selectedFunderItem ?? _initialSelectedFunderItem,
                  onSelection: _onFunderSelected),
            ),
          ],
        ),

        // Show the paste funder field if the user has selected the option
        Visibility(
          visible: _selectedFunderItem?.option ==
              FunderSelectionDropdown.pasteAddressOption,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildPasteFunderField(),
          ),
        )
      ],
    );
  }

  Column _buildPasteFunderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OrchidTextField(
          hintText: '0x...',
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          controller: _pastedFunderField,
          trailing: TextButton(
            child: Icon(Icons.paste, color: OrchidColors.tappable),
            onPressed: _onPasteFunderAddressButton,
          ),
        ),
        pady(24),
        ChainSelectionDropdown(onSelection: _onChainSelectionChanged),
      ],
    );
  }

  //
  // On change
  //

  void _onChainSelectionChanged(Chain chain) {
    setState(() {
      _pastedFunderChainSelection = chain;
    });
    fireUpdate();
  }

  void _onKeySelected(KeySelectionItem key) {
    setState(() {
      _selectedKeyItem = key;
      _selectedFunderItem = null;
      _pastedFunderField.text = null;
    });
    _clearKeyboard();
    fireUpdate();
  }

  void _onFunderSelected(FunderSelectionItem funder) {
    setState(() {
      _selectedFunderItem = funder;
    });
    _clearKeyboard();
    fireUpdate();
  }

  void _onPasteFunderAddressButton() async {
    ClipboardData data = await Clipboard.getData('text/plain');
    _pastedFunderField.text = data.text;
    fireUpdate();
  }

  void _textFieldChanged() {
    setState(() {}); // Update validation
    fireUpdate();
  }

  //
  // Validation
  //

  bool _keyRefValid() {
    // invalid selection
    if (_selectedKeyItem == null) {
      return false;
    }
    // key value selected
    if (_selectedKeyItem.keyRef != null) {
      return true;
    }
    return false;
  }

  bool _funderValid() {
    return (_selectedFunderItem != null &&
            _selectedFunderItem.option !=
                FunderSelectionDropdown.pasteAddressOption) ||
        _pastedFunderAndChainValid();
  }

  bool _pastedFunderAndChainValid() {
    return EthereumAddress.isValid(_pastedFunderField.text) &&
        _pastedFunderChainSelection != null;
  }

  bool _formValid() {
    return _funderValid() && _keyRefValid();
  }

  // Evaluate the state of the form and notify listeners
  void fireUpdate() {
    if (!_formValid()) {
      return widget.onChange(null);
    }

    // Signer
    final signerKeyRef = _selectedKeyItem.keyRef;

    // Funder, chain, contract
    EthereumAddress funderAddress;
    int chainId;
    int version;
    try {
      var funderAccount = _selectedFunderItem?.account;
      funderAddress = funderAccount?.funder ??
          EthereumAddress.from(_pastedFunderField.text);
      chainId = funderAccount?.chainId ?? _pastedFunderChainSelection.chainId;

      // Note: Currently inferring contract version from chain selection here.
      version = funderAccount?.version ??
          (_pastedFunderChainSelection.isEthereum ? 0 : 1);
    } catch (err) {
      // e.g. invalid pasted address
      return widget.onChange(null);
    }

    // Account
    widget.onChange(Account.base(
      signerKeyUid: signerKeyRef.keyUid,
      version: version,
      chainId: chainId,
      funder: funderAddress,
    ));
  }

  void _clearKeyboard() {
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  @override
  void dispose() {
    super.dispose();
    _pastedFunderField.removeListener(_textFieldChanged);
  }
}
