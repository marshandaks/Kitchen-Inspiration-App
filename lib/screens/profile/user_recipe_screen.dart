import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proyek_kel02/screens/home/recipe_detail_page.dart';
import 'package:flutter_proyek_kel02/size_config.dart';

import '../recipe/edit_recipe_page.dart';

class UserRecipeScreen extends StatefulWidget {
  @override
  _UserRecipeScreenState createState() => _UserRecipeScreenState();
}

class _UserRecipeScreenState extends State<UserRecipeScreen> {
  List<dynamic> userRecipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRecipes();
  }

  Future<void> _fetchUserRecipes() async {
    try {
      String authorId = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('author_id', isEqualTo: authorId)
          .get();

      setState(() {
        userRecipes = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Menyimpan ID dokumen
          return data;
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user recipes: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _deleteRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId) // Gunakan ID dokumen
          .delete();

      setState(() {
        userRecipes.removeWhere((recipe) => recipe['id'] == recipeId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe deleted successfully!')),
      );
    } catch (e) {
      print("Error deleting recipe: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recipe.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text("My Recipes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF90AF17),
        elevation: 5,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : userRecipes.isEmpty
                ? Center(child: Text("You don't have any recipes yet."))
                : Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: SizeConfig.defaultSize * 2),
                    child: ListView.builder(
                      itemCount: userRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = userRecipes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailPage(recipe: recipe),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding:
                                  EdgeInsets.all(SizeConfig.defaultSize * 1.5),
                              child: Row(
                                children: [
                                  // Informasi resep
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe['name'],
                                          style: TextStyle(
                                            fontSize:
                                                SizeConfig.defaultSize * 2.2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(
                                            height:
                                                SizeConfig.defaultSize * 0.5),
                                        Text(
                                          recipe['category'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize:
                                                SizeConfig.defaultSize * 1.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Ikon Edit
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.grey),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditRecipePage(
                                              recipeData: recipe,
                                              recipeId: recipe['id']),
                                        ),
                                      );
                                    },
                                  ),
                                  // Ikon Hapus
                                  IconButton(
                                    icon:
                                        Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () =>
                                        _deleteRecipe(recipe['id']),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
