import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<String?> signWithGoogle() async {
  try {
    final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
    if (googleSignInAccount == null) {
      return null; // Usuario canceló el inicio de sesión
    }

    final GoogleSignInAuthentication googleSignInAuth = await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuth.accessToken,
      idToken: googleSignInAuth.idToken,
    );

    // Intenta autenticar al usuario con las credenciales de Google
    final UserCredential authResult = await _auth.signInWithCredential(credential);
    final User? user = authResult.user;

    if (user == null) return null;

    assert(!user.isAnonymous);
    final idToken = await user.getIdToken();
    assert(idToken != null);

    final User? currentUser = _auth.currentUser;
    assert(user.uid == currentUser?.uid);

    print("Hola, el usuario es: ${user.displayName}");
    return 'Accediste como ${user.email}';
  } catch (e, stackTrace) {
    // Agregando detalles para el debugging
    print("Error en el proceso de autenticación: $e");
    print("Stack trace: $stackTrace");
    return null;
  }
}

void signOutGoogle() async {
  await _googleSignIn.signOut();
  print("You're out");
  await _auth.signOut();
}
