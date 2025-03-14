import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadedImagesProvider with ChangeNotifier {
  List<String> _uploadedImages = [];

  List<String> get uploadedImages => _uploadedImages;

  Future<void> fetchUploadedImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('images').get();
      _uploadedImages = snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
      notifyListeners();
    } catch (e) {
      print("❌ Error fetching images: $e");
    }
  }
}
