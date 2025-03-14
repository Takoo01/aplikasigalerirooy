import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:galleryapp/album_page.dart';
import 'package:galleryapp/kotak_masuk.dart';
import 'package:galleryapp/likes_page.dart';
import 'package:galleryapp/main_page.dart';
import 'package:galleryapp/search_page.dart';
import 'package:galleryapp/uploadphoto.dart';
import 'package:galleryapp/profil_page.dart';
import 'package:galleryapp/browse_page.dart';
import 'package:galleryapp/coba.dart';
import 'package:galleryapp/kotak_masuk.dart'; // Tambahkan import ini

class NavigatorPage extends StatefulWidget {
  const NavigatorPage({Key? key}) : super(key: key);

  @override
  _NavigatorPageState createState() => _NavigatorPageState();
}

class _NavigatorPageState extends State<NavigatorPage> {
  int _selectedIndex = 0;

  // **Tambahkan docId untuk MessagePage**
  final String docId = "idDokumenPesan"; // Ganti dengan ID yang sesuai

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const MainPage(),
      const SearchPage(),
      UploadPhotoPage(onImageUploaded: () {}),
      MessagePage(docId: docId), // Pastikan docId ada
      const ProfilePage(),
    ]);
  }

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
    const BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 35), label: "Upload"),
    const BottomNavigationBarItem(icon: Icon(CupertinoIcons.mail), label: "Kotak masuk"),
    const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: "Profile"),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _navItems, // DIPANGGIL OTOMATIS DARI LIST
      ),
    );
  }
}
