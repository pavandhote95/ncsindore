import 'dart:convert';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';
import 'package:cuickdevuser/model/loginmodel.dart';
import 'package:cuickdevuser/screen/welcome.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/application_model.dart';
import '../screen/login_screen.dart';

class LoginController extends GetxController {
  var email = ''.obs;
  var forgotemail = ''.obs;
  var appimageid = 0.obs;
  var landingPage = 0.obs;
  var orgimageid = 0.obs;
  var password = ''.obs;
  var orgName = ''.obs;
  var orgAddress = ''.obs; // New variable to store the address
  var isSaving = false.obs;
  var ispassHiden = true.obs;
  var roleId = 0.obs;
  var enableUserSignup = false.obs;
  var loginByEmail = false.obs;
  var loginByMobileNo = false.obs;
  var loginByLoginCode = false.obs;
  var roleName = "".obs;
  var appName = "".obs;
  var isButtonEnabled = false.obs;
  RxBool rememberMe = false.obs;
  int orgId = 0;
  int appId = 0;
  var applicationRoleId = "".obs;
  var applicationRolename = "".obs;
  
  RxList<Menu> menus = <Menu>[].obs;
  HttpServices httpServices = HttpServices();

  void updateEmail(String value) {
    email.value = value;
    update();
  }

  void updateForgotEmail(String value) {
    forgotemail.value = value;
  }

  void updatePassword(String value) {
    password.value = value;
    update();
  }

  void toggle() {
    ispassHiden.value = !ispassHiden.value;
  }

  void clearForgotEmail() {
    forgotemail.value = "";
  }

  Future<void> forgotpassword() async {
    var res = await httpServices.Forgotpassword(loginid: forgotemail.value);
    if (res['success'] == true) {
      CherryToast.success(
        backgroundColor: Color(0xFFDDF4DE),
        animationDuration: Durations.short1,
        title: Text(res['result']['message'],
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
    } else {
      CherryToast.error(
        backgroundColor: Colors.red.shade50,
        animationDuration: Durations.short1,
        title: Text(res['result']['message'],
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
    }
  }

  void showToast() {
    if (Get.overlayContext != null) {
      CherryToast.success(
        backgroundColor: Color(0xFFDDF4DE),
        animationDuration: Durations.short1,
        title: const Text("Login Successfully",
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
    }
  }

Future<void> GetapplicationDetails() async {
  
    final pref = await SharedPreferences.getInstance();
    String? cdauth = pref.getString('cdauthkey');

    if (cdauth != null && cdauth.isNotEmpty) {
      List<String> parts = cdauth.split('.');
      if (parts.length > 1) {
        orgId = int.parse(parts[0]);
        appId = int.parse(parts[1]);
      }
    }

    var res = await httpServices.GetapplicationDetails(appid: appId.toString());

    // ✅ API RESPONSE PRINT (FULL)
    debugPrint("GetapplicationDetails API RESPONSE ---> $res");

    var data = res?['result']['data'];

    // ✅ DATA PART PRINT
    debugPrint("GetapplicationDetails DATA ---> $data");
    String appCode = data['code'] ?? "";
    appimageid.value = data['logo'] ?? 0;
    landingPage.value = data['landingPage'] ?? 0;
    appName.value = data['name'] ?? "";
    roleId.value = data['roleId'] ?? 0;
    enableUserSignup.value = data['enableUserSignup'] ?? false;
    loginByEmail.value = data['loginByEmail'] ?? false;
    loginByMobileNo.value = data['loginByMobileNo'] ?? false;
    loginByLoginCode.value = data['loginByLoginCode'] ?? false;
    roleName.value = data['roleName'] ?? "";

    pref.setInt("logo", appimageid.value);
    pref.setString("appName", appName.value);
    pref.setString("appCode", appCode);

    await GetorgDetails();

    pref.setString("orgName", orgName.value);
    update();
  }

  Future<void> GetorgDetails() async {
    try {
      var res = await httpServices.GetORGDetails(orgid: orgId);
      if (res != null && res['success'] == true) {
        var data = res['result']['data'];
        orgName.value = data['name'] ?? "";
        orgimageid.value = data['logoId'] ?? 0;
        orgAddress.value = data['address'] ?? "";
        update();
      }
    } catch (e) {
      debugPrint("Error fetching org details: $e");
    }
  }

  void validateForm() {
    isButtonEnabled.value = email.isNotEmpty &&
        password.isNotEmpty &&
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.value);
  }

  Future<void> login(String emailtext, String passwordtext) async {
    isSaving.value = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? cdauth = prefs.getString('cdauthkey');
    if (cdauth != null && cdauth.isNotEmpty) {
      List<String> parts = cdauth.split('.');
      if (parts.length > 1) {
        appId = int.parse(parts[1]);
        orgId = int.parse(parts[0]);
      }
    }

    try {
      var res = await httpServices.userAuthentication(
        mailid: emailtext,
        password: passwordtext,
      );
      if (res['success'] == true) {
        prefs.setBool("islogin", true);
        prefs.setString("jsessionid", res['result']['jsessionid'] ?? "");
        prefs.setString("name", res['result']['data']['name'] ?? "");
        prefs.setInt(
            "authkey",
            int.tryParse(res['result']['data']['authKey']?.toString() ?? "0") ??
                0);
        prefs.setInt(
            "userid",
            int.tryParse(res['result']['data']['userId']?.toString() ?? "0") ??
                0);
        prefs.setInt(
            "imageId",
            int.tryParse(res['result']['data']['imageId']?.toString() ?? "0") ??
                0);
        prefs.setInt(
            "appId",
            int.tryParse(res['result']['data']['appId']?.toString() ?? "0") ??
                0);
        prefs.setString("loginId", res['result']['data']['loginId'] ?? "");
        prefs.setInt(
            "defaultRoleId", res['result']['data']['defaultRoleId'] ?? 0);
        prefs.setString("saved_email", emailtext);
        prefs.setString("saved_password", passwordtext);

        if (rememberMe.value) {
          prefs.setBool("remember_me", true);
          storeAppData(
            cdauthkey: cdauth ?? "",
            appName: res['result']['data']['appName'] ?? "",
            email: emailtext,
            password: passwordtext,
          );
        }

        await Getapplications_role(appId.toString(), emailtext);
      } else {
        CherryToast.error(
          backgroundColor: const Color(0xFFF8D0D9),
          animationDuration: Durations.short1,
          title:
              Text(res['message'], style: const TextStyle(color: Colors.red)),
        ).show(Get.overlayContext!);
      }
    } catch (e) {
      debugPrint("Login error: $e");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> storeAppData({
    required String cdauthkey,
    required String appName,
    required String email,
    required String password,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_$cdauthkey', email);
    await prefs.setString('password_$cdauthkey', password);
    await prefs.setBool('remember_$cdauthkey', true);
    await prefs.setString('appname_$cdauthkey', appName);

    List<String> appKeys = prefs.getStringList('saved_apps') ?? [];
    if (!appKeys.contains(cdauthkey)) {
      appKeys.add(cdauthkey);
      await prefs.setStringList('saved_apps', appKeys);
    }
  }

  Future<void> Getapplications_role(String appId, String email) async {
    try {
      var response = await httpServices.fetchApplicationRole(appId, email);
      if (response != null &&
          response is Map<String, dynamic> &&
          response["success"] == true) {
        List<dynamic> dataList = response["result"]["data"] ?? [];
        if (dataList.isNotEmpty) {
          if (dataList.length == 1) {
            var applicationRoleId = dataList[0]["applicationRoleId"].toString();
            applicationRolename.value =
                dataList[0]["applicationRoleName"].toString();
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("applicationRoleId", applicationRoleId);
            await Getapplications_API(applicationRoleId);
          } else {
            showRoleSelectionPopup(dataList);
          }
        }
      } else {
        CherryToast.error(
          backgroundColor: Colors.red.shade50,
          animationDuration: Durations.short1,
          title: Text(response?["message"] ?? "Unknown error",
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
        Get.off(() => const LoginScreen());
      }
    } catch (e) {
      debugPrint("API Call Failed: $e");
    }
  }

  Future<void> Getapplications_API(dynamic roleId) async {
    var res = await httpServices.Getapplications(roleId: roleId);
    if (res?.success == true) {
      var data = res?.result.data;
      menus.assignAll(data!.menus);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      applicationRolename.value = data.name;
      await prefs.setString("userrolename", applicationRolename.value);
      showToast();
      Get.off(() => const Welcomescreen());
    }
  }

  void showRoleSelectionPopup(List<dynamic> dataList) async {
    String? selectedRole;
    int? selectedRoleId;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Select Role",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Get.back()),
                ],
              ),
              SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text("Select a Role"),
                            value: selectedRole,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            items: dataList.map((item) {
                              return DropdownMenuItem<String>(
                                value: item["applicationRoleName"],
                                child: Text(item["applicationRoleName"]),
                                onTap: () {
                                  selectedRoleId = item["applicationRoleId"];
                                  applicationRoleId.value =
                                      item["applicationRoleId"].toString();
                                },
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedRole = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text("Close",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedRoleId != null) {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString("applicationRoleId",
                                    selectedRoleId!.toString());
                                await Getapplications_API(
                                    selectedRoleId!.toString());
                              } else {
                                Get.snackbar("Error", "Please select a role!",
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Select",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void signup() {
    Get.toNamed(
      '/signup',
      arguments: {
        'orgId': orgId,
        'roleId': roleId.value,
        'roleName': roleName.value,
        'appimageid': appimageid.value,
        'orgimageid': orgimageid.value,
      },
    );
  }
}
