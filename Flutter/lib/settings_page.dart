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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Ustawienia")),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color.fromRGBO(99, 171, 243, 0.1),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color.fromRGBO(99, 171, 243, 1.0),
                  child: Icon(Icons.person, size: 40, color: Colors.white,),
                ),
                const SizedBox(height: 12,),

                Text(user?.displayName ?? 'Użytkownik', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                
                Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                ),

                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified, size: 16, color: Colors.green,
                        ),
                        const SizedBox(width: 4,),
                        Text('Email zweryfikowany', style: TextStyle(fontSize: 12, color: Colors.green),)
                      ],
                    ),
                  )
              ],
            ),
          ),

          const SizedBox(height: 16,),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Preferencje', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600]),),
          ),

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
