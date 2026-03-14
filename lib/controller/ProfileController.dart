import 'dart:convert';

import 'package:cuickdevuser/model/Profilemodel.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  HttpServices  httpServices = HttpServices();

  Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  @override
  void onInit() {
    super.onInit();
    getUserProfile();
  }
  // API for Get User Profile
  Future<void> getUserProfile() async {
    try {
      var res = await httpServices.GetUserprofile();

      // 🔹 Full API response print in terminal
      print('User Profile API Response:');
      print(jsonEncode(res));

      if (res != null && res['success'] == true) {
        var data = res['result']['data'];

        // 🔹 Parsed data print
        print('Parsed User Data:');
        print(jsonEncode(data));

        userProfile.value = UserProfile.fromJson(data);
        update();
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
    }

  }

}