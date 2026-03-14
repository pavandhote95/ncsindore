import 'dart:io';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/updateprofilecontroller.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/controller/ProfileController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart'; // Required for MediaType
import 'package:image_cropper/image_cropper.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final Updateprofilecontroller controller = Get.put(Updateprofilecontroller());

  ProfileController profileController = Get.put(ProfileController());
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80, // Adjust quality as needed
    );

    return result != null ? File(result.path) : file; // Convert XFile to File
  }
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) {
      return;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile == null) {
      return;
    }

    File croppedFilePath = File(croppedFile.path);

    File compressedFile = await _compressImage(croppedFilePath);

    // Check if image size > 1MB
    if (compressedFile.lengthSync() > 1024 * 1024) {
      _showImageTooLargeDialog();
      return;
    }

    setState(() {
      _imageFile = XFile(compressedFile.path);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    final uri = Uri.parse(
        'https://api.ncsindore.com/ctl/User/cuickdev/user/doc/${controller.userProfile.value!.id}/${controller.userProfile.value!.imageId}/imageId;jsessionid=$sessionId');

    final mimeType = lookupMimeType(_imageFile!.path) ?? 'application/octet-stream';
    final mediaType = MediaType.parse(mimeType);

    final request = http.MultipartRequest('POST', uri)
      ..fields['id'] = controller.userProfile.value!.id.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
        contentType: mediaType,
      ));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        CherryToast.success(
          backgroundColor: const Color(0xFFDDF4DE),
          animationDuration: Durations.short1,
          title: const Text(
            "Image uploaded successfully!",
            style: TextStyle(color: Colors.black),
          ),
        ).show(context);
        profileController.getUserProfile();
        Get.back(result: true);
      } else {
        print('response---------------->>${response}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  void _showImageTooLargeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Image Too Large"),
          content: Text("Image is greater than 1MB, please select a smaller image."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
/*  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) {
      return;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile == null) {
      return;
    }

    File croppedFilePath = File(croppedFile.path);

    File compressedFile = await _compressImage(croppedFilePath);

    if (compressedFile.lengthSync() > 1024 * 1024) {
      return;
    }

    setState(() {
      _imageFile = XFile(compressedFile.path);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    final uri = Uri.parse(
        'https://api.ncsindore.com/ctl/User/cuickdev/user/doc/${controller.userProfile.value!.id}/${controller.userProfile.value!.imageId}/imageId;jsessionid=$sessionId');

    final mimeType =
        lookupMimeType(_imageFile!.path) ?? 'application/octet-stream';
    final mediaType = MediaType.parse(mimeType);

    final request = http.MultipartRequest('POST', uri)
      ..fields['id'] = controller.userProfile.value!.id.toString()
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
        contentType: mediaType,
      ));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        CherryToast.success(
          backgroundColor: const Color(0xFFDDF4DE),
          animationDuration: Durations.short1,
          title: const Text(
            "Image uploaded successfully!",
            style: TextStyle(color: Colors.black),
          ),
        ).show(context);
        profileController.getUserProfile();
        Get.back(result: true);
      } else {
       print('response---------------->>${response}') ;


      }
    } catch (e) {
      print('Error: $e');
    }
  }*/

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _imageFile = null;
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
          actionsIconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Update Profile',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        body: Obx(() {
          final profile = controller.userProfile.value;
          return profile == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [

                        Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xff0c0a0a),
                              backgroundImage: _imageFile != null
                                  ? FileImage(File(_imageFile!.path))
                                  : NetworkImage(
                                      "https://cuickdev.com/API/DOCS/api/doc/th/${profile.imageId}?t=${DateTime.now().millisecondsSinceEpoch}",
                                    ) as ImageProvider,
                            ),
                            Positioned(
                              bottom: 1,
                              right: 1,
                              child: GestureDetector(
                                onTap: () {
                                  _pickImage(ImageSource.gallery);
                                },
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.black,
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 50),
                        Form(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: controller.firstNameController,
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                                decoration: InputDecoration(
                                  fillColor:
                                      isDarkMode ? Colors.black : Colors.white,
                                  label: Text(
                                    "First Name",
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  errorText: controller.firstNameError.value.isEmpty
                                      ? null
                                      : controller.firstNameError.value,
                                  prefixIcon: Icon(
                                    CupertinoIcons.person,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: controller.lastNameController,
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                                decoration: InputDecoration(
                                  fillColor:
                                      isDarkMode ? Colors.black : Colors.white,
                                  errorText: controller.lastNameError.value.isEmpty
                                      ? null
                                      : controller.lastNameError.value,
                                  label: Text(
                                    "Last Name",
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),

                                  ),
                                  prefixIcon: Icon(
                                    CupertinoIcons.person,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Call the Updateprofile method with the updated values
                                    await controller.Updateprofile(
                                      firstName: controller.firstNameController.text,
                                      lastName: controller.lastNameController.text,
                                      loginId: controller.loginIdController.text,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode
                                        ? Colors.blueAccent
                                        : Appcolorblue,
                                    side: BorderSide.none,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text('Update',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
        }));
  }
}
