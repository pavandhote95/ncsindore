import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:cuickdevuser/screen/onboding/onboding_screen.dart';
import 'package:cuickdevuser/screen/welcome.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool islogin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  // Helper method to clear session data
  Future<void> clearSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('islogin', false);
    await prefs.remove('jsessionid');
    await prefs.remove('authkey');
    await prefs.remove('userid');
    await prefs.remove('imageId');
    await prefs.remove('appId');
    await prefs.remove('loginId');
    await prefs.remove('defaultRoleId');
    await prefs.remove('applicationRoleId');
    await prefs.remove('userrolename');
    await prefs.remove('name');
    print('🧹 SplashScreen: Session data cleared');
  }

  Future<void> checkLoginStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Print all stored values for debugging
      print('🔍 SplashScreen - Checking login status:');
      print('   islogin: ${prefs.getBool("islogin")}');
      print('   jsessionid: ${prefs.getString("jsessionid")}');
      print('   cdauthkey: ${prefs.getString("cdauthkey")}');
      print('   appId: ${prefs.getInt("appId")}');
      print('   authkey: ${prefs.getInt("authkey")}');

      // सभी required fields check करें
      final bool? loginStatus = prefs.getBool("islogin");
      final String? jsessionid = prefs.getString("jsessionid");
      final String? cdauthkey = prefs.getString("cdauthkey");
      final int? authkey = prefs.getInt("authkey");
      final int? appId = prefs.getInt("appId");

      // यदि कोई भी critical field missing है तो onboarding screen पर जाएं
      bool validSession = (loginStatus == true &&
          jsessionid != null &&
          jsessionid.isNotEmpty &&
          jsessionid != "0" &&
          cdauthkey != null &&
          cdauthkey.isNotEmpty &&
          authkey != null &&
          authkey != 0 &&
          appId != null &&
          appId != 0);

      print('✅ Valid session: $validSession');

      if (!validSession) {
        // Session invalid है तो user data clear करें
        await clearSessionData();
      }

      setState(() {
        islogin = validSession;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error checking login status: $e');
      await clearSessionData();
      setState(() {
        islogin = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Backgrounds/indorencs.png',
                height: 160,
                width: 200,
              ),
              SizedBox(height: 20),
              Text(
                'Checking session...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        duration: 2000,
        splash: Image.asset(
          'assets/Backgrounds/indorencs.png',
          height: 160,
          width: 200,
        ),
        nextScreen: islogin ? const Welcomescreen() : const OnboardingScreen(),
        splashTransition: SplashTransition.fadeTransition,
        splashIconSize: 300,
        pageTransitionType: PageTransitionType.fade,
        animationDuration: const Duration(seconds: 1),
        backgroundColor: Colors.white,
      ),
    );
  }
}
