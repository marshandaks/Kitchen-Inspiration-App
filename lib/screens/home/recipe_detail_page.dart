import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecipeDetailPage extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({required this.recipe, super.key});

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  bool _isSaved = false;
  late final User? _user;
  late final Stream<DocumentSnapshot> _savedStream;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _savedStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('saved_recipes')
          .doc(widget.recipe['id'])
          .snapshots();
    }
  }

  Future<void> _toggleSaveRecipe() async {
    if (_user == null) return;

    try {
      final recipeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('saved_recipes')
          .doc(widget.recipe['id']);

      if (_isSaved) {
        await recipeRef.delete();
        _showSnackBar("Recipe removed from saved recipes", Colors.red);
      } else {
        await recipeRef.set({
          'recipe_id': widget.recipe['id'],
          'name': widget.recipe['name'],
          'description': widget.recipe['description'],
          'category': widget.recipe['category'],
          'ingredients': widget.recipe['ingredients'],
          'instructions': widget.recipe['instructions'],
          'image_base64': widget.recipe['image_base64'],
          'created_by': widget.recipe['created_by'],
          'saved_at': FieldValue.serverTimestamp(),
          'author_id': widget.recipe['author_id'],
        });
        _showSnackBar("Recipe saved successfully!", Color(0xFF90AF17));
      }
    } catch (e) {
      print("Error toggling save recipe: $e");
      _showSnackBar("Failed to save/remove recipe", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecipeHeader(),
                  SizedBox(height: 24),
                  _buildIngredientsList(),
                  SizedBox(height: 24),
                  _buildInstructions(),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Color(0xFF90AF17),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildRecipeImage(),
            _buildGradientOverlay(),
          ],
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        if (_user != null)
          StreamBuilder<DocumentSnapshot>(
            stream: _savedStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _isSaved = snapshot.data!.exists;
              }
              return CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                    color: Color(0xFF90AF17),
                  ),
                  onPressed: _toggleSaveRecipe,
                ),
              );
            },
          ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRecipeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.recipe['name'] ?? 'Unnamed Recipe',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202E2E),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF90AF17).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.recipe['category'] ?? 'Uncategorized',
            style: TextStyle(
              color: Color(0xFF90AF17),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          widget.recipe['description'] ?? 'No description available',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7286A5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    final ingredients = widget.recipe['ingredients'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202E2E),
          ),
        ),
        SizedBox(height: 16),
        ...ingredients.map((ingredient) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record,
                      size: 8, color: Color(0xFF90AF17)),
                  SizedBox(width: 8),
                  Text(
                    ingredient.toString(),
                    style: TextStyle(fontSize: 16, color: Color(0xFF7286A5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202E2E),
          ),
        ),
        SizedBox(height: 16),
        Text(
          widget.recipe['instructions'] ?? 'No instructions available',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF7286A5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeImage() {
    final imageBase64 = widget.recipe['image_base64'];
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageBase64),
          fit: BoxFit.cover,
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Color(0xFF90AF17).withOpacity(0.1),
      child: Icon(
        Icons.restaurant,
        size: 80,
        color: Color(0xFF90AF17),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: [0.5, 1.0],
        ),
      ),
    );
  }

  // ... (implementasi widget helper lainnya)
}
