import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:galleryapp/providers/saved_images_provider.dart';
import 'package:provider/provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  AuthProvider() {
    _checkUserStatus();
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? newUser) {
      _user = newUser;
      notifyListeners();
    });
  }

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  void _checkUserStatus() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // 🔥 Fungsi Login
  Future<String?> login(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid;

      // 🔥 Reset & Load Saved Images untuk akun baru
      final savedImagesProvider =
      Provider.of<SavedImagesProvider>(context, listen: false);
      await savedImagesProvider.loadSavedImages(userId);

      notifyListeners();
      return null; // ✅ Return null jika login sukses
    } catch (e) {
      return e.toString(); // ✅ Return error message jika gagal
    }
  }

  // 🔥 Fungsi Register
  Future<String?> register(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Jangan sertakan field 'profileImage'
        await _firestore.collection('users').doc(user.uid).set({
          'banned': '',
          'username': username,
          'email': email,
          'role': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.updateDisplayName(username);
        await user.reload();
        _user = _auth.currentUser;
        notifyListeners();
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    }
  }

  // 🔥 Fungsi Logout
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();

    // 🔥 Reset daftar gambar setelah logout
    final savedImagesProvider =
    Provider.of<SavedImagesProvider>(context, listen: false);
    await savedImagesProvider.resetSavedImages();

    notifyListeners();
  }

  // 🔥 Sinkronisasi Data dari Firestore ke AuthProvider
  Future<void> _syncUserData(User user) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      String username = userDoc['username'] ?? user.displayName ?? "Pengguna";
      String profilePicture = userDoc['profileImage'] ?? "";

      if (user.displayName != username) {
        await user.updateDisplayName(username);
      }

      // Hanya update foto profil jika ada URL gambar yang valid
      if (profilePicture.isNotEmpty && user.photoURL != profilePicture) {
        await user.updatePhotoURL(profilePicture);
      }

      await user.reload();
      _user = _auth.currentUser;
      notifyListeners();
    }
  }

  // 🔥 Update Username
  Future<void> updateUsername(String newUsername) async {
    if (_user == null) return;

    await _firestore.collection('users').doc(_user!.uid).update({
      'username': newUsername,
    });

    await _user!.updateDisplayName(newUsername);
    await _user!.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  // 🔥 Update Foto Profil
  Future<void> updateProfilePicture(String imageUrl) async {
    if (_user == null) return;

    await _firestore.collection('users').doc(_user!.uid).update({
      'profileImage': imageUrl,
    });

    await _user!.updatePhotoURL(imageUrl);
    await _user!.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  // 🔥 Helper untuk Pesan Error
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Format email tidak valid.";
      case 'user-disabled':
        return "Akun ini telah dinonaktifkan.";
      case 'user-not-found':
        return "Akun tidak ditemukan.";
      case 'wrong-password':
        return "Password salah.";
      case 'email-already-in-use':
        return "Email sudah digunakan.";
      case 'weak-password':
        return "Gunakan password yang lebih kuat.";
      default:
        return "Terjadi kesalahan: ${e.message}";
    }
  }
}
