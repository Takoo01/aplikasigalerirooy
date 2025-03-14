import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:galleryapp/admin_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _email = "";
  String? userRole; // Untuk menyimpan role user


  @override
  void initState() {
    super.initState();
    _email = _auth.currentUser?.email ?? "";
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    String? uid = _auth.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        userRole = userDoc.data()?['role']; // Mendapatkan role user
      });
    }
    _email = _auth.currentUser?.email ?? "";
  }


  Future<void> _updateUsername(String newUsername) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null || newUsername.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'username': newUsername});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username berhasil diperbarui")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memperbarui username: $e")));
    }
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diperbarui")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memperbarui password: $e")));
    }
  }

  void _showEditDialog(String title, Function(String) onSave) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Masukkan nilai baru")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    bool confirmLogout = await _showLogoutConfirmation();
    if (confirmLogout) {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda ingin Logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Tidak")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Iya")),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    String? uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          String username = userData?['username'] ?? 'Pengguna';

          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(username),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog("Ubah Username", _updateUsername),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Ganti Password"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog("Ganti Password", (newPassword) => _updatePassword("oldPassword", newPassword)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(_email),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: _logout,
              ),
              // 🔥 Hanya tampilkan tombol admin jika user adalah admin
              if (userRole == "admin")
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text("Admin Page"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage())),
                ),
            ],
          );
        },
      ),
    );
  }
}
