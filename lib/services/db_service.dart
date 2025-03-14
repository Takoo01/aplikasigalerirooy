import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:galleryapp/services/cloudinary_service.dart';

class DbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;

  DbService() {
    ensureUserRoleExists(); // ✅ Pastikan setiap user punya role
  }

  /// **Memastikan setiap user memiliki role (default: "user")**
  Future<void> ensureUserRoleExists() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists || !(userDoc.data() as Map<String, dynamic>).containsKey('role')) {
        await userRef.set({"role": "user"}, SetOptions(merge: true));
      }
    } catch (e) {
      print("❌ Error memastikan role user: $e");
    }
  }

  /// **Mengirim notifikasi ke user tertentu**
  Future<void> addNotification(String userId, String title, String content) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print("❌ Gagal mengirim notifikasi: User tidak ditemukan.");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      if (userData['role'] == 'banned') {
        print("⚠️ User dibanned, tidak dapat menerima notifikasi.");
        return;
      }

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ Notifikasi berhasil dikirim ke user $userId");
    } catch (e) {
      print("❌ Error mengirim notifikasi: $e");
    }
  }

  /// **Menghapus akun dan notifikasi setelah banned**
  Future<void> banUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({'role': 'banned'});

    QuerySnapshot notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    print("🚨 Akun $userId dibanned dan semua notifikasi dihapus.");
  }

  /// **Menyimpan file yang diunggah ke Firestore**
  Future<DocumentReference?> saveUploadedFilesData(Map<String, String> data) async {
    if (user == null) return null;

    try {
      if (data.containsKey("name")) {
        data["name_lower"] = data["name"]!.toLowerCase();
      }

      data["userId"] = user!.uid;

      DocumentReference docRef = await _firestore.collection("uploads").add(data);
      print("✅ Data berhasil disimpan dengan ID: ${docRef.id}");
      return docRef;
    } catch (e) {
      print("❌ Error menyimpan file: $e");
      return null;
    }
  }

  /// **Membaca semua file yang diunggah**
  Stream<QuerySnapshot> readUploadedFiles() {
    return _firestore.collection("uploads").snapshots();
  }

  /// **Membaca file yang diunggah oleh user saat ini**
  Stream<QuerySnapshot> readUploadedFilesForUser() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection("uploads")
        .where("userId", isEqualTo: userId)
        .snapshots();
  }

  /// **Mengupdate semua dokumen yang belum memiliki `name_lower`**
  Future<void> updateExistingUploads() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("❌ Tidak ada user yang login!");
      return;
    }

    try {
      var snapshot = await _firestore.collection('uploads').where('userId', isEqualTo: userId).get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        if (!doc.data().containsKey('name_lower')) {
          batch.update(doc.reference, {"name_lower": doc["name"].toLowerCase()});
        }
      }

      await batch.commit();
      print("✅ Semua dokumen berhasil diperbarui.");
    } catch (e) {
      print("❌ Error memperbarui name_lower: $e");
    }
  }

  /// **Mengambil role user saat ini**
  Future<String?> getUserRole() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['role'] : null;
    } catch (e) {
      print("❌ Error mengambil role user: $e");
      return null;
    }
  }

  /// **Menghapus file dari Cloudinary & Firestore**
  Future<bool> deleteFile(String docId, String publicId) async {
    if (publicId.isEmpty) {
      print("⚠️ publicId kosong, tidak bisa menghapus file.");
      return false;
    }

    try {
      print("🗑️ Menghapus file dengan publicId: '$publicId' dari Cloudinary...");
      final result = await deleteFromCloudinary(publicId);

      if (result) {
        await _firestore.collection("uploads").doc(docId).delete();
        print("✅ File berhasil dihapus dari Firestore & Cloudinary.");

        // 🔥 Tambahkan notifikasi setelah menghapus file
        await addNotification(user!.uid, "File Dihapus", "File dengan ID: $docId telah dihapus.");

        return true;
      } else {
        print("❌ Gagal menghapus file dari Cloudinary.");
        return false;
      }
    } catch (e) {
      print("❌ Error menghapus file: $e");
      return false;
    }
  }
}
