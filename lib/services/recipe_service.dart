import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menambahkan resep baru
  Future<void> addRecipe({
    required String name,
    required String description,
    required List<String> ingredients,
    required String instructions,
    required String category,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final authorId = user?.uid ?? 'Anonymous';

    try {
      await _firestore.collection('recipes').add({
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'image_url': imageUrl,
        'category': category,
        'author_id': authorId,
      });
    } catch (e) {
      print("Error adding recipe: $e");
      throw e;
    }
  }

  // Memperbarui resep yang ada
  Future<void> updateRecipe({
    required String recipeId,
    required String name,
    required String description,
    required List<String> ingredients,
    required String instructions,
    required String category,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final authorId = user?.uid ?? 'Anonymous';

    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'updated_at': FieldValue.serverTimestamp(),
        'image_url': imageUrl,
        'category': category,
        'author_id': authorId,
      });
    } catch (e) {
      print("Error updating recipe: $e");
      throw e;
    }
  }

  // Mengambil daftar resep
  Future<List<Map<String, dynamic>>> getRecipes() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('recipes').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching recipes: $e");
      throw e;
    }
  }

  // Menghapus resep
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).delete();
    } catch (e) {
      print("Error deleting recipe: $e");
      throw e;
    }
  }
}
