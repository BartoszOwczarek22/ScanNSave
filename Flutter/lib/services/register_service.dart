import 'package:firebase_auth/firebase_auth.dart';

class RegisterService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}