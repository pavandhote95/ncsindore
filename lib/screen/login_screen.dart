import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/components/components.dart';
import 'package:cuickdevuser/controller/login_controller.dart';
import 'package:cuickdevuser/screen/onboding/components/sign_in_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:cuickdevuser/screen/onboding/onboding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller =
      Get.put(LoginController(), permanent: true);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await controller.GetapplicationDetails();
    // await controller.GetorgDetails();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
return PopScope(
      canPop: false, // default back ko block karega
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
      Get.offAllNamed('/onboarding');
        }
      },
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 40,
            color: Color(0xFF273070),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 220,
                    color: Color(0xFF273070),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Powered by ",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          RichText(
                            text: const TextSpan(
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16.0),
                              children: [
                                TextSpan(
                                  text: 'NCS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '^',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.white,
        body: Obx(() {
          return LoadingOverlay(
            isLoading: controller.isSaving.value,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.start,
                    direction: Axis.vertical,
                    children: [
                      controller.appimageid.value == 0
                          ? const SizedBox()
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Image.network(
                                "https://cuickdev.com/API/DOCS/api/doc/th/${controller.appimageid.value}?t=0",
                                fit: BoxFit.cover,
                              ),
                            ),
                      Text(
                        controller.appName.value.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const ScreenTitle(title: 'Login'),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SignInForm(),
                          ),
                          if (controller.enableUserSignup.value)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(fontSize: 14),
                                ),
                                TextButton(
                                  onPressed: () {
                                    controller.signup();
                                  },
                                  child: const Text(
                                    "Sign up",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      const SizedBox(height: 10),
                      controller.orgimageid.value == 0
                          ? const SizedBox()
                          : Image.network(
                              "https://cuickdev.com/API/DOCS/api/doc/th/${controller.orgimageid.value}?t=0",
                              height: 70,
                            ),
                      const SizedBox(height: 10),
                      Text(
                        "Managed by ${controller.orgName.value.toString()}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
