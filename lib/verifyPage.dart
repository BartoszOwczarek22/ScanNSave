import 'package:scan_n_save/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                        Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => HomePage())
                        )
                      }, 
                      child: Text('Kontynuuj'),),
                    ])
                  )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sprawdź swoją skrzynkę i kliknij w link!'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: checkEmailVerification,
                      child: const Text('Klikąłem w link!'),
                    ),
                  ],
                ),
      ),
    );
  }
}

final emailVerificationProvider = StateProvider<bool>((ref) {
  return false;
});
