import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:galleryapp/browse_page.dart';
import 'package:galleryapp/main_page.dart';
import 'package:galleryapp/navigator_Page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth/auth_provider.dart';
import 'auth/login_page.dart';
import 'setting_page.dart';
import 'detail_page.dart';
import 'likes_page.dart';
import 'services/db_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Saya")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Anda belum login.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                },
                child: const Text("Login Sekarang"),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Gagal memuat profil")));
        }

        var userData = snapshot.data!;
        String username = userData['username'] ?? 'Pengguna';
        String profilePicture = userData['profileImage'] ?? 'assets/profil_default.jpg';
        String email = userData['email'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text("Profil Saya"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NavigatorPage())),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(profilePicture),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on), text: "Post"),  // Ikon grid untuk video
                  Tab(icon: Icon(Icons.favorite_border), text: "Disukai"), // Ikon hati untuk favorit
                  Tab(icon: Icon(Icons.bookmark), text: "Bookmark"), // Ikon hati terisi untuk disukai
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.black,
                indicatorWeight: 4,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUploadedImages(user.uid),
                    _buildLikedImages(user.uid),
                    _buildBookmarkedImages(user.uid),
                  ],
                ),
              ),



            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadedImages(String uid) {
    return _buildImageGrid('uploads', 'userId', uid);
  }

  Widget _buildLikedImages(String uid) {
    return LikesPage(); // Memanggil halaman LikesPage langsung
  }

  Widget _buildBookmarkedImages(String uid) {
    return BrowsePage(); // Memanggil halaman LikesPage langsung
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      File imageFile = File(result.files.single.path!);
      String? imageUrl = await _uploadToCloudinary(imageFile);
      if (imageUrl != null) {
        await _saveProfileImageUrl(imageUrl);
      }
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dcefoloxz/image/upload";
    String uploadPreset = "upload-profil";

    var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var jsonData = json.decode(responseData);
      return jsonData['secure_url'];
    } else {
      return null;
    }
  }



  Future<void> _saveProfileImageUrl(String imageUrl) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? uid = authProvider.user?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "profileImage": imageUrl,
    });
  }

  Widget _buildImageGrid(String collection, String field, String uid) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(collection).where(field, isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        List userFiles = snapshot.data!.docs;
        if (userFiles.isEmpty) {
          return const Center(child: Text("Tidak ada foto."));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: userFiles.length,
          itemBuilder: (context, index) {
            String fileUrl = userFiles[index]['url'];
            String publicId = userFiles[index].id; // Perbaikan disini!

            return GestureDetector(
              onLongPress: () => _showDeleteDialog(snapshot, index, publicId),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(imageUrl: fileUrl))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(fileUrl, fit: BoxFit.cover),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(AsyncSnapshot snapshot, int index, String publicId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Foto"),
        content: const Text("Apakah Anda yakin ingin menghapus foto ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tidak")),
          TextButton(
            onPressed: () async {
              final bool deleteResult = await DbService().deleteFile(snapshot.data!.docs[index].id, publicId);
              if (deleteResult) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto berhasil dihapus.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus foto.")));
              }
              Navigator.pop(context);
            },
            child: const Text("Iya"),
          ),
        ],
      ),
    );
  }

}
