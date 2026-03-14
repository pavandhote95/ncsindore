// lib/service/session_manager.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cuickdevuser/screen/onboding/onboding_screen.dart'; // यदि required हो

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Session check करने का method
  Future<bool> checkValidSession() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final bool? loginStatus = prefs.getBool("islogin");
      final String? jsessionid = prefs.getString("jsessionid");
      final String? cdauthkey = prefs.getString("cdauthkey");

      return (loginStatus == true &&
          jsessionid != null &&
          jsessionid.isNotEmpty &&
          cdauthkey != null &&
          cdauthkey.isNotEmpty);
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }

  // Session data clear करने का method
  Future<void> clearSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cdauthkey');
    await prefs.remove('jsessionid');
    await prefs.remove('islogin');
    await prefs.remove('authkey');
    await prefs.remove('userid');
    await prefs.remove('imageId');
    await prefs.remove('appId');
    await prefs.remove('loginId');
    await prefs.remove('defaultRoleId');
    await prefs.remove('applicationRoleId');
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.setBool('islogin', false);
  }

  // Force logout (session expired के लिए)
  Future<void> forceLogout({String message = 'Session expired'}) async {
    await clearSessionData();

    // // Optional: Show a snackbar before redirecting
    // Get.snackbar(
    //   'Session Expired',
    //   message,
    //   backgroundColor: Colors.orange,
    //   colorText: Colors.white,
    //   duration: Duration(seconds: 3), // यहाँ Duration object use करें
    // );

    Get.offAll(() => const OnboardingScreen());
  }

  // Get current session info
  Future<Map<String, dynamic>> getSessionInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'islogin': prefs.getBool('islogin') ?? false,
      'jsessionid': prefs.getString('jsessionid') ?? '',
      'cdauthkey': prefs.getString('cdauthkey') ?? '',
      'loginId': prefs.getString('loginId') ?? '',
    };
  }
}
