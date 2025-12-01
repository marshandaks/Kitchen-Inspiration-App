import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class SavedRecipesScreen extends StatefulWidget {
  @override
  _SavedRecipesScreenState createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  List<Map<String, dynamic>> savedRecipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedRecipes();
  }

  Future<void> _fetchSavedRecipes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ambil semua resep yang disimpan dari subkoleksi 'saved_recipes'
        QuerySnapshot savedDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_recipes')
            .get();

        // Ubah hasil query menjadi daftar resep
        List<Map<String, dynamic>> fetchedRecipes = savedDocs.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        if (mounted) {
          setState(() {
            savedRecipes = fetchedRecipes;
            isLoading = false;
          });
        }
      } else {
        // Jika tidak ada pengguna yang login
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching saved recipes: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saved Recipes"),
        backgroundColor: Color(0xFF90AF17),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : savedRecipes.isEmpty
              ? Center(child: Text("No saved recipes"))
              : ListView.builder(
                  itemCount: savedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = savedRecipes[index];
                    return ListTile(
                      leading: recipe['image_base64'] != null
                          ? Image.memory(
                              base64Decode(recipe['image_base64']),
                              fit: BoxFit.cover,
                              width: 50,
                              height: 50,
                            )
                          : Icon(Icons.image),
                      title: Text(recipe['name'] ?? "Unknown Recipe"),
                      subtitle: Text(recipe['description'] ?? "No description"),
                      onTap: () {
                        // Navigasi ke halaman detail resep
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailPage(recipe: recipe),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe['name'] ?? "Recipe Detail"),
        backgroundColor: Color(0xFF90AF17),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe['image_base64'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(
                    base64Decode(recipe['image_base64']),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
                ),
              SizedBox(height: 20),
              Text(
                recipe['name'] ?? "Unknown Recipe",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                recipe['description'] ?? "No description available.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              Text(
                "Ingredients:",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 10),
              if (recipe['ingredients'] != null)
                ...List<Widget>.from(
                  (recipe['ingredients'] as List<dynamic>).map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: Colors.green[700]),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Text(
                  "No ingredients available.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              SizedBox(height: 20),
              Text(
                "Instructions:",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 10),
              Text(
                recipe['instructions'] ?? "No instructions provided.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
