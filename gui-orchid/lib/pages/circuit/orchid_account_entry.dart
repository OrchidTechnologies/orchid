import 'package:orchid/orchid.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/orchid/menu/orchid_chain_selector_menu.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/orchid/account/account_finder.dart';
import 'package:orchid/pages/account_manager/scan_paste_identity.dart';
import '../../orchid/menu/orchid_funder_selector_menu.dart';
import 'package:orchid/orchid/menu/orchid_key_selector_menu.dart';
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
  Chain _pastedOrOverriddenFunderChainSelection;
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

    _updateAccounts();
  }

  void _updateAccounts() async {
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
              color: _keyRefValid ? OrchidColors.valid : OrchidColors.invalid),
        ),
        pady(8),
        Row(
          children: <Widget>[
            Expanded(
              child: OrchidKeySelectorMenu(
                enabled: true,
                selected: _selectedKeyItem ?? _initialSelectedKeyItem,
                onSelection: _onKeySelected,
              ),
            ),
          ],
        ),

        // Show the import key field if the user has selected the option
        Visibility(
          visible:
              _selectedKeyItem?.option == OrchidKeySelectorMenu.importKeyOption,
          child: ScanOrPasteOrchidIdentity(
            onChange: (result) async {
              log("XXX: import identity = $result");
              // TODO: Saving the key should be deferred until the caller of this form
              // TODO: decides to save the account.  Doing so will require extending the
              // TODO: return data and modifying KeySelectionDropdown to handle transient keys.
              if (result != null) {
                if (result.isNew) {
                  await result.save();
                  _updateAccounts();
                }
                setState(() {
                  _selectedKeyItem =
                      KeySelectionItem(keyRef: result.signer.ref());
                  if (result.account != null) {
                    _selectedFunderItem =
                        FunderSelectionItem(funderAccount: result.account);
                    _pastedOrOverriddenFunderChainSelection =
                        result.account.chain;
                  }
                });
                fireUpdate();
              }
            },
            pasteOnly: pasteOnly,
          ).top(24),
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
                color:
                    _funderValid ? OrchidColors.valid : OrchidColors.invalid)),
        pady(8),

        Row(
          children: <Widget>[
            Expanded(
              child: OrchidFunderSelectorMenu(
                  signer: _selectedKeyItem?.keyRef,
                  // Update on change in key
                  key: ValueKey(_selectedKeyItem?.toString() ??
                      _initialSelectedKeyItem.toString()),
                  enabled: true,
                  selected: _selectedFunderItem ?? _initialSelectedFunderItem,
                  onSelection: _onFunderSelected),
            ),
          ],
        ),

        // Show the paste funder field if the user has selected the option
        Visibility(
          visible: _selectedFunderItem?.option ==
              OrchidFunderSelectorMenu.pasteAddressOption,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildPasteFunderField(),
          ),
        ),

        pady(16),
        Text(s.chain + ':',
            style: OrchidText.title.copyWith(
                color:
                    _funderValid ? OrchidColors.valid : OrchidColors.invalid)),
        pady(8),

        OrchidChainSelectorMenu(
          key: Key(_selectedFunderItem?.toString() ?? ''),
          onSelection: _onChainSelectionChanged,
          selected: _pastedOrOverriddenFunderChainSelection ??
              _selectedFunderItem?.account?.chain,
          enabled: _selectedFunderItem != null,
          width: double.infinity,
        ),
      ],
    );
  }

  Column _buildPasteFunderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OrchidTextField(
          hintText: '0x...',
          controller: _pastedFunderField,
          trailing: TextButton(
            child: Icon(Icons.paste, color: OrchidColors.tappable),
            onPressed: _onPasteFunderAddressButton,
          ),
        ),
      ],
    );
  }

  //
  // On change
  //

  void _onChainSelectionChanged(Chain chain) {
    setState(() {
      _pastedOrOverriddenFunderChainSelection = chain;
    });
    fireUpdate();
  }

  void _onKeySelected(KeySelectionItem key) {
    setState(() {
      _selectedKeyItem = key;
      _selectedFunderItem = null;
      _pastedFunderField.text = null;
      _pastedOrOverriddenFunderChainSelection = null;
    });
    _clearKeyboard();
    fireUpdate();
  }

  void _onFunderSelected(FunderSelectionItem funder) {
    setState(() {
      _selectedFunderItem = funder;
      _pastedFunderField.text = null;
      _pastedOrOverriddenFunderChainSelection = null;
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

  bool get _keyRefValid {
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

  bool get _funderValid {
    return (_selectedFunderItem != null &&
            _selectedFunderItem.option !=
                OrchidFunderSelectorMenu.pasteAddressOption) ||
        _pastedFunderAndChainValid;
  }

  bool get _pastedFunderAndChainValid {
    return EthereumAddress.isValid(_pastedFunderField.text) &&
        _pastedOrOverriddenFunderChainSelection != null;
  }

  bool get _formValid {
    log("XXX: _funderValid: $_funderValid, _keyRefValid: $_keyRefValid");
    return _funderValid && _keyRefValid;
  }

  // Evaluate the state of the form and notify listeners
  void fireUpdate() {
    if (!_formValid) {
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

      chainId = _pastedOrOverriddenFunderChainSelection?.chainId ??
          funderAccount?.chainId;

      // Note: Currently inferring contract version from chain selection here.
      version = funderAccount?.version ??
          (_pastedOrOverriddenFunderChainSelection.isEthereum ? 0 : 1);
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
