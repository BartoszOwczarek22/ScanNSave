import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget{
  const ResetPasswordPage({Key? key}) : super(key:key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
  }

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resetowanie hasła')
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Podaj adres e-mail, aby otrzymać link do zresetowania hasła.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,),
            const SizedBox(height: 24,),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24,),
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wpisz adres e-mail')),
                  );
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wysłano e-mail z linkiem do resetowania hasła')),
                  );
                  Navigator.pop(context);
                } on FirebaseAuthException catch (e){
                  String message = 'Wystąpił błąd';
                  if (e.code == 'user-not-found') {
                    message = 'Nie znaleziono konta powiązanego z tym e-mailem';
                  } else if (e.code == 'invalid-email'){
                    message = 'Nieprawidłowy e-mail';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message))
                  );
                }
              },
              child: const Text('Wyślij link resetujący'),
              ),
          ],
        ),
      ),
    );
  }
  }
