import 'package:cuickdevuser/controller/Uiform_controller.dart';
import 'package:cuickdevuser/controller/dynamic_chart.dart';
import 'package:cuickdevuser/controller/tableview_controller.dart';
import 'package:cuickdevuser/screen/welcome.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/login_controller.dart';
import '../controller/pivotcontroller.dart';
import '../service/httpservice.dart';

class Menucontroller extends GetxController with GetTickerProviderStateMixin {

  var currentIndex = 0.obs;
  var iscreate = 0.obs;
  var isread = 0.obs;
  var isupdate = 0.obs;
  var isdelete = 0.obs;
  var isuserFilter = 0.obs;

  final LoginController loginController = Get.put(LoginController());


  HttpServices httpServices = HttpServices();


  void changeTabmenu(int index) {

    if (currentIndex.value == 1) {
      Get.find<Uiformcontroller>().clearForm();
    }
    currentIndex.value = index;
    update();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

  }
  // void changeTab(int index) {
  //   // Lock orientation
  //   SystemChrome.setPreferredOrientations([
  //     DeviceOrientation.portraitUp,
  //     DeviceOrientation.portraitDown,
  //   ]);
  //
  //   final currentTab = currentIndex.value;
  //
  //   // If switching away from form-related tabs
  //   if ([1, 2, 3].contains(currentTab) && currentTab != index) {
  //     final formController = Get.find<Uiformcontroller>();
  //     formController.clearForm(); // 👈 Use your full clearing method here
  //     FocusScope.of(Get.context!).unfocus();
  //
  //
  //   }
  //
  //   // If user taps the current Home tab again, navigate to welcome screen
  //   if (currentTab == 0 && index == 0) {
  //     Get.offAll(() => const Welcomescreen());
  //   } else {
  //     currentIndex.value = index;
  //   }
  //
  //   update();
  // }

  void changeTab(int index, {bool isProgrammatic = false}) {
    // Lock orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final currentTab = currentIndex.value;

    // If switching away from form-related tabs
    if ([1, 2, 3].contains(currentTab) && currentTab != index) {
      final formController = Get.find<Uiformcontroller>();
      formController.clearForm();
      FocusScope.of(Get.context!).unfocus();
    }

    // Avoid triggering double back if it's a programmatic tab change
    if (!isProgrammatic && currentTab == 0 && index == 0) {
      Get.offAll(() => const Welcomescreen());
    } else {
      currentIndex.value = index;
    }

    update();
  }

  Future<void> getuser_role_access(String formID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String applicationRoleId =prefs.getString("applicationRoleId") ?? '';

    var res = await httpServices.getUserAccess(
      formId: formID,
      applicationRoleId: applicationRoleId,
    );

    if (res != null && res['success'] == true) {
      var userAccesslist = res['result']['data'];

      if (userAccesslist.isNotEmpty) {
        var firstAccess = userAccesslist[0]; // Get first index

        iscreate.value = firstAccess['create'] ?? 0;
        isread.value = firstAccess['read'] ?? 0;
        isupdate.value = firstAccess['update'] ?? 0;
        isdelete.value = firstAccess['delete'] ?? 0;
        isuserFilter.value = firstAccess['userFilter'] ?? 0; // If available

      } else {
      }
    } else {
    }
  }

}
