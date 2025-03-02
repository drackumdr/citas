import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web flow
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile flow (Android/iOS)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      User? user = userCredential.user;
      if (user != null) {
        // Verificar si el usuario ya existe en Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('usuarios').doc(user.uid).get();

        if (!userDoc.exists) {
          // Solo crear el documento si no existe el usuario
          await _firestore.collection('usuarios').doc(user.uid).set({
            'uid': user.uid,
            'nombre': user.displayName,
            'email': user.email,
            'especialidad': null, // Deberá ser actualizado después
            'telefono': null, // Deberá ser actualizado después
            'direccion': null, // Deberá ser actualizado después
            'horario': {
              'lunes': [],
              'martes': [],
              'miércoles': [],
              'jueves': [],
              'viernes': [],
              'sábado': [],
              'domingo': []
            },
            'foto': user.photoURL,
            'rol': 'paciente', // Por defecto es paciente
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        }
        // Si ya existe, conservamos sus datos incluyendo el rol
      }
      return user;
    } catch (e) {
      print("Error al autenticar con Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}
