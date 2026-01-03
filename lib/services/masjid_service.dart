import 'package:shared_preferences/shared_preferences.dart';

class MasjidService {
  static const String _masjidNameKey = 'masjid_name';
  static const String _defaultMasjidName = 'KAS MASJID';

  // Ambil nama masjid
  static Future<String> getMasjidName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_masjidNameKey) ?? _defaultMasjidName;
  }

  // Simpan nama masjid
  static Future<void> setMasjidName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name.trim().isEmpty) {
      await prefs.setString(_masjidNameKey, _defaultMasjidName);
    } else {
      await prefs.setString(_masjidNameKey, name.trim().toUpperCase());
    }
  }

  // Reset ke default
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_masjidNameKey, _defaultMasjidName);
  }
}

