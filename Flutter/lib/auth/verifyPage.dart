import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/api_service.dart';
import 'package:scan_n_save/auth/logingPage.dart';
import 'package:scan_n_save/providers/auth_providers.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  EmailVerificationPage({super.key})
  {}

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage>
    with WidgetsBindingObserver {
  //bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.currentUser?.sendEmailVerification();
    checkEmailVerification(); // sprawdź na starcie

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Aplikacja wróciła na pierwszy plan
      checkEmailVerification();
    }
  }

  Future<void> checkEmailVerification() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      if (mounted) {
        setState(() {
          ref.read(emailVerificationProvider.notifier).state =
              true; // Ustawienie stanu na zweryfikowany
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('E-mail został zweryfikowany!')));

        ApiService apiService = ApiService();
        apiService.sendUserToken();

        FirebaseAuth.instance.signOut();
        Navigator.pushNamedAndRemoveUntil(context, "/login", ( route) => false);
        // Opcjonalnie - przejście na inny ekran po weryfikacji
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = ref.watch(emailVerificationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weryfikacja e-maila')),
      body: Center(
        child:
            isVerified
                ? Center(
                  child: Column(
                    children: [
                      const Text('E-mail zweryfikowany! Możesz kontynuować.'),
                      ElevatedButton(onPressed: ()=>{
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home', // Trasa do ekranu logowania
                          (Route<dynamic> route) => false, // Usuwa wszystkie poprzednie strony
                        )
                      }, 
                      child: Text('Kontynuuj'),),
                    ])
                  )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sprawdź swoją skrzynkę i kliknij w link!'),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        }
                      },
                      child: const Text('Wróć do strony logowania'),
                    ),
                  ],
                ),
      ),
    );
  }
}


