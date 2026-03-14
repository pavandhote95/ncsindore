import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/ProfileController.dart';
import 'package:cuickdevuser/screen/UpdateProfileScreen.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart ';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../components/Appcolor.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userrolename = "";
  ProfileController profileController = Get.put(ProfileController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getrolename();
    profileController.getUserProfile();
  }
  getrolename() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userrolename = prefs.getString("userrolename") ?? '';
    });
  }
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
        // actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
            child: Obx(() {
              if (profileController.userProfile.value == null) {
                return const CircularProgressIndicator();
              }
              final profile = profileController.userProfile.value!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: const Color(0xff0c0a0a),
                    backgroundImage: NetworkImage(
                      "https://cuickdev.com/API/DOCS/api/doc/th/${profile.imageId}?t=${DateTime.now().millisecondsSinceEpoch}",
                    ),
                  ),
                  const SizedBox(height: 30),
                  itemProfile('Name', "${profile.firstName} ${profile.lastName}", CupertinoIcons.person),
                  const SizedBox(height: 10),
                  itemProfile('Email', profile.loginId, CupertinoIcons.mail),
                  const SizedBox(height: 10),
if (profile.loginCode != null && profile.loginCode!.isNotEmpty) ...[
  itemProfile(
    'Login Code',
    profile.loginCode!,
    Icons.dialpad,
  ),
  const SizedBox(height: 10),
]
,
             
if (profile.mobileId != null && profile.mobileId!.isNotEmpty) ...[
  itemProfile(
    'Mobile No',
    profile.mobileId!,
    Icons.mobile_friendly,
  ),

],

                  const SizedBox(height: 10),
                  itemProfile('Role', userrolename, CupertinoIcons.info),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showChangePasswordDialog(context);
                        },
                        child: Container(
                          height: 50,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.blueAccent
                                  : const Color(0xFF1A237E),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Change Password',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.blueAccent
                                    : const Color(0xFF1A237E),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Lato',
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          Get.to(const UpdateProfileScreen());
                        },
                        child: Container(
                          height: 50,
                          width: 150,
                          decoration: BoxDecoration(
                            // color: Color(0xFF1A237E),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.blueAccent
                                  : const Color(0xFF1A237E),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.blueAccent
                                    : const Color(0xFF1A237E),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Lato',
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    HttpServices httpServices = HttpServices();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              title: const Center(
                child: Text('Change Password',
                    style: TextStyle(
                      color: Colors.black, // Dynamic color
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 10),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width - 5,
                      child: Column(
                        // mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current Password
                          TextFormField(
                            controller: currentPasswordController,
                            obscureText: obscureCurrent,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureCurrent
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureCurrent = !obscureCurrent;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter current password'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          // New Password
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNew,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              border:const OutlineInputBorder(),
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureNew = !obscureNew;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter new password'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          // Confirm Password
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              border: const OutlineInputBorder(),
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureConfirm = !obscureConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:const Color(0xFFEE1939),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFFEE1939),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Lato',
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (formKey.currentState!.validate()) {
                                    var res = await httpServices.Changepassword(
                                        oldPassword:
                                            currentPasswordController.text,
                                        newPassword: newPasswordController.text,
                                        confirmPassword:
                                            confirmPasswordController.text);
                                    if (res['success'] == true) {
                                      Get.back();
                                      CherryToast.success(
                                        backgroundColor: const Color(0xFFDDF4DE),
                                        animationDuration: Durations.short1,
                                        title: const Text(
                                            "Password changed successfully!",
                                            style:
                                                TextStyle(color: Colors.black)),
                                      ).show(Get.overlayContext!);
                                    } else {
                                      CherryToast.error(
                                        backgroundColor:
                                            const Color(0xFFF8D0D9),
                                        animationDuration: Durations.short1,
                                        title: Text(
                                            res['message']?.toString() ??
                                                'Something went wrong',
                                            style:
                                            const TextStyle(color: Colors.black)),
                                      ).show(Get.overlayContext!);
                                    }
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:const Color(0xFF1A237E),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Update',
                                      style: TextStyle(
                                        color: Color(0xFF1A237E),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Lato',
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  itemProfile(String title, String subtitle, IconData iconData) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                offset:const Offset(0, 5),
                color: Colors.indigo.withOpacity(.2),
                spreadRadius: 2,
                blurRadius: 10)
          ]),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        leading: Icon(
          iconData,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        // trailing: Icon(Icons.arrow_forward, color: Colors.grey.shade400),
        tileColor: isDarkMode ? Colors.grey[850] : Colors.white,
      ),
    );
  }
}
