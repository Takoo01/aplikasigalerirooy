import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagePage extends StatefulWidget {
  final String docId; // ID dokumen yang akan diambil dari Firestore

  const MessagePage({super.key, required this.docId});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesan")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('messages').doc(widget.docId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Jika dokumen tidak ditemukan
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(
              child: Text("❌ Dokumen tidak ditemukan"),
            );
          }

          // Ambil data dari dokumen
          Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;

          // Jika data kosong atau tidak memiliki field "message"
          if (data == null || !data.containsKey('message')) {
            return const Center(
              child: Text("⚠️ Pesan tidak tersedia"),
            );
          }

          // Debugging: Cetak data ke dalam console
          print("🔥 Data dari Firestore: $data");

          // Ambil pesan dari dokumen
          String message = data['message'];

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                message,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
