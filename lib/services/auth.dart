import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quran_app_flutter/services/api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Add this method to get the JWT token
  Future<String?> getIdToken() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Force token refresh if needed
      try {
        return await user.getIdToken(true);
      } catch (err) {
        print("getIdToken error: $err");
      }
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {}
    try {
      await GoogleSignIn().signOut();
    } catch (e) {}
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerUserWithEmailAndPassword(
      String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    final credentials =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // send the token to the API
    try {
      if (credentials.credential?.accessToken != null &&
          credentials.credential!.accessToken!.isNotEmpty) {
        final form = {
          "uid": credentials.user?.uid,
          "email": credentials.user?.email,
          "name": credentials.user?.displayName ?? "Unknown",
        };
        print("Form: $form");
        final resp = await apiService.post(
          path: "/api/v1/login",
          data: form,
        );

        if (resp != null && resp?.statusCode == 200) {
          print("Successfully synced the user to API");
        } else {
          print("Failed to sync the user to API: ${resp?.data}");
        }
      }
    } catch (err) {
      print("Failed to sync the user to API ERROR: $err");
    }

    return credentials;
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    if (loginResult.accessToken == null) {
      // User cancelled the login
      return Future.error('User cancelled the login');
    }

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(
      loginResult.accessToken!.tokenString,
    );

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }
}
