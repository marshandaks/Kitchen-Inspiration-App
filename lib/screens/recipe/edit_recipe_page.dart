import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRecipePage extends StatefulWidget {
  final Map<String, dynamic> recipeData;
  final String recipeId;

  const EditRecipePage({required this.recipeData, required this.recipeId});

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String description;
  late List<String> ingredients;
  late String instructions;
  late String category;
  String? imageBase64;
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
    final recipe = widget.recipeData;
    name = recipe['name'] ?? '';
    description = recipe['description'] ?? '';
    ingredients = (recipe['ingredients'] as List<dynamic>)
        .map((item) => item.toString())
        .toList();
    instructions = recipe['instructions'] ?? '';
    category = recipe['category'] ?? '';
    imageBase64 = recipe['image_base64'];
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

  Future<void> _clearImage() async {
    setState(() {
      _imageFile = null;
      imageBase64 = null;
    });
  }

  Future<void> _updateRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String base64Image = imageBase64 ?? '';
      if (_imageFile != null) {
        List<int> imageBytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final updatedRecipe = {
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'category': category,
        'updated_at': FieldValue.serverTimestamp(),
        'image_base64': base64Image,
      };

      try {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipeId)
            .update(updatedRecipe);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe updated successfully!')),
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error updating recipe: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update recipe. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Input Name
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Recipe Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 16),

              // Input Description
              TextFormField(
                initialValue: description,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                maxLines: 3,
                onSaved: (value) => description = value!,
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: category.isNotEmpty ? category : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
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

              // Ingredients Input
              TextFormField(
                initialValue: ingredients.join(', '),
                decoration: InputDecoration(
                  labelText: 'Ingredients (comma separated)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onSaved: (value) => ingredients =
                    value?.split(',').map((e) => e.trim()).toList() ?? [],
              ),
              SizedBox(height: 16),

              // Instructions Input
              TextFormField(
                initialValue: instructions,
                decoration: InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                maxLines: 3,
                onSaved: (value) => instructions = value!,
              ),
              SizedBox(height: 20),

              // Image Picker
              if (_imageFile != null)
                Column(
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _clearImage,
                      child: Text('Clear Image'),
                    ),
                  ],
                )
              else if (imageBase64 != null)
                Column(
                  children: [
                    Image.memory(
                      base64Decode(imageBase64!),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Change Image'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick an Image'),
                ),
              SizedBox(height: 20),

              // Update Button
              ElevatedButton(
                onPressed: _updateRecipe,
                child: Text('Update Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
