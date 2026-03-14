import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/httpservice.dart';


class SignUpController extends GetxController {
  var firstName = ''.obs;
  var lastName = ''.obs;
  var email = ''.obs;
  var password = ''.obs;
  var confirmPass = ''.obs;
  var isSaving = false.obs;
  var orgId = ''.obs;
  var roleId = ''.obs;
  var roleName = ''.obs;
  var ispassHiden = true.obs;
  var isButtonEnabled = false.obs;
  HttpServices httpServices = HttpServices();
  void setSignUpData(dynamic orgIdVal, dynamic roleIdVal, String roleNameVal) {
    // Ensure orgId and roleId are converted to strings
    orgId.value = orgIdVal?.toString() ?? ''; // Convert to string or default to empty string
    roleId.value = roleIdVal?.toString() ?? ''; // Convert to string or default to empty string
    roleName.value = roleNameVal;
  }

  void updateFirstName(String value) {
    firstName.value = value;
    validateForm();
  }

  void updateLastName(String value) {
    lastName.value = value;
    validateForm();
  }

  void updateEmail(String value) {
    email.value = value;
    validateForm();
  }

  void updatePassword(String value) {
    password.value = value;
    validateForm();
  }

  void updateConfirmPass(String value) {
    confirmPass.value = value;
    validateForm();
  }

  void validateForm() {
    isButtonEnabled.value = firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        password.isNotEmpty &&
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.value);
  }

  void toggle() {
    ispassHiden.value = !ispassHiden.value;  // Toggles password visibility
  }

  Future<void> signUp() async {
    isSaving.value = true; // Set loading state
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Prepare the payload with form data
    Map<String, dynamic> payload = {
      'firstName': firstName.string,
      'lastName': lastName.string,
      'loginId': email.string,
      'password': password.string,
      'orgId': orgId.string, // Replace with correct data type if needed
      'roleId': roleId.string,
      'roleName': roleName.string,
    };

    if (isButtonEnabled.value) {
      try {
        var res = await httpServices.signUpUser(payload);
        print('response of sign up===>${res}');// Make the API call
        if (res != null && res['success'] == true) {
          // If the signup is successful
          isSaving.value = false;
          showToast(); // Show success message or toast

          prefs.setBool("islogin", true);
          prefs.setString("jsessionid", res['result']?['jsessionid'] ?? "");
          prefs.setString("name", res['result']?['data']?['name'] ?? "");
          prefs.setInt("authkey", int.tryParse(res['result']?['data']?['authKey']?.toString() ?? "0") ?? 0);
          prefs.setInt("imageId",int.tryParse(res['result']['data']['imageId']?.toString() ?? "0") ?? 0);
          prefs.setInt("userid", int.tryParse(res['result']?['data']?['userId']?.toString() ?? "0") ?? 0);

          // Navigate to the next screen after successful sign-up
          Get.back();
        } else {
          // Error response
          String errorMessage = res?['message']?.toString() ?? 'Signup failed';
          debugPrint('Error Message: $errorMessage'); // Debug print the error message
          CherryToast.error(
            backgroundColor: const Color(0xFFF8D0D9),
            animationDuration: Durations.short1,
            title: Text(errorMessage, style: const TextStyle(color: Colors.black)),
          ).show(Get.overlayContext!);
        }
      } catch (e) {
        // Handle errors
        print("Error during sign-up: $e");
        CherryToast.error(
          backgroundColor: Color(0xFFF8D0D9),
          animationDuration: Durations.short3,
          animationCurve: Curves.easeInCubic,
          title: Text('Server not found', style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
      } finally {
        isSaving.value = false; // End loading state
      }
    }

  }

  void navigateToHome() {
    Get.offNamed('/login');
  }

  void showToast() {
    CherryToast.success(
      backgroundColor: Color(0xFFDDF4DE),
      animationDuration: Durations.short1,
      title: const Text("Sign up successful",
          style: TextStyle(color: Colors.black)),
    ).show(Get.overlayContext!);


  }
}

