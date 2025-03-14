import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedImagesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<String>> _savedImages = {}; // Menyimpan foto per user

  /// Cek apakah gambar sudah disimpan
  bool isSaved(String userId, String imageUrl) {
    return _savedImages[userId]?.contains(imageUrl) ?? false;
  }



  /// Load saved images dari Firestore & cache lokal
  Future<void> loadSavedImages(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ Tidak ada user yang login!");
      resetSavedImages();
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('saved_images')
          .doc(userId)
          .collection('images')
          .get();

      _savedImages[userId] = snapshot.docs.map((doc) => doc['url'] as String).toList();
      notifyListeners();
      print("✅ Data dari Firestore: $_savedImages");
    } catch (e) {
      print("⚠️ Gagal mengambil dari Firestore: $e");
    }
  }



  /// Reset saved images
  Future<void> resetSavedImages() async {
    _savedImages.clear();
    notifyListeners();
  }

  /// Ambil daftar foto yang disimpan
  List<String> getSavedPhotos(String userId) {
    return _savedImages[userId] ?? [];
  }

  /// Encode image URL agar aman disimpan sebagai dokumen Firestore
  String encodeImageUrl(String imageUrl) {
    return base64Url.encode(utf8.encode(imageUrl));
  }

  /// Simpan data ke cache lokal
  Future<void> _saveToStorage(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_images_$userId", json.encode(_savedImages[userId] ?? []));
    print("✅ Data gambar berhasil disimpan ke cache");
  }

  /// Tambahkan gambar ke daftar tersimpan
  Future<bool> addImage(BuildContext context, String userId, String imageUrl) async {
    if (_savedImages[userId]?.contains(imageUrl) ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Gambar sudah ada di daftar tersimpan!")),
      );
      return false; // Gambar sudah ada, tidak perlu menyimpan ulang
    }

    try {
      DocumentReference docRef = _firestore
          .collection('saved_images')
          .doc(userId)
          .collection('images')
          .doc(encodeImageUrl(imageUrl));

      await docRef.set({
        'url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _savedImages[userId] ??= [];
      _savedImages[userId]!.add(imageUrl);
      await _saveToStorage(userId);

      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Gambar berhasil disimpan!")),
      );
      print("🟢 Gambar ditambahkan: $imageUrl");
      return true; // Sukses menyimpan gambar
    } catch (e) {
      print("❌ Gagal menyimpan gambar: $e");
      return false; // Gagal menyimpan
    }
  }


  /// Hapus gambar dari daftar tersimpan
  Future<bool> removeImage(BuildContext context, String userId, String imageUrl) async {
    try {
      DocumentReference docRef = _firestore
          .collection('saved_images')
          .doc(userId)
          .collection('images')
          .doc(encodeImageUrl(imageUrl));

      await docRef.delete();
      _savedImages[userId]?.remove(imageUrl);
      await _saveToStorage(userId);

      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🛑 Gambar berhasil dihapus!")),
      );
      print("🛑 Gambar dihapus: $imageUrl");

      return true; // ✅ Sukses menghapus gambar
    } catch (e) {
      print("❌ Gagal menghapus gambar: $e");

      return false; // ❌ Gagal menghapus gambar
    }
  }

}
