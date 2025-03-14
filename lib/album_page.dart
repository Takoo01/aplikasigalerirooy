import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_album.dart';

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  final TextEditingController _albumController = TextEditingController();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userRole = snapshot.data()?['role'];
      });
    }
  }

  Future<String?> _fetchAlbumCover(String albumId) async {
    final photos = await FirebaseFirestore.instance
        .collection("albums")
        .doc(albumId)
        .collection("photos")
        .orderBy("uploadedAt", descending: false) // Ambil foto pertama
        .limit(1)
        .get();

    if (photos.docs.isNotEmpty) {
      return photos.docs.first["url"]; // Ambil URL foto pertama
    }
    return null; // Jika tidak ada foto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Album Foto", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (userRole == "admin")
            IconButton(
              icon: const Icon(Icons.add, size: 30),
              onPressed: () {}, // Fungsi tetap sama
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection("albums").orderBy("createdAt", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada album"));
                }
                var albums = snapshot.data!.docs;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      var album = albums[index];
                      return FutureBuilder<String?>(
                        future: _fetchAlbumCover(album.id),
                        builder: (context, coverSnapshot) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlbumDetailPage(albumId: album.id, albumName: album["name"] ?? "Tanpa Nama"),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: coverSnapshot.connectionState == ConnectionState.waiting
                                        ? Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: CircularProgressIndicator()),
                                    )
                                        : coverSnapshot.data != null
                                        ? Image.network(
                                      coverSnapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                        : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  album["name"] ?? "Tanpa Nama",
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
