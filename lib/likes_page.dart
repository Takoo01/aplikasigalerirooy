import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:galleryapp/providers/liked_photos_provider.dart';
import 'detail_page.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({Key? key}) : super(key: key);

  @override
  _LikesPageState createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  String? _uid;
  late LikedPhotosProvider _likedPhotosProvider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedPhotos();
  }

  Future<void> _loadLikedPhotos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
      _likedPhotosProvider = Provider.of<LikedPhotosProvider>(context, listen: false);
      await _likedPhotosProvider.loadLikedPhotos(_uid!);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Liked Photos")),
        body: const Center(
          child: Text(
            "Anda belum login.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<LikedPhotosProvider>(
        builder: (context, provider, child) {
          final likedPhotos = provider.getLikedPhotos(_uid!);
          if (likedPhotos.isEmpty) {
            return const Center(child: Text("No liked photos yet!"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: likedPhotos.length,
            itemBuilder: (context, index) {
              final imageUrl = likedPhotos[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(imageUrl: imageUrl),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          await provider.removeLikedPhoto(_uid!, imageUrl);
                          setState(() {}); // ✅ Tambahkan ini agar UI diperbarui langsung
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
