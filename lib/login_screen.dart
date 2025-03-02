import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginScreen({super.key});

  Future<void> checkUserRole(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        String role = doc['rol'];

        if (role == "doctor") {
          Navigator.pushReplacementNamed(context, '/doctor_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/patient_dashboard');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Center(
        child: ElevatedButton.icon(
          icon: Image.asset('assets/google_logo.png',
              height: 24), // Agrega un icono de Google en assets
          label: const Text("Iniciar sesión con Google"),
          onPressed: () async {
            final user = await _authService.signInWithGoogle();
            if (user != null) {
              await checkUserRole(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al iniciar sesión")),
              );
            }
          },
        ),
      ),
    );
  }
}
