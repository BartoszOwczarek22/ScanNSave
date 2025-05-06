import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:scan_n_save/logingPage.dart';
import 'package:scan_n_save/registerPage.dart';
import 'package:scan_n_save/resetPasswordPage.dart';
import 'package:scan_n_save/verifyPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (kDebugMode) {
    const String devMachineIP =
        '10.0.2.2'; // Replace with your actual IP address

    await FirebaseAuth.instance.useAuthEmulator(devMachineIP, 9099);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
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

class HomePage extends ConsumerStatefulWidget {
  HomePage({super.key}) {}

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EmailVerificationPage()),
      );
    }
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kamera")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) => LoginPage())
                          );
            ref.read(isLoadingProvider.notifier).state = false;
            ref.read(emailVerificationProvider.notifier).state = false;
          },
          child: const Text('wyloguj'),
        ),
      ),
    );
  }
}
