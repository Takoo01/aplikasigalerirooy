import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/saved_images_provider.dart';
import 'detail_page.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({Key? key}) : super(key: key);

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  bool _isUnlocked = true;
  String _savedPassword = "1234";
  String? _uid;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = "User not logged in";
        _isLoading = false;
      });
      return;
    }

    _uid = user.uid;
    await _loadPassword();
    await _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    try {
      if (_uid == null) return;
      await Provider.of<SavedImagesProvider>(context, listen: false).loadSavedImages(_uid!);
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading images: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _loadPassword() async {
    if (_uid == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPassword = prefs.getString("browse_password_$_uid") ?? "1234";
    });
    // _showPasswordDialog();
  }

  // void _showPasswordDialog() {
  //   TextEditingController passwordController = TextEditingController();
  //
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text("Masukkan Kata Sandi"),
  //         content: TextField(
  //           controller: passwordController,
  //           keyboardType: TextInputType.number,
  //           obscureText: true,
  //           maxLength: 4,
  //           decoration: const InputDecoration(hintText: "Masukkan 4 digit sandi"),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               if (passwordController.text == _savedPassword) {
  //                 setState(() {
  //                   _isUnlocked = true;
  //                 });
  //                 Navigator.pop(context);
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(
  //                     content: Text("Kata sandi salah!"),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //                 passwordController.clear();
  //               }
  //             },
  //             child: const Text("OK"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _changePassword() {
  //   TextEditingController newPasswordController = TextEditingController();
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text("Ubah Kata Sandi"),
  //         content: TextField(
  //           controller: newPasswordController,
  //           keyboardType: TextInputType.number,
  //           obscureText: true,
  //           maxLength: 4,
  //           decoration: const InputDecoration(hintText: "Masukkan kata sandi baru (4 digit)"),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () async {
  //               final newPassword = newPasswordController.text;
  //
  //               if (newPassword.length == 4 && int.tryParse(newPassword) != null) {
  //                 final user = FirebaseAuth.instance.currentUser;
  //                 if (user != null) {
  //                   SharedPreferences prefs = await SharedPreferences.getInstance();
  //                   await prefs.setString("browse_password_${user.uid}", newPassword);
  //                   setState(() {
  //                     _savedPassword = newPassword;
  //                   });
  //                   Navigator.pop(context);
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text("Kata sandi berhasil diubah!"),
  //                       backgroundColor: Colors.green,
  //                     ),
  //                   );
  //                 }
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(
  //                     content: Text("Harap masukkan 4 digit angka!"),
  //                     backgroundColor: Colors.red,
  //                   ),
  //                 );
  //               }
  //             },
  //             child: const Text("Simpan"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final savedImagesProvider = Provider.of<SavedImagesProvider>(context);
    final savedImages = savedImagesProvider.getSavedPhotos(_uid!);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Saved Photos"),
      //   actions: [
      //     // if (_isUnlocked)
      //     //   IconButton(
      //     //     icon: const Icon(Icons.lock_reset),
      //     //     onPressed: _changePassword,
      //     //   ),
      //   ],
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : _isUnlocked
          ? savedImages.isEmpty
          ? const Center(child: Text("No saved photos yet!"))
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: savedImages.length,
        itemBuilder: (context, index) {
          final imageUrl = savedImages[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(imageUrl: imageUrl),
                ),
              );
            },
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      )
          : const Center(
        // child: Text(
        //   "Halaman ini terkunci.\nMasukkan kata sandi untuk mengakses.",
        //   textAlign: TextAlign.center,
        //   style: TextStyle(fontSize: 18),
        // ),
      ),
    );
  }
}
