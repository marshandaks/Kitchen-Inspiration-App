import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import '../../components/my_bottom_nav_bar.dart';
import '../recipe/add_recipe_page.dart';
import '../home/recipe_detail_page.dart'; // Import halaman detail resep

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

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
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot savedDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_recipes')
            .orderBy('saved_at', descending: true)
            .get();

        if (mounted) {
          setState(() {
            savedRecipes = savedDocs.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();
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

  Future<void> _removeRecipe(String recipeId, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_recipes')
            .doc(recipeId)
            .delete();

        setState(() {
          savedRecipes.removeAt(index);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recipe removed from saved'),
              backgroundColor: Color(0xFF90AF17),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.white,
                onPressed: _fetchSavedRecipes,
              ),
            ),
          );
        }
      } catch (e) {
        print("Error removing recipe: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove recipe'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF90AF17),
        title: Text(
          "Saved Recipes",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (savedRecipes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildSortingOptions(),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF90AF17)),
              ),
            )
          : savedRecipes.isEmpty
              ? _buildEmptyState()
              : _buildRecipeList(),
      bottomNavigationBar: MyBottomNavBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: Color(0xFF90AF17).withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            "No saved recipes yet",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF202E2E),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Your bookmarked recipes will appear here",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7286A5),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.search),
            label: Text("Browse Recipes"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF90AF17),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              // Navigate to search or home screen
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    return RefreshIndicator(
      color: Color(0xFF90AF17),
      onRefresh: _fetchSavedRecipes,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: savedRecipes.length,
        itemBuilder: (context, index) => _buildRecipeCard(index),
      ),
    );
  }

  Widget _buildRecipeCard(int index) {
    final recipe = savedRecipes[index];
    return Dismissible(
      key: Key(recipe['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) => _removeRecipe(recipe['id'], index),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailPage(recipe: recipe),
              ),
            ).then((_) => _fetchSavedRecipes());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecipeImage(recipe),
              _buildRecipeInfo(recipe),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Map<String, dynamic> recipe) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: recipe['image_base64'] != null
                ? Image.memory(
                    base64Decode(recipe['image_base64']),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Color(0xFFEFF6E7),
                    child: Icon(
                      Icons.restaurant,
                      size: 50,
                      color: Color(0xFF90AF17),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  "30 min",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeInfo(Map<String, dynamic> recipe) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF90AF17).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recipe['category'] ?? 'Uncategorized',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF90AF17),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Spacer(),
              Icon(
                Icons.bookmark,
                size: 20,
                color: Color(0xFF90AF17),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            recipe['name'] ?? 'Unnamed Recipe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF202E2E),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF90AF17).withOpacity(0.1),
                child: Text(
                  (recipe['created_by'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFF90AF17),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  recipe['created_by'] ?? 'Unknown Chef',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7286A5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortingOptions() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Recently Saved'),
            onTap: () {
              setState(() {
                savedRecipes.sort((a, b) {
                  final aTime = (a['saved_at'] as Timestamp).toDate();
                  final bTime = (b['saved_at'] as Timestamp).toDate();
                  return bTime.compareTo(aTime);
                });
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.sort_by_alpha),
            title: Text('Name (A-Z)'),
            onTap: () {
              setState(() {
                savedRecipes.sort((a, b) => (a['name'] ?? '')
                    .toString()
                    .compareTo((b['name'] ?? '').toString()));
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('Category'),
            onTap: () {
              setState(() {
                savedRecipes.sort((a, b) => (a['category'] ?? '')
                    .toString()
                    .compareTo((b['category'] ?? '').toString()));
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
