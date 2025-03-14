import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userRole = snapshot.data()?['role'];
      });

      if (userRole != "admin") {
        Navigator.pop(context); // Kembali jika bukan admin
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    bool confirmDelete = await _showConfirmationDialog("Hapus Pengguna", "Apakah Anda yakin ingin menghapus pengguna ini?");
    if (confirmDelete) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    }
  }

  Future<void> _changeUserRole(String userId, String currentRole) async {
    String? newRole = await _showRoleSelectionDialog(currentRole);
    if (newRole != null && newRole != currentRole) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': newRole});
    }
  }

  Future<void> _banUser(String userId) async {
    bool confirmBan = await _showConfirmationDialog("Blokir Pengguna", "Apakah Anda yakin ingin memblokir pengguna ini?");
    if (confirmBan) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'banned': true});
    }
  }

  /// 🔥 Fungsi Unban User
  Future<void> _unbanUser(String userId) async {
    bool confirmUnban = await _showConfirmationDialog("Buka Blokir Pengguna", "Apakah Anda yakin ingin membuka blokir pengguna ini?");
    if (confirmUnban) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'banned': false});
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Tidak"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Iya"),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<String?> _showRoleSelectionDialog(String currentRole) async {
    String? selectedRole = currentRole;
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Peran Pengguna"),
        content: DropdownButton<String>(
          value: selectedRole,
          items: ["user", "admin"].map((role) {
            return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedRole = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selectedRole),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userRole != "admin") {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              bool isBanned = user['banned'] ?? false;

              return ListTile(
                title: Text(user['email'] ?? 'No Email'),
                subtitle: Text("Role: ${user['role'] ?? 'User'} | ${isBanned ? '🔴 BANNED' : '🟢 Active'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () => _changeUserRole(user.id, user['role'] ?? 'user'),
                    ),
                    if (!isBanned)
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.red),
                        onPressed: () => _banUser(user.id),
                      ),
                    if (isBanned)
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _unbanUser(user.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user.id),
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
