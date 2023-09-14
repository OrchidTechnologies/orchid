import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/common/app_buttons.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/orchid/field/orchid_labeled_identity_field.dart';
import 'package:orchid/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/orchid/menu/orchid_chain_selector_menu.dart';
import 'package:orchid/orchid/menu/orchid_funder_selector_menu.dart';
import 'package:orchid/orchid/menu/orchid_version_selector_menu.dart';
import 'package:orchid/orchid/orchid_circular_progress.dart';
import 'package:orchid/orchid/menu/orchid_key_selector_menu.dart';

/// Allow selection or manual entry of all components of an OrchidAccount
class OrchidAccountEntry extends StatefulWidget {
  final StoredEthereumKeyRef? initialKeySelection;
  final Account? initialFunderSelection;

  /// Callback fires on changes with either a valid account or null if the form state is invalid or
  /// incomplete. The account has not been persisted.
  final void Function(Account? account) onAccountUpdate;

  /// Callback fires on import of multiple accounts via config pasted into the identity import field.
  final void Function(List<Account> accounts) onAccountsImport;

  OrchidAccountEntry({
    required this.onAccountUpdate,
    required this.onAccountsImport,
    this.initialKeySelection,
    this.initialFunderSelection,
  });

  @override
  _OrchidAccountEntryState createState() => _OrchidAccountEntryState();
}

class _OrchidAccountEntryState extends State<OrchidAccountEntry> {
  // Signer key selection
  KeySelectionItem? _initialSelectedKeyItem;
  KeySelectionItem? _selectedKeyItem;

  // Funder account selection
  var _pastedFunderField = TextEditingController();
  Chain? _pastedOrOverriddenFunderChainSelection;
  int? _overriddenFunderVersionSelection;
  FunderSelectionItem? _initialSelectedFunderItem;
  FunderSelectionItem? _selectedFunderItem;

  bool _updatingAccounts = false;

  @override
  void initState() {
    super.initState();

    // Init the UI from a supplied keyref and/or funder account info
    setState(() {
      final keyRef = widget.initialKeySelection;
      _initialSelectedKeyItem =
          keyRef != null ? KeySelectionItem(keyRef: keyRef) : null;
      _selectedKeyItem = _initialSelectedKeyItem;

      final funder = widget.initialFunderSelection;
      _initialSelectedFunderItem =
          funder != null ? FunderSelectionItem(funderAccount: funder) : null;
      _selectedFunderItem = _initialSelectedFunderItem;
    });

    _pastedFunderField.addListener(_textFieldChanged);

    // _updateAccounts();
  }

  /*
  void _updateAccounts({List<EthereumKeyRef> addIdentities}) async {
    setState(() {
      _updatingAccounts = true;
    });
    AccountFinder().find(
      addIdentities: addIdentities,
      callback: (accounts) async {
        if (mounted) {
          setState(() {
            _updatingAccounts = false;
          });
        }
      },
    );
  }
   */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Signer
            _buildSelectIdentityField(),

            // Funder
            // We used to hide the funder field until a valid identity was selected.
            // if (_selectedKeyItem?.keyRef != null)
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
  Widget _buildSelectIdentityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            Text(
              s.orchidIdentity + ':',
              style: OrchidText.title.copyWith(
                  color:
                      _keyRefValid ? OrchidColors.valid : OrchidColors.invalid),
            ),
            _buildCopyIdentityButton().bottom(4),
          ],
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
        AnimatedVisibility(
          duration: millis(250),
          show:
              _selectedKeyItem?.option == OrchidKeySelectorMenu.importKeyOption,
          child: OrchidLabeledImportIdentityField(
            label: s.orchidIdentity,
            onChange: _parsedValueChanged,
          ).top(24),
        )
      ],
    );
  }

  Widget _buildCopyIdentityButton() {
    final keyItem = _selectedKeyItem ?? _initialSelectedKeyItem;
    final text = keyItem?.keyRef == null
        ? null
        : keyItem!.address!.toString(prefix: true, elide: false); // or null
    return CopyTextButton(copyText: text);
  }

  void _parsedValueChanged(ParseOrchidIdentityOrAccountResult? result) async {
    log("XXX: import identity = $result");

    if (result != null) {
      if (result.hasMultipleAccounts) {
        widget.onAccountsImport(result.accounts!);
      } else {
        final keyRef = TransientEthereumKeyRef(result.signer);
        setState(() {
          _onKeySelected(KeySelectionItem(keyRef: keyRef));

          if (result.account != null) {
            _onFunderSelected(
                FunderSelectionItem(funderAccount: result.account));
          }
        });
        // _updateAccounts(addIdentities: [keyRef]);
      }
    }
  }

  /// Select a funder account address for the selected signer identity
  Column _buildSelectFunderField() {
    final _funderValidStyle = OrchidText.title.copyWith(
        color: _funderValid ? OrchidColors.valid : OrchidColors.invalid);

    final effectiveChainSelection = _pastedOrOverriddenFunderChainSelection ??
        _selectedFunderItem?.account?.chain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(s.funderAddress + ':', style: _funderValidStyle),
        // Show the paste funder field if the user has selected the option
        _buildPasteFunderField().top(8),

        Text(s.chain + ':', style: _funderValidStyle).top(16),

        OrchidChainSelectorMenu(
          onSelection: _onChainSelectionChanged,
          selected: effectiveChainSelection,
          // enabled: _selectedFunderItem != null,
          width: double.infinity,
        ).top(8),

        if (effectiveChainSelection == Chains.Ethereum)
          Text(s.contractVersion + ':', style: _funderValidStyle).top(16),

        AnimatedVisibility(
          show: effectiveChainSelection == Chains.Ethereum,
          child: OrchidVersionSelectorMenu(
            onSelection: _onVersionSelectionChanged,
            selected: _overriddenFunderVersionSelection ??
                _selectedFunderItem?.account?.version ?? 1,
            // enabled: _selectedFunderItem != null,
            enabled: true,
            width: double.infinity,
          ).top(8),
        ),
      ],
    );
  }

  // TODO: Needs to highlight border with validation
  Column _buildPasteFunderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OrchidLabeledTextField(
          label: s.pasteAddress,
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
      _overriddenFunderVersionSelection = null;
    });
    fireUpdate();
  }

  void _onVersionSelectionChanged(int version) {
    setState(() {
      _overriddenFunderVersionSelection = version;
    });
    fireUpdate();
  }

  void _onKeySelected(KeySelectionItem? key) {
    setState(() {
      _selectedKeyItem = key;
      _selectedFunderItem = null;
      _pastedFunderField.text = '';
      _pastedOrOverriddenFunderChainSelection = null;
      _overriddenFunderVersionSelection = null;
    });
    _clearKeyboard();
    fireUpdate();
  }

  void _onFunderSelected(FunderSelectionItem funder) {
    log("XXX: onFunderSelected: $funder");
    setState(() {
      _selectedFunderItem = funder;
      _pastedFunderField.text = '';
      _pastedOrOverriddenFunderChainSelection = null;
      _overriddenFunderVersionSelection = null;
    });
    _clearKeyboard();
    fireUpdate();
  }

  void _onPasteFunderAddressButton() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    _pastedFunderField.text = data?.text ?? '';
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
    if (_selectedKeyItem!.keyRef != null) {
      return true;
    }
    return false;
  }

  bool get _funderValid {
    return (_selectedFunderItem != null &&
            _selectedFunderItem!.option !=
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
      return widget.onAccountUpdate(null);
    }

    // Signer
    // null guarded by _formValid
    final EthereumKeyRef signerKeyRef = _selectedKeyItem!.keyRef!;

    // Funder, chain, contract
    EthereumAddress funderAddress;
    int? chainId;
    int version;
    try {
      var funderAccount = _selectedFunderItem?.account;
      funderAddress = funderAccount?.funder ??
          EthereumAddress.from(_pastedFunderField.text);

      chainId = _pastedOrOverriddenFunderChainSelection?.chainId ??
          funderAccount?.chainId;

      if (chainId == null) {
        throw Exception("Chain ID not found");
      }

      version = _overriddenFunderVersionSelection ??
          funderAccount?.version ??
          (_pastedOrOverriddenFunderChainSelection!.isEthereum ? 0 : 1);
    } catch (err) {
      // e.g. invalid pasted address
      return widget.onAccountUpdate(null);
    }

    // Account
    widget.onAccountUpdate(Account.fromSignerKey(
      signerKey: signerKeyRef.get(),
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
