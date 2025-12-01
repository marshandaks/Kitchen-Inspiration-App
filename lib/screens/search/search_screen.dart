import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proyek_kel02/screens/home/recipe_detail_page.dart';
import 'package:flutter_proyek_kel02/screens/recipe/add_recipe_page.dart';
import 'package:flutter_proyek_kel02/size_config.dart';
import 'dart:convert';
import '../../components/my_bottom_nav_bar.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> recipes = [];
  bool isLoading = true;
  String selectedCategory = "All";
  Timer? _debounce;

  final List<String> categories = [
    "All",
    "Breakfast",
    "Lunch",
    "Dinner",
    "Quick"
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchRecipes(query: query);
    });
  }

  Future<void> _fetchRecipes({String query = ""}) async {
    setState(() => isLoading = true);
    try {
      Query recipesQuery = FirebaseFirestore.instance.collection('recipes');

      if (selectedCategory != "All") {
        recipesQuery =
            recipesQuery.where('category', isEqualTo: selectedCategory);
      }

      QuerySnapshot snapshot = await recipesQuery.get();

      if (mounted) {
        setState(() {
          recipes = snapshot.docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            };
          }).toList();

          if (query.isNotEmpty) {
            String queryLower = query.toLowerCase();
            List<String> searchTerms =
                queryLower.split(' ').where((term) => term.isNotEmpty).toList();

            recipes = recipes.where((recipe) {
              String searchableText = [
                (recipe['name'] ?? ''),
                (recipe['description'] ?? ''),
                (recipe['category'] ?? ''),
                (recipe['created_by'] ?? ''),
                ...(recipe['ingredients'] as List<dynamic>? ?? []),
              ].join(' ').toLowerCase();

              return searchTerms.every((term) => searchableText.contains(term));
            }).toList();

            recipes.sort((a, b) {
              String aName = (a['name'] ?? '').toLowerCase();
              String bName = (b['name'] ?? '').toLowerCase();

              bool aExactMatch = aName == queryLower;
              bool bExactMatch = bName == queryLower;
              if (aExactMatch != bExactMatch) {
                return aExactMatch ? -1 : 1;
              }

              bool aStartsWith = aName.startsWith(queryLower);
              bool bStartsWith = bName.startsWith(queryLower);
              if (aStartsWith != bStartsWith) {
                return aStartsWith ? -1 : 1;
              }

              return aName.compareTo(bName);
            });
          }

          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching recipes: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Search Recipes",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF90AF17),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF90AF17),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search recipes...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF90AF17)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Color(0xFF90AF17)),
                              onPressed: () {
                                searchController.clear();
                                _fetchRecipes();
                              },
                            )
                          : null,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                SizedBox(height: 16),
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      bool isSelected = selectedCategory == category;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Color(0xFF90AF17),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                            _fetchRecipes(query: searchController.text);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Color(0xFF90AF17),
                          checkmarkColor: Colors.white,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF90AF17)),
                    ),
                  )
                : recipes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) =>
                            _buildRecipeCard(recipes[index]),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF90AF17),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipePage()),
          );
          _fetchRecipes();
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Color(0xFF90AF17).withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            "No recipes found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202E2E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Try adjusting your search",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7286A5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: recipe['image_base64'] != null
                  ? Image.memory(
                      base64Decode(recipe['image_base64']),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: Color(0xFFEFF6E7),
                      child: Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Color(0xFF90AF17),
                      ),
                    ),
            ),
            // Recipe Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['name'] ?? 'Unnamed Recipe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202E2E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF90AF17).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                              fontSize: 12,
                              color: Color(0xFF7286A5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
