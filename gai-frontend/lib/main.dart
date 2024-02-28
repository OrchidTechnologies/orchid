import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'chat/chat.dart';

void main() async {
  await UserPreferences.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orchid Genera',
      localizationsDelegates: OrchidLanguage.localizationsDelegates,
      supportedLocales: OrchidLanguage.supportedLocales,
      locale: OrchidLanguage.languageOverrideLocale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ChatView(),
    );
  }
}

