import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scan_n_save/auth/logingPage.dart';
import 'package:scan_n_save/auth/registerPage.dart';
import 'package:scan_n_save/auth/resetPasswordPage.dart';
import 'package:scan_n_save/auth/verifyPage.dart';
import 'package:scan_n_save/pages/home_page.dart';
import 'sharedprefsnotifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  /*if (kDebugMode) {
    const String devMachineIP =
        '10.0.2.2'; // Replace with your actual IP address

    await FirebaseAuth.instance.useAuthEmulator(devMachineIP, 9099);
  } */

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: AuthGate(),
      initialRoute: '/',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/reset-password': (context) => ResetPasswordPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  bool firstTime = true;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Jeszcze ładuje, pokazuj spinner
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Użytkownik zalogowany
          if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
            firstTime = false;
            return HomePage();
          } else {
            if (firstTime) {
              firstTime = false;
              return EmailVerificationPage();
            }
          }
        }
        firstTime = false;
        // Użytkownik NIE zalogowany
        return LoginPage();
      },
    );
  }
}

