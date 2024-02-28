import 'package:flutter/material.dart';

import 'package:orchid/gui-orchid/lib/orchid/orchid_gradients.dart';
import 'package:orchid/gui-orchid/lib/orchid/field/orchid_text_field.dart';


class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}




class _SettingsViewState extends State<SettingsView> {
  final messageTextController = TextEditingController();

  @override
  void dispose() {
    messageTextController.dispose();
    super.dispose();
  }

  void goBack() {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            gradient: OrchidGradients.blackGradientBackground,
          ),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  IconButton.filled(
                    onPressed: () { Navigator.pop(context); },
                    icon: const Icon(Icons.arrow_back),
                  ),
                ]
              ),
              const SizedBox(height: 10),
              OrchidTextField(
                controller: TextEditingController(),
                hintText: 'Orchid Account Funder',
              ),
              const SizedBox(height: 10),
              OrchidTextField(
                hintText: 'Orchid Account Signer Key',
                obscureText: true,
                controller: TextEditingController(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}