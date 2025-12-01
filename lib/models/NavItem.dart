import 'package:flutter/material.dart';
import 'package:flutter_proyek_kel02/screens/home/home_screen.dart';
import 'package:flutter_proyek_kel02/screens/profile/profile_screen.dart';
import 'package:flutter_proyek_kel02/screens/home/savedrecipe_screen.dart';
import 'package:flutter_proyek_kel02/screens/search/search_screen.dart';

class NavItem {
  final int id;
  final String icon;
  final Widget? destination;

  const NavItem({
    required this.id,
    required this.icon,
    this.destination,
  });

// If there is no destination then it help us
  bool destinationChecker() => destination != null;
}

// If we made any changes here Provider package rebuid those widget those use this NavItems
class NavItems extends ChangeNotifier {
  // By default first one is selected
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeNavIndex({required int index}) {
    _selectedIndex = index;
    // if any changes made it notify widgets that use the value
    notifyListeners();
  }

  List<NavItem> items = [
    NavItem(
      id: 1,
      icon: "assets/icons/home.svg",
      destination: HomeScreen(),
    ),
    NavItem(
      id: 2,
      icon: "assets/icons/bookmark_fill.svg",
      destination: SavedRecipesScreen(),
    ),
    NavItem(
      id: 3,
      icon: "assets/icons/search.svg",
      destination: SearchScreen(),
    ),
    NavItem(
      id: 4,
      icon: "assets/icons/user.svg",
      destination: ProfileScreen(),
    ),
  ];
}
