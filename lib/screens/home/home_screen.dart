import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proyek_kel02/screens/recipe/add_recipe_page.dart';
import 'package:flutter_proyek_kel02/size_config.dart';
import 'package:flutter_proyek_kel02/components/my_bottom_nav_bar.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'recipe_detail_page.dart';

// Update color constants to match app theme
const Color kPrimaryColor = Color(0xFF90AF17); // Update dari 0xFF84AB5C
const Color kTextColor = Color(0xFF202E2E); // From constants.dart
const Color kTextLightColor = Color(0xFF7286A5); // From constants.dart
const Color kBackgroundColor = Color(0xFFF8F9FA);
const Color kSurfaceColor = Color(0xFFFFFFFF);
const Color kAccentColor = Color(0xFFEFF6E7);
const Color kShimmerBase = Color(0xFFE0E0E0);
const Color kShimmerHighlight = Color(0xFFF5F5F5);
const Color kCardShadow = Color(0x1A000000);
const Color kErrorColor = Color(0xFFE74C3C);

// Move calculateReadingTime to be a static method outside of any class
String calculateReadingTime(Map<String, dynamic> recipe) {
  String description = recipe['description'] ?? '';
  String instructions = recipe['instructions'] ?? '';
  List<dynamic> ingredients = recipe['ingredients'] ?? [];

  String allText = description + instructions + ingredients.join(' ');
  int wordCount = allText.split(' ').length;
  int minutes = (wordCount / 200).ceil();
  return "${minutes < 1 ? 1 : minutes} min";
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String selectedCategory = "All";
  bool isLoading = true;
  List<dynamic> recipes = [];
  String userName = '';
  final searchController = TextEditingController();
  bool isSearching = false;

  // Initialize animation controller and animation
  late final AnimationController _fadeController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _getUserName();
    _fadeController.forward();
  }

  @override
  void dispose() {
    if (_fadeController.isAnimating) {
      _fadeController.stop();
    }
    _fadeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserName() async {
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        userName = user.displayName ?? 'User';
      });
    }
  }

  Future<void> _fetchRecipes() async {
    if (!mounted) return;

    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('recipes').get();
      if (mounted) {
        setState(() {
          recipes = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();
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

  List<dynamic> getFilteredRecipes() {
    var filtered = recipes;

    // Filter by search query
    if (searchController.text.isNotEmpty) {
      filtered = filtered
          .where((recipe) =>
              recipe['name']
                  .toString()
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase()) ||
              recipe['description']
                  .toString()
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase()))
          .toList();
    }

    // Filter by category
    if (selectedCategory != "All") {
      filtered = filtered
          .where((recipe) => recipe['category'] == selectedCategory)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildCreativeHeader(),
          Expanded(
            child: RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _fetchRecipes,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Categories with Animation
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCategoriesSection(),
                    ),
                  ),

                  // Featured Recipe Section
                  if (!isLoading && getFilteredRecipes().isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildFeaturedRecipe(getFilteredRecipes().first),
                    ),

                  // Recipe Grid with Staggered Animation
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.defaultSize * 2,
                    ),
                    sliver:
                        isLoading ? _buildLoadingShimmer() : _buildRecipeGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MyBottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildAnimatedFAB(),
    );
  }

  Widget _buildCreativeHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 15,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        boxShadow: [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kPrimaryColor,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: kAccentColor,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: TextStyle(
                          color: kTextLightColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        userName,
                        style: TextStyle(
                          color: kTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_none_outlined),
                  color: kTextColor,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Modern Search Bar with Recipe Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: kPrimaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Find your favorite recipe...",
                            hintStyle: TextStyle(color: kTextLightColor),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close, color: kTextLightColor),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Recipe Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.restaurant_menu,
                      label: "Total Recipes",
                      value: "${recipes.length}",
                    ),
                    _buildStatItem(
                      icon: Icons.favorite,
                      label: "Saved",
                      value: "0",
                    ),
                    _buildStatItem(
                      icon: Icons.timer,
                      label: "Quick Recipes",
                      value:
                          "${recipes.where((r) => r['category'] == 'Quick').length}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    if (label == "Saved") {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('saved_recipes')
              .snapshots(),
          builder: (context, snapshot) {
            final savedCount =
                snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kAccentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark, color: kPrimaryColor, size: 20),
                ),
                SizedBox(height: 4),
                Text(
                  "$savedCount",
                  style: TextStyle(
                    color: kTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: kTextLightColor,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        );
      }
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAccentColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: kTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: kTextLightColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedRecipe(Map<String, dynamic> recipe) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Featured Recipe",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailPage(recipe: recipe),
              ),
            ),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 20,
                    color: kCardShadow,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Featured Recipe Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: recipe['image_base64'] != null
                        ? Image.memory(
                            base64Decode(recipe['image_base64']),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: kShimmerBase,
                            child: Icon(Icons.image,
                                size: 50, color: kTextLightColor),
                          ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Recipe Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['name'] ?? 'Unnamed Recipe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person,
                                color: Colors.white.withOpacity(0.8), size: 16),
                            SizedBox(width: 8),
                            Text(
                              recipe['created_by'] ?? 'Unknown Chef',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fadeAnimation.value,
          child: FloatingActionButton(
            backgroundColor: kPrimaryColor,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddRecipePage()),
              );
              _fetchRecipes();
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildShimmerCard(),
        childCount: 6,
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: kShimmerBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: kShimmerHighlight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: kShimmerHighlight,
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity * 0.7,
                    color: kShimmerHighlight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.defaultSize * 2,
            vertical: SizeConfig.defaultSize,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Categories",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "See All",
                  style: TextStyle(color: kPrimaryColor),
                ),
              ),
            ],
          ),
        ),
        Categories(onCategorySelected: (category) {
          setState(() {
            selectedCategory = category;
            isLoading = true;
          });
          _fetchRecipes();
        }),
      ],
    );
  }

  Widget _buildRecipeGrid() {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => RecipeCard(
          recipe: getFilteredRecipes()[index],
          press: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailPage(
                  recipe: getFilteredRecipes()[index],
                ),
              ),
            );
          },
        ),
        childCount: getFilteredRecipes().length,
      ),
    );
  }

  Widget _buildRecipeMetrics(Map<String, dynamic> recipe) {
    final user = FirebaseAuth.instance.currentUser;

    return Row(
      children: [
        Icon(Icons.timer, size: 16, color: kTextLightColor),
        SizedBox(width: 4),
        Text(
          calculateReadingTime(recipe),
          style: TextStyle(
            fontSize: 12,
            color: kTextLightColor,
          ),
        ),
        SizedBox(width: 16),
        if (user != null) ...[
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('saved_recipes')
                .snapshots(),
            builder: (context, snapshot) {
              final savedCount =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    size: 16,
                    color: kPrimaryColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "$savedCount",
                    style: TextStyle(
                      fontSize: 12,
                      color: kTextLightColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRecipeInfo(Map<String, dynamic> recipe) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: kAccentColor,
                child: Text(
                  (recipe['created_by'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  recipe['created_by'] ?? 'Unknown Chef',
                  style: TextStyle(
                    fontSize: 11,
                    color: kTextLightColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user != null) ...[
                StreamBuilder<int>(
                  stream: _getSavedRecipeCount(recipe['id']),
                  builder: (context, snapshot) {
                    final savedCount = snapshot.data ?? 0;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kAccentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            size: 12,
                            color: kPrimaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "$savedCount",
                            style: TextStyle(
                              fontSize: 10,
                              color: kTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Stream<int> _getSavedRecipeCount(String? recipeId) {
    if (recipeId == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('saved_recipes')
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists ? 1 : 0);
  }
}

class Categories extends StatefulWidget {
  final Function(String) onCategorySelected;

  const Categories({super.key, required this.onCategorySelected});

  @override
  _CategoriesState createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  List<String> categories = ["All", "Breakfast", "Lunch", "Dinner", "Quick"];
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 40,
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) => buildCategoryItem(index),
      ),
    );
  }

  Widget buildCategoryItem(int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
          widget.onCategorySelected(categories[index]);
        });
      },
      child: Container(
        margin: EdgeInsets.only(
          left: index == 0 ? 20 : 10,
          right: index == categories.length - 1 ? 20 : 0,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : kAccentColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon for each category
            Icon(
              _getCategoryIcon(categories[index]),
              size: 16,
              color: isSelected ? kSurfaceColor : kPrimaryColor,
            ),
            SizedBox(width: 8),
            Text(
              categories[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? kSurfaceColor : kTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.restaurant_menu;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'quick':
        return Icons.timer;
      default:
        return Icons.restaurant;
    }
  }
}

// Update RecipeCard for grid layout
class RecipeCard extends StatelessWidget {
  final dynamic recipe;
  final VoidCallback press;
  final bool isSavedPage;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.press,
    this.isSavedPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kTextColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: press,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 190,
            child: Column(
              children: [
                // Image Section
                SizedBox(
                  height: 125,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                        child: _buildRecipeImage(),
                      ),
                      _buildGradientOverlay(),
                      _buildCategoryTag(),
                      _buildCookingTime(recipe),
                      if (user != null) _buildBookmarkButton(user.uid),
                    ],
                  ),
                ),
                // Content Section
                Container(
                  height: 65,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['name'] ?? 'Unnamed Recipe',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: kAccentColor,
                            child: Text(
                              (recipe['created_by'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              recipe['created_by'] ?? 'Unknown Chef',
                              style: TextStyle(
                                fontSize: 11,
                                color: kTextLightColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kAccentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: kPrimaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "4.5",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeImage() {
    return recipe['image_base64'] != null
        ? Image.memory(
            base64Decode(recipe['image_base64']),
            fit: BoxFit.cover,
          )
        : Container(
            color: kBackgroundColor,
            child: Icon(Icons.image, size: 50, color: kTextLightColor),
          );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              kTextColor.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kSurfaceColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          recipe['category'] ?? 'Uncategorized',
          style: TextStyle(
            color: kPrimaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCookingTime(Map<String, dynamic> recipe) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kSurfaceColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: kPrimaryColor),
            SizedBox(width: 4),
            Text(
              calculateReadingTime(recipe),
              style: TextStyle(
                color: kTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkButton(String userId) {
    final recipeId = recipe['id'];
    if (recipeId == null) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: StreamBuilder<bool>(
        stream: SavedRecipe.isSaved(userId, recipeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();

          final isSaved = snapshot.data ?? false;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => SavedRecipe.toggleSaveRecipe(userId, recipe),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isSaved ? kPrimaryColor : kSurfaceColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                  size: 20,
                  color: isSaved ? kSurfaceColor : kPrimaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SavedRecipe {
  static const String collectionName = 'users';

  static Future<void> toggleSaveRecipe(
      String userId, Map<String, dynamic> recipe) async {
    if (recipe['id'] == null) return;

    final savedRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(userId)
        .collection('saved_recipes')
        .doc(recipe['id']);

    try {
      final doc = await savedRef.get();
      if (doc.exists) {
        await savedRef.delete();
      } else {
        final recipeData = {
          'recipe_id': recipe['id'],
          'name': recipe['name'] ?? 'Unnamed Recipe',
          'description': recipe['description'] ?? '',
          'category': recipe['category'] ?? 'Uncategorized',
          'ingredients': recipe['ingredients'] ?? [],
          'instructions': recipe['instructions'] ?? '',
          'image_base64': recipe['image_base64'],
          'created_by': recipe['created_by'] ?? 'Unknown Chef',
          'saved_at': FieldValue.serverTimestamp(),
          'author_id': recipe['author_id'],
        };
        await savedRef.set(recipeData);
      }
    } catch (e) {
      print("Error toggling save recipe: $e");
    }
  }

  static Stream<bool> isSaved(String userId, String? recipeId) {
    if (recipeId == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(userId)
        .collection('saved_recipes')
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
