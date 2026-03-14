// lib/services/local_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocalStorageService {
  static const String _keyDashboardData = 'dashboard_data';
  static const String _keyMenuData = 'menu_data';
  static const String _keyApplicationDetails = 'application_details';
  static const String _keyOrgDetails = 'org_details';
  static const String _keyTableData = 'table_data_';
  static const String _keyLastSync = 'last_sync_time';

  // Save dashboard data
  static Future<void> saveDashboardData(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDashboardData, jsonEncode(data));
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
      print("✅ Dashboard data cached successfully");
    } catch (e) {
      print("❌ Error saving dashboard data: $e");
    }
  }
  
  // Add these methods to your LocalStorageService class

  static Future<void> saveOrgImage(String key, Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/org_images';
      await Directory(path).create(recursive: true);
      final file = File('$path/org_$key.png');
      await file.writeAsBytes(bytes);
      print('✅ Org image saved to local storage: $path/org_$key.png');
    } catch (e) {
      print('❌ Error saving org image to local storage: $e');
    }
  }

  static Future<Uint8List?> loadOrgImage(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/org_images/org_$key.png');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        print('📦 Org image loaded from local storage: org_$key.png');
        return bytes;
      }
    } catch (e) {
      print('❌ Error loading org image from local storage: $e');
    }
    return null;
  }

  static Future<void> deleteOrgImage(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/org_images/org_$key.png');
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Org image deleted from local storage: org_$key.png');
      }
    } catch (e) {
      print('❌ Error deleting org image from local storage: $e');
    }
  }

  // Load dashboard data
  static Future<List<dynamic>> loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_keyDashboardData);
      if (data != null) {
        return jsonDecode(data) as List;
      }
    } catch (e) {
      print("❌ Error loading dashboard data: $e");
    }
    return [];
  }

  // Save menu data
  static Future<void> saveMenuData(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMenuData, jsonEncode(data));
      print("✅ Menu data cached successfully");
    } catch (e) {
      print("❌ Error saving menu data: $e");
    }
  }
  // Add to LocalStorageService.dart
  static Future<void> saveProfileImage(String imageId, Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/profile_images';
      await Directory(path).create(recursive: true);

      final file = File('$path/profile_$imageId.png');
      await file.writeAsBytes(bytes);
      print("✅ Profile image saved to file: $path/profile_$imageId.png");
    } catch (e) {
      print("❌ Error saving profile image: $e");
    }
  }

  static Future<Uint8List?> loadProfileImage(String imageId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file =
          File('${directory.path}/profile_images/profile_$imageId.png');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        print("✅ Profile image loaded from file for ID: $imageId");
        return bytes;
      }
    } catch (e) {
      print("❌ Error loading profile image: $e");
    }
    return null;
  }

  static Future<void> clearAllProfileImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${directory.path}/profile_images');
      if (await profileDir.exists()) {
        await profileDir.delete(recursive: true);
        print("✅ All profile images cleared");
      }
    } catch (e) {
      print("❌ Error clearing profile images: $e");
    }
  }

  // Load menu data
  static Future<List<dynamic>> loadMenuData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_keyMenuData);
      if (data != null) {
        return jsonDecode(data) as List;
      }
    } catch (e) {
      print("❌ Error loading menu data: $e");
    }
    return [];
  }

  // Save application details
  static Future<void> saveApplicationDetails(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyApplicationDetails, jsonEncode(data));
    } catch (e) {
      print("❌ Error saving application details: $e");
    }
  }

  // Load application details
  static Future<Map<String, dynamic>?> loadApplicationDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_keyApplicationDetails);
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (e) {
      print("❌ Error loading application details: $e");
    }
    return null;
  }

  // Save org details
  static Future<void> saveOrgDetails(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyOrgDetails, jsonEncode(data));
    } catch (e) {
      print("❌ Error saving org details: $e");
    }
  }

  // Load org details
  static Future<Map<String, dynamic>?> loadOrgDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_keyOrgDetails);
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    } catch (e) {
      print("❌ Error loading org details: $e");
    }
    return null;
  }

  // Save table data for specific form
  static Future<void> saveTableData(String formId, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyTableData$formId', jsonEncode(data));
    } catch (e) {
      print("❌ Error saving table data for $formId: $e");
    }
  }

  // Load table data for specific form
  static Future<List<dynamic>> loadTableData(String formId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('$_keyTableData$formId');
      if (data != null) {
        return jsonDecode(data) as List;
      }
    } catch (e) {
      print("❌ Error loading table data for $formId: $e");
    }
    return [];
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? time = prefs.getString(_keyLastSync);
      if (time != null) {
        return DateTime.parse(time);
      }
    } catch (e) {
      print("❌ Error getting last sync time: $e");
    }
    return null;
  }

  // Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDashboardData);
      await prefs.remove(_keyMenuData);
      await prefs.remove(_keyApplicationDetails);
      await prefs.remove(_keyOrgDetails);
      await prefs.remove(_keyLastSync);

      // Clear all table data
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith(_keyTableData)) {
          await prefs.remove(key);
        }
      }
      print("✅ All cache cleared");
    } catch (e) {
      print("❌ Error clearing cache: $e");
    }
  }

  // Check if we have cached data
  static Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyDashboardData) ||
          prefs.containsKey(_keyMenuData);
    } catch (e) {
      print("❌ Error checking cached data: $e");
    }
    return false;
  }
}
