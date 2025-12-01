import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_auth/firebase_auth.dart';

class AddRecipePage extends StatefulWidget {
  final VoidCallback? onSave;

  const AddRecipePage({super.key, this.onSave});

  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String description;
  late List<String> ingredients;
  late String instructions;
  late String category;
  String? imageBase64; // Simpan gambar dalam format Base64
  File? _imageFile;

  final List<String> categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Quick',
  ];

  @override
  void initState() {
    super.initState();
    name = '';
    description = '';
    ingredients = [];
    instructions = '';
    category = ''; // Default kategori
    imageBase64 = null;
    _imageFile = null;
  }

  Future<void> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    setState(() {
      imageBase64 = base64Encode(bytes);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _imageFile = imageFile;
      });
      await _convertImageToBase64(imageFile);
    } else {
      print("No image selected.");
    }
  }

  String getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    return '';
  }

  String getCurrentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      return user.displayName!;
    }
    return 'Unknown';
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String base64Image = '';
      if (_imageFile != null) {
        List<int> imageBytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final recipeData = {
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'category': category,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'image_base64': base64Image,
        'author_id': getCurrentUserId(),
        'created_by': getCurrentUserName(),
      };

      try {
        await FirebaseFirestore.instance.collection('recipes').add(recipeData);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error saving recipe: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save recipe. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF90AF17),
        elevation: 0,
        title: Text(
          'Add Recipe',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Color(0xFFF8F9FA),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              // Image Picker Section
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFFEFF6E7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF90AF17).withOpacity(0.3)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : InkWell(
                        onTap: _pickImage,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: Color(0xFF90AF17),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add Recipe Photo',
                              style: TextStyle(
                                color: Color(0xFF90AF17),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              SizedBox(height: 24),

              // Recipe Name Input
              TextFormField(
                decoration: _buildInputDecoration(
                  'Recipe Name',
                  Icons.restaurant_menu,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration(
                  'Category',
                  Icons.category,
                ),
                value: category.isNotEmpty ? category : null,
                items: categories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Category is required'
                    : null,
              ),
              SizedBox(height: 16),

              // Description Input
              TextFormField(
                decoration: _buildInputDecoration(
                  'Description',
                  Icons.description,
                ).copyWith(
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onSaved: (value) => description = value!,
              ),
              SizedBox(height: 16),

              // Ingredients Input
              TextFormField(
                decoration: _buildInputDecoration(
                  'Ingredients (comma separated)',
                  Icons.format_list_bulleted,
                ).copyWith(
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                onSaved: (value) => ingredients =
                    value?.split(',').map((e) => e.trim()).toList() ?? [],
              ),
              SizedBox(height: 16),

              // Instructions Input
              TextFormField(
                decoration: _buildInputDecoration(
                  'Instructions',
                  Icons.receipt_long,
                ).copyWith(
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                onSaved: (value) => instructions = value!,
              ),
              SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF90AF17),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _saveRecipe,
                child: Text(
                  'Save Recipe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF90AF17)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF90AF17)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF90AF17).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF90AF17), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
