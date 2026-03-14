import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/controller/ProfileController.dart';
import 'package:cuickdevuser/model/Profilemodel.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';



class Updateprofilecontroller extends GetxController {
  HttpServices  httpServices = HttpServices();

  Rxn<UserProfile> userProfile = Rxn<UserProfile>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController loginIdController = TextEditingController();
  var firstNameError = ''.obs;
  var lastNameError = ''.obs;
  @override
  void onInit() {
    super.onInit();
    getUserProfile();
  }

  Future<void> getUserProfile() async {
    try {

      var res = await httpServices.GetUserprofile();

      if (res != null && res['success'] == true) {
        var data = res['result']['data'];
        userProfile.value = UserProfile.fromJson(data);
        if(userProfile.value != null){
          firstNameController.text =userProfile.value!.firstName;
          lastNameController.text = userProfile.value!.lastName;
          loginIdController.text = userProfile.value!.loginId;
        }
        update();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  ProfileController profileController = Get.put(ProfileController());
  Future<void> Updateprofile({
    required String firstName,
    required String lastName,
    required String loginId,
  }) async {

    firstNameError.value = '';
    lastNameError.value = '';
    try {
      var res = await httpServices.upadateUserprofile(
        id: userProfile.value!.id,
        firstname: firstName, // Pass the updated first name
        lastname: lastName, // Pass the updated last name
        loginid: loginId, // Pass the updated login id
        orgid: userProfile.value!.orgId,
        roleId: userProfile.value!.roleId,
        imageId: userProfile.value!.imageId,
      );

      if (res != null && res['success'] == true) {

        CherryToast.success(
          backgroundColor: const Color(0xFFDDF4DE),
          animationDuration: Durations.short1,
          title: const Text("Profile Updated!",
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
        await getUserProfile();


        profileController.getUserProfile();
        Get.back(result: true);
      }else{
        final inputErrors = res!['result']['inputerror'];
        print('inputErrors=============>>${inputErrors}');
        firstNameError.value = inputErrors['firstName'] ?? '';
        lastNameError.value = inputErrors['lastName'] ?? '';
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }



}
