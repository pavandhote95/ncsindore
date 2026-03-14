import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/components/components.dart';
import 'package:cuickdevuser/components/constants.dart';
import 'package:cuickdevuser/controller/login_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _forgotPassFormKey = GlobalKey<FormState>();
  final LoginController controller =
      Get.put(LoginController(), permanent: true);
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isShowLoading = false;
  bool isShowConfetti = false;

  late SMITrigger check;
  late SMITrigger error;
  late SMITrigger reset;
  late SMITrigger confetti;

  StateMachineController getRiveController(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    return controller;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _loadRememberedCredentials();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Stack(
      children: [
        Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20,),

                Obx(() {
                  final loginByEmail = controller.loginByEmail.value;
                  final loginByMobileNo = controller.loginByMobileNo.value;
                  final loginByLoginCode = controller.loginByLoginCode.value;

                  final loginMethodLabel = getLoginOptionsText(
                    loginByEmail: loginByEmail,
                    loginByMobileNo: loginByMobileNo,
                    loginByLoginCode: loginByLoginCode,
                  );

                  final hintText = getHintText(
                    loginByEmail: loginByEmail,
                    loginByMobileNo: loginByMobileNo,
                    loginByLoginCode: loginByLoginCode,
                  );

                  // ⭐️ FIXED: Keyboard type logic updated
                  final bool requiresFullKeyboard = loginByEmail || loginByLoginCode;
                  final bool onlyMobileEnabled = loginByMobileNo && !loginByEmail && !loginByLoginCode;

                  final TextInputType keyboardType = onlyMobileEnabled
                      ? TextInputType.phone
                      : requiresFullKeyboard
                          ? TextInputType.text // Use text for alphanumeric login code
                          : TextInputType.emailAddress; // Default fallback to email

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loginMethodLabel,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 13,
                        ),
                      ),
              Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                        child: TextFormField(
                          onChanged: (value) {
                            controller.updateEmail(value.trim());
                          },
                          controller: emailController,
                          keyboardType: keyboardType,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your Login ID";
                            }

                            final input = value.trim();

                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            final mobileRegex = RegExp(r'^\d{10}$');

                            final E = controller.loginByEmail.value;
                            final M = controller.loginByMobileNo.value;
                            final C = controller.loginByLoginCode.value;

                            final bool isEmailFormat =
                                emailRegex.hasMatch(input);
                            final bool isMobileFormat =
                                mobileRegex.hasMatch(input);

                            if (E && isEmailFormat) {
                              return null;
                            }

                            if (M && isMobileFormat) {
                              return null;
                            }

                            if (C) {
                              bool matchesDisabledFormat =
                                  (!E && isEmailFormat) ||
                                      (!M && isMobileFormat);

                              if (!matchesDisabledFormat) {
                                return null;
                              }
                            }

                            if (!E && !M && !C && isEmailFormat) {
                              return null;
                            }

                            List<String> validOptions = [];

                            if (E || (!E && !M && !C))
                              validOptions.add('a valid Email address');
                            if (M) validOptions.add('a 10-digit Mobile Number');
                            if (C) validOptions.add('your Login Code');

                            String errorMsg = 'Invalid Login ID. Please enter ';

                            if (validOptions.length == 1) {
                              errorMsg += validOptions.first + '.';
                            } else {
                              errorMsg += validOptions
                                      .sublist(0, validOptions.length - 1)
                                      .join(', ') +
                                  ' or ' +
                                  validOptions.last +
                                  '.';
                            }

                            return errorMsg;
                          },
                          onSaved: (email) {},
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            hintText: hintText,
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),

                    ],
                  );
                }),

                Text(
                  "Password",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,fontSize: 13
                  ),
                ),
                Obx(
                      () {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                      child: TextFormField(
                        controller: passwordController,
                        onChanged: controller.updatePassword,
                        obscureText: controller.ispassHiden.value,
                        // Bind visibility to RxBool
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password cannot be empty"; // Add meaningful message
                          }
                          return null;
                        },
                        onSaved: (password) {},
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          // Removed prefixIcon to eliminate the left padding/space.
                          suffixIcon: GestureDetector(
                            onTap: controller.toggle,
                            // Call toggle() to switch visibility
                            child: Icon(
                              controller.ispassHiden.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: controller.ispassHiden.value
                                  ? Colors.black45
                                  : Colors.indigo,
                              size: 20,
                            ),
                          ),

                        ),
                      ),
                    );
                  },
                ),
                Obx(() => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Checkbox(
                      value: controller.rememberMe.value,
                      onChanged: (value) {
                        controller.rememberMe.value = value ?? false;
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text(
                      "Remember me",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black, // adjust as needed
                      ),
                    ),
                  ],
                )),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                  child: Obx(
                        () {
                      return ElevatedButton.icon(
                        // ⭐️ FIXED: Button logic uses controller text for submission
                     onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            controller.login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          // Button color based on content (for visual feedback)
                          backgroundColor: (controller.email.isNotEmpty &&
                              controller.password.isNotEmpty)
                              ? const Color(0xFF243262)
                              : Colors.grey,
                          minimumSize: const Size(double.infinity, 56),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                              bottomLeft: Radius.circular(25),
                            ),
                          ),
                        ),
                        label: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                GestureDetector(
                    onTap: () {
                      ForgotpassDailog();
                    },
                    child: const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Forgot Password ?",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        ))),
              ],
            )),
        isShowLoading
            ? CustomPositioned(
            child: RiveAnimation.asset(
              "assets/RiveAssets/check.riv",
              onInit: (artboard) {
                StateMachineController controller =
                    getRiveController(artboard);
                check = controller.findSMI("Check") as SMITrigger;
                error = controller.findSMI("Error") as SMITrigger;
                reset = controller.findSMI("Reset") as SMITrigger;
              },
            ))
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
            child: Transform.scale(
              scale: 6,
              child: RiveAnimation.asset(
                "assets/RiveAssets/confetti.riv",
                onInit: (artboard) {
                  StateMachineController controller =
                      getRiveController(artboard);
                  confetti =
                      controller.findSMI("Trigger explosion") as SMITrigger;
                },
              ),
            ))
            : const SizedBox()
      ],
    );
  }
  void ForgotpassDailog() async {
    final emailController = TextEditingController();
    Get.defaultDialog(
    
      title: '',
      middleText: '',
      backgroundColor: Colors.white,
      barrierDismissible: false,
      content: SizedBox(
        height: 330,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: Form( // Wrapped in a Form to enable validation
            key: _forgotPassFormKey,
            child: Column(
              
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
      Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ClipOval(
                      child: Image.network(
                        "https://cuickdev.com/API/DOCS/api/doc/th/${controller.appimageid.value}?t=0",
                        height: 90,
                        width:
                            90, // important: height & width same hone chahiye
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "Forgot Password ?",
                    style: TextStyle(
                        fontSize: 23,
                        fontFamily: 'Gilroy',
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
        
                TextFormField(
                  controller: emailController,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 15),
                  onChanged: controller.updateForgotEmail,
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      hintText: 'Email',
                      hintStyle: const TextStyle(
                          color: Colors.black26,
                          fontWeight: FontWeight.w400,
                          fontSize: 15),
                      // Removed prefixIcon to remove the space
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required'; // Validate if the input is empty
                    }
        
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email'; // Validate if the email matches the pattern
                    }
        
                    return null; // If no validation errors, return null
                  },
                ),
                const SizedBox(height: 30),
        
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(25)),
                          child: const Center(
                            child: Text("Cancel",
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Gilroy')),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Check validation before proceeding
                          if (_forgotPassFormKey.currentState!.validate()) {
                            controller.forgotpassword();
                            controller.clearForgotEmail();
                            Get.back();
                          } else {
                            // Optional: Toast message for overall failure, though field errors are visible
                            CherryToast.error(
                              backgroundColor: const Color(0xFFF8D0D9),
                              animationDuration: Durations.short3,
                              animationCurve: Curves.easeInCubic,
                              title: const Text('Please Enter a valid Login Id',
                                  style: TextStyle(color: Colors.black)),
                            ).show(Get.overlayContext!);
                          }
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF243262),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              "Send Email",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper functions (kept outside the class)

String getLoginOptionsText({
  required bool loginByEmail,
  required bool loginByMobileNo,
  required bool loginByLoginCode,
}) {
  List<String> options = [];

  if (loginByEmail) options.add('Email');
  if (loginByMobileNo) options.add('Mobile No');
  if (loginByLoginCode) options.add('Login Code');

  if (options.isEmpty) {
    options.add('Email'); // default fallback to email
  }

  return 'Login by ${options.join(" / ")}';
}

String getHintText({
  required bool loginByEmail,
  required bool loginByMobileNo,
  required bool loginByLoginCode,
}) {
  if (loginByEmail) return 'Enter your email';
  if (loginByMobileNo) return 'Enter your mobile number';
  if (loginByLoginCode) return 'Enter login code';
  return 'Enter your email'; // Default fallback
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, required this.child, this.size = 100});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: size,
            width: size,
            child: child,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}