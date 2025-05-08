import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:scan_n_save/providers/auth_providers.dart';

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
      // appBar: AppBar(
      //   title: const Text('Login Page'),
      // ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Spacer(),
                
                    SvgPicture.asset(
                      'assets/icons/logo.svg',
                      colorFilter: ColorFilter.mode(Color.fromARGB(255, 99, 171, 243), BlendMode.srcIn), // <- tutaj ustawiasz kolor
                      width: 110,
                      height: 110,
                    ),
                    const SizedBox(height: 40),
                
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Hasło',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reset-password');
                        },
                        child:const Text('Nie pamiętasz hasła?', style: TextStyle(decoration: TextDecoration.underline),)),
                    ),
                    const SizedBox(height: 12),
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
                                if (mounted){
                                  ref.read(isLoadingProvider.notifier).state = false;
                                }
                              }
                            },
                            child: const Text('Zaloguj'),
                          ),
                    SizedBox(height: 16,),
                    Text("Nie masz jeszcze konta?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text('Zarejestruj'),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.login),
                      label: Text('Zaloguj się przez Google'),
                      onPressed: () async {
                        try {
                          ref.read(isLoadingProvider.notifier).state = true;
                          await ref.read(authProvider).signInWithGoogle();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/home');
                        } on FirebaseAuthException catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Błąd logowania Google: ${e.message}'))
                          );
                        } finally {
                          if (mounted){
                             ref.read(isLoadingProvider.notifier).state = false;
                          }
                        }
                      },
                    ),
                
                     Spacer(),  
                  ],
                ),
              ),
            ),
        );
        },
      ),
      ),
    );
  }
}


