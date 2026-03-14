import 'dart:async';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/screen/Utility_Apps_Screen.dart';
import 'package:cuickdevuser/screen/login_screen.dart';
import 'package:cuickdevuser/screen/onboding/onboding_screen.dart';
import 'package:cuickdevuser/screen/signup_screen.dart';
import 'package:cuickdevuser/screen/splash_screen.dart';
import 'package:cuickdevuser/screen/welcome.dart';
import 'package:cuickdevuser/service/DBHelper.dart';
import 'package:cuickdevuser/service/FormSyncService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';

class SessionManager {  
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;  
  SessionManager._internal();

  Timer? _inactivityTimer;
  static const int _inactivityTimeoutMinutes = 25;

  void startTimer() {
    _inactivityTimer?.cancel(); 
    _inactivityTimer =
        Timer(const Duration(minutes: _inactivityTimeoutMinutes), () {
      _logoutUser();
    });
  }

  void resetTimer() {
    startTimer();
  }

  void cancelTimer() {
    _inactivityTimer?.cancel();
  }

  Future<void> _logoutUser() async {
    // Clear all user data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // IMPORTANT: Clear all relevant session data
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
    // Navigate to OnboardingScreen instead of login
    Get.offAll(const OnboardingScreen());
  }
}

class SessionWrapper extends StatefulWidget {
  final Widget child;

  const SessionWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  final sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    sessionManager.startTimer();
  }

  @override
  void dispose() {
    sessionManager.cancelTimer();
    super.dispose();
  }

  void _handleUserInteraction([_]) {
    sessionManager.resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
late List<CameraDescription> cameras;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   cameras = await availableCameras();
  FormSyncService().initialize();
    

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeProvider, child) {
        return SessionWrapper(
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            darkTheme: ThemeData(
              primaryColor: Colors.white,
              scaffoldBackgroundColor: Colors.black,
              textTheme:
                  const TextTheme(labelMedium: TextStyle(color: Colors.white)),
              fontFamily: "Intel",
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.black,
                errorStyle: TextStyle(height: 0),
                border: darkdefaultInputBorder,
                enabledBorder: darkdefaultInputBorder,
                focusedBorder: darkdefaultInputBorder,
                errorBorder: darkerrorInputBorder,
              ),            ),
            theme: ThemeData(
              textTheme: const TextTheme(
                bodyMedium: TextStyle(
                  fontFamily: 'Ubuntu',
                ),
              ),
              scaffoldBackgroundColor: const Color(0xFFFFFFFF),
              primarySwatch: Colors.blue,
              fontFamily: "Intel",
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                errorStyle: TextStyle(height: 0),
                border: defaultInputBorder,
                enabledBorder: defaultInputBorder,
                focusedBorder: defaultInputBorder,
                errorBorder: darkerrorInputBorder,
              ),
            ),
            initialRoute: '/splash',
         getPages: [
              GetPage(name: '/login', page: () => const LoginScreen()),
              GetPage(name: '/signup', page: () => SignUpScreen()),
              GetPage(name: '/welcome', page: () => const Welcomescreen()),
              GetPage(name: '/splash', page: () => const SplashScreen()),

              // Onboarding
              GetPage(
                name: '/onboarding',
                page: () => const OnboardingScreen(),
              ),

              // ✅ Apps Screen
              GetPage(
                name: '/utilityapps',
                page: () => const UtilityAppsScreen(),
              ),

              
            ],

          ),
        );
      },
    );
  }
}


const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
const darkdefaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(
    color: Color(0xFFB9B8B8),
    width: 1,
  ),
);
const darkerrorInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
  borderSide: BorderSide(
    color: Color(0xFFEA1818),
    width: 1,
  ),
);
