import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_proyek_kel02/constants.dart';
import 'package:flutter_proyek_kel02/models/NavItem.dart';
import 'package:flutter_proyek_kel02/size_config.dart';

class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double defaultSize = SizeConfig.defaultSize;
    return Consumer<NavItems>(
      builder: (context, navItems, child) => Container(
        padding: EdgeInsets.symmetric(horizontal: defaultSize * 2), // Spasi kiri/kanan
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: Offset(0, -7),
              blurRadius: 30,
              color: Color(0xFF4B1A39).withOpacity(0.2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Ikon di sisi kiri
              Row(
                children: List.generate(
                  2, // Ikon pertama dan kedua
                  (index) => buildIconNavBarItem(
                    isActive: navItems.selectedIndex == index ? true : false,
                    icon: navItems.items[index].icon,
                    press: () {
                      navItems.changeNavIndex(index: index);
                      if (navItems.items[index].destinationChecker()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                navItems.items[index].destination!,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              // Spacer untuk memberi ruang bagi tombol tambah
              SizedBox(width: defaultSize * 4),
              // Ikon di sisi kanan
              Row(
                children: List.generate(
                  2, // Ikon ketiga dan keempat
                  (index) => buildIconNavBarItem(
                    isActive: navItems.selectedIndex == index + 2 ? true : false,
                    icon: navItems.items[index + 2].icon,
                    press: () {
                      navItems.changeNavIndex(index: index + 2);
                      if (navItems.items[index + 2].destinationChecker()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                navItems.items[index + 2].destination!,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconButton buildIconNavBarItem({
    required String icon,
    required VoidCallback press,
    bool isActive = false,
  }) {
    return IconButton(
      icon: SvgPicture.asset(
        icon,
        color: isActive ? kPrimaryColor : Color(0xFFD1D4D4),
        height: 22,
      ),
      onPressed: press,
    );
  }
}
