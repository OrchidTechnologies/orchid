import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/src/material/colors.dart';
//import 'dart:html';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid_gradients.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/orchid_labeled_numeric_field.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/orchid_labeled_address_field.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/orchid_labeled_text_field.dart';

import 'settings.dart';
import 'app_colors.dart';

import 'provider.dart';

TextStyle medium_20_050 = TextStyle(
    fontFamily: "Baloo2",
    fontWeight: FontWeight.normal,
    color: Colors.white,
    fontSize: 20,
    height: 1.0);

TextStyle normal_14 = TextStyle(
    fontFamily: "Baloo2",
    fontWeight: FontWeight.normal,
    // w400
    color: Colors.white,
    fontSize: 14,
    height: 1.0);

TextStyle normal_14_grey = TextStyle(
    fontFamily: "Baloo2",
    fontWeight: FontWeight.normal,
    // w400
    color: Colors.grey,
    fontSize: 14,
    height: 1.0);

TextStyle normal_16_025_grey = TextStyle(
      fontFamily: "Baloo2",
      fontWeight: FontWeight.normal,
      color: Colors.grey,
      fontSize: 16,
      height: 1.0,
      letterSpacing: 0.25);

enum OrchataMenuItem { debug }

enum ChatMessageSource { client, provider, system, internal }


class ChatMessage {
  ChatMessageSource source;
  String msg;
  Map<String, dynamic>? _metadata;

  ChatMessage(this.source, this.msg, {metadata})
    : _metadata = metadata;

  String get message {
    return msg;
  }

  Map<String, dynamic> get metadata {
    return _metadata ?? Map<String, dynamic>();
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<ChatMessage> messages = [];
  List<String> _providers = [];
  var _debugMode = false;
  var _connected = false;
  var _bid = 0.00007;
  var _funder = null;
  var _signerKey = null;
  var _providerConnection;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      var uri = Uri.dataFromString(window.location.href);
      Map<String, String> params = uri.queryParameters;
      var funder = params['funder'];
      var signer = params['signer'];
      var provider = params['provider'];
      if (provider != null) {
        _providers = [provider];
      }
      if (params['funder'] != null) {
        _funder = EthereumAddress.from(funder ?? '');
      }
      if (params['signer'] != null) {
        _signerKey = BigInt.parse(signer ?? '');
      }
    }

    _providerConnection = ProviderConnection(
      providers: _providers,
      onMessage: (msg) { addMessage(ChatMessageSource.internal, msg); },
      onConnect: providerConnected,
      onChat: (msg, metadata) { addMessage(ChatMessageSource.provider, msg, metadata); },
      onDisconnect: providerDisconnected,
      onError: (msg) { addMessage(ChatMessageSource.system, 'Provider error: $msg'); },
      onSystemMessage: (msg) { addMessage(ChatMessageSource.system, msg); },
      onInternalMessage: (msg) { addMessage(ChatMessageSource.internal, msg); },
      funder: _funder,
      signerKey: _signerKey,
      contract: EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82'), 
    );
  }

  void providerConnected() {
    _connected = true; 
    addMessage(ChatMessageSource.system, 'Connected to provider.'); 
  }

  void providerDisconnected() {
    _connected = false;
    addMessage(ChatMessageSource.system, 'Provider disconnected');
  }

  void addMessage(ChatMessageSource source, String msg, [metadata]) {
     if (metadata == null) {
       messages.add(ChatMessage(source, msg));
     } else {
       messages.add(ChatMessage(source, msg, metadata: metadata));
     }
     if (source != ChatMessageSource.internal || _debugMode == true) {
       setState(() {});
       scrollMessagesDown();
     }
  }

  void setBid(double? value) {
    var _value = value ?? _bid;
    _bid = _value;
    setState(() {});
  }

  Widget buildPromptDialog(BuildContext context, Animation<double> anim1,  Animation<double> anim2) {
    var controller = NumericValueFieldController();
    controller.value = _bid;
    
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[const Color(0xFF303030), const Color(0xFF757575)],
          ),
        ),
        height: 130,
        child: Column(
          children: <Widget>[
            Text('Your bid is the price per token in/out you will pay.', style: medium_20_050 ),
            const SizedBox(height: 3),
            OrchidLabeledNumericField(
              label: 'Bid', 
              onChange: setBid,
              controller: controller,
            )
          ],
        ),
      ),
    );
  }

  Widget buildAccountDialog(BuildContext context, Animation<double> anim1,  Animation<double> anim2) {
    var scontroller = TextEditingController(text: _signerKey.toString());
    var fcontroller = AddressValueFieldController();
    if (_funder != null) {
      fcontroller.value = _funder;
    }
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[const Color(0xFF303030), const Color(0xFF757575)],
          ),
        ),
        height: 225,
        child: Column(
          children: <Widget>[
            Text('Set your Orchid account', style: medium_20_050 ),
            const SizedBox(height: 3),
            OrchidLabeledAddressField(
              label: 'Funder Address',
              onChange: (EthereumAddress? s) { _funder = s; },
              controller: fcontroller,
            ),
            const SizedBox(height: 5),
            OrchidLabeledTextField(
              label: 'Signer Key', 
              controller: scontroller,
              onChanged: (String s) { _signerKey = s; },
            ),
          ],
        ),
      ),
    );
  }

  void popAccountDialog() {
    showGeneralDialog<String>(
      context: context,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: buildAccountDialog,
      barrierDismissible: true,
      barrierLabel: 'Orchid Account Settings',
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, -1),
                          end: Offset(0,-0.3)).animate(anim1),
          child: child,
        );
      },
    );
  }

  bool accountSet() {
    if (_funder == null || _signerKey == null) {
      return false;
    }
    return true;
  }

  List<Color> msgBubbleColor(ChatMessageSource src) {
    if (src == ChatMessageSource.client) { 
      return <Color>[
                    Color(0xff52319c),
                    Color(0xff3b146a),
                    ];
    } else {
       return <Color>[
         AppColors.teal_2,
         AppColors.neutral_1,
       ];
    }
  }

  Widget buildChatBubble(context, index) {
    ChatMessageSource src = messages[index].source;
    String metadataString;

    if (src == ChatMessageSource.system || src == ChatMessageSource.internal) {
      if (!_debugMode && src == ChatMessageSource.internal) {
         return Container();
      }

      return Center(
        child: Column(
          children: <Widget>[
            Text(messages[index].message, style: src == ChatMessageSource.system ? normal_14 : normal_14_grey),
            const SizedBox(height: 2),
          ],
        ),
      );
    }
    return Align(
      alignment: src == ChatMessageSource.provider ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: 0.6 * 800, //MediaQuery.of(context).size.width * 0.6,
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
                child: Text(src == ChatMessageSource.provider ? 'Chat' : 'You', style: normal_14),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      width: 0.6 * 800, // MediaQuery.of(context).size.width * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: msgBubbleColor(messages[index].source),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.6 * 800, // MediaQuery.of(context).size.width * 0.6,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(messages[index].message, style: medium_20_050),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            if (src == ChatMessageSource.provider) ...[
              Text(
                style: normal_14,
                'model: ${messages[index].metadata["model"]}   usage: ${messages[index].metadata["usage"]}', 
              )
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void sendPrompt(String msg, TextEditingController controller) {
    var message = '{"type": "job", "bid": $_bid, "prompt": "$msg"}';
    _providerConnection.sendProviderMessage(message);
    controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    addMessage(ChatMessageSource.client, msg);
    addMessage(ChatMessageSource.internal, 'Client: $message');
    print('Sending message to provider $message');
  }

  final ScrollController messageListController = ScrollController(); 

  void scrollMessagesDown() {
    messageListController.animateTo(
      messageListController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  } 

  List<PopupMenuEntry<OrchataMenuItem>> buildMenu(BuildContext context) {
    return <PopupMenuEntry<OrchataMenuItem>>[
      const PopupMenuItem<OrchataMenuItem>(
        value: OrchataMenuItem.debug,
        child: Text('Debug'),
      )
    ];
  }

  void clearChat() {
    messages = [];
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var promptTextController = TextEditingController();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
              gradient: OrchidGradients.blackGradientBackground,
              ),
            ),
            Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 800),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Image.asset(OrchidAssetImage.logo_small_purple_path),
                        Expanded(child: Container()),
                        FilledButton(
                          onPressed: () { _providerConnection.connectProvider(); },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_connected ? 'Reroll' : 'Connect'),
                        ),
                        SizedBox(width: 5),
                        FilledButton(
                          onPressed: clearChat,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Clear Chat'),
                        ),
                        SizedBox(width: 5),
                        FilledButton(
                          onPressed: popAccountDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Account'),
                        ),
                        SizedBox(width: 5),
                        PopupMenuButton<OrchataMenuItem>(
                          initialValue: null,
                          onSelected: (OrchataMenuItem item) {
                            setState(() {
                              _debugMode = !_debugMode;
                            });
                          },
                          itemBuilder: buildMenu,
                          icon: const Icon(Icons.menu),
/*
                          child: IconButton.filled(
                            color: Colors.white,
                            icon: const Icon(Icons.menu),
                            onPressed: (OrchataMenuItem item) {
                              setState(() {
                                _debugMode = !_debugMode;
                              });
                            },
                          ),
*/
                          color: Colors.deepPurple,
//                          iconColor: Colors.white,
                          position: PopupMenuPosition.under,
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        controller: messageListController,
                        itemCount: messages.length,
                        itemBuilder: buildChatBubble,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: <Widget>[
                          IconButton.filled(
                            onPressed: () {
                              showGeneralDialog<String>(
                                context: context,
                                transitionDuration: Duration(milliseconds: 300),
                                pageBuilder: buildPromptDialog,
                                barrierDismissible: true,
                                barrierLabel: 'Prompt Settings',
                                transitionBuilder: (context, anim1, anim2, child) {
                                  return SlideTransition(
                                    position: Tween(begin: Offset(0, 0.8),
                                                    end: Offset(0,0.3)).animate(anim1),
                                    child: child,
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.more_horiz),
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: TextFormField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter a prompt',
                                hintStyle: normal_16_025_grey,
                              ),
                              style: medium_20_050,
                              autofocus: true,
                              controller: promptTextController,
                            ),
                          ),
                          SizedBox(width: 5),
                          IconButton.filled(
                            onPressed: () { accountSet() ? sendPrompt(promptTextController.text, promptTextController) 
                                                         : popAccountDialog(); },
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                    Text('Your bid is $_bid XDAI per token.', style: normal_14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
