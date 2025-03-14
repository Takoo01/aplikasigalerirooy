import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Cari file...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
            });
          },
        ),
        backgroundColor: Colors.redAccent,
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = "";
                });
              },
            ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? _buildEmptySearch()
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("uploads")
            .where("name_lower", isGreaterThanOrEqualTo: _searchQuery)
            .where("name_lower", isLessThanOrEqualTo: "$_searchQuery\uf8ff")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoResults();
          }

          var results = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: results.length,
            itemBuilder: (context, index) {
              var file = results[index];
              bool isImage = ["png", "jpg", "jpeg", "gif"]
                  .contains(file["extension"]);
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: isImage
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      file["url"],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(Icons.insert_drive_file, size: 50, color: Colors.blue),
                  title: Text(
                    file["name"] ?? "Tanpa Nama",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Ukuran: ${file["size"]} bytes"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(imageUrl: file["url"]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("Masukkan nama file untuk mencari", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(color: Colors.redAccent));
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
          SizedBox(height: 10),
          Text("Tidak ada hasil ditemukan", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
