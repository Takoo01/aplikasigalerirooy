import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:galleryapp/pages.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/saved_images_provider.dart';
import 'providers/liked_photos_provider.dart';
import 'package:galleryapp/services/db_service.dart';
import 'package:galleryapp/services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';




class DetailPage extends StatefulWidget {
  final String imageUrl;

  const DetailPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}


class _DetailPageState extends State<DetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLiked = false;
  bool _isSaved = false;
  String? _profileImagePath;
  String _username = "Pengguna";

  @override
  void initState() {
    super.initState();
    debugSharedPreferences();  // Tambahkan ini untuk debugging
    _loadUserData(). then((_) => _loadComments());
    _loadComments();
    _checkIfLikedAndSaved();
  }

  /// **Memuat username & foto profil dari Firebase Authentication**
  Future<void> _loadUserData() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc = await firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      setState(() {
        _username = userDoc['username'] ?? "Pengguna";
        _profileImagePath = userDoc['profileImage'] ?? "assets/default_avatar.png";
      });
    }
  }




  Future<void> debugSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("🔍 Semua data di SharedPreferences:");
    for (String key in prefs.getKeys()) {
      print("$key: ${prefs.get(key)}");
    }
  }

  void _checkIfLikedAndSaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final likedProvider = Provider.of<LikedPhotosProvider>(context, listen: false);
      final savedProvider = Provider.of<SavedImagesProvider>(context, listen: false);
      setState(() {
        _isLiked = likedProvider.isLiked(userId, widget.imageUrl);
        _isSaved = savedProvider.isSaved(userId, widget.imageUrl);
      });
    }
  }



  // Fungsi untuk mengambil komentar dari Firestore
  Future<void> _loadComments() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String imageId = widget.imageUrl.hashCode.toString();

    QuerySnapshot snapshot = await firestore
        .collection('comments')
        .doc(imageId)
        .collection('user_comments')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> fetchedComments = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return {
        "uid": data['uid'],
        "username": data['username'] ?? 'Pengguna',
        "profileImage": data['profileImage'] ?? "assets/default_avatar.png",
        "comment": data['comment'],
        "likes": data['likes'] ?? 0,
      };
    }).toList();

    setState(() {
      _comments = fetchedComments;
    });
  }

  // Fungsi untuk menambahkan komentar ke Firestore
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String imageId = widget.imageUrl.hashCode.toString();

    await firestore.collection('comments').doc(imageId).collection('user_comments').add({
      "uid": uid,
      "username": _username,
      "profileImage": _profileImagePath,
      "comment": _commentController.text.trim(),
      "likes": 0,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    _loadComments();
  }

  void _toggleLike(int index) async {
    setState(() {
      _comments[index]["likes"] += 1;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedComments = _comments
        .map((c) => "${c['uid']}::${c['username']}::${c['profileImage'] ?? 'null'}::${c['comment']}::${c['likes']}")
        .toList();
    await prefs.setStringList(widget.imageUrl, savedComments);
  }


  void toggleSaveImage(BuildContext context) async {
    final provider = Provider.of<SavedImagesProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login!')),
      );
      return;
    }


    if (provider.isSaved(userId, widget.imageUrl)) {
      await provider.removeImage(context, userId, widget.imageUrl).then((success) {
        if (success) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Image remove to Private Photos')),
          );
        }
      });
    } else {
      await provider.addImage(context, userId, widget.imageUrl).then((success) {
        if (success) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Image saved to Private Photos')),
          );
        }
      });


    }
  }





  void toggleLikePhoto(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login!')),
      );
      return;
    }

    final provider = Provider.of<LikedPhotosProvider>(context, listen: false);
    final String userId = user.uid;
    String message;

    if (_isLiked) {
      await provider.removeLikedPhoto(userId, widget.imageUrl);
      message = 'Anda telah menghapus like!';
    } else {
      await provider.addLikedPhoto(userId, widget.imageUrl);
      message = 'Foto berhasil di-like!';
    }

    setState(() {
      _isLiked = !_isLiked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final bool isSaved = userId != null && Provider.of<SavedImagesProvider>(context).isSaved(userId, widget.imageUrl);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(widget.imageUrl), // Gunakan imageUrl

                    fit: BoxFit.contain,

                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.2),
                              child: const Icon(
                                CupertinoIcons.chevron_back,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                      _isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => toggleLikePhoto(context),
                ),
                Row(
                  children: [
                    buildButton(
                      text: 'Comments',
                      color: Colors.grey[200]!,
                      onTap: () => _showCommentSection(context),
                    ),

                    Consumer<SavedImagesProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaved ? Colors.red : Theme.of(context).colorScheme.secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => toggleSaveImage(context),
                          child: Text(isSaved ? 'Unsave' : 'Save'),
                        );
                      },
                    ),

                  ],
                ),
                IconButton(
                  onPressed: () async {
                    final downloadResult = await downloadFileFromCloudinary(widget.imageUrl, 'downloaded_image');
                    if (downloadResult) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("File downloaded"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error in downloading the file."),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                ),              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentSection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 500,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header Komentar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Komentar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Daftar Komentar
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  String profileImage = comment["profileImage"] ?? "assets/default_avatar.png";

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foto Profil
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: profileImage.startsWith("http")
                                ? NetworkImage(profileImage)
                                : const AssetImage("assets/default_avatar.png") as ImageProvider,
                          ),

                          const SizedBox(width: 10),

                          // Username & Komentar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment["username"] ?? "Pengguna",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  comment["comment"] ?? "",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                          // Tombol Like
                          Column(
                            children: [
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(thickness: 0.5),
                    ],
                  );
                },
              ),
            ),

            // Input Komentar
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10),
              child: Row(
                children: [
                  // Foto Profil Pengguna Saat Ini
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _profileImagePath != null
                        ? (_profileImagePath!.startsWith("http")
                        ? NetworkImage(_profileImagePath!) as ImageProvider
                        : FileImage(File(_profileImagePath!)) as ImageProvider)
                        : const AssetImage("assets/default_avatar.png"),
                  ),
                  const SizedBox(width: 10),

                  // Input Field Komentar
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        hintText: "Tambahkan komentar...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Tombol Kirim
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget buildButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,  // Use backgroundColor instead of primary
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

}
