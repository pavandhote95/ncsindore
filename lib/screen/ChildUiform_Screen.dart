import 'dart:convert';
import 'dart:io';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/Childcontroller.dart';
import 'package:cuickdevuser/controller/Uiform_controller.dart';
import 'package:cuickdevuser/controller/editform_controller.dart';
import 'package:cuickdevuser/screen/Menucontroller.dart';
import 'package:cuickdevuser/service/apihelper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../controller/tableview_controller.dart';

class ChilduiformScreen extends StatefulWidget {

final String title ;
final int editid ;

  const ChilduiformScreen({
    super.key,
  required this.title,
  required this.editid
  });

  @override
  State<ChilduiformScreen> createState() => _UiFormScreenState();
}

class _UiFormScreenState extends State<ChilduiformScreen> {
  final Childcontroller controller = Get.put(Childcontroller());
  final ApiBaseHelper helper = ApiBaseHelper();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String fieldvalue = "";
  String? selectedValue; // Store selected value
  bool isFormSubmitted = false; // Track form submission status
  int captureimage = 0;
  bool search = false;
  final ImagePicker _picker = ImagePicker();
  String? filePath;
  Map<String, TextEditingController> _controllers = {};
  late var result = false;
  Map<String, String?> resulterror = {}; // Store dynamic errors
  Menucontroller menucontroller = Get.put(Menucontroller());
  final TableviewController viewcontroller = Get.put(TableviewController());
  Future<Map<String, dynamic>?> SaveForm() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");

    }
    Map<String, dynamic> reqBody = {};

    if(controller.saveform_id.value != 0  ){
      reqBody = {'id': controller.saveform_id.value}; // Add the 'id' field first
    }

    for (var field in controller.childlabellist) {
      dynamic fieldValue = controller.getFieldValue(field['label']) ?? '';

      if (fieldValue.isNotEmpty && fieldValue != "") {
        reqBody[field['code'].toString()] = fieldValue;
      }
    }
    try {
      final response = await helper.postApi(
        "api/v1/${controller.childappCode.value}/${controller.childcode.toLowerCase()}/${controller.saveformcode.value}/saveForm;jsessionid=$sessionId",
        reqBody,
      );

      print('✅ API Response URL : ${'api/v1/${controller.childappCode.value}/${controller.childcode.toLowerCase()}/${controller.saveformcode.value}/saveForm'}');
      print('API Response: ${response.toString()}');

      if (response == null) {
        print("❌ API response is NULL");
      } else {
        print("✅ API response received: $response");
        if (response != null && response['success'] == true) {
              print('response======data========>>>${response['result']['data']['id']}');
              setState(() {
                controller.saveform_id.value = response['result']['data']['id'];
              });
              Get.back();

              showToast();
              return response;
            } else {
              return response;
            }
      }
    } catch (e) {
      print("⚠️ Error occurred: $e");
    }
    return null;

  }
  void handleButtonClick(String buttonType) async {
    if (buttonType == "save") {
      if (_formKey.currentState?.validate() ?? false) {


        Map<String, dynamic>? response = await SaveForm();
        print('response================$response');

        if (response != null && response['success']) {
          setState(() {
            controller.saveform_id.value = response['result']['data']['id'];
          });

          showToast();
        } else {
          var inputError = response!['result']['inputerror'];
          setState(() {
            resulterror.clear();
            inputError.forEach((key, value) {
              resulterror[key] = value;
              CherryToast.error(
                backgroundColor: const Color(0xFFF8D0D9),
                animationDuration: Durations.short1,
                title: const Text("Error Saving Form",
                    style: TextStyle(color: Colors.black)),
              ).show(Get.overlayContext!);
            });

          });
        }
      }
    }

    else if (buttonType == "cancel") {
      debugPrint('Navigating to list...');
      controller.saveform_id.value = 0 ;
      Get.back();

    }
    else if (buttonType == "delete") {

      debugPrint('delete-------------');
      if(controller.saveform_id.value!= 0){
        showDeleteConfirmationedit();
      }
    }

    else if (buttonType == "list") {
      debugPrint('Navigating to list...');
      Get.back();

    }
    else if (buttonType == "new") {
      debugPrint('Navigating to New...');
      controller.imagePaths.clear();
      // controller.clearForm();
      _controllers.clear();
      controller.saveform_id.value = 0 ;
      setState(() {});
    }
  }
  Future<void> _pickAndUploadImage(String code) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // Handle case where no image was picked

    File imageFile = File(pickedFile.path);
    int imageSizeInBytes = await imageFile.length();
    print('Original image size: ${imageSizeInBytes} bytes');

    // Keep compressing the image until it's <= 512 KB
    while (imageSizeInBytes > 512000) {
      print('Compressing image... Current size: ${imageSizeInBytes} bytes');
      imageFile = await compressImage(imageFile);
      imageSizeInBytes = await imageFile.length();
      setState(() {
        controller.imagePaths[code] = imageFile.path;
      });
    }

    print('Final compressed image size: ${imageSizeInBytes} bytes');
    setState(() {
      controller.imagePaths[code] = imageFile.path;
    });
    // Convert to XFile before uploading
    final XFile compressedXFile = XFile(imageFile.path);
    await _uploadImage(compressedXFile, code);
  }
  Future<void> getImage1(String fieldCode, ImageSource source) async {
    // Pick an image from the source (gallery or camera)
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return; // Handle case where no image was picked

    File imageFile = File(pickedFile.path);
    int imageSizeInBytes = await imageFile.length();
    print('Original image size: ${imageSizeInBytes} bytes');

    // Keep compressing the image until it's <= 512 KB
    while (imageSizeInBytes > 512000) {
      print('Compressing image... Current size: ${imageSizeInBytes} bytes');
      imageFile = await compressImage(imageFile);
      imageSizeInBytes = await imageFile.length();
      setState(() {
        controller.imagePaths[fieldCode] = imageFile.path;
      });
    }

    print('Final compressed image size: ${imageSizeInBytes} bytes');
    setState(() {
      controller.imagePaths[fieldCode] = imageFile.path;
    });
    // Convert to XFile before uploading
    final XFile compressedXFile = XFile(imageFile.path);
    await _uploadImage(compressedXFile, fieldCode);
  }
  Future<File> compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: 50,
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }

    // Return the compressed file
    final compressedFile = File(imageFile.path)..writeAsBytesSync(result);
    return compressedFile;
  }
  Future<void> _uploadImage(XFile pickedFile, String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      print('Session ID is empty. Please login again.');
      return;
    }
    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.childappCode.value}/${controller.childcode.value}/doc/${controller.saveform_id.value}/0/$code;jsessionid=$sessionId');

    var request = http.MultipartRequest('POST', uri);
    File imageFile = File(pickedFile.path);

    var file = await http.MultipartFile.fromPath('file', imageFile.path);

    request.files.add(file);

    var response = await request.send();

    String responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      CherryToast.success(
        backgroundColor: Color(0xFFBCF3BF),

        animationDuration: Durations.short1,
        description: const Text("Image uploaded successfully!",
            style: TextStyle(color: Colors.black)),
        title: const Text("Success",
            style: TextStyle(color: Colors.black)),
      ).show(context);

      try {
        var jsonResponse = jsonDecode(responseBody);
        setState(() {
          controller.uploadimage[code] =jsonResponse['result']['data'][code];
        });
      } catch (e) {}
    } else {
      CherryToast.error(
        backgroundColor: const Color(0xFFF37691),
        animationDuration: Durations.short1,
        title: const Text('Failed to upload the file!',
            style: const TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);

    }
  }
  void showToast() {
    CherryToast.success(
      backgroundColor: Color(0xFFBCF3BF),
      animationDuration: Durations.short1,
      title: const Text("Form saved successfully!",
          style: TextStyle(color: Colors.black)),
    ).show(context);
    controller.filteredData.refresh(); // Refresh UI using GetX
    controller.Getlistdata();
    if(menucontroller.currentIndex.value == 0){
      setState(() {
        resulterror.clear(); // Clear errors if success
      });
      // Get.back();
      controller.imagePaths.clear();
      for (var field in controller.childlabellist) {
        var fieldValue = controller.getFieldValue(field['label']) ?? '';
        if (fieldValue.isNotEmpty && fieldValue != "") {
          controller.imagePaths[field['code']]= null;
          controller.setFieldValue(field['label'],"");
          controller.setInitialValue(field['code'],"");
        }
      }
      _controllers.clear();
      setState(() {});
      for (var group in controller.groupchildlabellist) {
        var allFields = controller.getGroupsField(group.label);
        for (var field in allFields) {
          controller.setFieldValue(field['label'],"");
          controller.setInitialValue(field['code'],"");

        }
      }

       // Refresh UI using GetX
       // Refresh UI using GetX
    }


  }
  void showDeleteConfirmationedit() {
    Get.dialog(
      AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () {
              // JUST CLOSE THE DIALOG, NO EXTRA NAVIGATION!
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {

              // viewcontroller.deletelistitem(widget.appurl, widget.menutitle,  controller.saveform_id.value.toString(), viewcontroller.CurrentPage.value, 10);
              for (var field in controller.childlabellist) {
                controller.setFieldValue(field['label'], ""); // Reset field value
                controller.setInitialValue(field['code'], "");
              }
              controller.dataMap.clear();
              setState(() {
                controller.saveform_id.value = 0;
                controller.uploadDocument.clear() ;
                controller.uploadimage.clear() ;
              });
              Get.back();
              controller.imagePaths.clear();
              // controller.clearForm();
              for (var field in controller.childlabellist) {
                var fieldValue = controller.getFieldValue(field['label']) ?? '';

                if (fieldValue.isNotEmpty && fieldValue != "") {
                  controller.imagePaths[field['code']]= null;
                  controller.setFieldValue(field['label'],"");
                  controller.setInitialValue(field['code'],"");
                }
              }
              setState(() {});
              menucontroller.changeTab(0);
              Get.find<TableviewController>().update();
              viewcontroller.GetForm_API(viewcontroller.appurl.value);
              viewcontroller.CurrentPage.value = 0;

            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false, // Prevents accidental dismiss
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print('dispose===dispose========>>');

  }


  void showPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadFile(String id) async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.any, // Change this to `FileType.custom` for specific file types
    );

    if (pickedFile != null && pickedFile.files.single.path != null) {

      filePath = pickedFile.files.single.path!; // Update observable
      setState(() {
        controller.imagePaths[id] =  filePath!;
      });
      File file = File(filePath!);
      await _uploadFile(file, id);
    } else {
      Get.snackbar(
        "File Selection",
        "No file selected!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
  Future<void> _uploadFile(File pickedFile, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      Get.snackbar("Session Error", "Please log in again.");
      return;
    }

    int uploadDocumentId = (controller.uploadDocument[id] ?? 0) as int;


    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.childappCode.toString()}/${controller.childcode.value}/doc/${controller.saveform_id.value}/$uploadDocumentId/$id;jsessionid=$sessionId');

    print('=======>>$uri');

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(responseBody);
          print('jsonResponse=====jsonResponse========>>${jsonResponse}');

          var dataValue = jsonResponse['result']['data'][id];
          if (dataValue is int) {
            dataValue = dataValue.toString();
          }
          setState(() {
            controller.uploadDocument[id] = dataValue;
          });

          Get.snackbar(
            "Success",
            "File uploaded successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          print('Failed to parse JSON response: $e');
        }
      } else {
        Get.snackbar(
          "Upload Failed",
          "Failed to upload file. Error: ${response.statusCode}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error uploading file: $e');
      Get.snackbar(
        'Error',
        'An error occurred while uploading the file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }




  void updateResult(Map<String, String> reqBody, String showvalue) {
    setState(() {
      result = controller.evaluateCondition(reqBody, showvalue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final labelStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
      fontSize: 15,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar:  AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Appcolorblue,
        title:  Text('${widget.title}',
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body:
          SingleChildScrollView(child:
          Obx(
            () {

              var itemsWithoutGroup = controller.getItemsWithoutGroup();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child:Form(
                key: _formKey,
                child: controller.groupchildlabellist.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10),
                  child: Column(
                    children: [
                      ...controller.childlabellist.map((field) {
                        String label = field['label'];
                        String code = field['code'];
                        String fieldType = field['type'];
                        bool isRequired = field['required'] == 1;
                        bool isRefKey = field['refKey'] == 1;
                        bool primaryUsecase =
                            field['primaryUsecase'] != "";
                        bool showDropdown = primaryUsecase && isRefKey;
                        String yUsecase = field['primaryUsecase'] ?? "";
                        String showvalue = field['show'] ?? "";
                        String event = field['event'] ?? "";
                        String rule = field['rule'] ?? "";
                        int captureImage = field['captureImage'] ?? 0;
                        Map<String, String> reqBody = {};

                        for (var field in controller.childlabellist) {
                          String fieldValue = controller
                              .getFieldValue(field['label'])
                              ?.toString() ??
                              '';
                          reqBody[field['code'].toString()] =
                              fieldValue;
                        }

                        final result = controller.evaluateCondition(
                            reqBody, showvalue);

                        if (field['system'] == 1) {
                          return const SizedBox.shrink();
                        }

                        // Ensure each field has a separate controller
                        _controllers.putIfAbsent(
                            label, () => TextEditingController());

                        // Set initial value once
                        _controllers[label]!.text =
                            controller.getFieldValue(label) ?? "";

                        if (fieldType == 'text' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                errorText: resulterror[code],
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.text,
                              onChanged: (value) {
                                controller.setFieldValue(label, value);
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                              enabled: field['code'] != controller.parentKey, // Disable if code matches parentKey
                            ),
                          );
                        }
                        if (fieldType == 'email' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) async {
                                setState(() {
                                  controller.setFieldValue(
                                      label, value);
                                });
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                              enabled: field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        if (fieldType == 'textarea' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: TextFormField(
                              style: labelStyle,

                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelStyle: labelStyle,
                                labelText: label,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: 3,
                              // You can set this to null for unlimited lines
                              onChanged: (value) {
                                controller.setFieldValue(label, value);
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                              enabled: field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        if (showDropdown && result) {
                          final dropdownItems = controller.prelaodlist[yUsecase] ?? [];
                          bool isDisabled = field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,),
                            child: DropdownButtonFormField<String>(
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                                hintText:
                                'Select $label', // Placeholder hint text
                              ),
                              value: controller
                                  .getFieldValue(label)
                                  ?.isEmpty ??
                                  true
                                  ? null // Ensures value is null if empty or not set
                                  : controller.getFieldValue(label),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null, // Placeholder value
                                  child: Text(
                                    'Select an $label',
                                    style:
                                    TextStyle(color: Colors.black),
                                  ),
                                ),
                                ...dropdownItems
                                    .map<DropdownMenuItem<String>>(
                                        (item) {
                                      return DropdownMenuItem<String>(
                                        value: item['id'].toString(),
                                        child: Text(item['_val']),
                                      );
                                    }).toList(),
                              ],
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller.GetUserData(code, rule, value!);
                                  controller.admissionId = value;
                                  setState(() {
                                    controller.setFieldValue(label, value);
                                  });
                                } else {
                                  controller.setFieldValue(label, value!);
                                }
                              },

                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,

                            ),
                          );
                        }
                        if (fieldType == 'object' && result) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,

                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.text,
                              onChanged: (value) {
                                controller.setFieldValue(label, value);
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'email' && result) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,

                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) async {
                                setState(() {
                                  controller.setFieldValue(label, value);
                                });
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'url'&& result) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
                              decoration: InputDecoration(

                                labelStyle: labelStyle,
                                labelText: label,
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.url,
                              onChanged: (value) {
                                controller.setFieldValue(label, value);
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'password' && result) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
                              decoration: InputDecoration(
                                labelStyle: labelStyle,
                                labelText: label,
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                                // suffixIcon: Icon(Icons.lock), // Password icon
                              ),
                              // obscureText: true, //  Hide password text
                              onChanged: (value) {
                                controller.setFieldValue(label, value);
                              },
                              validator: (value) {
                                if (isRequired &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter $label';
                                }

                                final regexPattern =
                                field['regex']; // e.g., "^[1-5]$"
                                if (regexPattern != null &&
                                    value != null &&
                                    value.isNotEmpty) {
                                  final regex = RegExp(regexPattern);
                                  if (!regex.hasMatch(value)) {
                                    return 'Invalid input for $label';
                                  }
                                }

                                return null;
                              },
                            ),
                          );
                        }
                        if ((fieldType == 'number' ||
                            fieldType == 'long' ||
                            fieldType == 'decimal' ||fieldType ==
                            'expression' ||
                            fieldType == 'phone') &&
                            result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                controller.setFieldValue(label, value);
                                // controller.updateTextController(label, value);
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                              enabled: field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        if (fieldType == 'time' && result) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              readOnly: true,
                              style: labelStyle,
                              controller: TextEditingController(
                                  text: controller.getFieldValue(label)),
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelStyle: labelStyle,

                                labelText: label,

                                suffixIcon: Icon(
                                  Icons.access_time,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                // Time icon
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              onTap: () async {
                                TimeOfDay? selectedTime =
                                await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (selectedTime != null) {
                                  // Convert TimeOfDay to DateTime
                                  final now = DateTime.now();
                                  final dateTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      selectedTime.hour,
                                      selectedTime.minute);

                                  // Format the time to 24-hour format (HH:mm) without AM/PM
                                  String formattedTime =
                                  DateFormat('HH:mm').format(
                                      dateTime); // 24-hour format

                                  setState(() {
                                    controller.setFieldValue(
                                        label, formattedTime);
                                  });
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'date' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              readOnly: true,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                suffixIcon: Icon(
                                  Icons.calendar_today,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              onTap: () async {
                                DateTime? selectedDate =
                                await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );

                                if (selectedDate != null) {
                                  String formattedDate =
                                  "${selectedDate.toLocal()}"
                                      .split(' ')[0];

                                  if (event != "") {
                                    // Call API to validate the selected date
                                    var response = await controller
                                        .validateAndSubmitDate(
                                        rule, formattedDate);
                                    // Handle response
                                    if (response != null &&
                                        response['success'] == false) {
                                      String errorMessage = response[
                                      'result']?['message'] ??
                                          'An error occurred while validating the date.';
                                      print(
                                          'errorMessage==========>>>>>${errorMessage}');
                                      showPopup(context, 'Error',
                                          errorMessage);
                                    } else if (response != null &&
                                        response['success'] == true) {
                                      // showPopup(context, 'Success', 'Date updated successfully!');

                                      controller.setFieldValue(
                                          label, formattedDate);
                                    }
                                  } else {
                                    setState(() {
                                      controller.setFieldValue(
                                          label, formattedDate);
                                    });
                                  }
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                              enabled: field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        if (fieldType == 'list' && result) {
                          List<dynamic> uniqueValues =
                          field['values'].toSet().toList();
                          String? selectedValue =
                          controller.getFieldValue(label);

                          if (!uniqueValues.contains(selectedValue)) {
                            selectedValue = null;
                          }
                          bool isDisabled = field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: DropdownButtonFormField<String>(
                              style: labelStyle,
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              decoration: InputDecoration(
                                labelText: label,
                                labelStyle: labelStyle,
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                                hintText:
                                'Select $label', // Placeholder text
                              ),
                              value: selectedValue,
                              items: [
                                DropdownMenuItem<String>(
                                  value: null, // Placeholder value
                                  child: Text('Select an $label',
                                      style: TextStyle(
                                          color: Colors.black)),
                                ),
                                ...uniqueValues
                                    .map<DropdownMenuItem<String>>(
                                        (value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                              ],
                                onChanged: isDisabled
                                    ? null // Disables dropdown if isDisabled is true
                                    : (value) async {
                                  if (event != "") {
                                    await controller.GetUserData(code, rule, value!);
                                    controller.admissionId = value;
                                    setState(() {
                                      controller.setFieldValue(label, value);
                                    });
                                  } else {
                                    controller.setFieldValue(label, value!);
                                  }
                                },

                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'map' && result) {
                          // Ensure the 'values' field contains data before displaying the dropdown
                          List<dynamic> mapValues =
                              field['values'] ?? [];
                          bool isDisabled = field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: DropdownButtonFormField<String>(
                              style: labelStyle,
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              //  value: controller.getFieldValue(label), // Set the initial value
                              value: controller
                                  .getFieldValue(label)
                                  ?.isEmpty ??
                                  true
                                  ? null // Set value to null if it's empty or null
                                  : controller.getFieldValue(label),
                              items: mapValues
                                  .map<DropdownMenuItem<String>>(
                                      (item) {
                                    // Map each entry to a dropdown item, using the 'value' field for display
                                    return DropdownMenuItem<String>(
                                      value: item['key'].toString(),
                                      // The key will be sent as the value
                                      child: Text(
                                        item['value'],
                                        style: labelStyle,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller.GetUserData(code, rule, value!);
                                  controller.admissionId = value;
                                  setState(() {
                                    controller.setFieldValue(label, value);
                                  });
                                } else {
                                  controller.setFieldValue(label, value!);
                                }
                              },

                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'doc' && result) {
                          return controller.saveform_id.value != 0
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: TextFormField(
                                    style: labelStyle,
                                    onTap: () {
                                      _pickAndUploadFile(code);
                                    },
                                    readOnly: true,
                                    controller:
                                    TextEditingController(
                                        text: controller.imagePaths[
                                        code] !=
                                            null
                                            ? controller.imagePaths[
                                        code]!
                                            .split('/')
                                            .last
                                            : ''

                                    ),
                                    decoration: InputDecoration(
                                      labelText: label,
                                      labelStyle: labelStyle,
                                      errorText:
                                      resulterror[code],
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      border:
                                      const OutlineInputBorder(
                                        borderSide:
                                        const BorderSide(
                                            color:
                                            Colors.green),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.attachment,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        onPressed: () {
                                          _pickAndUploadFile(
                                              code);
                                        },
                                      ),
                                    ),
                                    enabled: field['code'] != controller.parentKey,
                                    onChanged: (value) {
                                      setState(() {
                                        // filePath = value;
                                        controller.imagePaths[code] = value;
                                      });

                                      controller.setFieldValue(
                                          label, '0');
                                      controller.setInitialValue(
                                          label, '0');
                                      setState(() {

                                      });
                                    },
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 16.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Image.network(
                                      controller.uploadDocument[code] != null && controller.uploadDocument[code]!.isNotEmpty
                                          ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadDocument[code]}?t=${DateTime.now().millisecondsSinceEpoch}"
                                          : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
                                    ),
                                  ),

                                ),

                              ],
                            ),
                          )
                              : const SizedBox.shrink();
                        }
                        if (fieldType == 'file' && result) {
                          return controller.saveform_id.value != 0
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: TextFormField(
                                    style: labelStyle,
                                    onTap: () {
                                      if (captureImage == 1) {
                                        getImage1(code,
                                            ImageSource.camera);
                                      } else {
                                        _pickAndUploadImage(code);
                                      }
                                    },
                                    readOnly: true,
                                    controller:
                                    TextEditingController(
                                        text: controller.imagePaths[
                                        code] !=
                                            null
                                            ? controller.imagePaths[
                                        code]!
                                            .split('/')
                                            .last
                                            : ''),
                                    decoration: InputDecoration(
                                      labelText: label,
                                      labelStyle: labelStyle,
                                      errorText:
                                      resulterror[code],
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      border:
                                      const OutlineInputBorder(
                                        borderSide:
                                        const BorderSide(
                                            color:
                                            Colors.green),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.attachment,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        onPressed: () {
                                          if (captureImage == 1) {
                                            getImage1(code,
                                                ImageSource.camera);
                                          } else {
                                            _pickAndUploadImage(code);
                                          }
                                        },
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        controller.imagePaths[code] = value;
                                      });
                                      controller.setFieldValue(
                                          label, '0');
                                      controller.setInitialValue(
                                          label, '0');
                                    },
                                    enabled: field['code'] != controller.parentKey,
                                  ),
                                ),
                                controller.imagePaths[code] != null
                                    ? Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 16.0),
                                  child: Image.file(File(
                                      controller.imagePaths[
                                      code]!)), // Display the selected image (optional)
                                )
                                    :
                                Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 16.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Image.network(
                                      controller.uploadimage[code] != null && controller.uploadimage[code]!.isNotEmpty
                                          ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadimage[code]}?t=${DateTime.now().millisecondsSinceEpoch}"
                                          : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
                                    ),
                                  ),

                                ),

                              ],
                            ),
                          )
                              : const SizedBox.shrink();
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                      const SizedBox(height: 23),
                      Center(
                        child: Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          alignment: WrapAlignment.center,
                          children: controller.childbuttons.where((button) {
                            // Show button only if the corresponding permission is 1
                            switch (button.name.toLowerCase()) {
                              case 'list':
                                return controller.isread == 1;
                              case 'delete':
                                return controller.isdelete == 1;
                              case 'update':
                                return controller.isupdate == 1;
                              case 'save':
                                return controller.iscreate == 1; // Assuming you have issave for Save button
                              case 'new':
                                return controller.iscreate == 1;
                              case 'cancel':
                                return controller.iscreate == 1;
                              default:
                                return true; // Hide button if it doesn't match any case
                            }
                          }).map((button) {
                            return GestureDetector(
                              onTap: () {
                                handleButtonClick(
                                    button.name.toLowerCase());
                              },
                              child: Container(
                                height: 45,
                                width: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Color(0xFF4F76E2)
                                        : Color(0xFF1A237E),
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    button.name.toUpperCase(),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Color(0xFF4F76E2)
                                          : Color(0xFF1A237E),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Lato',
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [



                      if (controller.groupchildlabellist.isNotEmpty)
                        ...controller.groupchildlabellist.map((field) {
                          var filteredFields = controller.getGroupsField(field.label);

                          return filteredFields.isNotEmpty
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8),
                            child: SizedBox(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  labelStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  )
                                  ,
                                  fillColor: isDarkMode
                                      ? Colors.black
                                      : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        10.0),
                                  ),
                                ),
                                child: Column(
                                  children: [

                                    ...filteredFields
                                        .map((field) {
                                      String label =
                                      field['label'];
                                      String code = field['code'];
                                      String fieldType =
                                      field['type'];

                                      bool isRequired =
                                          field['required'] == 1;

                                      bool isRefKey =
                                          field['refKey'] == 1;
                                      bool primaryUsecase = field[
                                      'primaryUsecase'] !=
                                          "";
                                      String? showvalue = field.containsKey("show") ? field["show"] : null;
                                      String event =
                                          field['event'] ?? "";
                                      String rule =
                                          field['rule'] ?? "";
                                      bool showDropdown =
                                          primaryUsecase &&
                                              isRefKey;
                                      String yUsecase = field[
                                      'primaryUsecase'] ??
                                          "";



                                      String parentfilter =
                                          field['parentFilter'] ??
                                              "";
                                      int captureImage =
                                          field['captureImage'] ??
                                              0;
                                      if (parentfilter != "" &&
                                          parentfilter
                                              .isNotEmpty) {
                                        controller
                                            .addParentFilter();
                                      }

                                      Map<String, String> reqBody = {};
                                      for (var group in controller.groupchildlabellist) {
                                        var allFields = controller.getGroupsField(group.label);
                                        for (var field in allFields) {
                                          String fieldValue = controller.getFieldValue(field['label'])?.toString() ?? '';
                                          reqBody[field['code'].toString()] = fieldValue;
                                        }
                                      }


                                      final result = controller
                                          .evaluateCondition(
                                          reqBody, showvalue!);


                                      if (field['system'] == 1) {
                                        return const SizedBox
                                            .shrink();
                                      }

                                      _controllers.putIfAbsent(
                                          label,
                                              () =>
                                              TextEditingController());

                                      _controllers[label]!
                                          .text = (controller.getInitialValues(field['code'], label) ?? "").toString();

                                      if (fieldType == 'text' &&
                                          result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            style: labelStyle,
                                            controller:
                                            _controllers[
                                            label],
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[
                                              code],
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            keyboardType:
                                            TextInputType
                                                .text,
                                            onChanged:
                                                (value) async {
                                              if (event != "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                setState(() {
                                                  controller.dataMap[
                                                  field[
                                                  'code']] =
                                                  value!;

                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      value);
                                                  updateResult(reqBody, showvalue);
                                                });

                                              } else {
                                                setState(() {
                                                  controller.dataMap[
                                                  field[
                                                  'code']] =
                                                  value!;
                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      value!);
                                                  updateResult(reqBody, showvalue);
                                                });
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                            enabled: field['code'] != controller.parentKey,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'email' &&
                                          result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            style: labelStyle,
                                            controller:
                                            _controllers[
                                            label],
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[
                                              code],
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            keyboardType:
                                            TextInputType
                                                .emailAddress,
                                            onChanged:
                                                (value) async {
                                              setState(() {
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                controller
                                                    .setFieldValue(
                                                    label,
                                                    value!);
                                              });
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                            enabled: field['code'] != controller.parentKey,
                                          ),
                                        );
                                      }
                                      if (showDropdown &&
                                          result) {
                                        final dropdownItems =
                                            controller.prelaodlist[
                                            yUsecase] ??
                                                [];
                                        bool isDisabled = field['code'] == controller.parentKey;
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child:
                                          DropdownButtonFormField<
                                              String>(
                                            dropdownColor:
                                            isDarkMode
                                                ? Colors
                                                .grey[800]
                                                : Colors
                                                .white,
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              border:
                                              OutlineInputBorder(
                                                borderSide:
                                                BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                              hintText:
                                              'Select $label', // Placeholder hint text
                                            ),
                                            value: controller
                                                .getFieldValue(
                                                label)
                                                ?.isEmpty ??
                                                true
                                                ? null // Ensures value is null if empty or not set
                                                : controller
                                                .getFieldValue(
                                                label),
                                            items: [
                                              DropdownMenuItem<
                                                  String>(
                                                value: null,
                                                // Placeholder value
                                                child: Text(
                                                  'Select an $label',
                                                  style: const TextStyle(
                                                      color: Colors
                                                          .black),
                                                ),
                                              ),
                                              ...dropdownItems.map<
                                                  DropdownMenuItem<
                                                      String>>((item) {
                                                return DropdownMenuItem<
                                                    String>(
                                                  value: item[
                                                  'id']
                                                      .toString(),
                                                  child: Text(item[
                                                  '_val']),
                                                );
                                              }).toList(),
                                            ],
                                            onChanged: isDisabled
                                                ? null // Disables dropdown if isDisabled is true
                                                : (value) async {
                                              if (event != "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                controller
                                                    .admissionId =
                                                    value;
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                setState(() {
                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      value);
                                                  updateResult(reqBody, showvalue);
                                                });
                                              }
                                              else {
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                controller
                                                    .setFieldValue(
                                                    label,
                                                    value!);
                                                updateResult(reqBody, showvalue);
                                              }
                                            },


                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'object' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            controller: _controllers[label],
                                            style: labelStyle,
                                            decoration: InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,

                                              labelStyle: labelStyle,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.text,
                                            onChanged: (value) {
                                              controller.setFieldValue(label, value);
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'email' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            style: labelStyle,
                                            controller: _controllers[label],
                                            decoration: InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle: labelStyle,

                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: (value) async {
                                              setState(() {
                                                controller.setFieldValue(label, value);
                                              });
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'url'&& result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            controller: _controllers[label],
                                            style: labelStyle,
                                            decoration: InputDecoration(

                                              labelStyle: labelStyle,
                                              labelText: label,
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.url,
                                            onChanged: (value) {
                                              controller.setFieldValue(label, value);
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'password' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            controller: _controllers[label],
                                            style: labelStyle,
                                            decoration: InputDecoration(
                                              labelStyle: labelStyle,
                                              labelText: label,
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                              // suffixIcon: Icon(Icons.lock), // Password icon
                                            ),
                                            // obscureText: true, //  Hide password text
                                            onChanged: (value) {
                                              controller.setFieldValue(label, value);
                                            },
                                            validator: (value) {
                                              if (isRequired &&
                                                  (value == null || value.isEmpty)) {
                                                return 'Please enter $label';
                                              }

                                              final regexPattern =
                                              field['regex']; // e.g., "^[1-5]$"
                                              if (regexPattern != null &&
                                                  value != null &&
                                                  value.isNotEmpty) {
                                                final regex = RegExp(regexPattern);
                                                if (!regex.hasMatch(value)) {
                                                  return 'Invalid input for $label';
                                                }
                                              }

                                              return null;
                                            },
                                          ),
                                        );
                                      }

                                      if ((fieldType ==
                                          'number' ||
                                          fieldType ==
                                              'phone' ||
                                          fieldType ==
                                              'long' ||fieldType ==
                                          'expression' ||
                                          fieldType ==
                                              'decimal') &&
                                          result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            style: labelStyle,
                                            controller:
                                            _controllers[
                                            label],
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              errorText:
                                              resulterror[
                                              code],
                                              labelStyle:
                                              labelStyle,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            keyboardType:
                                            TextInputType
                                                .number,
                                            onChanged:
                                                (value) async {
                                              controller.dataMap[
                                              field[
                                              'code']] =
                                                  value; // Directly updating dataMap
                                              controller
                                                  .setInitialValue(
                                                  field[
                                                  'code'],
                                                  value);
                                              controller
                                                  .setFieldValue(
                                                  label,
                                                  value);
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }

                                      if (fieldType == 'date' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            readOnly: true,
                                            style: labelStyle,
                                            controller: TextEditingController(
                                                text: controller
                                                    .getFieldValue(
                                                    label)),
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[
                                              code],
                                              suffixIcon: Icon(
                                                Icons
                                                    .calendar_today,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors
                                                    .black,
                                              ),
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            enabled: field['code'] != controller.parentKey,
                                            onTap: () async {
                                              DateTime?
                                              selectedDate =
                                              await showDatePicker(
                                                context: context,
                                                initialDate:
                                                DateTime
                                                    .now(),
                                                firstDate:
                                                DateTime(
                                                    1900),
                                                lastDate:
                                                DateTime(
                                                    2100),
                                              );

                                              if (selectedDate !=
                                                  null) {
                                                String
                                                formattedDate =
                                                "${selectedDate.toLocal()}"
                                                    .split(
                                                    ' ')[0];

                                                if (event != "") {
                                                  // Call API to validate the selected date
                                                  var response =
                                                  await controller
                                                      .validateAndSubmitDate(
                                                      rule,
                                                      formattedDate);
                                                  updateResult(reqBody, showvalue);
                                                  // Handle response
                                                  if (response !=
                                                      null &&
                                                      response[
                                                      'success'] ==
                                                          false) {
                                                    String
                                                    errorMessage =
                                                        response['result']
                                                        ?[
                                                        'message'] ??
                                                            'An error occurred while validating the date.';
                                                    print(
                                                        'errorMessage==========>>>>>${errorMessage}');
                                                    showPopup(
                                                        context,
                                                        'Error',
                                                        errorMessage);
                                                  } else if (response !=
                                                      null &&
                                                      response[
                                                      'success'] ==
                                                          true) {
                                                    // showPopup(context, 'Success', 'Date updated successfully!');
                                                    setState(() {
                                                      controller.setFieldValue(
                                                          label,
                                                          formattedDate);
                                                      updateResult(reqBody, showvalue);
                                                    });
                                                  }
                                                } else {
                                                  setState(() {
                                                    controller.dataMap[
                                                    field[
                                                    'code']] =
                                                    formattedDate!;
                                                    controller
                                                        .setFieldValue(
                                                        label,
                                                        formattedDate);
                                                  });
                                                }
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'time' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            readOnly: true,
                                            style: labelStyle,
                                            controller: TextEditingController(
                                                text: controller
                                                    .getFieldValue(
                                                    label)),
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[
                                              code],
                                              labelText: label,

                                              suffixIcon: Icon(
                                                Icons.access_time,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors
                                                    .black,
                                              ),
                                              // Time icon
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            enabled: field['code'] != controller.parentKey,
                                            onTap: () async {
                                              TimeOfDay?
                                              selectedTime =
                                              await showTimePicker(
                                                context: context,
                                                initialTime:
                                                TimeOfDay
                                                    .now(),
                                              );
                                              if (selectedTime !=
                                                  null) {
                                                // Convert TimeOfDay to DateTime
                                                final now =
                                                DateTime
                                                    .now();
                                                final dateTime =
                                                DateTime(
                                                    now.year,
                                                    now.month,
                                                    now.day,
                                                    selectedTime
                                                        .hour,
                                                    selectedTime
                                                        .minute);

                                                // Format the time to 24-hour format (HH:mm) without AM/PM
                                                String
                                                formattedTime =
                                                DateFormat(
                                                    'HH:mm')
                                                    .format(
                                                    dateTime); // 24-hour format

                                                setState(() {
                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      formattedTime);
                                                });
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'map' && result) {
                                        // Ensure the 'values' field contains data before displaying the dropdown
                                        List<dynamic> mapValues =
                                            field['values'] ?? [];
                                        bool isDisabled = field['code'] == controller.parentKey;
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child:
                                          DropdownButtonFormField<
                                              String>(
                                            style: labelStyle,
                                            dropdownColor:
                                            isDarkMode
                                                ? Colors
                                                .grey[800]
                                                : Colors
                                                .white,
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            //  value: controller.getFieldValue(label), // Set the initial value
                                            value: controller
                                                .getFieldValue(
                                                label)
                                                ?.isEmpty ??
                                                true
                                                ? null // Set value to null if it's empty or null
                                                : controller
                                                .getFieldValue(
                                                label),
                                            items: mapValues.map<
                                                DropdownMenuItem<
                                                    String>>((item) {
                                              // Map each entry to a dropdown item, using the 'value' field for display
                                              return DropdownMenuItem<
                                                  String>(
                                                value: item['key']
                                                    .toString(),
                                                // The key will be sent as the value
                                                child: Text(
                                                  item['value'],
                                                  style:
                                                  labelStyle,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: isDisabled
                                                ? null // Disables dropdown if isDisabled is true
                                                : (value) async {
                                              if (event != "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                controller
                                                    .admissionId =
                                                    value;
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                setState(() {
                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      value);
                                                  updateResult(reqBody, showvalue);
                                                });
                                              }
                                              else {
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                controller
                                                    .setFieldValue(
                                                    label,
                                                    value!);
                                                updateResult(reqBody, showvalue);
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'list' && result) {
                                        List<dynamic>
                                        uniqueValues =
                                        field['values']
                                            .toSet()
                                            .toList();
                                        String? selectedValue =
                                        controller
                                            .getFieldValue(
                                            label);
                                        bool isDisabled = field['code'] == controller.parentKey;
                                        if (!uniqueValues
                                            .contains(
                                            selectedValue)) {
                                          selectedValue = null;
                                        }

                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child:
                                          DropdownButtonFormField<
                                              String>(
                                            style: labelStyle,
                                            dropdownColor:
                                            isDarkMode
                                                ? Colors
                                                .grey[800]
                                                : Colors
                                                .white,
                                            decoration:
                                            InputDecoration(
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              border:
                                              OutlineInputBorder(
                                                borderSide:
                                                BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                              hintText:
                                              'Select $label', // Placeholder text
                                            ),
                                            value: selectedValue,
                                            items: [
                                              DropdownMenuItem<
                                                  String>(
                                                value: null,
                                                // Placeholder value
                                                child: Text(
                                                    'Select an $label',
                                                    style: const TextStyle(
                                                        color: Colors
                                                            .black)),
                                              ),
                                              ...uniqueValues.map<
                                                  DropdownMenuItem<
                                                      String>>(
                                                      (value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child:
                                                      Text(value),
                                                    );
                                                  }).toList(),
                                            ],
                                            onChanged: isDisabled
                                                ? null // Disables dropdown if isDisabled is true
                                                : (value) async {
                                              if (event != "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                controller
                                                    .admissionId =
                                                    value;
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                setState(() {
                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      value);
                                                  updateResult(reqBody, showvalue);
                                                });
                                              }
                                              else {
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                controller
                                                    .setFieldValue(
                                                    label,
                                                    value!);
                                                updateResult(reqBody, showvalue);
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'file' && result) {
                                        return controller.saveform_id.value != 0
                                            ? Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical:
                                              8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical:
                                                    8.0),
                                                child:
                                                TextFormField(
                                                  onTap:
                                                      () {
                                                    if (captureImage ==
                                                        1) {
                                                      getImage1(
                                                          code,
                                                          ImageSource.camera);
                                                    } else {
                                                      _pickAndUploadImage(
                                                          code);
                                                    }
                                                    // _pickAndUploadImage(code);
                                                  },
                                                  style:
                                                  labelStyle,
                                                  readOnly:
                                                  true,
                                                  controller: TextEditingController(
                                                      text: controller.imagePaths[code] != null
                                                          ? controller.imagePaths[code]!.split('/').last
                                                          : ''),
                                                  decoration:
                                                  InputDecoration(
                                                    errorText:
                                                    resulterror[code],
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    labelText:
                                                    label,
                                                    labelStyle:
                                                    labelStyle,
                                                    border:
                                                    const OutlineInputBorder(
                                                      borderSide:
                                                      const BorderSide(color: Colors.green),
                                                    ),
                                                    suffixIcon:
                                                    IconButton(
                                                      icon:
                                                      Icon(
                                                        Icons.attachment,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                      onPressed:
                                                          () {
                                                        if (captureImage == 1) {
                                                          getImage1(code,
                                                              ImageSource.camera);
                                                        } else {
                                                          _pickAndUploadImage(code);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  enabled: field['code'] != controller.parentKey,
                                                  onChanged:
                                                      (value) async {
                                                    setState(
                                                            () {
                                                          setState(() {
                                                            // filePath = value;
                                                            controller.imagePaths[code] = value;
                                                          });

                                                          controller.setFieldValue(
                                                              label, '0');
                                                          controller.setInitialValue(
                                                              label, '0');
                                                          setState(() {

                                                          });
                                                        });
                                                  },
                                                ),
                                              ),
                                              controller.imagePaths[code] != null
                                                  ? Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical: 16.0),
                                                child: Image.file(File(
                                                    controller.imagePaths[
                                                    code]!)), // Display the selected image (optional)
                                              )
                                                  :
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical: 16.0),
                                                child:
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                  child: Image.network(
                                                    controller.uploadimage[code] != null && controller.uploadimage[code]!.isNotEmpty
                                                        ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadimage[code]}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                        : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
                                                  ),
                                                ),

                                              ),

                                            ],
                                          ),
                                        )
                                            : const SizedBox
                                            .shrink();
                                      }
                                      if (fieldType == 'doc' && result) {
                                        return controller.saveform_id.value != 0
                                            ? Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical:
                                              8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical:
                                                    8.0),
                                                child:
                                                TextFormField(
                                                  style:
                                                  labelStyle,
                                                  onTap:
                                                      () {
                                                    _pickAndUploadFile(
                                                        code);
                                                  },
                                                  readOnly:
                                                  true,
                                                  controller:
                                                  TextEditingController(
                                                      text: controller.imagePaths[
                                                      code] !=
                                                          null
                                                          ? controller.imagePaths[
                                                      code]!
                                                          .split('/')
                                                          .last
                                                          : ''

                                                  ),
                                                  decoration:
                                                  InputDecoration(
                                                    labelText:
                                                    label,
                                                    labelStyle:
                                                    labelStyle,
                                                    errorText:
                                                    resulterror[code],
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    border:
                                                    const OutlineInputBorder(
                                                      borderSide:
                                                      const BorderSide(color: Colors.green),
                                                    ),
                                                    suffixIcon:
                                                    IconButton(
                                                      icon:
                                                      Icon(
                                                        Icons.attachment,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                      onPressed:
                                                          () {
                                                        _pickAndUploadFile(code);
                                                      },
                                                    ),
                                                  ),              enabled: field['code'] != controller.parentKey,
                                                  onChanged:
                                                      (value) {
                                                    setState(() {
                                                      // filePath = value;
                                                      controller.imagePaths[code] = value;
                                                    });

                                                    controller.setFieldValue(
                                                        label, '0');
                                                    controller.setInitialValue(
                                                        label, '0');
                                                    setState(() {

                                                    });
                                                  },
                                                ),
                                              ),
                                              // controller.imagePaths[code] != null
                                              //     ? Padding(
                                              //   padding: const EdgeInsets
                                              //       .symmetric(
                                              //       vertical: 16.0),
                                              //   child: Image.file(File(
                                              //       controller.imagePaths[
                                              //       code]!)), // Display the selected image (optional)
                                              // )
                                              //     :
                                              Padding(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    vertical: 16.0),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                  child: Image.network(
                                                    controller.uploadDocument[code] != null && controller.uploadDocument[code]!.isNotEmpty
                                                        ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadDocument[code]}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                        : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
                                                  ),
                                                ),

                                              ),
                                            ],
                                          ),
                                        )
                                            : const SizedBox
                                            .shrink();
                                      }
                                      if (fieldType == 'time' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            readOnly: true,
                                            style: labelStyle,
                                            controller: TextEditingController(
                                                text: controller.getFieldValue(label)),
                                            decoration: InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelStyle: labelStyle,

                                              labelText: label,

                                              suffixIcon: Icon(
                                                Icons.access_time,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              // Time icon
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            onTap: () async {
                                              TimeOfDay? selectedTime =
                                              await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.now(),
                                              );
                                              if (selectedTime != null) {
                                                // Convert TimeOfDay to DateTime
                                                final now = DateTime.now();
                                                final dateTime = DateTime(
                                                    now.year,
                                                    now.month,
                                                    now.day,
                                                    selectedTime.hour,
                                                    selectedTime.minute);

                                                // Format the time to 24-hour format (HH:mm) without AM/PM
                                                String formattedTime =
                                                DateFormat('HH:mm').format(
                                                    dateTime); // 24-hour format

                                                setState(() {
                                                  controller.setFieldValue(
                                                      label, formattedTime);
                                                });
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'textarea' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            style: labelStyle,
                                            controller:
                                            _controllers[
                                            label],
                                            decoration:
                                            InputDecoration(
                                              fillColor:
                                              isDarkMode
                                                  ? Colors
                                                  .black
                                                  : Colors
                                                  .white,
                                              labelText: label,
                                              errorText:
                                              resulterror[
                                              code],
                                              labelStyle:
                                              labelStyle,
                                              border:
                                              OutlineInputBorder(
                                                borderSide:
                                                BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            enabled: field['code'] != controller.parentKey,
                                            keyboardType:
                                            TextInputType
                                                .multiline,
                                            maxLines: null,
                                            // Allows the textarea to expand based on input
                                            onChanged:
                                                (value) async {
                                              setState(() {
                                                controller.dataMap[
                                                field[
                                                'code']] =
                                                value!;
                                                controller
                                                    .setFieldValue(
                                                    label,
                                                    value);
                                              });
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value ==
                                                  null ||
                                                  value
                                                      .isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'object' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            controller: _controllers[label],
                                            style: labelStyle,
                                            decoration: InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,

                                              labelStyle: labelStyle,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.text,
                                            onChanged: (value) {
                                              controller.setFieldValue(label, value);
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'email' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            style: labelStyle,
                                            controller: _controllers[label],
                                            decoration: InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle: labelStyle,

                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: (value) async {
                                              setState(() {
                                                controller.setFieldValue(label, value);
                                              });
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'url'&& result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            controller: _controllers[label],
                                            style: labelStyle,
                                            decoration: InputDecoration(

                                              labelStyle: labelStyle,
                                              labelText: label,
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.url,
                                            onChanged: (value) {
                                              controller.setFieldValue(label, value);
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'password' && result) {
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(vertical: 8.0),
                                          child: TextFormField(
                                            controller: _controllers[label],
                                            style: labelStyle,
                                            decoration: InputDecoration(
                                              labelStyle: labelStyle,
                                              labelText: label,
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                              // suffixIcon: Icon(Icons.lock), // Password icon
                                            ),
                                            // obscureText: true, //  Hide password text
                                            onChanged: (value) {
                                              controller.setFieldValue(label, value);
                                            },
                                            validator: (value) {
                                              if (isRequired &&
                                                  (value == null || value.isEmpty)) {
                                                return 'Please enter $label';
                                              }

                                              final regexPattern =
                                              field['regex']; // e.g., "^[1-5]$"
                                              if (regexPattern != null &&
                                                  value != null &&
                                                  value.isNotEmpty) {
                                                final regex = RegExp(regexPattern);
                                                if (!regex.hasMatch(value)) {
                                                  return 'Invalid input for $label';
                                                }
                                              }

                                              return null;
                                            },
                                          ),
                                        );
                                      }
                                      return const SizedBox
                                          .shrink();
                                    }).toList(),


                                  ],
                                ),
                              ),
                            ),
                          )
                              : SizedBox.shrink();
                        }),

                      ...itemsWithoutGroup.map((field) {
                        String label = field['label'];
                        String code = field['code'];
                        String fieldType = field['type'];

                        bool isRequired = field['required'] == 1;

                        bool isRefKey = field['refKey'] == 1;
                        bool primaryUsecase =
                            field['primaryUsecase'] != "";

                        bool showDropdown = primaryUsecase && isRefKey;
                        String yUsecase = field['primaryUsecase'] ?? "";

                        String showvalue = field['show'] ?? "";
                        String event = field['event'] ?? "";
                        String rule = field['rule'] ?? "";

                        String parentfilter =
                            field['parentFilter'] ?? "";
                        int captureImage = field['captureImage'] ?? 0;
                        if (parentfilter != "" &&
                            parentfilter.isNotEmpty) {
                          controller.addParentFilter();
                        }

                        // Request body for dynamic field value
                        Map<String, String> reqBody = {};
                        for (var field in itemsWithoutGroup) {
                          String fieldValue = controller
                              .getFieldValue(field['label'])
                              ?.toString() ??
                              '';
                          reqBody[field['code'].toString()] =
                              fieldValue;
                        }

                        final result = controller.evaluateCondition(
                            reqBody, showvalue);

                        if (field['system'] == 1) {
                          return const SizedBox.shrink();
                        }

                        _controllers.putIfAbsent(
                            label, () => TextEditingController());

                        _controllers[label]!.text =
                            (controller.getInitialValues(
                                field['code'], label) ??
                                "")
                                .toString();

                        if (fieldType == 'text' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              enabled: field['code'] != controller.parentKey,
                              keyboardType: TextInputType.text,
                              onChanged: (value) async {
                                if (event != "") {
                                  await controller.GetUserData(
                                      code, rule, value!);
                                  setState(() {
                                    //controller.dataMap[field['code']] = value;
                                    controller.setFieldValue(
                                        label, value);
                                  });
                                } else {
                                  setState(() {
                                    controller.dataMap[field['code']] =
                                    value!;
                                    controller.setFieldValue(
                                        label, value!);
                                  });
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'email' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) async {
                                setState(() {
                                  controller.dataMap[field['code']] =
                                  value!;
                                  controller.setFieldValue(
                                      label, value!);
                                });
                              },
                              enabled: field['code'] != controller.parentKey,
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (showDropdown && result) {
                          final dropdownItems =
                              controller.prelaodlist[yUsecase] ?? [];
                          bool isDisabled = field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0,horizontal: 8.0),
                            child: DropdownButtonFormField<String>(
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                                hintText:
                                'Select $label', // Placeholder hint text
                              ),
                              value: controller
                                  .getFieldValue(label)
                                  ?.isEmpty ??
                                  true
                                  ? null // Ensures value is null if empty or not set
                                  : controller.getFieldValue(label),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null, // Placeholder value
                                  child: Text(
                                      'Select an $label',
                                      style:labelStyle
                                    //     TextStyle(color: Colors.black),
                                  ),
                                ),
                                ...dropdownItems
                                    .map<DropdownMenuItem<String>>(
                                        (item) {
                                      return DropdownMenuItem<String>(
                                        value: item['id'].toString(),
                                        child: Text(item['_val']),
                                      );
                                    }).toList(),
                              ],
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller
                                      .GetUserData(
                                      code,
                                      rule,
                                      value!);
                                  controller
                                      .admissionId =
                                      value;
                                  controller.dataMap[
                                  field[
                                  'code']] =
                                  value!;
                                  setState(() {
                                    controller
                                        .setFieldValue(
                                        label,
                                        value);
                                    updateResult(reqBody, showvalue);
                                  });
                                }
                                else {
                                  controller.dataMap[
                                  field[
                                  'code']] =
                                  value!;
                                  controller
                                      .setFieldValue(
                                      label,
                                      value!);
                                  updateResult(reqBody, showvalue);
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if ((fieldType == 'number' || fieldType == 'phone' || fieldType == 'long' ||fieldType == 'expression' || fieldType == 'decimal') && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              enabled: field['code'] != controller.parentKey,
                              keyboardType: TextInputType.number,
                              onChanged: (value) async {
                                controller.dataMap[field['code']] =
                                    value; // Directly updating dataMap
                                controller.setInitialValue(
                                    field['code'], value);
                                controller.setFieldValue(label, value);
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'date' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: TextFormField(
                              readOnly: true,
                              style: labelStyle,
                              enabled: field['code'] != controller.parentKey,
                              controller: TextEditingController(
                                  text:
                                  controller.getFieldValue(label)),
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                suffixIcon: Icon(
                                  Icons.calendar_today,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              onTap: () async {
                                DateTime? selectedDate =
                                await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime(2100),
                                );

                                if (selectedDate != null) {
                                  String formattedDate =
                                  "${selectedDate.toLocal()}"
                                      .split(' ')[0];

                                  if (event != "") {
                                    // Call API to validate the selected date
                                    var response = await controller
                                        .validateAndSubmitDate(
                                        rule, formattedDate);
                                    // Handle response
                                    if (response != null &&
                                        response['success'] == false) {
                                      String errorMessage = response[
                                      'result']?['message'] ??
                                          'An error occurred while validating the date.';
                                      print(
                                          'errorMessage==========>>>>>${errorMessage}');
                                      showPopup(context, 'Error',
                                          errorMessage);
                                    } else if (response != null &&
                                        response['success'] == true) {
                                      // showPopup(context, 'Success', 'Date updated successfully!');
                                      setState(() {
                                        controller.setFieldValue(
                                            label, formattedDate);
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      controller.setFieldValue(
                                          label, formattedDate);
                                    });
                                  }
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'time' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: TextFormField(
                              readOnly: true,
                              style: labelStyle,
                              enabled: field['code'] != controller.parentKey,
                              controller: TextEditingController(
                                  text:
                                  controller.getFieldValue(label)),
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelStyle: labelStyle,
                                labelText: label,
                                errorText: resulterror[code],
                                suffixIcon: Icon(
                                  Icons.access_time,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                // Time icon
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              onTap: () async {
                                TimeOfDay? selectedTime =
                                await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (selectedTime != null) {
                                  // Convert TimeOfDay to DateTime
                                  final now = DateTime.now();
                                  final dateTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      selectedTime.hour,
                                      selectedTime.minute);

                                  // Format the time to 24-hour format (HH:mm) without AM/PM
                                  String formattedTime =
                                  DateFormat('HH:mm').format(
                                      dateTime); // 24-hour format

                                  setState(() {
                                    controller.setFieldValue(
                                        label, formattedTime);
                                  });
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'map' && result) {
                          // Ensure the 'values' field contains data before displaying the dropdown
                          List<dynamic> mapValues =
                              field['values'] ?? [];
                          bool isDisabled = field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: DropdownButtonFormField<String>(
                              style: labelStyle,
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Appcolorblue)),
                              ),
                              //  value: controller.getFieldValue(label), // Set the initial value
                              value: controller
                                  .getFieldValue(label)
                                  ?.isEmpty ??
                                  true
                                  ? null // Set value to null if it's empty or null
                                  : controller.getFieldValue(label),
                              items: mapValues
                                  .map<DropdownMenuItem<String>>(
                                      (item) {
                                    // Map each entry to a dropdown item, using the 'value' field for display
                                    return DropdownMenuItem<String>(
                                      value: item['key'].toString(),
                                      // The key will be sent as the value
                                      child: Text(
                                        item['value'],
                                        // Display the 'value' field
                                        style: labelStyle,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller
                                      .GetUserData(
                                      code,
                                      rule,
                                      value!);
                                  controller
                                      .admissionId =
                                      value;
                                  controller.dataMap[
                                  field[
                                  'code']] =
                                  value!;
                                  setState(() {
                                    controller
                                        .setFieldValue(
                                        label,
                                        value);
                                    updateResult(reqBody, showvalue);
                                  });
                                }
                                else {
                                  controller.dataMap[
                                  field[
                                  'code']] =
                                  value!;
                                  controller
                                      .setFieldValue(
                                      label,
                                      value!);
                                  updateResult(reqBody, showvalue);
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'list' && result) {
                          List<dynamic> uniqueValues =
                          field['values'].toSet().toList();
                          String? selectedValue =
                          controller.getFieldValue(label);
                          bool isDisabled = field['code'] == controller.parentKey;
                          if (!uniqueValues.contains(selectedValue)) {
                            selectedValue = null;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0,horizontal: 8.0),
                            child: DropdownButtonFormField<String>(
                              style: labelStyle,
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              decoration: InputDecoration(
                                labelText: label,
                                labelStyle: labelStyle,
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                                hintText:
                                'Select $label', // Placeholder text
                              ),
                              value: selectedValue,
                              items: [
                                DropdownMenuItem<String>(
                                  value: null, // Placeholder value
                                  child: Text('Select an $label',
                                      style: TextStyle(
                                          color: Colors.black)),
                                ),
                                ...uniqueValues
                                    .map<DropdownMenuItem<String>>(
                                        (value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                              ],
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller
                                      .GetUserData(
                                      code,
                                      rule,
                                      value!);
                                  controller
                                      .admissionId =
                                      value;
                                  controller.dataMap[
                                  field[
                                  'code']] =
                                  value!;
                                  setState(() {
                                    controller
                                        .setFieldValue(
                                        label,
                                        value);
                                    updateResult(reqBody, showvalue);
                                  });
                                }
                                else {
                                  controller.dataMap[
                                  field[
                                  'code']] =
                                  value!;
                                  controller
                                      .setFieldValue(
                                      label,
                                      value!);
                                  updateResult(reqBody, showvalue);
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'time' && result) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              readOnly: true,
                              style: labelStyle,
                              controller: TextEditingController(
                                  text: controller.getFieldValue(label)),
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelStyle: labelStyle,

                                labelText: label,

                                suffixIcon: Icon(
                                  Icons.access_time,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                // Time icon
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              onTap: () async {
                                TimeOfDay? selectedTime =
                                await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (selectedTime != null) {
                                  // Convert TimeOfDay to DateTime
                                  final now = DateTime.now();
                                  final dateTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      selectedTime.hour,
                                      selectedTime.minute);

                                  // Format the time to 24-hour format (HH:mm) without AM/PM
                                  String formattedTime =
                                  DateFormat('HH:mm').format(
                                      dateTime); // 24-hour format

                                  setState(() {
                                    controller.setFieldValue(
                                        label, formattedTime);
                                  });
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'file' && result) {
                          return   controller.saveform_id.value != 0
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: TextFormField(
                                    onTap: () {
                                      if (captureImage == 1) {
                                        getImage1(code,
                                            ImageSource.camera);
                                      } else {
                                        _pickAndUploadImage(code);
                                      }
                                      // getImage1(code,ImageSource.camera);
                                    },
                                    style: labelStyle,
                                    readOnly: true,
                                    enabled: field['code'] != controller.parentKey,
                                    controller:
                                    TextEditingController(
                                        text: controller.imagePaths[
                                        code] !=
                                            null
                                            ? controller.imagePaths[
                                        code]!
                                            .split('/')
                                            .last
                                            : ''),
                                    decoration: InputDecoration(
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      errorText:
                                      resulterror[code],
                                      labelText: label,
                                      labelStyle: labelStyle,
                                      border:
                                      const OutlineInputBorder(
                                        borderSide:
                                        const BorderSide(
                                            color:
                                            Colors.green),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.attachment,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        onPressed: () {
                                          if (captureImage == 1) {
                                            getImage1(code,
                                                ImageSource.camera);
                                          } else {
                                            _pickAndUploadImage(code);
                                          }
                                        },
                                      ),
                                    ),
                                    onChanged: (value) async {
                                      setState(() {

                                        controller.setFieldValue(
                                            label, value!);
                                      });
                                    },
                                  ),
                                ),
                                controller.imagePaths[code] != null
                                    ? Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 16.0),
                                  child: Image.file(File(
                                      controller.imagePaths[
                                      code]!)), // Display the selected image (optional)
                                )
                                    :
                                Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 16.0),
                                  child:Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Image.network(
                                      controller.uploadimage[code] != null && controller.uploadimage[code]!.isNotEmpty
                                          ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadimage[code]}?t=${DateTime.now().millisecondsSinceEpoch}"
                                          : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
                                    ),
                                  ),


                                ),

                              ],
                            ),
                          )
                              : const SizedBox.shrink();
                        }
                        if (fieldType == 'doc' && result) {
                          return controller.saveform_id.value != 0
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: TextFormField(
                                    style: labelStyle,
                                    onTap: () {
                                      _pickAndUploadFile(code);
                                    },
                                    readOnly: true,
                                    enabled: field['code'] != controller.parentKey,
                                    controller:
                                    TextEditingController(
                                        text: controller.imagePaths[
                                        code] !=
                                            null
                                            ? controller.imagePaths[
                                        code]!
                                            .split('/')
                                            .last
                                            : ''

                                    ),
                                    decoration: InputDecoration(
                                      labelText: label,
                                      labelStyle: labelStyle,
                                      errorText:
                                      resulterror[code],
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      border:
                                      const OutlineInputBorder(
                                        borderSide:
                                        const BorderSide(
                                            color:
                                            Colors.green),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.attachment,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        onPressed: () {
                                          _pickAndUploadFile(
                                              code);
                                        },
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        // filePath = value;
                                        controller.imagePaths[code] = value;
                                      });

                                      controller.setFieldValue(
                                          label, '0');
                                      controller.setInitialValue(
                                          label, '0');
                                      setState(() {

                                      });
                                    },
                                  ),
                                ),
                            
                                Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 16.0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Image.network(
                                      controller.uploadDocument[code] != null && controller.uploadDocument[code]!.isNotEmpty
                                          ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadDocument[code]}?t=${DateTime.now().millisecondsSinceEpoch}"
                                          : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
                                    ),
                                  ),

                                ),
                              ],
                            ),
                          )
                              : const SizedBox.shrink();
                        }
                        if (fieldType == 'textarea' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 8.0),
                            child: TextFormField(
                              style: labelStyle,
                              controller: _controllers[label],
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                              ),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              // Allows the textarea to expand based on input
                              onChanged: (value) async {
                                setState(() {
                                  controller.dataMap[field['code']] =
                                  value!;
                                  controller.setFieldValue(
                                      label, value);
                                });
                              },
                              enabled: field['code'] != controller.parentKey,
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      }).toList(),
                      const SizedBox(height: 23),
                      Center(
                        child: Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          alignment: WrapAlignment.center,
                          children: controller.childbuttons.where((button) {
                            switch (button.name.toLowerCase()) {
                              case 'list':
                                return controller.isread == 1;
                              case 'delete':
                                return controller.isdelete == 1;
                              case 'update':
                                return controller.isupdate == 1;
                              case 'save':
                                return controller.iscreate == 1;
                              case 'new':
                                return controller.iscreate == 1;
                              case 'cancel':
                                return controller.iscreate == 1;
                              default:
                                return true;
                            }
                          }).map((button) {
                            return GestureDetector(
                              onTap: () {
                                handleButtonClick(
                                    button.name.toLowerCase());
                              },
                              child: Container(
                                height: 45,
                                width: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Color(0xFF4F76E2)
                                        : Color(0xFF1A237E),
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    button.name.toUpperCase(),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Color(0xFF4F76E2)
                                          : Color(0xFF1A237E),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Lato',
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                )),

          );
        },
      )),
    );
  }


}
