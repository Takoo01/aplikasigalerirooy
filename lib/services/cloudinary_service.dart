// uploading files to cloudinary
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:galleryapp/services/db_service.dart';
import 'package:galleryapp/main_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:http/http.dart" as http;
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';// For accessing device directories

Future<String?> uploadToCloudinary(FilePickerResult? filePickerResult) async {
  if (filePickerResult == null || filePickerResult.files.isEmpty) {
    print("No file selected!");
    return null;
  }

  File file = File(filePickerResult.files.single.path!);

  String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  // Buat request ke Cloudinary
  var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload");
  var request = http.MultipartRequest("POST", uri);

  // Tambahkan file ke request
  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: file.path.split("/").last,
    ),
  );

  request.fields['upload_preset'] = "preset-for-file-upload";
  request.fields['resource_type'] = "raw";

  // Kirim request
  var response = await request.send();
  var responseBody = await response.stream.bytesToString();

  print(responseBody); // Debugging

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(responseBody);

    // Ambil URL dari respons Cloudinary
    String uploadedFileUrl = jsonResponse["secure_url"];

    return uploadedFileUrl; // ✅ Kembalikan URL, bukan bool
  } else {
    print("Upload failed with status: ${response.statusCode}");
    return null; // ❌ Jangan return `false`
  }
}


//tambahan untuk daftar file unggah
class CloudinaryService {

  Future<List<Map<String, dynamic>>> fetchUploadedFiles() async {

    try {
      String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      String apiSecret = dotenv.env['CLOUDINARY_SECRET_KEY'] ?? '';

      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      String toSign = 'timestamp=$timestamp$apiSecret';
      var bytes = utf8.encode(toSign);
      var digest = sha1.convert(bytes);
      String signature = digest.toString();

      var uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/resources/image',
      );

      var response = await http.get(
        uri,
        headers: {
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$apiKey:$apiSecret'))
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        List resources = jsonResponse['resources'];

        return resources.map((file) {
          return {
            "id": file["public_id"],
            "url": file["secure_url"],
            "format": file["format"],
            "created_at": file["created_at"],
          };
        }).toList();
      } else {
        print("Failed to fetch images. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }
}



  Future<bool> deleteFromCloudinary(String publicId) async {
    await dotenv.load(); // Pastikan dotenv sudah dimuat

    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
    final apiSecret = dotenv.env['CLOUDINARY_SECRET_KEY'] ?? '';

    if (cloudName.isEmpty || apiKey.isEmpty || apiSecret.isEmpty) {
      print("❌ Cloudinary credentials tidak ditemukan!");
      return false;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String toSign = "public_id=$publicId&timestamp=$timestamp$apiSecret";
    final String signature = sha1.convert(utf8.encode(toSign)).toString();

    final url = "https://api.cloudinary.com/v1_1/$cloudName/image/destroy";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          "public_id": publicId,
          "api_key": apiKey,
          "timestamp": timestamp.toString(),
          "signature": signature,
        },
      );

      print("🌍 Cloudinary Response: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ File berhasil dihapus dari Cloudinary.");
        return true;
      } else {
        print("❌ Gagal menghapus file. Status Code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error saat menghapus file: $e");
      return false;
    }
  }




// download the user file inside the download folder
Future<bool> downloadFileFromCloudinary(String url, String fileName) async {
  try {
    // Request storage permission
    var status = await Permission.storage.request();
    var manageStatus = await Permission.manageExternalStorage.request();
    if (status == PermissionStatus.granted &&
        manageStatus == PermissionStatus.granted) {
      // The user has granted both permissions, so proceed
      print("Storage permissions granted");
    } else {
      // The user has permanently denied one or both permissions, so open the settings
      await openAppSettings();
    }

    // Get the Downloads directory
    Directory? downloadsDir = Directory('/storage/emulated/0/Download');
    if (!downloadsDir.existsSync()) {
      print("Downloads directory not found");
      return false;
    }

    // Create the file path
    String filePath = '${downloadsDir.path}/$fileName';

    // Make the HTTP GET request
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Write file to Downloads folder
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      print("Foto berhasi di unduh! Saved at: $filePath");
      return true;
    } else {
      print("Gagal mengunduh foto. Status code: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Error downloading file: $e");
    return false;
  }
}