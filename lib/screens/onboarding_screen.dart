import 'package:flutter/material.dart';
import 'package:flutter_proyek_kel02/utils/auth_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Periksa status login dan arahkan pengguna
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthPreferences.getLoginStatus();
    if (isLoggedIn) {
      // Jika sudah login, arahkan ke Home
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SizedBox(
        height: h,
        width: w,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                height: h * .79,
                width: w,
                decoration: const BoxDecoration(
                  color: Color(0xFF90AF17),
                  image: DecorationImage(
                    image: AssetImage('assets/images/best_2020@2x.png'),
                  ),
                ),
              ),
            ),
            Center(
              child: Image.asset('assets/images/image_19.png'),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                height: h * .243,
                width: w,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(40),
                    topLeft: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: h * .032),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Let\'s cook good food',
                          style: TextStyle(
                            fontSize: w * .06,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: h * .01),
                        const Text(
                          'Check out the app and start to cooking delicious meals!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: h * .032),
                        SizedBox(
                          width: w * .8,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF90AF17),
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/login'); // /home ganti jadi /login
                            },
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
