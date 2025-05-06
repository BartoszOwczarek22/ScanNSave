import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class  _LoginPageState extends ConsumerState<LoginPage> {
  // Kontrolery do pól tekstowych
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16),
          child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'e-mail',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wypełnij wszystkie pola!')),
                          );
                          return;
                        }

                        ref.read(isLoadingProvider.notifier).state = true;

                        try {
                          ref.read(isLoadingProvider.notifier).state = false;
                          await ref.read(authProvider).signIn(email, password);
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Zalogowano pomyślnie!')),
                          );
                          Navigator.pushReplacementNamed(context, '/home');
                        } on FirebaseAuthException catch (e) {
                          String message = 'Wystąpił błąd logowania';

                          if (e.code == 'user-not-found') {
                            message = 'Nie znaleziono użytkownika o takim adresie email.';
                          } else if (e.code == 'wrong-password') {
                            message = 'Błędne hasło.';
                          } else if (e.code == 'invalid-email') {
                            message = 'Nieprawidłowy format adresu email.';
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        } finally {
                          ref.read(isLoadingProvider.notifier).state = false;
                        
                        }
                      },
                      child: const Text('Login'),
                    ),
              Text("You don't have an account?"),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Register'),
              ),
            ],
          ),
        )
      ),
    );
  }
}

final isLoadingProvider = StateProvider<bool>((ref) {
  return false;
});


final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> signIn(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}