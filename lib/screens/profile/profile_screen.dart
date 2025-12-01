import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_proyek_kel02/size_config.dart';
import 'package:flutter_proyek_kel02/components/my_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../utils/auth_preferences.dart';
import '../recipe/add_recipe_page.dart';
import 'user_recipe_screen.dart';
import 'package:flutter_proyek_kel02/screens/theme/theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        username = user.displayName ?? "Anonymous";
        email = user.email ?? "No Email";
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await AuthPreferences.saveLoginStatus(false);
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF90AF17),
        leading: const SizedBox(),
        centerTitle: true,
        title: const Text("Profile"),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: Text(
              "Logout",
              style: TextStyle(
                color: Colors.white,
                fontSize: SizeConfig.defaultSize * 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _Info(
              image: "assets/images/pic.jpg",
              name: username.isEmpty ? "Loading..." : username,
              email: email.isEmpty ? "Loading..." : email,
            ),
            SizedBox(height: SizeConfig.defaultSize * 2),
            _ProfileMenuItem(
              iconSrc: "assets/icons/chef_color.svg",
              title: "$username Recipes",
              press: () {
               Navigator.push(
                context,
                  MaterialPageRoute(
                  builder: (context) => UserRecipeScreen(), 
                  ),
               );
              },
            ),
            _ProfileMenuItem(
              iconSrc: "assets/icons/language.svg",
              title: themeNotifier.isDarkTheme ? "Light Mode" : "Dark Mode",
              press: () {
                themeNotifier.toggleTheme();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyBottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF90AF17),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipePage()),
          );
        },
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String name, email, image;

  const _Info({
    Key? key,
    required this.name,
    required this.email,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double defaultSize = SizeConfig.defaultSize;
    return SizedBox(
      height: defaultSize * 24,
      child: Stack(
        children: <Widget>[
          ClipPath(
            clipper: _CustomShape(),
            child: Container(
              height: defaultSize * 15,
              color: const Color(0xFF90AF17),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: defaultSize),
                  height: defaultSize * 14,
                  width: defaultSize * 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: defaultSize * 0.8,
                    ),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(image),
                    ),
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: defaultSize * 2.2,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                SizedBox(height: defaultSize / 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8492A2),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String iconSrc, title;
  final Function press;

  const _ProfileMenuItem({
    Key? key,
    required this.iconSrc,
    required this.title,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double defaultSize = SizeConfig.defaultSize;
    return InkWell(
      onTap: () => press(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: defaultSize * 2,
          vertical: defaultSize * 3,
        ),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(iconSrc),
            SizedBox(width: defaultSize * 2),
            Text(
              title,
              style: TextStyle(
                fontSize: defaultSize * 1.6,
                color: const Color(0xFF757575),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: defaultSize * 1.6,
              color: const Color(0xFF757575),
            )
          ],
        ),
      ),
    );
  }
}

class _CustomShape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    double height = size.height;
    double width = size.width;
    path.lineTo(0, height - 100);
    path.quadraticBezierTo(width / 2, height, width, height - 100);
    path.lineTo(width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
