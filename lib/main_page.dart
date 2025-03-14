import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:galleryapp/album_page.dart';
import 'package:galleryapp/services/db_service.dart';
import 'package:galleryapp/detail_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // 🔥 Cek koneksi internet


class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String? userRole; // 🔥 Role user (admin/user)
  bool isOffline = false; // 🔥 Status koneksi internet


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserRole(); // 🔥 Cek peran pengguna saat aplikasi dibuka
    _checkInternetConnection(); // 🔥 Cek koneksi internet saat aplikasi dibuka
  }

  /// 🔥 Cek koneksi internet
  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() => isOffline = true);
      _showNoInternetDialog(); // 🔥 Munculkan popup jika tidak ada internet
    } else {
      setState(() => isOffline = false);
    }
  }

  /// 🔥 Popup jika tidak ada koneksi internet
  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Tidak bisa ditutup dengan klik di luar
      builder: (context) => AlertDialog(
        title: const Text("Jaringan Tidak Tersedia"),
        content: const Text("Pastikan perangkat Anda terhubung ke internet."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup popup
              _checkInternetConnection(); // 🔥 Coba cek ulang koneksi
            },
            child: const Text("Refresh"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // 🔥 Tutup popup & kembali
            child: const Text("Kembali"),
          ),
        ],
      ),
    );
  }


  /// 🔥 Ambil role user dari Firestore
  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userRole = snapshot.data()?['role']; // Ambil role dari Firestore
      });
    }
  }

  /// 🔥 Fungsi untuk menghapus file dengan konfirmasi
  void _confirmDeleteFile(String docId, String publicId) {
    if (userRole != "admin") return; // 🔒 Hanya admin yang bisa hapus

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Foto"),
        content: const Text("Apakah Anda yakin ingin menghapus foto ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tidak"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              final bool deleteResult = await DbService().deleteFile(docId, publicId);
              if (deleteResult) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Foto berhasil dihapus")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal menghapus foto")),
                );
              }
            },
            child: const Text("Iya"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 🔹 TabBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Watch'),
                    Tab(text: 'Album'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black,
                  indicatorColor: Colors.red,
                  indicatorWeight: 4,
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 🔹 Watch Tab
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Jelajahi", // 🔥 Judul di atas
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: DbService().readUploadedFiles(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text("Tidak ada foto yang diunggah."));
                              }

                              List<QueryDocumentSnapshot> allUploadedFiles = snapshot.data!.docs;

                              return GridView.builder(
                                padding: const EdgeInsets.all(8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: allUploadedFiles.length,
                                itemBuilder: (context, index) {
                                  Map<String, dynamic> fileData =
                                  allUploadedFiles[index].data() as Map<String, dynamic>;
                                  String fileUrl = fileData["url"] ?? "";
                                  String ext = fileData["extension"] ?? "";
                                  String fileName = fileData["name"] ?? "Unknown";
                                  String docId = allUploadedFiles[index].id;

                                  // 🔥 Debug log
                                  print("File Name: $fileName, URL: $fileUrl, Extension: $ext");

                                  return GestureDetector(
                                    onLongPress: userRole == "admin"
                                        ? () => _confirmDeleteFile(docId, fileUrl)
                                        : null, // 🔥 Admin bisa hapus dengan long press
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailPage(imageUrl: fileUrl),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: fileUrl.isNotEmpty
                                                ? Image.network(
                                              fileUrl,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return const Center(
                                                    child: CircularProgressIndicator());
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.error,
                                                    color: Colors.red); // 🔥 Jika gagal tampilkan icon error
                                              },
                                            )
                                                : const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.image),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    fileName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // 🔹 Album Tab
                    const AlbumPage()
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
