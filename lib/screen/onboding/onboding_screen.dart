import 'dart:ui';

import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/screen/onboding/components/custom_sign_in.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/login_controller.dart';
import 'LandingPageView.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isSignInDialogShown = false;
  // final LoginController controller = Get.put(LoginController(), permanent: true);
  @override
  void initState() {
    super.initState();
    // controller.GetapplicationDetails();
    // controller.GetorgDetails();
  }


  // void _loadRememberedCredentials() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //
  //   String? cdauth = prefs.getString('cdauthkey')?.trim();
  //
  //     setState(() {
  //       controller.email.value = prefs.getString("saved_email") ?? "";
  //       controller.password.value = prefs.getString("saved_password") ?? "";
  //       controller.login( controller.email.toString(),controller.password.toString());
  //     });
  //
  //   // print('cdauth==cdauth===cdauth====>${cdauth}');
  //
  //
  //
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
                child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: const SizedBox(),
            )),
            AnimatedPositioned(
              duration: Duration(milliseconds: 240),
              top: isSignInDialogShown ? -50 : 0,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        SizedBox(

                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/Backgrounds/bgindoreNCS.png',
                                  height: 165,
                                ),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      // letterSpacing: .6,
                                      height: 1.4,
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                          text:
                                              "NCS^ Private Limited is dedicated to streamlining software development at all levels through its exclusive Project; 'NCS^ Indore' - a \n"),
                                      TextSpan(
                                        text:
                                            "No-Code, Customizable, Serverless",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: .5,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                          text: " ApplicationS Platform designed to make the process easy, simple and QUICK."),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      letterSpacing: .5,
                                      fontFamily: 'Lato',
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(text: "This '"),
                                      TextSpan(
                                        text: "Envisioned & Mission",
                                        style: TextStyle(
                                            letterSpacing: .5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      TextSpan(
                                          text:
                                              "' oriented Project is a result of decades of dedication and timeless efforts by the core team behind its successful development & delivery."),
                                    ],
                                  ),
                                ),
                              ]),
                        ),
                        const Spacer(
                          flex: 2,
                        ),
                        SwipeButton.expand(
                          thumb: const Icon(
                            Icons.double_arrow_rounded,
                            color: Colors.white,
                          ),
                          activeThumbColor: Colors.red,
                          activeTrackColor: Colors.grey.withOpacity(0.05),

                          onSwipe: () {
                            setState(() {
                              isSignInDialogShown = true;
                            });

                            customSigninDialog(context, onClosed: (_) {
                              setState(() {
                                isSignInDialogShown = false;
                              });
                            });
                          },
                          child: const Text(
                            "Swipe to next",
                            style: TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            "The Project, in its entirety has been designed & developed @ Indore, the Cleanest City of India.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            )
          ],
        ));
  }
}
