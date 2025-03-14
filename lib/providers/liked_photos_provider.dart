import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikedPhotosProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<String>> _likedPhotos = {}; // Menyimpan foto per user

  // Ambil foto yang disukai dari Firestore
  Future<void> loadLikedPhotos(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('likes') // ✅ Gunakan koleksi yang sesuai dengan rules
          .doc(userId)
          .collection('images')
          .get();

      _likedPhotos[userId] = snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
      notifyListeners();
    } catch (e) {
      print("❌ Error loading liked photos: $e");
    }
  }



  // Ambil daftar foto yang disukai
  List<String> getLikedPhotos(String userId) {
    return _likedPhotos[userId] ?? [];
  }

  // Tambahkan foto ke daftar yang disukai di Firestore
  Future<void> addLikedPhoto(String userId, String imageUrl) async {
    try {
      DocumentReference docRef = _firestore
          .collection('likes')
          .doc(userId)
          .collection('images')
          .doc(imageUrl.hashCode.toString());

      await docRef.set({'imageUrl': imageUrl, 'timestamp': FieldValue.serverTimestamp()});

      _likedPhotos[userId] ??= [];
      _likedPhotos[userId]!.add(imageUrl);
      notifyListeners();
    } catch (e) {
      print("❌ Error adding liked photo: $e");
    }
  }


  // Hapus foto dari daftar yang disukai di Firestore
  Future<void> removeLikedPhoto(String userId, String imageUrl) async {
    try {
      DocumentReference docRef = _firestore
          .collection('likes')
          .doc(userId)
          .collection('images')
          .doc(imageUrl.hashCode.toString());

      await docRef.delete();

      _likedPhotos[userId]?.remove(imageUrl);
      notifyListeners();
    } catch (e) {
      print("❌ Error removing liked photo: $e");
    }
  }


  // Cek apakah foto sudah disukai
  bool isLiked(String userId, String imageUrl) {
    return _likedPhotos[userId]?.contains(imageUrl) ?? false;
  }
}
