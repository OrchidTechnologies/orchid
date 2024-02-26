import 'package:flutter/material.dart';
//import 'guid_orchid/lib/common/app_buttons.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:stream_channel/isolate_channel.dart';
import 'dart:convert';

import 'package:orchid/gui-orchid/lib/orchid/orchid_action_button.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid_asset.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid_gradients.dart';
import 'package:orchid/gui-orchid/lib/orchid/orchid_logo.dart';

import 'chat.dart';
import 'settings.dart';
import 'app_colors.dart';

void main() {
//  ReceivePort _providerPort; // = ReceivePort();
//  IsolateChannel _providerChannel = new;
//  IsolateChannel _providerChannel = IsolateChannel.connectReceive();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orchid Genera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatView(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  OrchidAssetImage _orchidAsset = OrchidAssetImage();


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea( 
          child: Stack(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: OrchidGradients.blackGradientBackground,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[Center(child: _orchidAsset.logo_outline)],
              ),
              Container(
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          IconButton.filled(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsView()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OrchidActionButton(
                        text: 'Chat',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatView()),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      OrchidActionButton(
                        text: 'Txt2Img',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatView()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
