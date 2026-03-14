import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/components/components.dart';
import 'package:cuickdevuser/components/constants.dart';
import 'package:cuickdevuser/controller/signup_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:loading_overlay/loading_overlay.dart';


class SignUpScreen extends StatelessWidget { 
  SignUpScreen({super.key});

  final SignUpController controller = Get.put(SignUpController()); // Initialize the controller
  // Access roleId
  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>?; // Retrieve arguments
    final orgId = arguments?['orgId']?.toString() ?? '';  // Safely handle null and non-string types
    final roleId = arguments?['roleId']?.toString() ?? '';
    final roleName = arguments?['roleName']?.toString() ?? '';
    final appimageid = arguments?['appimageid']?.toString() ?? ''; // Ensure as string
    final orgimageid = arguments?['orgimageid']?.toString() ?? '';

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    controller.setSignUpData(orgId, roleId, roleName);
    return WillPopScope(
      onWillPop: () async {
        controller.navigateToHome(); // Use GetX navigation
        return true;
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
                    // color: Color(0xFF273070),
                    color: Color(0xFF273070),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Powered by ",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                          RichText(
                            text: const TextSpan(
                              text: '', // Normal text
                              style: TextStyle(color: Colors.white, fontSize: 16.0),
                              children: [
                                TextSpan(
                                  text: 'NCS',
                                  style: TextStyle(
                                    color: Colors.white, // Black text for "NCS"
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '^',
                                  style: TextStyle(
                                    color: Colors.red, // Red text for "^"
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

                        appimageid.isEmpty ?
                        SizedBox():
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Image.network(
                         "https://cuickdev.com/API/DOCS/api/doc/th/$appimageid?t=0", 
                            fit: BoxFit.cover,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const ScreenTitle(title: 'Sign Up'),
                            const SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                              child: TextFormField(
                                onChanged: controller.updateFirstName,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "First name is required";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  fillColor: isDarkMode? Colors.black:Colors.white,
                                  labelStyle:  TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: 'First Name',
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: SvgPicture.asset("assets/icons/User.svg"), // Replace with your icon
                                  ),
                                ),
                              ),
                            ),
                            // Last Name
                            Padding( 
                              padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                              child: TextFormField(
                                onChanged: controller.updateLastName,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Last name is required";
                                  }
                                  return null;
                                },

                                decoration: InputDecoration(
                                  fillColor: isDarkMode? Colors.black:Colors.white,
                                  labelStyle:  TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: 'Last Name',
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: SvgPicture.asset("assets/icons/User.svg"), // Replace with your icon
                                  ),
                                ),
                              ),
                            ),
                            // Email
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                              child: TextFormField(
                                onChanged: controller.updateEmail,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Email is required";
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return "Enter a valid email address";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  fillColor: isDarkMode? Colors.black:Colors.white,
                                  labelStyle:  TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: SvgPicture.asset("assets/icons/email.svg"),
                                  ),
                                ),
                              ),
                            ),

                            Obx(
                                  () {
                                return   Padding(
                                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                                  child: TextFormField(
                                    onChanged: controller.updatePassword,
                                    obscureText: controller.ispassHiden.value,  // Bind visibility to RxBool
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return "Password cannot be empty"; // Add meaningful message
                                      }
                                      return null;
                                    },
                                    onSaved: (password) {},

                                    decoration: InputDecoration(
                                      labelStyle:  TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      fillColor: isDarkMode? Colors.black:Colors.white,
                                      hintText: 'Password',
                                      hintStyle: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      suffixIcon: GestureDetector(
                                        onTap: controller.toggle,  // Call toggle() to switch visibility
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
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: SvgPicture.asset("assets/icons/password.svg"),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const  SizedBox(
                              height: 10,
                            ),

                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 15),
                              child: Obx(
                                    () {
                                  return ElevatedButton.icon(
                                    onPressed: controller.isButtonEnabled.value ? controller.signUp : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: controller.isButtonEnabled.value
                                          ? const Color(0xFF243262) // Enabled color
                                          : Colors.grey, // Disabled color
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
                                      "Sign up",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    //   icon: const Icon(Icons.login, color: Colors.white),
                                  );
                                },
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Have an account?",
                                  style: TextStyle(
                                    fontSize: 14,
                                    //color: Colors.grey,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate back to the sign-in page
                                    Get.back();
                                  },
                                  child: Text(
                                    "Sign in",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20,),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 60,
                                width: 150,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      orgimageid.isEmpty
                                          ? Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: Image.asset(
                                          "assets/images/cuickdevblack.jpg",
                                          fit: BoxFit.cover,
                                        ),
                                      ) :
                                      // Obx(() {  return
                                      Padding(   
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: Image.network(
                                          "https://cuickdev.com/API/DOCS/api/doc/th/$orgimageid?t=0",
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                    (loadingProgress.expectedTotalBytes ?? 1)
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),

                                      ),
                                      // }
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const  SizedBox(height: 20,)
                          ],
                        ),
                      ] ,
                    ),
                  ),
                ),
              )
          );
        }
        ),
      ),
    );
  }
}
