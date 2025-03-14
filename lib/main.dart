import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // ✅ Pakai alias!
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:galleryapp/coba.dart';
import 'package:galleryapp/navigator_Page.dart';
import 'package:galleryapp/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:galleryapp/auth/auth_provider.dart';
import 'package:galleryapp/auth/login_page.dart';
import 'package:galleryapp/main_page.dart';
import 'package:galleryapp/profil_page.dart';
import 'package:galleryapp/upload_area.dart';
import 'package:galleryapp/setting_page.dart';
import 'package:galleryapp/likes_page.dart';
import 'package:galleryapp/services/db_service.dart';

import 'package:galleryapp/providers/saved_images_provider.dart';
import 'package:galleryapp/providers/liked_photos_provider.dart';
import 'package:galleryapp/providers/uploaded_images_provider.dart';
import 'package:galleryapp/navigator_Page.dart';
import 'package:galleryapp/services/cloudinary_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  await dotenv.load();


// 🔥 Panggil updateExistingUploads sekali saat aplikasi mulai
  final dbService = DbService(); // ✅ Buat instance dari DbService
  await dbService.updateExistingUploads(); // ✅ Panggil fungsi dengan benar


  // 🔥 Ambil userId dari FirebaseAuth
  final user = firebase_auth.FirebaseAuth.instance.currentUser;
  final userId = user?.uid; // Bisa null jika belum login

  final savedImagesProvider = SavedImagesProvider();


  if (userId != null) {
    await savedImagesProvider.loadSavedImages(userId); // ✅ Load data jika user login
  }


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LikedPhotosProvider()),
        ChangeNotifierProvider(create: (context) => SavedImagesProvider()), // ✅ Pastikan ini ada
        ChangeNotifierProvider(create: (_) => UploadedImagesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallery App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AuthWrapper(), // 🔥 Gantilah dengan `AuthWrapper()`
      routes: {
        '/home': (context) => const NavigatorPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/upload': (context) => const UploadArea(),
        '/settings': (context) => const SettingsPage(),
        '/likes': (context) => const LikesPage(),
      },
    );
  }
}

// 🔥 Widget untuk Mengecek Status Login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true; // Awalnya tampilkan SplashScreen

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false; // Setelah 3 detik, tampilkan NavigatorPage
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash ? const SplashPage() : const NavigatorPage();
  }
}

