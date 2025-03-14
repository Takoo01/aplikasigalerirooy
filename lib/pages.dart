// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:galleryapp/services/cloudinary_service.dart';
//
// class UploadArea extends StatefulWidget {
//   const UploadArea({super.key});
//
//   @override
//   State<UploadArea> createState() => _UploadAreaState();
// }
//
// class _UploadAreaState extends State<UploadArea> {
//   late TextEditingController _fileNameController;
//   FilePickerResult? selectedFile;
//   String? selectedAlbumId;
//   List<Map<String, dynamic>> albumList = [];
//   bool isBanned = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _fileNameController = TextEditingController();
//     _fetchAlbums();
//     _checkBannedStatus();
//   }
//
//   /// 🔹 Mengambil daftar album dari Firestore
//   Future<void> _fetchAlbums() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance.collection("albums").get();
//
//       if (snapshot.docs.isEmpty) {
//         print("No albums found.");
//         return;
//       }
//
//       setState(() {
//         albumList = snapshot.docs.map((doc) => {
//           "id": doc.id, // ✅ Ambil ID dokumen Firestore
//           "name": doc.data().containsKey("name") ? doc["name"] : "Tanpa Nama", // ✅ Null Safety
//         }).toList();
//       });
//
//       print("Album List: $albumList"); // 🔍 Debugging
//     } catch (e) {
//       print("Error fetching albums: $e"); // 🔍 Debugging error
//     }
//   }
//
//   /// 🔹 Mengecek apakah user terkena banned
//   Future<void> _checkBannedStatus() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final snapshot = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
//       setState(() {
//         isBanned = snapshot.data()?['banned'] == true;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (selectedFile == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text("Upload Area")),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Upload Area")),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             DropdownButtonFormField<String>(
//               value: selectedAlbumId,
//               items: albumList.map((album) {
//                 return DropdownMenuItem<String>(
//                   value: album["id"].toString(), // ✅ Null Safety
//                   child: Text(album["name"]),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedAlbumId = value;
//                 });
//               },
//               decoration: const InputDecoration(labelText: "Pilih Album"),
//             ),
//             TextFormField(
//               controller: _fileNameController,
//               decoration: const InputDecoration(labelText: "File Name"),
//             ),
//             TextFormField(
//               readOnly: true,
//               initialValue: selectedFile!.files.first.extension,
//               decoration: const InputDecoration(labelText: "Extension"),
//             ),
//             TextFormField(
//               readOnly: true,
//               initialValue: "${selectedFile!.files.first.size} bytes",
//               decoration: const InputDecoration(labelText: "Size"),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     child: const Text("Cancel"),
//                   ),
//                 ),
//                 const SizedBox(width: 25),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: selectedAlbumId == null ? null : _uploadFile,
//                     child: const Text("Upload"),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// 🔥 Proses Upload File ke Cloudinary
//   Future<void> _uploadFile() async {
//     if (isBanned) {
//       _showBannedDialog();
//       return;
//     }
//
//     String newFileName = _fileNameController.text.trim();
//     if (newFileName.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("File name cannot be empty!")),
//       );
//       return;
//     }
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//
//     // 🔹 Upload ke Cloudinary
//     final cloudinaryUploadResult = await uploadToCloudinary(selectedFile);
//     if (cloudinaryUploadResult == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Cannot Upload Your File.")),
//       );
//       return;
//     }
//
//     // 🔹 Simpan ke Firestore
//     final newUpload = {
//       "userId": user.uid,
//       "name": newFileName,
//       "url": cloudinaryUploadResult["url"], // ✅ Ambil dari hasil upload
//       "publicId": cloudinaryUploadResult["publicId"], // ✅ Ambil dari hasil upload
//       "uploadedAt": FieldValue.serverTimestamp(),
//       "extension": selectedFile!.files.first.extension,
//       "size": selectedFile!.files.first.size.toInt(),
//     };
//
//     try {
//       // 🔥 Simpan ke koleksi uploads (semua unggahan)
//       final uploadDoc =
//       await FirebaseFirestore.instance.collection("uploads").add(newUpload);
//
//       // 🔥 Simpan ke album yang dipilih
//       await FirebaseFirestore.instance
//           .collection("albums")
//           .doc(selectedAlbumId)
//           .collection("photos")
//           .doc(uploadDoc.id)
//           .set(newUpload);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("File Uploaded Successfully.")),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to upload: $e")),
//       );
//     }
//   }
//
//   /// 🔥 Dialog peringatan jika pengguna dibanned
//   void _showBannedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Akun Diblokir"),
//         content:
//         const Text("Anda tidak dapat mengunggah foto karena akun Anda telah diblokir."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _fileNameController.dispose();
//     super.dispose();
//   }
// }
