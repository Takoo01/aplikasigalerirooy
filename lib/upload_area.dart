import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:galleryapp/services/cloudinary_service.dart';

class UploadArea extends StatefulWidget {
  const UploadArea({super.key});

  @override
  State<UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<UploadArea> {
  late TextEditingController _fileNameController;
  FilePickerResult? selectedFile;
  String? selectedAlbumId;
  List<Map<String, dynamic>> albumList = [];
  bool isBanned = false;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController();
    _fetchAlbums();
    _checkBannedStatus();
  }

  Future<void> _fetchAlbums() async {
    final snapshot = await FirebaseFirestore.instance.collection("albums").get();
    setState(() {
      albumList = snapshot.docs
          .map((doc) => {"id": doc.id, "name": doc["name"] as String})
          .toList();
    });
  }

  Future<void> _checkBannedStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      setState(() {
        isBanned = snapshot.data()?['banned'] == true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedFile == null) {
      selectedFile = ModalRoute.of(context)!.settings.arguments as FilePickerResult?;
      if (selectedFile != null) {
        _fileNameController.text = selectedFile!.files.first.name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Upload Area")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Area")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedAlbumId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("Unggah tanpa album"),
                ),
                ...albumList.map((album) {
                  return DropdownMenuItem<String>(
                    value: album["id"] as String,
                    child: Text(album["name"]),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAlbumId = value;
                });
              },
              decoration: const InputDecoration(labelText: "Pilih Album"),
            ),
            TextFormField(
              controller: _fileNameController,
              decoration: const InputDecoration(labelText: "File Name"),
            ),
            TextFormField(
              readOnly: true,
              initialValue: selectedFile!.files.first.extension,
              decoration: const InputDecoration(labelText: "Extension"),
            ),
            TextFormField(
              readOnly: true,
              initialValue: "${selectedFile!.files.first.size} bytes",
              decoration: const InputDecoration(labelText: "Size"),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isBanned) {
                        _showBannedDialog();
                        return;
                      }

                      String newFileName = _fileNameController.text.trim();
                      if (newFileName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("File name cannot be empty!")),
                        );
                        return;
                      }

                      // 🔹 Upload ke Cloudinary
                      String? uploadedFileUrl = await uploadToCloudinary(selectedFile);

                      if (uploadedFileUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cannot Upload Your File.")),
                        );
                        return;
                      }

                      // 🔥 Simpan di album jika dipilih, jika tidak simpan di `uploads`
                      if (selectedAlbumId != null) {
                        await FirebaseFirestore.instance
                            .collection("albums")
                            .doc(selectedAlbumId)
                            .collection("photos")
                            .add({
                          "name": newFileName,
                          "url": uploadedFileUrl,
                          "uploadedAt": FieldValue.serverTimestamp(),
                        });
                      } else {
                        await FirebaseFirestore.instance.collection("uploads").add({
                          "name": newFileName,
                          "url": uploadedFileUrl,
                          "uploadedAt": FieldValue.serverTimestamp(),
                          "userId": FirebaseAuth.instance.currentUser!.uid,
                        });
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("File Uploaded Successfully.")),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Upload"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBannedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Akun Diblokir"),
        content: const Text("Anda tidak dapat mengunggah foto karena akun Anda telah diblokir."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }
}
