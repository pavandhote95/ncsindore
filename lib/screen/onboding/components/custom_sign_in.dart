import 'package:cuickdevuser/screen/QR_scanner.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controller/login_controller.dart';
import '../../login_screen.dart';

Future<Object?> customSigninDialog(BuildContext context, {required ValueChanged onClosed}) async {



  return showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: "Sign up",
      context: context,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        Tween<Offset> tween = Tween(begin: Offset(0, -1), end: Offset.zero);
        return SlideTransition(
            position: tween.animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child);
      },
      pageBuilder: (context, _, __) => Center(
            child: Container(
              height: 700,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(40))),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                resizeToAvoidBottomInset:
                    false, // avoid overflow error when keyboard shows up
                body: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(children: [
                      Image.asset(
                        'assets/Backgrounds/indorencs.png',
                        width: 200,
                        height: 150,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "Effortlessly build advanced applications with indoreites —no coding needed! Transform your business using our intuitive no-code, serverless platform.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            // print('IconButton======IconButton=======>>');
                            // Get.to(QrScreen());
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(builder: (_) => QrScreen()),
                            );
                          },
                          icon: SvgPicture.asset(
                            "assets/icons/scanicon.svg",
                            height: 100,
                            width: 100,
                          )),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        "Click here to scan for login.",
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                      // :SizedBox(),
                      const SizedBox(
                        height: 30,
                      ),
                      Container(
                        height: 40,
                        width: 180,
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
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16.0),
                                  children: [
                                    TextSpan(
                                      text: 'NCS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        // Black text for "NCS"
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
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () {
                          _showSavedAppsPopup(context);
                        },
                        child: Container(
                          height: 40,
                          width: 180,
                          decoration: BoxDecoration(
                           border: Border.all(color: const Color(0xFF273070)),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          // color: Color(0xFF273070),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('My Apps '  ,style: TextStyle(
                                    color: Color(0xFF273070), fontSize: 16),),
                                Icon(Icons.arrow_drop_down_outlined,color: Color(0xFF273070), )
                              ],
                            ),
                          ),
                        ),
                      ),

                    ]),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: -48,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.close, color: Colors.black),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )).then(onClosed);
}

void _showSavedAppsPopup(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> appKeys = prefs.getStringList('saved_apps') ?? [];
  // print('===appKeys=============>>>${appKeys}');
  List<Map<String, String>> apps = [];
  String email ="";
  String pass="";
  String appName ="";
  for (String key in appKeys) {
    bool remember = prefs.getBool('remember_$key') ?? false;
    if (remember) {


      email = prefs.getString('email_$key') ?? '';
      appName = prefs.getString('appname_$key') ?? '';
      pass = prefs.getString('password_$key') ?? '';
      apps.add({
        'cdauthkey': key,
        'email': email,
        'appName': appName,
        'password': pass,
      });


    }
  }
  final LoginController loginController = Get.put(LoginController());


  // Show Dialog
  showDialog(


    context: context,
    builder: (context) {
      return  StatefulBuilder(
        builder: (context, setState) {
          return


            AlertDialog(

              contentPadding: EdgeInsets.symmetric(horizontal: 6),
              backgroundColor: Colors.white,
              title: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('', style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black)),
              ),
              content: apps.isEmpty
                  ? const Text('No saved apps.')
                  : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return app['appName']!.isEmpty ?SizedBox() :


                      Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child:
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(app['appName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black)),
                        // subtitle: Text(app['email'] ?? '', style: const TextStyle(color: Colors.grey,fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.login, color: Colors.blue),
                              tooltip: 'Login to this app',
                              onPressed: () async {
                                Get.back();

                                await prefs.remove('cdauthkey',);

                                await prefs.setString(
                                    'cdauthkey', app['cdauthkey']!);
                                Navigator.pop(context); // Close dialog
                                final email = app['email'];
                                final password = app['password'];

                                if (email != null && password != null &&
                                    email.isNotEmpty && password.isNotEmpty) {
                                  loginController.login(email, password);
                                } else {
                                  Get.snackbar(
                                    "Missing Credentials",
                                    "Email or password not found for this app.",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red.shade100,
                                    colorText: Colors.black,
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete this app',
                              onPressed: () async {

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: const Text("Are you sure you want to delete this app?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Cancel"),
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                        ),
                                        TextButton(
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () async {
                                            // Perform delete action here
                                            String key = app['cdauthkey']!;
                                            await prefs.remove('email_$key');
                                            await prefs.remove('password_$key');
                                            await prefs.remove('remember_$key');
                                            await prefs.remove('appname_$key');

                                            List<String> updatedList = prefs.getStringList(
                                                'saved_apps') ?? [];
                                            updatedList.remove(key);
                                            await prefs.setStringList(
                                                'saved_apps', updatedList);

                                            setState(() {
                                              apps.removeAt(index);
                                            });

                                            Navigator.of(context).pop(); // Close the dialog after delete
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },

                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );

        }
      )
          ;
    },
  );
}

