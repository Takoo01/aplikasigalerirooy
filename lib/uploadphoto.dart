import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:galleryapp/auth/auth_provider.dart';
import 'package:provider/provider.dart';


class UploadPhotoPage extends StatefulWidget {
  final VoidCallback onImageUploaded;

  const UploadPhotoPage({Key? key, required this.onImageUploaded}) : super(key: key);

  @override
  _UploadPhotoPageState createState() => _UploadPhotoPageState();
}

class _UploadPhotoPageState extends State<UploadPhotoPage> {
  File? _selectedFile;
  bool _isUploading = false;
  String _username = "Pengguna";
  String? _uid;


  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _uid = user.uid;
      });

    }
  }

  FilePickerResult? _filePickerResult;


  void _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        allowedExtensions: ["jpg", "jpeg", "png", "mp4"],
        type: FileType.custom);
    setState(() {
      _filePickerResult = result;
    });

    if (_filePickerResult != null) {
      Navigator.pushNamed(context, "/upload", arguments: _filePickerResult);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Anda belum login.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
          ),
        ),


      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Foto")),
      body: Center(
        child: ElevatedButton(
          onPressed: _openFilePicker,
          child: const Text("Pilih Foto"),
        ),
      ),
    );
  }
}
