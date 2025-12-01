import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proyek_kel02/screens/auth/login_page.dart';
import 'package:flutter_proyek_kel02/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_proyek_kel02/models/NavItem.dart';
import 'package:flutter_proyek_kel02/screens/home/home_screen.dart';
import 'package:flutter_proyek_kel02/screens/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NavItems()),
        ChangeNotifierProvider(create: (context) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Recipe App',
            theme: theme.isDarkTheme ? ThemeData.dark() : ThemeData.light(),
            routes: {
              '/onboarding': (context) => OnboardingScreen(),
              '/login': (context) => LoginPage(),
              '/home': (context) => HomeScreen(),
            },
            home: OnboardingScreen(),
          );
        },
      ),
    );
  }
}
