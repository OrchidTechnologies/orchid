import 'dart:convert';
import 'dart:typed_data';

import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/dapp/orchid/dapp_button.dart';
import 'package:orchid/dapp/orchid/dapp_tab_context.dart';
import 'package:orchid/dapp/orchid_web3/orchid_web3_context.dart';
import 'package:orchid/dapp/preferences/dapp_transaction.dart';
import 'package:orchid/dapp/preferences/user_preferences_dapp.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/orchid_labeled_text_field.dart';
import 'package:orchid/gui-orchid/lib/util/hex.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/stake_dapp/orchid_web3_location_v0.dart';

class LocationPanel extends StatefulWidget {
  final OrchidWeb3Context? web3context;
  final bool enabled;
  final Location? location;

  const LocationPanel({
    super.key,
    required this.web3context,
    required this.enabled,
    required this.location,
  });

  @override
  State<LocationPanel> createState() => _LocationPanelState();
}

class _LocationPanelState extends State<LocationPanel>
    with DappTabWalletContext {
  OrchidWeb3Context? get web3Context => widget.web3context;

  late TextEditingController _urlController;
  late TextEditingController _tlsController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _urlController.addListener(_formFieldChanged);
    _tlsController = TextEditingController();
    _tlsController.addListener(_formFieldChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrchidLabeledTextField(
          enabled: widget.enabled,
          label: "URL",
          hintText: widget.location?.url ?? 'https://...',
          controller: _urlController,
          error: _urlFieldError,
        ).top(32).padx(8),
        OrchidLabeledTextField(
          enabled: widget.enabled,
          label: "TLS",
          hintText: widget.location?.tls ?? '0x...',
          controller: _tlsController,
          error: _tlsFieldError,
        ).top(16).padx(8),
        if (widget.location?.set != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Last set date: " + widget.location!.set.toIso8601String())
                  .subtitle
                  .top(20)
                  .padx(8),
            ],
          ),
        DappButton(
          text: _isPoke ? "POKE" : "UPDATE",
          onPressed: _isPoke
              ? (_formEnabled ? _poke : null)
              : (_formEnabled ? _updateLocation : null),
        ).top(32),
      ],
    ).width(double.infinity);
  }

  void _formFieldChanged() {
    // Update UI
    setState(() {});
  }

  bool get _isPoke {
    return (widget.location != null) &&
        _urlController.text.isEmpty &&
        _tlsController.text.isEmpty;
  }

  bool get _formEnabled {
    return !txPending && (_isPoke || _isValidUpdate);
  }

  bool get _isValidUpdate {
    return _urlFieldValid &&
        _tlsFieldValid &&
        (_urlController.text.isNotEmpty || _tlsController.text.isNotEmpty);
  }

  bool get _urlFieldError {
    final text = _urlController.text;
    if (text.isEmpty) {
      return false;
    }
    return !text.isValidURL;
  }

  bool get _urlFieldValid {
    return !_urlFieldError;
  }

  bool get _tlsFieldError {
    var text = _tlsController.text;
    if (text.isEmpty) {
      return false;
    }
    try {
      Hex.decodeBytes(text);
      return false;
    } catch (err) {
      return true;
    }
  }

  bool get _tlsFieldValid {
    return !_tlsFieldError;
  }

  void _poke() async {
    setState(() {
      txPending = true;
    });
    try {
      final txHashes = await OrchidWeb3LocationV0(web3Context!).orchidPoke();
      UserPreferencesDapp()
          .addTransactions(txHashes.map((hash) => DappTransaction(
                transactionHash: hash,
                chainId: web3Context!.chain.chainId, // always Ethereum
                type: DappTransactionType.pokeLocation,
              )));

      setState(() {});
    } catch (err) {
      log('Error on update location: $err');
    }
    setState(() {
      txPending = false;
    });
  }

  void _updateLocation() async {
    var urlText = _urlController.text;
    var tlsText = _tlsController.text;

    if (urlText.isEmpty && tlsText.isEmpty) {
      throw Exception('Invalid state for update location');
    }

    if (urlText.isEmpty && widget.location?.url != null) {
      urlText = widget.location!.url;
    }
    if (tlsText.isEmpty && widget.location?.tls != null) {
      tlsText = widget.location!.tls;
    }

    final url = urlText.isEmpty
        ? Uint8List(0)
        : Uint8List.fromList(utf8.encode(urlText));
    final tls = tlsText.isEmpty
        ? Uint8List(0)
        : Uint8List.fromList(Hex.decodeBytes(tlsText));

    setState(() {
      txPending = true;
    });
    try {
      final txHashes = await OrchidWeb3LocationV0(web3Context!).orchidMove(
        url: url,
        tls: tls,
      );

      UserPreferencesDapp()
          .addTransactions(txHashes.map((hash) => DappTransaction(
                transactionHash: hash,
                chainId: web3Context!.chain.chainId, // always Ethereum
                type: DappTransactionType.moveLocation,
              )));

      _urlController.clear();
      _tlsController.clear();
      setState(() {});
    } catch (err) {
      log('Error on update location: $err');
    }
    setState(() {
      txPending = false;
    });
  }
}
