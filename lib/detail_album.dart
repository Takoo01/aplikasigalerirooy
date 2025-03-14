import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:galleryapp/services/cloudinary_service.dart'; // Pastikan import layanan Cloudinary

class AlbumDetailPage extends StatefulWidget {
  final String albumId;
  final String albumName;

  const AlbumDetailPage({super.key, required this.albumId, required this.albumName});

  @override
  _AlbumDetailPageState createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _addPhotoToAlbum,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('albums')
            .doc(widget.albumId)
            .collection('photos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Album ini kosong"));
          }

          var photos = snapshot.data!.docs;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              var photo = photos[index];
              return GestureDetector(
                onLongPress: () => _confirmDelete(photo.id, photo['publicId']), // Pakai Public ID
                child: Image.network(
                  photo['url'],
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// **Tambah Foto ke Album**
  void _addPhotoToAlbum() async {
    final snapshot = await _firestore.collection('uploads').get();

    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada foto yang tersedia.")),
      );
      return;
    }

    String? selectedPhotoUrl = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pilih Foto"),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                var photo = snapshot.docs[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, photo['url']),
                  child: Image.network(
                    photo['url'],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedPhotoUrl != null) {
      var selectedPhoto = snapshot.docs.firstWhere((doc) => doc['url'] == selectedPhotoUrl);
      await _firestore
          .collection('albums')
          .doc(widget.albumId)
          .collection('photos')
          .add({
        'url': selectedPhotoUrl,
        'publicId': selectedPhoto['publicId'], // Simpan Public ID dari Cloudinary
        'uploadedBy': _auth.currentUser!.uid, // Simpan user yang mengunggah
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto berhasil ditambahkan ke album!")),
      );
    }
  }

  /// **Konfirmasi Sebelum Menghapus**
  void _confirmDelete(String photoId, String publicId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Foto?"),
        content: const Text("Apakah Anda yakin ingin menghapus foto ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto(photoId, publicId);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// **Menghapus Foto dari Firestore & Cloudinary**
  void _deletePhoto(String photoId, String publicId) async {
    try {
      // **🔹 Hapus dari Cloudinary terlebih dahulu**
      bool deletedFromCloudinary = await deleteFromCloudinary(publicId);

      if (deletedFromCloudinary) {
        // **🔹 Jika berhasil, hapus dari Firestore**
        await _firestore
            .collection('albums')
            .doc(widget.albumId)
            .collection('photos')
            .doc(photoId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto berhasil dihapus!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus foto dari Cloudinary.")),
        );
      }
    } catch (e) {
      print("❌ Error saat menghapus foto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan saat menghapus foto.")),
      );
    }
  }
}
