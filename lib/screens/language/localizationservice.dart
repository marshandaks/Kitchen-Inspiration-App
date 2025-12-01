import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageCodeKey = 'languageCode';

  // Memuat bahasa yang tersimpan di SharedPreferences
  static Future<Locale> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey) ?? 'en';
    return Locale(languageCode, '');
  }

  // Menyimpan pilihan bahasa di SharedPreferences
  static Future<void> saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }
}
