import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/auth/logingPage.dart';
import 'package:scan_n_save/providers/auth_providers.dart';
import 'sharedprefsnotifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Ustawienia")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Tryb ciemny'),
            subtitle: const Text('Włącz/wyłącz ciemny motyw'),
            value: isDark,
            onChanged: (value) {
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
            secondary: const Icon(Icons.dark_mode),
          ), 
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
              ref.read(isLoadingProvider.notifier).state = false;
              ref.read(emailVerificationProvider.notifier).state = false;
            },
            child: const Text('wyloguj'),
          ),
        ],
      ),
    );
  }
}
