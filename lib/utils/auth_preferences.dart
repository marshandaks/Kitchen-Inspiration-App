import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPreferences {
  static const String _isLoggedInKey = 'isLoggedIn';

  /// Simpan status login
  static Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  /// Ambil status login
  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Ambil user ID yang sedang login (Firebase UID)
  static Future<String?> getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Ambil email pengguna yang sedang login
  static Future<String?> getUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  /// Hapus data login (Logout)
  static Future<void> clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await FirebaseAuth.instance.signOut(); // Logout dari Firebase
  }
}
