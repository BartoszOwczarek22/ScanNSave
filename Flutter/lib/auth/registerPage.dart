import 'package:scan_n_save/auth/verifyPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scan_n_save/providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}


class _RegisterPageState extends ConsumerState<RegisterPage> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isRegistering = ref.watch(isRegisteringProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarejestruj się'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                controller: emailController,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  border: OutlineInputBorder(),
                ),
                controller: passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              isRegistering
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async{
                        final email = emailController.text.trim();
                        final password = passwordController.text.trim();
                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wypełnij wszystkie pola!')),
                          );
                          return;
                        }
                        ref.read(isRegisteringProvider.notifier).state = true;
                        try{
                          await ref.read(registerProvider).registerWithEmailAndPassword(
                            email,
                            password,
                          );

                        
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zarejestrowano pomyślnie!')),
                          );

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => EmailVerificationPage()),
                            (Route<dynamic> route) => false,
                          );

                        } on FirebaseAuthException catch (e) {
                          String message = 'Wystąpił błąd rejestracji';
                          if (e.code == 'weak-password') {
                            message = 'Hasło jest zbyt słabe.';
                          } else if (e.code == 'email-already-in-use') {
                            message = 'Konto już istnieje dla tego adresu e-mail.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        
                        } catch (e) {
                          // Gdyby coś jeszcze poszło źle (np. problem z siecią)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Coś poszło nie tak. Spróbuj ponownie.')),
                          );
                        } finally {
                          ref.read(isRegisteringProvider.notifier).state = false;
                        }
                      },
                      child: const Text('Zarejestruj'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
