import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/Appcolor.dart';
import '../controller/Childcontroller.dart';
import '../controller/Editchildformcontroller.dart';
import '../controller/tableview_controller.dart';
import '../service/apihelper.dart';
import 'Menucontroller.dart';
import 'package:provider/provider.dart';

class Editchildform extends StatefulWidget {
  final String title;

  final int editid;

  final int formusecaseid;

  const Editchildform(
      {super.key,
        required this.title,
        required this.editid,
        required this.formusecaseid});

  @override
  State<Editchildform> createState() => _EditchildformState();
}

class _EditchildformState extends State<Editchildform> {
  final Editchildformcontroller controller = Get.put(Editchildformcontroller());
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
    Map<String, dynamic> reqBody = {};
    // Initialize reqBody with 'id' first
    if (widget.editid != 0) {
      controller.saveform_id.value = widget.editid;
    }
    if (controller.saveform_id.value != 0) {
      reqBody = {
        'id': controller.saveform_id.value
      }; // Add the 'id' field first
    }
    for (var field in controller.childlabellist) {
      dynamic fieldValue = controller.getFieldValue(field['label']) ?? '';

      if (fieldValue.isNotEmpty && fieldValue != "") {
        reqBody[field['code'].toString()] = fieldValue;
      }
    }


    try {
      final response = await helper.postApi(
        "api/v1/${controller.childappCode.value}/${controller.childcode.value}/${controller.saveformcode.value}/saveForm;jsessionid=$sessionId",
        reqBody,
      );

      if (response['success'] == true) {
        setState(() {
          controller.saveform_id.value = response['result']['data']['id'];
        });
        Get.back();

        showToast();
      } else {


        var inputError = response!['result']['inputerror'];

        setState(() {
          resulterror.clear(); // Clear previous errors
          inputError.forEach((key, value) {
            resulterror[key] = value;
            CherryToast.error(
              backgroundColor: const Color(0xFFF8D0D9),
              animationDuration: Durations.short1,
              title: const Text("Error Saving Form",
                  style: const TextStyle(color: Colors.black)),
              // description: Text(value,
              //     style: const TextStyle(color: Colors.black)),
            ).show(Get.overlayContext!); // Store each error dynamically
          });
        });

        return response; // Return the error response directly
      }
    } catch (e) {
      debugPrint("Error in SaveForm: $e");
      return null;
    }

    return null; // Return null when the save is successful
  }


  /*Future<Map<String, dynamic>?> SaveForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
    }
    Map<String, dynamic> reqBody = {};
    if (widget.editid != 0) {
      controller.saveform_id.value = widget.editid;
    }
    if (controller.saveform_id.value != 0) {
      reqBody = {
        'id': controller.saveform_id.value
      }; // Add the 'id' field first
    }

    for (var field in controller.childlabellist) {
      dynamic fieldValue = controller.getFieldValue(field['label']) ?? '';

      if (fieldValue.isNotEmpty && fieldValue != "") {
        reqBody[field['code'].toString()] = fieldValue;
      }
    }
    try {
      final response = await helper.postApi(
        "api/v1/${controller.childappCode.value}/${controller.childcode.value}/${controller.saveformcode.value}/saveForm;jsessionid=$sessionId",
        reqBody,
      );

      if (response == null) {
      } else {
        if (response != null && response['success'] == true) {
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
    } catch (e) {}
    return null;
  }*/

  void handleButtonClick(String buttonType) async {
    if (buttonType == "save") {
      if (_formKey.currentState?.validate() ?? false) {
        Map<String, dynamic>? response = await SaveForm();

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
    } else if (buttonType == "cancel") {
      controller.saveform_id.value = 0;
      Get.back();
    } else if (buttonType == "delete") {
      if (controller.saveform_id.value != 0) {
        showDeleteConfirmationedit();
      }
    } else if (buttonType == "list") {
      Get.back();
    } else if (buttonType == "new") {
      controller.imagePaths.clear();
      _controllers.clear();
      controller.saveform_id.value = 0;
      setState(() {});
    }
  }

  Future<void> _uploadImage(XFile pickedFile, int imageid, String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.childappCode.value}/${controller.childcode.value}/doc/${widget.editid}/$imageid/$code;jsessionid=$sessionId');

    File imageFile = File(pickedFile.path);
    List<int> imageBytes = await imageFile.readAsBytes();

    var request = http.MultipartRequest('POST', uri)
      ..fields['id'] =
      controller.dataMap['id'].toString() // Add the ID field here
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: pickedFile.name,
        ),
      );

    try {
      final response = await request.send();
      String responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(responseBody);

          var dataValue = jsonResponse['result']['data'][code];
          if (dataValue is int) {
            dataValue = dataValue.toString();
          }
          setState(() {
            controller.uploadimage[code] = dataValue;
          });

          Get.snackbar(
            'Success',
            'Image uploaded successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {}
      } else {
        Get.snackbar(
          'Error',
          'Failed to upload the image!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      // Handle error
    }
  }

  final Childcontroller childcontroller = Get.put(Childcontroller());

  void showToast() {
    CherryToast.success(
      backgroundColor: const Color(0xFFDDF4DE),
      animationDuration: Durations.short1,
      title: const Text("Form saved successfully!",
          style: TextStyle(color: Colors.black)),
    ).show(context);
    childcontroller.filteredData.refresh(); // Refresh UI using GetX
    childcontroller.Getlistdata();
  }

  _pickAndUploadFile(int imageid, String code) async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType
          .any, // Change this to `FileType.custom` for specific file types
    );

    if (pickedFile != null && pickedFile.files.single.path != null) {
      filePath = pickedFile.files.single.path!; // Update observable
      setState(() {
        controller.imagePaths[code] = filePath!;
      });
      File file = File(filePath!);
      await _uploadFile(file, code, imageid);
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

  Future<void> _pickAndUploadImage(int imageid, String code) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // Handle case where no image was picked

    File imageFile = File(pickedFile.path);
    int imageSizeInBytes = await imageFile.length();

    // Keep compressing the image until it's <= 512 KB
    while (imageSizeInBytes > 512000) {
      imageFile = await compressImage(imageFile);
      imageSizeInBytes = await imageFile.length();
      setState(() {
        controller.imagePaths[code] = imageFile.path;
      });
    }

    setState(() {
      controller.imagePaths[code] = imageFile.path;
    });
    // Convert to XFile before uploading
    final XFile compressedXFile = XFile(imageFile.path);
    await _uploadImage(compressedXFile, imageid, code);
  }

  Future<void> getImage1(
      int imageid, String fieldCode, ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return; // Handle case where no image was picked
    File imageFile = File(pickedFile.path);
    int imageSizeInBytes = await imageFile.length();
    while (imageSizeInBytes > 512000) {
      imageFile = await compressImage(imageFile);
      imageSizeInBytes = await imageFile.length();
      setState(() {
        controller.imagePaths[fieldCode] = imageFile.path;
      });
    }
    setState(() {
      controller.imagePaths[fieldCode] = imageFile.path;
    });

    final XFile compressedXFile = XFile(imageFile.path);
    await _uploadImage(compressedXFile, imageid, fieldCode);
  }

  Future<File> compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: 50,
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }

    final compressedFile = File(imageFile.path)..writeAsBytesSync(result);
    return compressedFile;
  }

  Future<void> _uploadFile(File pickedFile, String code, int imageid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      print('Session ID is empty. Please log in again.');

      return;
    }

    // Replace `id` with the actual document ID you need to send
    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.childappCode.value}/${controller.childcode.value}/doc/${widget.editid}/$imageid/$code;jsessionid=$sessionId');

    var request = http.MultipartRequest('POST', uri);

    var file = await http.MultipartFile.fromPath('file', pickedFile.path);
    request.files.add(file);

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'File uploaded successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        try {
          var jsonResponse = jsonDecode(responseBody);

          var dataValue = jsonResponse['result']['data'][code];
          if (dataValue is int) {
            dataValue = dataValue.toString();
          }
          setState(() {
            controller.uploadDocument[code] = dataValue;
          });
        } catch (e) {}
      } else {
        Get.snackbar(
          'Error',
          'Failed to upload the file!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while uploading the file.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showDeleteConfirmationedit() {
    Get.dialog(
      AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () {
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              for (var field in controller.childlabellist) {
                controller.setFieldValue(
                    field['label'], ""); // Reset field value
                controller.setInitialValue(field['code'], "");
              }
              controller.dataMap.clear();
              setState(() {
                controller.saveform_id.value = 0;
                controller.uploadDocument.clear();
                controller.uploadimage.clear();
              });
              Get.back();
              controller.imagePaths.clear();
              // controller.clearForm();
              for (var field in controller.childlabellist) {
                var fieldValue = controller.getFieldValue(field['label']) ?? '';

                if (fieldValue.isNotEmpty && fieldValue != "") {
                  controller.imagePaths[field['code']] = null;
                  controller.setFieldValue(field['label'], "");
                  controller.setInitialValue(field['code'], "");
                }
              }
              setState(() {});
              menucontroller.changeTab(0);
              Get.find<TableviewController>().update();
              viewcontroller.GetForm_API(viewcontroller.appurl.value);
              viewcontroller.CurrentPage.value = 0;
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false, // Prevents accidental dismiss
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
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
  void setCurrentLocation(String label,String code) async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print('❌ Location service not enabled.');
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print('❌ Location permission not granted.');
        return;
      }
    }

    LocationData position = await location.getLocation();
    double? lat = position.latitude;
    double? lng = position.longitude;

    if (lat != null && lng != null) {
      var locationMap = {'lat': lat, 'lng': lng};
      controller.setFieldValue(label, locationMap.toString());
      controller.setInitialValue(code, locationMap.toString());
      setState(() {
        _controllers[label]!.text = lat.toString() ?? '';
        _controllers[label]!.text = lng.toString() ?? '';
        controller.latController.text = lat.toString() ?? '';
        controller.longController.text = lng.toString() ?? '';
        controller.showTextField.value= true;
      });
      print('📍 Location set: Lat = $lat, Lng = $lng');
    } else {
      print('❌ Failed to get location coordinates.');
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.getchildlist(widget.formusecaseid, widget.editid);
  }

  void updateResult(Map<String, String> reqBody, String showvalue) {
    setState(() {
      result = controller.evaluateCondition(reqBody, showvalue);
    });
  }
  void _clearText(String label,String code) {
    setState(() {
      controller.latController.clear();
      controller.longController.clear();
      controller.showTextField.value  = false;
      controller.setFieldValue(label, ""); // clear stored map
      controller.setInitialValue(code, "");
    });
  }
  List<bool> isSelected = [false, false];

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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Appcolorblue,
        title: Text('${widget.title}',
            style:const TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: SingleChildScrollView(child: Obx(
            () {
          var itemsWithoutGroup = controller.getItemsWithoutGroup();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Form(
                key: _formKey,
                child: controller.groupchildlabellist.isEmpty
                    ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Obx(
                          () {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...controller.childlabellist.map((field) {
                              String label = field['label'];
                              String code = field['code'];
                              String fieldType = field['type'];
                              String show = field['show'] ?? "";
                              bool isRequired = field['required'] == 1;
                              bool systemValueIsOne = field['system'] ==
                                  1; // Check if systemValue is 1
                              String event = field['event'] ?? "";
                              String rule = field['rule'] ?? "";
                              bool isRefKey = field['refKey'] == 1;
                              bool primaryUsecase =
                                  field['primaryUsecase'] != "";
                              String yUsecase =
                                  field['primaryUsecase'] ?? "";
                              bool showDropdown = primaryUsecase == true &&
                                  isRefKey == true;

                              int captureImage = field['captureImage'] ?? 0;
                              if (systemValueIsOne) {
                                return const SizedBox.shrink();
                              }

                              // Request body for dynamic field value
                              Map<String, String> reqBody = {};
                              for (var field in controller.childlabellist) {
                                String fieldValue = controller
                                    .getInitialValue(field['label'])
                                    ?.toString() ??
                                    '';
                                reqBody[field['code'].toString()] =
                                    fieldValue;
                              }

                              bool result = controller.evaluateCondition(
                                  reqBody, show);
                              final initialValue =
                              controller.getInitialValue(field['code']);

                              if (initialValue != null &&
                                  initialValue.toString().isNotEmpty) {
                                result =
                                true; // Ensure the field is visible if it has data
                              }

                              _controllers.putIfAbsent(
                                  label, () => TextEditingController());
                              _controllers[label]!.text =
                                  (initialValue ?? "").toString();
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
                                      labelStyle: labelStyle,
                                      errorText: resulterror[code],
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(5),
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      controller.setInitialValue(
                                          code, value);
                                      controller.setFieldValue(
                                          label, value);
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
                                    enabled: field['code'] !=
                                        controller
                                            .parentKey, // Disable if code matches parentKey
                                  ),
                                );
                              }
                              if (fieldType == 'textarea' && result) {
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
                                      labelStyle: labelStyle,
                                      errorText: resulterror[code],
                                      border: OutlineInputBorder(
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 3,
                                    // You can set this to null for unlimited lines
                                    onChanged: (value) => controller
                                        .setInitialValue(code, value),
                                    validator: isRequired
                                        ? (value) {
                                      if (value == null ||
                                          value.isEmpty) {
                                        return 'Please enter $label';
                                      }
                                      return null;
                                    }
                                        : null,
                                    enabled: field['code'] !=
                                        controller
                                            .parentKey, // Disable if code matches parentKey
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
                                      errorText: resulterror[
                                      code],
                                      border: OutlineInputBorder(
                                          borderSide:
                                          BorderSide(color: Appcolorblue)),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) async {
                                      setState(() {
                                        controller.dataMap[
                                        code] =
                                            value; // Directly updating dataMap
                                        controller
                                            .setInitialValue(
                                            code,
                                            value);
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
                                  ),
                                );
                              }
                              if (fieldType == 'url' && result ) {
                                return TextFormField(
                                  controller: _controllers[label],

                                  style: labelStyle,
                                  decoration: InputDecoration(
                                    errorText: resulterror[code],
                                    labelStyle: labelStyle,
                                    labelText: label,
                                    fillColor: isDarkMode ? Colors.black : Colors.white,
                                    border: OutlineInputBorder(borderSide: BorderSide(color: Appcolorblue)),
                                  ),
                                  keyboardType: TextInputType.url,
                                  onChanged: (value) {
                                    controller.setInitialValue(
                                        code, value);
                                    controller.setFieldValue(
                                        label, value);
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

                                );
                              }
                              if (fieldType == 'password' && result ) {
                                return TextFormField(
                                  controller: _controllers[label],
                                  style: labelStyle,
                                  decoration: InputDecoration(
                                    errorText: resulterror[code],
                                    labelStyle: labelStyle,
                                    labelText: label,
                                    fillColor: isDarkMode ? Colors.black : Colors.white,
                                    border: OutlineInputBorder(borderSide: BorderSide(color: Appcolorblue)),
                                    // suffixIcon: Icon(Icons.lock), // Password icon
                                  ),

                                  onChanged: (value) {
                                    controller.setInitialValue(
                                        code, value);
                                    controller.setFieldValue(
                                        label, value);
                                  },
                                  validator: (value) {
                                    if (isRequired && (value == null || value.isEmpty)) {
                                      return 'Please enter $label';
                                    }

                                    final regexPattern = field['regex']; // e.g., "^[1-5]$"
                                    if (regexPattern != null && value != null && value.isNotEmpty) {
                                      final regex = RegExp(regexPattern);
                                      if (!regex.hasMatch(value)) {
                                        return 'Invalid input for $label';
                                      }
                                    }

                                    return null;
                                  },


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
                                      errorText: resulterror[code],
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
                              if (showDropdown && result) {
                                final dropdownItems =
                                    controller.prelaodlist[yUsecase] ?? [];

                                // Ensure unique IDs in the dropdown items
                                final uniqueDropdownItems = dropdownItems
                                    .toSet()
                                    .toList(); // Remove duplicates based on 'id'
                                bool isDisabled =
                                    field['code'] == controller.parentKey;
                                final currentValue = controller
                                    .getInitialValue(field['code']);

                                final validValue = uniqueDropdownItems.any(
                                        (item) =>
                                    item['id'].toString() ==
                                        currentValue)
                                    ? currentValue
                                    : null;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.white,
                                    style: labelStyle,
                                    decoration: InputDecoration(
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      labelText: label,
                                      errorText: resulterror[code],
                                      labelStyle: labelStyle,
                                      border: OutlineInputBorder(
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    // Ensure dropdown can handle null or empty selection
                                    value: validValue?.isEmpty ?? true
                                        ? null // Set value to null if it's empty or null
                                        : validValue,
                                    // Use null if no valid value is found
                                    items: [
                                      if (!isRequired)
                                        DropdownMenuItem<String>(
                                          value: null,
                                          child: Text(
                                            'Select $label',
                                            style: labelStyle,
                                          ),
                                        ),
                                      ...uniqueDropdownItems
                                          .map<DropdownMenuItem<String>>(
                                              (item) {
                                            return DropdownMenuItem<String>(
                                              value: item['id'].toString(),
                                              child: Text(
                                                item['_val'],
                                                style: labelStyle,
                                              ),
                                            );
                                          }).toList(),
                                    ],
                                    onChanged: isDisabled
                                        ? null // Disables dropdown if isDisabled is true
                                        : (value) async {
                                      if (event != "") {
                                        await controller.GetUserData(
                                            code, rule, value!);
                                        controller.admissionId =
                                            value;
                                        setState(() {
                                          controller.setFieldValue(
                                              label,
                                              value ??
                                                  ""); // Update the field value
                                          controller.setInitialValue(
                                              code, value ?? "");
                                        });
                                      } else {
                                        controller.setFieldValue(
                                            label,
                                            value ??
                                                ""); // Update the field value
                                        controller.setInitialValue(
                                            code, value ?? "");
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
                              if (fieldType == 'number' && result) {
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
                                      labelStyle: labelStyle,
                                      errorText: resulterror[code],
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(5),
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (value != null &&
                                          value.isNotEmpty) {
                                        // Parse as a number (integer or float)
                                        double? numericValue =
                                        double.tryParse(value);
                                        if (numericValue != null) {
                                          // If numeric value is an integer, store it as an integer (without decimals)
                                          controller
                                              .dataMap[field['code']] =
                                          numericValue ==
                                              numericValue.toInt()
                                              ? numericValue
                                              .toInt()
                                              .toString()
                                              : numericValue.toString();
                                        } else {

                                        }
                                      } else {
                                        controller.dataMap[field['code']] =
                                            value; // Handle empty or null
                                      }
                                      controller.setInitialValue(
                                          code, value ?? "");
                                      controller.setFieldValue(
                                          label,
                                          value ??
                                              ""); // Update the field value
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
                                    enabled: field['code'] !=
                                        controller
                                            .parentKey, // Disable if code matches parentKey
                                  ),
                                );
                              }
                              if (fieldType == 'long' && result) {
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
                                        borderRadius:
                                        BorderRadius.circular(5),
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (value != null &&
                                          value.isNotEmpty) {
                                        // Parse as a long integer
                                        int? numericValue =
                                        int.tryParse(value);
                                        if (numericValue != null) {
                                          controller.dataMap[
                                          field[
                                          'code']] = numericValue
                                              .toString(); // Store as integer
                                        } else {

                                        }
                                      } else {
                                        controller.dataMap[field['code']] =
                                            value; // Handle empty or null
                                      }
                                      controller.setInitialValue(
                                          code, value ?? "");

                                      controller.setFieldValue(
                                          label, value ?? ""); // U
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
                                    enabled: field['code'] !=
                                        controller
                                            .parentKey, // Disable if code matches parentKey
                                  ),
                                );
                              }
                              if ((fieldType == 'decimal' || fieldType == 'expression') && result) {
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
                                        borderRadius:
                                        BorderRadius.circular(5),
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    keyboardType:
                                    const  TextInputType.numberWithOptions(
                                        decimal: true),
                                    onChanged: (value) {
                                      if (value != null &&
                                          value.isNotEmpty) {
                                        // Allow decimal input and ensure it's a valid number
                                        double? numericValue = double
                                            .tryParse(value.replaceAll(',',
                                            '.')); // Handle locale issues
                                        if (numericValue != null) {
                                          // Format to two decimal places and store
                                          controller
                                              .dataMap[field['code']] =
                                              numericValue
                                                  .toStringAsFixed(2);
                                        } else {

                                        }
                                      } else {
                                        controller.dataMap[field['code']] =
                                            value; // Handle empty or null
                                      }
                                      controller.setInitialValue(
                                          code, value ?? "");

                                      controller.setFieldValue(
                                          label, value ?? ""); // U
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
                                    enabled: field['code'] !=
                                        controller
                                            .parentKey, // Disable if code matches parentKey
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
                                    controller: TextEditingController(
                                        text: controller
                                            .getInitialValue(code)),
                                    decoration: InputDecoration(
                                      labelText: label,
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      labelStyle: labelStyle,
                                      errorText: resulterror[code],
                                      suffixIcon: Icon(Icons.calendar_today,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(5),
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
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
                                              response['success'] ==
                                                  false) {
                                            String errorMessage = response[
                                            'result']?['message'] ??
                                                'An error occurred while validating the date.';

                                            showPopup(context, 'Error',
                                                errorMessage);
                                          } else if (response != null &&
                                              response['success'] == true) {
                                            // showPopup(context, 'Success', 'Date updated successfully!');

                                            controller.setFieldValue(
                                                label, formattedDate);
                                            controller.setInitialValue(
                                                code, formattedDate);
                                          }
                                        } else {
                                          setState(() {
                                            controller.setInitialValue(
                                                code, formattedDate);
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
                                    enabled: field['code'] !=
                                        controller
                                            .parentKey, // Disable if code matches parentKey
                                  ),
                                );}
                              if (fieldType == 'time' && result) {
                                return Padding(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      vertical: 8.0),
                                  child: TextFormField(
                                    readOnly: true,
                                    style: labelStyle,
                                    controller:
                                    TextEditingController(
                                        text: controller
                                            .getFieldValue(
                                            label)),
                                    decoration:
                                    InputDecoration(
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      labelStyle:
                                      labelStyle,
                                      errorText:
                                      resulterror[code],
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
                                          BorderSide(
                                              color:
                                              Appcolorblue)),
                                    ),
                                    onTap: () async {
                                      TimeOfDay?
                                      selectedTime =
                                      await showTimePicker(
                                        context: context,
                                        initialTime:
                                        TimeOfDay.now(),
                                      );
                                      if (selectedTime !=
                                          null) {
                                        // Convert TimeOfDay to DateTime
                                        final now =
                                        DateTime.now();
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

                                          controller.setFieldValue(
                                              label, formattedTime);
                                          controller
                                              .setInitialValue(code,
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
                              if (fieldType == 'list' && result) {
                                final values = field['values'] ?? [];
                                final validInitialValue = values.contains(
                                    controller.getInitialValue(code))
                                    ? controller.getInitialValue(code)
                                    : null;
                                bool isDisabled =
                                    field['code'] == controller.parentKey;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: DropdownButtonFormField<String>(
                                    dropdownColor: isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.white,
                                    style: labelStyle,
                                    decoration: InputDecoration(
                                      fillColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      labelText: label,
                                      labelStyle: labelStyle,
                                      errorText: resulterror[code],
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(5),
                                        borderSide:
                                        BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    value: validInitialValue?.isEmpty ??
                                        true
                                        ? null // Set value to null if it's empty or null
                                        : validInitialValue,
                                    // Ensure valid initial value
                                    items: [
                                      if (!isRequired)
                                        DropdownMenuItem<String>(
                                          value: null,
                                          child: Text(
                                            'Select $label',
                                            style: labelStyle,
                                          ),
                                        ),
                                      ...values
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
                                        await controller.GetUserData(
                                            code, rule, value!);
                                        controller.admissionId =
                                            value;
                                        setState(() {
                                          controller.dataMap[code] =
                                              value; // Update dataMap directly
                                          controller.setInitialValue(
                                              code, value ?? "");
                                          controller.setFieldValue(
                                              label, value ?? "");
                                        });
                                      } else {
                                        controller.dataMap[code] =
                                            value; // Update dataMap directly
                                        controller.setInitialValue(
                                            code, value ?? "");
                                        controller.setFieldValue(
                                            label, value ?? "");
                                      }
                                    },

                                    validator: isRequired
                                        ? (value) {
                                      if (value == null ||
                                          value.isEmpty) {
                                        return 'Please select $label'; // Handle empty or null selection
                                      }
                                      return null;
                                    }
                                        : null,
                                  ),
                                );
                              }
                              if (fieldType == 'doc' && result) {
                                return Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    // Custom file input field that looks like a TextField
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: TextFormField(
                                        style: labelStyle,
                                        onTap: () {
                                          _pickAndUploadFile(
                                            int.tryParse(controller
                                                .getInitialValue(
                                                code)
                                                ?.toString() ??
                                                '0') ??
                                                0,
                                            code.toString(),
                                          );
                                        },
                                        readOnly: true,
                                        controller: TextEditingController(
                                            text: controller
                                                .imagePaths[code] !=
                                                null
                                                ? controller
                                                .imagePaths[code]!
                                                .split('/')
                                                .last
                                                : ''),
                                        // Display the file name or path
                                        decoration: InputDecoration(
                                          errorText: resulterror[code],
                                          fillColor: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                          labelText: label,
                                          labelStyle: labelStyle,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(5),
                                            borderSide: const BorderSide(
                                                color: Colors.green),
                                          ),
                                          suffixIcon: IconButton(
                                              icon: Icon(Icons.attachment,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black),
                                              onPressed: () {
                                                _pickAndUploadFile(
                                                  int.tryParse(controller
                                                      .getInitialValue(
                                                      code)
                                                      ?.toString() ??
                                                      '0') ??
                                                      0,
                                                  code.toString(),
                                                );
                                              } // Trigger the file picker on tap

                                          ),
                                        ),
                                        onChanged: (value) {
                                          // Save the file path (or name) to the controller
                                          setState(() {
                                            controller.imagePaths[code] =
                                                value;
                                          });
                                          controller
                                              .dataMap[field['code']] =
                                              value; // Directly updating dataMap
                                          controller.setInitialValue(
                                              code, value);
                                          controller.setFieldValue(
                                              label, value);
                                        },
                                        enabled: field['code'] !=
                                            controller
                                                .parentKey, // Disable if code matches parentKey
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: _buildImageWidget(
                                          controller, field['code']),
                                    ),
                                  ],
                                );
                              }
                              if (fieldType == 'file' && result) {
                                return Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    // Custom file input field that looks like a TextField
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: TextFormField(
                                        style: labelStyle,
                                        onTap: () {
                                          if (captureImage == 1) {
                                            getImage1(
                                                int.tryParse(controller
                                                    .getInitialValue(
                                                    code)
                                                    ?.toString() ??
                                                    '0') ??
                                                    0,
                                                code.toString(),
                                                ImageSource.camera);
                                          } else {
                                            _pickAndUploadImage(
                                              int.tryParse(controller
                                                  .getInitialValue(
                                                  code)
                                                  ?.toString() ??
                                                  '0') ??
                                                  0,
                                              code.toString(),
                                            );
                                            _pickAndUploadImage(
                                              int.tryParse(controller
                                                  .getInitialValue(
                                                  code)
                                                  ?.toString() ??
                                                  '0') ??
                                                  0,
                                              code.toString(),
                                            );
                                          }
                                        },
                                        enabled: field['code'] !=
                                            controller.parentKey,
                                        readOnly: true,
                                        controller: TextEditingController(
                                            text: controller
                                                .imagePaths[code] !=
                                                null
                                                ? controller
                                                .imagePaths[code]!
                                                .split('/')
                                                .last
                                                : ''),
                                        // Display the file name or path
                                        decoration: InputDecoration(
                                          errorText: resulterror[code],
                                          fillColor: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                          labelText: label,
                                          labelStyle: labelStyle,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(5),
                                            borderSide: const BorderSide(
                                                color: Colors.green),
                                          ),
                                          suffixIcon: IconButton(
                                              icon: Icon(Icons.attachment,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black),
                                              onPressed: () {
                                                if (captureImage == 1) {
                                                  getImage1(
                                                      int.tryParse(controller
                                                          .getInitialValue(
                                                          code)
                                                          ?.toString() ??
                                                          '0') ??
                                                          0,
                                                      code.toString(),
                                                      ImageSource.camera);
                                                } else {
                                                  _pickAndUploadImage(
                                                    int.tryParse(controller
                                                        .getInitialValue(
                                                        code)
                                                        ?.toString() ??
                                                        '0') ??
                                                        0,
                                                    code.toString(),
                                                  );
                                                  _pickAndUploadImage(
                                                    int.tryParse(controller
                                                        .getInitialValue(
                                                        code)
                                                        ?.toString() ??
                                                        '0') ??
                                                        0,
                                                    code.toString(),
                                                  );
                                                }
                                              } // Trigger the file picker on tap

                                          ),
                                        ),
                                        onChanged: (value) {
                                          // Save the file path (or name) to the controller
                                          setState(() {
                                            controller.imagePaths[code] =
                                                value; // Optionally save the file path here
                                          });
                                          controller
                                              .dataMap[field['code']] =
                                              value; // Directly updating dataMap
                                          controller.setInitialValue(
                                              code, value);
                                          controller.setFieldValue(
                                              label, value);
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: _buildImageshowWidget(
                                          controller, field['code']),
                                    ),
                                  ],
                                );
                              }
                              if (fieldType == 'combobox' && result) {
                                List<dynamic> mapValues = field['values'] ?? [];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    style: labelStyle,
                                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                    decoration: InputDecoration(
                                      fillColor: isDarkMode ? Colors.black : Colors.white,
                                      labelText: label,
                                      labelStyle: labelStyle,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(color: Appcolorblue),
                                      ),
                                    ),
                                    hint: Text(
                                      "Select $label",
                                      style: labelStyle,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    value: controller.getInitialValue(code)?.isEmpty ?? true
                                        ? null // Set value to null if it's empty or null
                                        : controller.getInitialValue(code),
                                    items: mapValues.map<DropdownMenuItem<String>>((item) {
                                      // Treat item as a string
                                      String displayValue = item.toString();  // Directly use the string value

                                      return DropdownMenuItem<String>(
                                        value: displayValue,  // Use the string as the value
                                        child: Text(
                                          displayValue,
                                          style: labelStyle, overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      if (event != "") {
                                        // If there is an event, update the necessary values
                                        await controller.GetUserData(code, rule, value!);
                                        controller.admissionId = value;

                                        controller.setFieldValue(label, value ?? "");
                                        controller.setInitialValue(code, value ?? "");
                                      } else {
                                        // If no event, directly update the dataMap
                                        controller.dataMap[code] = value;
                                        controller.setFieldValue(label, value ?? "");
                                        controller.setInitialValue(code, value ?? "");
                                      }
                                    },
                                    validator: isRequired
                                        ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select $label';
                                      }
                                      return null;
                                    }
                                        : null,
                                  ),
                                );
                              }
                              if (fieldType == 'boolean' && result) {
                                // Initialize isSelected based on saved value
                                String? savedValue = initialValue.toString();
                                if (savedValue == '1') {
                                  isSelected = [true, false];
                                } else if (savedValue == '0') {
                                  isSelected = [false, true];
                                } else {
                                  isSelected = [false, false];
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 9),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(label, style: labelStyle)),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: ToggleButtons(
                                          borderRadius: BorderRadius.circular(5),
                                          selectedColor: Colors.white,
                                          borderColor: isDarkMode
                                              ? const Color(0xFF4F76E2)
                                              : const Color(0xFF1A237E),
                                          fillColor: isDarkMode
                                              ? const Color(0xFF4F76E2)
                                              : const Color(0xFF1A237E),
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          isSelected: isSelected,
                                          onPressed: (index) {
                                            setState(() {
                                              for (int i = 0; i < isSelected.length; i++) {
                                                isSelected[i] = i == index;
                                              }

                                              var selectedValue = index == 0 ? 1 : 0;
                                              String savedValue = selectedValue.toString();

                                              controller.dataMap[field['code']] = savedValue;
                                              controller.setFieldValue(label, savedValue);
                                              controller.setInitialValue(code, savedValue);
                                            });
                                          },
                                          children:  const [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text("Yes", style:  TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),),
                                            ),
                                            Padding(
                                              padding:const EdgeInsets.symmetric(horizontal: 16),
                                              child: Text("No", style:  TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (fieldType == 'location' && result) {


                                final locationMap = initialValue;

                                if (locationMap != null && locationMap is Map) {

                                  if(locationMap.isNotEmpty){
                                    controller.showTextField.value= true;
                                  }

                                  controller.latController.text = locationMap['lat'].toString() ?? '';
                                  controller.longController.text = locationMap['lng'].toString() ?? '';

                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(label,  style: labelStyle,),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey, width: 1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.location_on, color: Appcolorblue),
                                                onPressed: () {

                                                  setCurrentLocation(label,code);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.remove_red_eye, color: Appcolorblue),
                                                onPressed: () async {
                                                  final lat = controller.latController.text;
                                                  final lng = controller.longController.text;
                                                  if (lat.isEmpty || lng.isEmpty) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text("Missing Location"),
                                                        content: const Text("Location not available. Please set the location first.."),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: Text("OK"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  } else {
                                                    final Uri mapUrl = Uri.parse("https://www.google.com/maps?q=$lat,$lng");
                                                    await launchUrl(mapUrl, mode: LaunchMode.platformDefault);
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () {
                                                  _clearText(label, code);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if ( controller.showTextField.value ) ...[
                                        TextField(
                                          controller: controller.latController,
                                          readOnly: true,
                                          style: labelStyle,
                                          decoration:  InputDecoration(
                                            labelText: 'Latitude',
                                            fillColor: isDarkMode ? Colors.black : Colors.white,
                                            labelStyle: labelStyle,
                                            border: const OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          controller: controller.longController,
                                          readOnly: true,
                                          style: labelStyle,
                                          decoration:  InputDecoration(
                                            labelText: 'Longitude',
                                            fillColor: isDarkMode ? Colors.black : Colors.white,
                                            labelStyle: labelStyle,
                                            border: const OutlineInputBorder(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }
                              return SizedBox.shrink();
                            }).toList(),
                            const SizedBox(height: 20),
                            Center(
                              child: Wrap(
                                spacing: 10.0,
                                runSpacing: 10.0,
                                alignment: WrapAlignment.center,
                                children:
                                controller.childbuttons.where((button) {
                                  switch (button.name.toLowerCase()) {
                                    case 'list':
                                      return controller.isread == 1;
                                    case 'delete':
                                      return controller.isdelete == 1;
                                    case 'update':
                                      return controller.isupdate == 1;
                                    case 'save':
                                      return controller.iscreate == 1 ||
                                          controller.isupdate == 1 &&
                                              widget.formusecaseid !=
                                                  ''; // Assuming you have issave for Save button
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
                                              ? const Color(0xFF4F76E2)
                                              : const Color(0xFF1A237E),
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          button.name.toUpperCase(),
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? const Color(0xFF4F76E2)
                                                : const Color(0xFF1A237E),
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
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ))
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.groupchildlabellist.isNotEmpty)
                        ...controller.groupchildlabellist.map((field) {
                          var filteredFields =
                          controller.getGroupsField(field.label);
                          return filteredFields.isNotEmpty
                              ? Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8),
                            child: SizedBox(
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  fillColor: isDarkMode
                                      ? Colors.black
                                      : Colors
                                      .white, // Dynamic color
                                  labelText: field.label,
                                  labelStyle: const TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    ...filteredFields.map((field) {
                                      String label = field['label'];
                                      String code = field['code'];

                                      String fieldType =
                                      field['type'];
                                      bool isRequired =
                                          field['required'] == 1;
                                      bool isRefKey =
                                          field['refKey'] == 1;
                                      bool primaryUsecase =
                                          field['primaryUsecase'] !=
                                              "";

                                      bool showDropdown =
                                          primaryUsecase &&
                                              isRefKey;
                                      String yUsecase =
                                          field['primaryUsecase'] ??
                                              "";
                                      String showvalue =
                                          field['show'] ?? "";

                                      Map<String, String> reqBody =
                                      {};
                                      for (var group in controller
                                          .groupchildlabellist) {
                                        var allFields = controller
                                            .getGroupsField(
                                            group.label);
                                        for (var field
                                        in allFields) {
                                          String fieldValue = controller
                                              .getInitialValue(
                                              field['code'])
                                              ?.toString() ??
                                              '';
                                          reqBody[field['code']
                                              .toString()] =
                                              fieldValue;
                                        }
                                      }

                                      int captureImage =
                                          field['captureImage'] ??
                                              0;
                                      String event =
                                          field['event'] ?? "";
                                      String rule =
                                          field['rule'] ?? "";

                                      // bool shouldShowField = controller.evaluateCondition(reqBody, showvalue);

                                      String parentfilter =
                                          field['parentFilter'] ??
                                              "";

                                      if (parentfilter != "" &&
                                          parentfilter.isNotEmpty) {
                                        controller
                                            .addParentFilter();
                                      }
                                      // Skip if system value is 1 (based on your condition from Angular code)
                                      if (field['system'] == 1) {
                                        return const SizedBox
                                            .shrink();
                                      }

                                      bool result = controller
                                          .evaluateCondition(
                                          reqBody, showvalue);
                                      final initialValue =
                                      controller
                                          .getInitialValue(
                                          field['code']);

                                      if (initialValue != null &&
                                          initialValue
                                              .toString()
                                              .isNotEmpty) {
                                        result =
                                        true; // Ensure the field is visible if it has data
                                      }

                                      _controllers.putIfAbsent(
                                          label,
                                              () =>
                                              TextEditingController());
                                      _controllers[label]!.text =
                                          (initialValue ?? "")
                                              .toString();

                                      _controllers.putIfAbsent(
                                          label,
                                              () =>
                                              TextEditingController());

                                      _controllers[label]!
                                          .text = (controller
                                          .getInitialValue(
                                          code) ??
                                          "")
                                          .toString();

                                      if (fieldType == 'text' && result) {
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            controller:
                                            _controllers[label],
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[code],
                                              border:
                                              OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    5),
                                                borderSide: BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            keyboardType:
                                            TextInputType.text,
                                            onChanged: (value) {
                                              controller.dataMap[
                                              code] =
                                                  value; // Directly updating dataMap
                                              controller
                                                  .setInitialValue(
                                                  code, value);
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
                                            enabled:
                                            field['code'] !=
                                                controller
                                                    .parentKey,
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
                                              errorText: resulterror[
                                              code],
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(color: Appcolorblue)),
                                            ),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: (value) async {
                                              setState(() {
                                                controller.dataMap[
                                                code] =
                                                    value; // Directly updating dataMap
                                                controller
                                                    .setInitialValue(
                                                    code,
                                                    value);
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
                                          ),
                                        );
                                      }
                                      if (fieldType == 'url' && result ) {
                                        return TextFormField(
                                          controller: _controllers[label],

                                          style: labelStyle,
                                          decoration: InputDecoration(
                                            errorText: resulterror[code],
                                            labelStyle: labelStyle,
                                            labelText: label,
                                            fillColor: isDarkMode ? Colors.black : Colors.white,
                                            border: OutlineInputBorder(borderSide: BorderSide(color: Appcolorblue)),
                                          ),
                                          keyboardType: TextInputType.url,
                                          onChanged: (value) {
                                            controller.setInitialValue(
                                                code, value);
                                            controller.setFieldValue(
                                                label, value);
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

                                        );
                                      }
                                      if (fieldType == 'password' && result ) {
                                        return TextFormField(
                                          controller: _controllers[label],
                                          style: labelStyle,
                                          decoration: InputDecoration(
                                            errorText: resulterror[code],
                                            labelStyle: labelStyle,
                                            labelText: label,
                                            fillColor: isDarkMode ? Colors.black : Colors.white,
                                            border: OutlineInputBorder(borderSide: BorderSide(color: Appcolorblue)),
                                            // suffixIcon: Icon(Icons.lock), // Password icon
                                          ),

                                          onChanged: (value) {
                                            controller.setInitialValue(
                                                code, value);
                                            controller.setFieldValue(
                                                label, value);
                                          },
                                          validator: (value) {
                                            if (isRequired && (value == null || value.isEmpty)) {
                                              return 'Please enter $label';
                                            }

                                            final regexPattern = field['regex']; // e.g., "^[1-5]$"
                                            if (regexPattern != null && value != null && value.isNotEmpty) {
                                              final regex = RegExp(regexPattern);
                                              if (!regex.hasMatch(value)) {
                                                return 'Invalid input for $label';
                                              }
                                            }

                                            return null;
                                          },


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
                                              errorText: resulterror[code],
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
                                      if (fieldType == 'textarea' && result) {
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            controller:
                                            _controllers[label],
                                            style: labelStyle,

                                            decoration:
                                            InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[code],
                                              border:
                                              OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            keyboardType:
                                            TextInputType
                                                .multiline,
                                            maxLines: 3,
                                            // You can set this to null for unlimited lines
                                            onChanged: (value) =>
                                                controller
                                                    .setInitialValue(
                                                    code,
                                                    value),
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
                                            enabled:
                                            field['code'] !=
                                                controller
                                                    .parentKey,
                                          ),
                                        );
                                      }
                                      if (showDropdown && result) {
                                        final dropdownItems =
                                            controller.prelaodlist[
                                            yUsecase] ??
                                                [];

                                        // Ensure no duplicates in the dropdownItems based on the 'id' field
                                        final uniqueItems =
                                        dropdownItems
                                            .toSet()
                                            .toList();
                                        bool isDisabled =
                                            field['code'] ==
                                                controller
                                                    .parentKey;
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child:
                                          DropdownButtonFormField<
                                              String>(
                                            dropdownColor:
                                            isDarkMode
                                                ? Colors
                                                .grey[850]
                                                : Colors.white,
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              errorText:
                                              resulterror[code],
                                              labelStyle:
                                              labelStyle,
                                              border:
                                              OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            value: controller
                                                .getInitialValue(
                                                code)
                                                ?.isEmpty ??
                                                true
                                                ? null
                                                : controller
                                                .getInitialValue(
                                                code),
                                            items: [
                                              DropdownMenuItem<
                                                  String>(
                                                value: null,
                                                // Null value for the placeholder
                                                child: Text(
                                                    "Select $label",
                                                    style:
                                                    labelStyle),
                                              ),
                                              // Mapping dropdownItems to DropdownMenuItems
                                              ...uniqueItems.map<
                                                  DropdownMenuItem<
                                                      String>>((item) {
                                                return DropdownMenuItem<
                                                    String>(
                                                  value: item['id']
                                                      .toString(),
                                                  child: Text(
                                                    item['_val'],
                                                    style:
                                                    labelStyle,
                                                  ),
                                                );
                                              }).toList(),
                                            ],
                                            onChanged: isDisabled
                                                ? null // Disables dropdown if isDisabled is true
                                                : (value) async {
                                              if (event !=
                                                  "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                controller
                                                    .admissionId =
                                                    value;
                                                setState(() {
                                                  controller.setFieldValue(
                                                      label,
                                                      value ??
                                                          ""); // Update the field value
                                                  controller.setInitialValue(
                                                      code,
                                                      value ??
                                                          "");
                                                });
                                              } else {
                                                controller.setFieldValue(
                                                    label,
                                                    value ??
                                                        ""); // Update the field value
                                                controller
                                                    .setInitialValue(
                                                    code,
                                                    value ??
                                                        "");
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
                                      if ((fieldType == 'number' || fieldType == 'phone' || fieldType == 'long' || fieldType == 'expression' || fieldType == 'decimal') && result) {
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            controller:
                                            _controllers[label],
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              errorText:
                                              resulterror[code],
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              border:
                                              OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    5),
                                                borderSide: BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            keyboardType:
                                            TextInputType
                                                .number,
                                            onChanged: (value) {
                                              controller.dataMap[
                                              code] =
                                                  value; // Directly updating dataMap
                                              controller
                                                  .setInitialValue(
                                                  code, value);
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
                                            enabled:
                                            field['code'] !=
                                                controller
                                                    .parentKey,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'date' && result) {
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            readOnly: true,
                                            controller:
                                            TextEditingController(
                                                text:
                                                initialValue),
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              errorText:
                                              resulterror[code],
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              suffixIcon: Icon(
                                                Icons
                                                    .calendar_today,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              border:
                                              OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    5),
                                                borderSide: BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            onTap: () async {
                                              DateTime?
                                              selectedDate =
                                              await showDatePicker(
                                                context: context,
                                                initialDate:
                                                DateTime.now(),
                                                firstDate:
                                                DateTime(1900),
                                                lastDate:
                                                DateTime(2100),
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

                                                    controller
                                                        .setFieldValue(
                                                        label,
                                                        formattedDate);
                                                    controller
                                                        .setInitialValue(
                                                        code,
                                                        formattedDate);
                                                  }
                                                } else {
                                                  setState(() {
                                                    controller
                                                        .setInitialValue(
                                                        code,
                                                        formattedDate);
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
                                            enabled:
                                            field['code'] !=
                                                controller
                                                    .parentKey,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'list' && result) {
                                        bool isDisabled =
                                            field['code'] ==
                                                controller
                                                    .parentKey;
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child:
                                          DropdownButtonFormField<
                                              String>(
                                            dropdownColor:
                                            isDarkMode
                                                ? Colors
                                                .grey[850]
                                                : Colors.white,
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              errorText:
                                              resulterror[code],
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              border:
                                              OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    5),
                                                borderSide: BorderSide(
                                                    color:
                                                    Appcolorblue),
                                              ),
                                            ),
                                            // value: initialValue ?? null,
                                            value: controller
                                                .getInitialValue(
                                                code)
                                                ?.isEmpty ??
                                                true
                                                ? null // Set value to null if it's empty or null
                                                : controller
                                                .getInitialValue(
                                                code),
                                            items: [
                                              if (!isRequired)
                                                DropdownMenuItem(
                                                    value: null,
                                                    child: Text(
                                                        'Select $label')),
                                              ...field['values'].map<
                                                  DropdownMenuItem<
                                                      String>>(
                                                      (value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(
                                                        value,
                                                        style:
                                                        labelStyle,
                                                      ),
                                                    );
                                                  }).toList(),
                                            ],
                                            onChanged: isDisabled
                                                ? null // Disables dropdown if isDisabled is true
                                                : (value) async {
                                              if (event !=
                                                  "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                controller
                                                    .admissionId =
                                                    value;
                                                setState(() {
                                                  controller.setFieldValue(
                                                      label,
                                                      value ??
                                                          ""); // Update the field value
                                                  controller.setInitialValue(
                                                      code,
                                                      value ??
                                                          "");
                                                });
                                              } else {
                                                controller.setFieldValue(
                                                    label,
                                                    value ??
                                                        ""); // Update the field value
                                                controller
                                                    .setInitialValue(
                                                    code,
                                                    value ??
                                                        "");
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
                                        bool isDisabled =
                                            field['code'] ==
                                                controller
                                                    .parentKey;
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child:
                                          DropdownButtonFormField<
                                              String>(
                                            dropdownColor:
                                            isDarkMode
                                                ? Colors
                                                .grey[850]
                                                : Colors.white,
                                            style: labelStyle,
                                            decoration:
                                            InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelText: label,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[code],
                                              border: OutlineInputBorder(
                                                  borderSide:
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            //  value: controller.getFieldValue(label), // Set the initial value
                                            value: controller
                                                .getInitialValue(
                                                code)
                                                ?.isEmpty ??
                                                true
                                                ? null // Set value to null if it's empty or null
                                                : controller
                                                .getInitialValue(
                                                code),

                                            items: [
                                              if (!isRequired)
                                                DropdownMenuItem(
                                                  value: null,
                                                  child: Text(
                                                      'Select $label'),
                                                ),
                                              ...field['values'].map<
                                                  DropdownMenuItem<
                                                      String>>(
                                                      (value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(
                                                        value,
                                                        style:
                                                        labelStyle,
                                                      ),
                                                    );
                                                  }).toList(),
                                            ],
                                            onChanged: isDisabled
                                                ? null // Disables dropdown if isDisabled is true
                                                : (value) async {
                                              if (event !=
                                                  "") {
                                                await controller
                                                    .GetUserData(
                                                    code,
                                                    rule,
                                                    value!);
                                                controller
                                                    .admissionId =
                                                    value;
                                                setState(() {
                                                  controller.setFieldValue(
                                                      label,
                                                      value ??
                                                          ""); // Update the field value
                                                  controller.setInitialValue(
                                                      code,
                                                      value ??
                                                          "");
                                                });
                                              } else {
                                                controller.setFieldValue(
                                                    label,
                                                    value ??
                                                        ""); // Update the field value
                                                controller
                                                    .setInitialValue(
                                                    code,
                                                    value ??
                                                        "");
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
                                      if (fieldType == 'doc' && result) {
                                        return Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            // Custom file input field that looks like a TextField
                                            Padding(
                                              padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  vertical:
                                                  8.0),
                                              child: TextFormField(
                                                style: labelStyle,

                                                onTap: () {
                                                  _pickAndUploadFile(
                                                    int.tryParse(controller
                                                        .getInitialValue(code)
                                                        ?.toString() ??
                                                        '0') ??
                                                        0,
                                                    code.toString(),
                                                  );
                                                },
                                                readOnly: true,
                                                controller: TextEditingController(
                                                    text: controller.imagePaths[
                                                    code] !=
                                                        null
                                                        ? controller
                                                        .imagePaths[
                                                    code]!
                                                        .split(
                                                        '/')
                                                        .last
                                                        : ''),
                                                // Display the file name or path
                                                decoration:
                                                InputDecoration(
                                                  errorText:
                                                  resulterror[
                                                  code],
                                                  fillColor:
                                                  isDarkMode
                                                      ? Colors
                                                      .black
                                                      : Colors
                                                      .white,
                                                  labelText: label,
                                                  hintText: label,
                                                  labelStyle:
                                                  labelStyle,
                                                  border:
                                                  OutlineInputBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        5),
                                                    borderSide: const BorderSide(
                                                        color: Colors
                                                            .green),
                                                  ),
                                                  suffixIcon:
                                                  IconButton(
                                                      icon: Icon(
                                                          Icons
                                                              .attachment,
                                                          color: isDarkMode
                                                              ? Colors
                                                              .white
                                                              : Colors
                                                              .black),
                                                      onPressed:
                                                          () {
                                                        _pickAndUploadFile(
                                                          int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ??
                                                              0,
                                                          code.toString(),
                                                        );
                                                      } // Trigger the file picker on tap

                                                  ),
                                                ),
                                                enabled: field[
                                                'code'] !=
                                                    controller
                                                        .parentKey,
                                                onChanged: (value) {
                                                  // Save the file path (or name) to the controller
                                                  setState(() {
                                                    controller.imagePaths[
                                                    code] =
                                                        value; // Optionally save the file path here
                                                  });
                                                  controller.dataMap[
                                                  code] =
                                                      value; // Directly updating dataMap
                                                  controller
                                                      .setInitialValue(
                                                      code,
                                                      value);
                                                  controller
                                                      .setFieldValue(
                                                      label,
                                                      value);
                                                },
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  vertical:
                                                  16.0),
                                              child:
                                              _buildImageWidget(
                                                  controller,
                                                  field[
                                                  'code']),
                                            ),
                                          ],
                                        );
                                      }
                                      if (fieldType == 'file' && result) {
                                        return Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            // Custom file input field that looks like a TextField
                                            Padding(
                                              padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  vertical:
                                                  8.0),
                                              child: TextFormField(
                                                onTap: () {
                                                  if (captureImage ==
                                                      1) {
                                                    getImage1(
                                                        int.tryParse(controller.getInitialValue(code)?.toString() ??
                                                            '0') ??
                                                            0,
                                                        code
                                                            .toString(),
                                                        ImageSource
                                                            .camera);
                                                  } else {
                                                    _pickAndUploadImage(
                                                      int.tryParse(controller
                                                          .getInitialValue(code)
                                                          ?.toString() ??
                                                          '0') ??
                                                          0,
                                                      code.toString(),
                                                    );
                                                    _pickAndUploadImage(
                                                      int.tryParse(controller
                                                          .getInitialValue(code)
                                                          ?.toString() ??
                                                          '0') ??
                                                          0,
                                                      code.toString(),
                                                    );
                                                  }
                                                },
                                                readOnly: true,
                                                style: labelStyle,
                                                enabled: field[
                                                'code'] !=
                                                    controller
                                                        .parentKey,
                                                controller: TextEditingController(
                                                    text: controller.imagePaths[
                                                    code] !=
                                                        null
                                                        ? controller
                                                        .imagePaths[
                                                    code]!
                                                        .split(
                                                        '/')
                                                        .last
                                                        : ''),
                                                // Display the file name or path
                                                decoration:
                                                InputDecoration(
                                                  errorText:
                                                  resulterror[
                                                  code],
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
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        5),
                                                    borderSide: const BorderSide(
                                                        color: Colors
                                                            .green),
                                                  ),
                                                  suffixIcon:
                                                  IconButton(
                                                      icon:
                                                      Icon(
                                                        Icons
                                                            .attachment,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                      onPressed:
                                                          () {
                                                        if (captureImage ==
                                                            1) {
                                                          getImage1(
                                                              int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                              code.toString(),
                                                              ImageSource.camera);
                                                        } else {
                                                          _pickAndUploadImage(
                                                            int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ??
                                                                0,
                                                            code.toString(),
                                                          );
                                                          _pickAndUploadImage(
                                                            int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ??
                                                                0,
                                                            code.toString(),
                                                          );
                                                        }
                                                      } // Trigger the file picker on tap

                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    controller.imagePaths[
                                                    code] =
                                                        value; // Optionally save the file path here
                                                  });
                                                  controller.dataMap[
                                                  code] =
                                                      value; // Directly updating dataMap
                                                  controller
                                                      .setInitialValue(
                                                      code,
                                                      '0');
                                                },
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  vertical:
                                                  16.0),
                                              child:
                                              _buildImageshowWidget(
                                                  controller,
                                                  field[
                                                  'code']),
                                            ),
                                          ],
                                        );
                                      }
                                      if (fieldType == 'time' && result) {
                                        return Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              vertical: 8.0),
                                          child: TextFormField(
                                            readOnly: true,
                                            style: labelStyle,
                                            controller:
                                            TextEditingController(
                                                text: controller
                                                    .getFieldValue(
                                                    label)),
                                            decoration:
                                            InputDecoration(
                                              fillColor: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              labelStyle:
                                              labelStyle,
                                              errorText:
                                              resulterror[code],
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
                                                  BorderSide(
                                                      color:
                                                      Appcolorblue)),
                                            ),
                                            onTap: () async {
                                              TimeOfDay?
                                              selectedTime =
                                              await showTimePicker(
                                                context: context,
                                                initialTime:
                                                TimeOfDay.now(),
                                              );
                                              if (selectedTime !=
                                                  null) {
                                                // Convert TimeOfDay to DateTime
                                                final now =
                                                DateTime.now();
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

                                                  controller.setFieldValue(
                                                      label, formattedTime);
                                                  controller
                                                      .setInitialValue(code,
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
                                      if (fieldType == 'combobox' && result) {
                                        List<dynamic> mapValues = field['values'] ?? [];

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            style: labelStyle,
                                            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                            decoration: InputDecoration(
                                              fillColor: isDarkMode ? Colors.black : Colors.white,
                                              labelText: label,
                                              labelStyle: labelStyle,
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(color: Appcolorblue),
                                              ),
                                            ),
                                            hint: Text(
                                              "Select $label",
                                              style: labelStyle,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            value: controller.getInitialValue(code)?.isEmpty ?? true
                                                ? null // Set value to null if it's empty or null
                                                : controller.getInitialValue(code),
                                            items: mapValues.map<DropdownMenuItem<String>>((item) {
                                              // Treat item as a string
                                              String displayValue = item.toString();  // Directly use the string value

                                              return DropdownMenuItem<String>(
                                                value: displayValue,  // Use the string as the value
                                                child: Text(
                                                  displayValue,
                                                  style: labelStyle, overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) async {
                                              if (event != "") {
                                                // If there is an event, update the necessary values
                                                await controller.GetUserData(code, rule, value!);
                                                controller.admissionId = value;

                                                controller.setFieldValue(label, value ?? "");
                                                controller.setInitialValue(code, value ?? "");
                                              } else {
                                                // If no event, directly update the dataMap
                                                controller.dataMap[code] = value;
                                                controller.setFieldValue(label, value ?? "");
                                                controller.setInitialValue(code, value ?? "");
                                              }
                                            },
                                            validator: isRequired
                                                ? (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select $label';
                                              }
                                              return null;
                                            }
                                                : null,
                                          ),
                                        );
                                      }
                                      if (fieldType == 'boolean' && result) {
                                        // Initialize isSelected based on saved value
                                        String? savedValue = initialValue.toString();
                                        if (savedValue == '1') {
                                          isSelected = [true, false];
                                        } else if (savedValue == '0') {
                                          isSelected = [false, true];
                                        } else {
                                          isSelected = [false, false];
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 9),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Text(label, style: labelStyle)),
                                              const SizedBox(height: 10),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: ToggleButtons(
                                                  borderRadius: BorderRadius.circular(5),
                                                  selectedColor: Colors.white,
                                                  borderColor: isDarkMode
                                                      ? const Color(0xFF4F76E2)
                                                      : const Color(0xFF1A237E),
                                                  fillColor: isDarkMode
                                                      ? const Color(0xFF4F76E2)
                                                      : const Color(0xFF1A237E),
                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                  isSelected: isSelected,
                                                  onPressed: (index) {
                                                    setState(() {
                                                      for (int i = 0; i < isSelected.length; i++) {
                                                        isSelected[i] = i == index;
                                                      }

                                                      var selectedValue = index == 0 ? 1 : 0;
                                                      String savedValue = selectedValue.toString();

                                                      controller.dataMap[field['code']] = savedValue;
                                                      controller.setFieldValue(label, savedValue);
                                                      controller.setInitialValue(code, savedValue);
                                                    });
                                                  },
                                                  children:  const [
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      child: Text("Yes", style:  TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w400,
                                                      ),),
                                                    ),
                                                    Padding(
                                                      padding:const EdgeInsets.symmetric(horizontal: 16),
                                                      child: Text("No", style:  TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w400,
                                                      ),),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      if (fieldType == 'location' && result) {


                                        final locationMap = initialValue;

                                        if (locationMap != null && locationMap is Map) {

                                          if(locationMap.isNotEmpty){
                                            controller.showTextField.value= true;
                                          }

                                          controller.latController.text = locationMap['lat'].toString() ?? '';
                                          controller.longController.text = locationMap['lng'].toString() ?? '';

                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(label,  style: labelStyle,),
                                              const SizedBox(height: 8),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey, width: 1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.location_on, color: Appcolorblue),
                                                        onPressed: () {

                                                          setCurrentLocation(label,code);
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.remove_red_eye, color: Appcolorblue),
                                                        onPressed: () async {
                                                          final lat = controller.latController.text;
                                                          final lng = controller.longController.text;
                                                          if (lat.isEmpty || lng.isEmpty) {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                title: const Text("Missing Location"),
                                                                content: const Text("Location not available. Please set the location first.."),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: Text("OK"),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          } else {
                                                            final Uri mapUrl = Uri.parse("https://www.google.com/maps?q=$lat,$lng");
                                                            await launchUrl(mapUrl, mode: LaunchMode.platformDefault);
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete, color: Colors.red),
                                                        onPressed: () {
                                                          _clearText(label, code);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if ( controller.showTextField.value ) ...[
                                                TextField(
                                                  controller: controller.latController,
                                                  readOnly: true,
                                                  style: labelStyle,
                                                  decoration:  InputDecoration(
                                                    labelText: 'Latitude',
                                                    fillColor: isDarkMode ? Colors.black : Colors.white,
                                                    labelStyle: labelStyle,
                                                    border: const OutlineInputBorder(),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                TextField(
                                                  controller: controller.longController,
                                                  readOnly: true,
                                                  style: labelStyle,
                                                  decoration:  InputDecoration(
                                                    labelText: 'Longitude',
                                                    fillColor: isDarkMode ? Colors.black : Colors.white,
                                                    labelStyle: labelStyle,
                                                    border: const OutlineInputBorder(),
                                                  ),
                                                ),
                                              ],
                                            ],
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
                              : const SizedBox.shrink();
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

                        Map<String, String> reqBody = {};
                        for (var field in itemsWithoutGroup) {
                          String fieldValue = controller
                              .getInitialValue(label)
                              ?.toString() ??
                              '';
                          reqBody[code.toString()] = fieldValue;
                        }
                        final result = controller.evaluateCondition(
                            reqBody, showvalue);

                        String event = field['event'] ?? "";
                        String rule = field['rule'] ?? "";
                        int captureImage = field['captureImage'] ?? 0;

                        String parentfilter = field['parentFilter'] ?? "";

                        if (parentfilter != "" &&
                            parentfilter.isNotEmpty) {
                          controller.addParentFilter();
                        }

                        if (field['system'] == 1) {
                          return const SizedBox.shrink();
                        }

                        dynamic initialValue =
                        controller.getInitialValue(code);

                        _controllers.putIfAbsent(
                            label, () => TextEditingController());

                        _controllers[label]!.text =
                            (controller.getInitialValue(code) ?? "")
                                .toString();

                        if (fieldType == 'text' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                              ),
                              keyboardType: TextInputType.text,
                              onChanged: (value) {
                                controller.dataMap[code] =
                                    value; // Directly updating dataMap
                                controller.setInitialValue(code, value);
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
                              enabled:
                              field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        if (fieldType == 'textarea' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
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
                              maxLines: 3,
                              // You can set this to null for unlimited lines
                              onChanged: (value) =>
                                  controller.setInitialValue(code, value),
                              validator: isRequired
                                  ? (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter $label';
                                }
                                return null;
                              }
                                  : null,
                              enabled:
                              field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        if (showDropdown && result) {
                          final dropdownItems =
                              controller.prelaodlist[yUsecase] ?? [];

                          // Ensure unique IDs in the dropdown items
                          final uniqueDropdownItems = dropdownItems
                              .toSet()
                              .toList(); // Remove duplicates based on 'id'
                          bool isDisabled =
                              field['code'] == controller.parentKey;
                          final currentValue =
                          controller.getInitialValue(field['code']);

                          final validValue = uniqueDropdownItems.any(
                                  (item) =>
                              item['id'].toString() ==
                                  currentValue)
                              ? currentValue
                              : null;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 8),
                            child: DropdownButtonFormField<String>(
                              dropdownColor: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.white,
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                errorText: resulterror[code],
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                              ),
                              // Ensure dropdown can handle null or empty selection
                              value: validValue?.isEmpty ?? true
                                  ? null // Set value to null if it's empty or null
                                  : validValue,
                              // Use null if no valid value is found
                              items: [
                                if (!isRequired)
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'Select $label',
                                      style: labelStyle,
                                    ),
                                  ),
                                ...uniqueDropdownItems
                                    .map<DropdownMenuItem<String>>(
                                        (item) {
                                      return DropdownMenuItem<String>(
                                        value: item['id'].toString(),
                                        child: Text(
                                          item['_val'],
                                          style: labelStyle,
                                        ),
                                      );
                                    }).toList(),
                              ],
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller.GetUserData(
                                      code, rule, value!);
                                  controller.admissionId = value;
                                  setState(() {
                                    controller.setFieldValue(
                                        label,
                                        value ??
                                            ""); // Update the field value
                                    controller.setInitialValue(
                                        code, value ?? "");
                                  });
                                } else {
                                  controller.setFieldValue(
                                      label,
                                      value ??
                                          ""); // Update the field value
                                  controller.setInitialValue(
                                      code, value ?? "");
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
                                errorText: resulterror[
                                code],
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) async {
                                setState(() {
                                  controller.dataMap[
                                  code] =
                                      value; // Directly updating dataMap
                                  controller
                                      .setInitialValue(
                                      code,
                                      value);
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
                            ),
                          );
                        }
                        if (fieldType == 'url' && result ) {
                          return TextFormField(
                            controller: _controllers[label],

                            style: labelStyle,
                            decoration: InputDecoration(
                              errorText: resulterror[code],
                              labelStyle: labelStyle,
                              labelText: label,
                              fillColor: isDarkMode ? Colors.black : Colors.white,
                              border: OutlineInputBorder(borderSide: BorderSide(color: Appcolorblue)),
                            ),
                            keyboardType: TextInputType.url,
                            onChanged: (value) {
                              controller.setInitialValue(
                                  code, value);
                              controller.setFieldValue(
                                  label, value);
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

                          );
                        }
                        if (fieldType == 'password' && result ) {
                          return TextFormField(
                            controller: _controllers[label],
                            style: labelStyle,
                            decoration: InputDecoration(
                              errorText: resulterror[code],
                              labelStyle: labelStyle,
                              labelText: label,
                              fillColor: isDarkMode ? Colors.black : Colors.white,
                              border: OutlineInputBorder(borderSide: BorderSide(color: Appcolorblue)),
                              // suffixIcon: Icon(Icons.lock), // Password icon
                            ),

                            onChanged: (value) {
                              controller.setInitialValue(
                                  code, value);
                              controller.setFieldValue(
                                  label, value);
                            },
                            validator: (value) {
                              if (isRequired && (value == null || value.isEmpty)) {
                                return 'Please enter $label';
                              }

                              final regexPattern = field['regex']; // e.g., "^[1-5]$"
                              if (regexPattern != null && value != null && value.isNotEmpty) {
                                final regex = RegExp(regexPattern);
                                if (!regex.hasMatch(value)) {
                                  return 'Invalid input for $label';
                                }
                              }

                              return null;
                            },


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
                                errorText: resulterror[code],
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
                        if ((fieldType == 'number' || fieldType == 'phone' || fieldType == 'long' || fieldType == 'expression' || fieldType == 'decimal') && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: TextFormField(
                              controller: _controllers[label],
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                enabled:
                                field['code'] != controller.parentKey,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                controller.dataMap[code] = value;
                                controller.setInitialValue(code, value);
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
                        else if (fieldType == 'date' && result) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                  text: initialValue),
                              style: labelStyle,
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
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
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
                                      showPopup(
                                          context, 'Error', errorMessage);
                                    } else if (response != null &&
                                        response['success'] == true) {
                                      // showPopup(context, 'Success', 'Date updated successfully!');

                                      controller.setFieldValue(
                                          label, formattedDate);
                                      controller.setInitialValue(
                                          code, formattedDate);
                                    }
                                  } else {
                                    setState(() {
                                      controller.setInitialValue(
                                          code, formattedDate);
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
                              enabled:
                              field['code'] != controller.parentKey,
                            ),
                          );
                        }
                        else if (fieldType == 'list' && result) {
                          bool isDisabled =
                              field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: DropdownButtonFormField<String>(
                              dropdownColor: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.white,
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  borderSide:
                                  BorderSide(color: Appcolorblue),
                                ),
                              ),
                              // value: initialValue ?? null,
                              value: controller
                                  .getInitialValue(code)
                                  ?.isEmpty ??
                                  true
                                  ? null // Set value to null if it's empty or null
                                  : controller.getInitialValue(code),
                              // Ensure this matches a value in the items list
                              items: [
                                if (!isRequired)
                                  DropdownMenuItem(
                                      value: null,
                                      child: Text('Select $label')),
                                ...field['values']
                                    .map<DropdownMenuItem<String>>(
                                        (value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: labelStyle,
                                        ),
                                      );
                                    }).toList(),
                              ],
                              onChanged: isDisabled
                                  ? null // Disables dropdown if isDisabled is true
                                  : (value) async {
                                if (event != "") {
                                  await controller.GetUserData(
                                      code, rule, value!);
                                  controller.admissionId = value;
                                  setState(() {
                                    controller.setFieldValue(
                                        label,
                                        value ??
                                            ""); // Update the field value
                                    controller.setInitialValue(
                                        code, value ?? "");
                                  });
                                } else {
                                  controller.setFieldValue(
                                      label,
                                      value ??
                                          ""); // Update the field value
                                  controller.setInitialValue(
                                      code, value ?? "");
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
                          List<dynamic> mapValues = field['values'] ?? [];
                          bool isDisabled =
                              field['code'] == controller.parentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 5.0),
                            child: DropdownButtonFormField<String>(
                              dropdownColor: isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.white,
                              style: labelStyle,
                              decoration: InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                errorText: resulterror[code],
                                border: OutlineInputBorder(
                                    borderSide:
                                    BorderSide(color: Appcolorblue)),
                              ),
                              //  value: controller.getFieldValue(label), // Set the initial value
                              value: controller
                                  .getInitialValue(code)
                                  ?.isEmpty ??
                                  true
                                  ? null // Set value to null if it's empty or null
                                  : controller.getInitialValue(code),

                              items: mapValues
                                  .map<DropdownMenuItem<String>>((item) {
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
                                  await controller.GetUserData(
                                      code, rule, value!);
                                  controller.admissionId = value;
                                  setState(() {
                                    controller.setFieldValue(
                                        label,
                                        value ??
                                            ""); // Update the field value
                                    controller.setInitialValue(
                                        code, value ?? "");
                                  });
                                } else {
                                  controller.setFieldValue(
                                      label,
                                      value ??
                                          ""); // Update the field value
                                  controller.setInitialValue(
                                      code, value ?? "");
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
                        else if (fieldType == 'doc' && result) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Custom file input field that looks like a TextField
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 5.0),
                                child: TextFormField(
                                  style: labelStyle,
                                  onTap: () {
                                    _pickAndUploadFile(
                                      int.tryParse(controller
                                          .getInitialValue(code)
                                          ?.toString() ??
                                          '0') ??
                                          0,
                                      code.toString(),
                                    );
                                  },
                                  readOnly: true,
                                  controller: TextEditingController(
                                      text: controller.imagePaths[code] !=
                                          null
                                          ? controller.imagePaths[code]!
                                          .split('/')
                                          .last
                                          : ''),
                                  // Display the file name or path
                                  decoration: InputDecoration(
                                    fillColor: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    labelText: label,
                                    hintText: label,
                                    labelStyle: labelStyle,
                                    errorText: resulterror[code],
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(5),
                                      borderSide: const BorderSide(
                                          color: Colors.green),
                                    ),
                                    suffixIcon: IconButton(
                                        icon: Icon(Icons.attachment,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black),
                                        onPressed: () {
                                          _pickAndUploadFile(
                                            int.tryParse(controller
                                                .getInitialValue(
                                                code)
                                                ?.toString() ??
                                                '0') ??
                                                0,
                                            code.toString(),
                                          );
                                        } // Trigger the file picker on tap

                                    ),
                                  ),
                                  enabled: field['code'] !=
                                      controller.parentKey,
                                  onChanged: (value) {
                                    // Save the file path (or name) to the controller
                                    setState(() {
                                      controller.imagePaths[code] =
                                          value; // Optionally save the file path here
                                    });
                                    controller.dataMap[code] =
                                        value; // Directly updating dataMap
                                    controller.setInitialValue(
                                        code, value);
                                    controller.setFieldValue(
                                        label, value);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16.0),
                                child: _buildImageWidget(
                                    controller, field['code']),
                              ),
                            ],
                          );
                        }
                        else if (fieldType == 'file' && result) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Custom file input field that looks like a TextField
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 5.0),
                                child: TextFormField(
                                  onTap: () {
                                    if (captureImage == 1) {
                                      getImage1(
                                          int.tryParse(controller
                                              .getInitialValue(
                                              code)
                                              ?.toString() ??
                                              '0') ??
                                              0,
                                          code.toString(),
                                          ImageSource.camera);
                                    } else {
                                      _pickAndUploadImage(
                                        int.tryParse(controller
                                            .getInitialValue(code)
                                            ?.toString() ??
                                            '0') ??
                                            0,
                                        code.toString(),
                                      );
                                      _pickAndUploadImage(
                                        int.tryParse(controller
                                            .getInitialValue(code)
                                            ?.toString() ??
                                            '0') ??
                                            0,
                                        code.toString(),
                                      );
                                    }
                                  },
                                  readOnly: true,
                                  style: labelStyle,
                                  controller: TextEditingController(
                                      text: controller.imagePaths[code] !=
                                          null
                                          ? controller.imagePaths[code]!
                                          .split('/')
                                          .last
                                          : ''),
                                  // Display the file name or path
                                  decoration: InputDecoration(
                                    fillColor: isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    labelText: label,
                                    labelStyle: labelStyle,
                                    errorText: resulterror[code],
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(5),
                                      borderSide: const BorderSide(
                                          color: Colors.green),
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
                                            getImage1(
                                                int.tryParse(controller
                                                    .getInitialValue(
                                                    code)
                                                    ?.toString() ??
                                                    '0') ??
                                                    0,
                                                code.toString(),
                                                ImageSource.camera);
                                          } else {
                                            _pickAndUploadImage(
                                              int.tryParse(controller
                                                  .getInitialValue(
                                                  code)
                                                  ?.toString() ??
                                                  '0') ??
                                                  0,
                                              code.toString(),
                                            );
                                            _pickAndUploadImage(
                                              int.tryParse(controller
                                                  .getInitialValue(
                                                  code)
                                                  ?.toString() ??
                                                  '0') ??
                                                  0,
                                              code.toString(),
                                            );
                                          }
                                        } // Trigger the file picker on tap

                                    ),
                                  ),
                                  enabled: field['code'] !=
                                      controller.parentKey,
                                  onChanged: (value) {
                                    setState(() {
                                      controller.imagePaths[code] =
                                          value; // Optionally save the file path here
                                    });
                                    controller.dataMap[code] =
                                        value; // Directly updating dataMap
                                    controller.setInitialValue(code, '0');
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16.0),
                                child: _buildImageshowWidget(
                                    controller, field['code']),
                              ),
                            ],
                          );
                        }
                        if (fieldType == 'time' && result) {
                          return Padding(
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 8.0),
                            child: TextFormField(
                              readOnly: true,
                              style: labelStyle,
                              controller:
                              TextEditingController(
                                  text: controller
                                      .getFieldValue(
                                      label)),
                              decoration:
                              InputDecoration(
                                fillColor: isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                labelStyle:
                                labelStyle,
                                errorText:
                                resulterror[code],
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
                                    BorderSide(
                                        color:
                                        Appcolorblue)),
                              ),
                              onTap: () async {
                                TimeOfDay?
                                selectedTime =
                                await showTimePicker(
                                  context: context,
                                  initialTime:
                                  TimeOfDay.now(),
                                );
                                if (selectedTime !=
                                    null) {
                                  // Convert TimeOfDay to DateTime
                                  final now =
                                  DateTime.now();
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

                                    controller.setFieldValue(
                                        label, formattedTime);
                                    controller
                                        .setInitialValue(code,
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
                        if (fieldType == 'combobox' && result) {
                          List<dynamic> mapValues = field['values'] ?? [];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              style: labelStyle,
                              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                              decoration: InputDecoration(
                                fillColor: isDarkMode ? Colors.black : Colors.white,
                                labelText: label,
                                labelStyle: labelStyle,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Appcolorblue),
                                ),
                              ),
                              hint: Text(
                                "Select $label",
                                style: labelStyle,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              value: controller.getInitialValue(code)?.isEmpty ?? true
                                  ? null // Set value to null if it's empty or null
                                  : controller.getInitialValue(code),
                              items: mapValues.map<DropdownMenuItem<String>>((item) {
                                // Treat item as a string
                                String displayValue = item.toString();  // Directly use the string value

                                return DropdownMenuItem<String>(
                                  value: displayValue,  // Use the string as the value
                                  child: Text(
                                    displayValue,
                                    style: labelStyle, overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                if (event != "") {
                                  // If there is an event, update the necessary values
                                  await controller.GetUserData(code, rule, value!);
                                  controller.admissionId = value;

                                  controller.setFieldValue(label, value ?? "");
                                  controller.setInitialValue(code, value ?? "");
                                } else {
                                  // If no event, directly update the dataMap
                                  controller.dataMap[code] = value;
                                  controller.setFieldValue(label, value ?? "");
                                  controller.setInitialValue(code, value ?? "");
                                }
                              },
                              validator: isRequired
                                  ? (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select $label';
                                }
                                return null;
                              }
                                  : null,
                            ),
                          );
                        }
                        if (fieldType == 'boolean' && result) {
                          // Initialize isSelected based on saved value
                          String? savedValue = initialValue.toString();
                          if (savedValue == '1') {
                            isSelected = [true, false];
                          } else if (savedValue == '0') {
                            isSelected = [false, true];
                          } else {
                            isSelected = [false, false];
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 9),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(label, style: labelStyle)),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: ToggleButtons(
                                    borderRadius: BorderRadius.circular(5),
                                    selectedColor: Colors.white,
                                    borderColor: isDarkMode
                                        ? const Color(0xFF4F76E2)
                                        : const Color(0xFF1A237E),
                                    fillColor: isDarkMode
                                        ? const Color(0xFF4F76E2)
                                        : const Color(0xFF1A237E),
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    isSelected: isSelected,
                                    onPressed: (index) {
                                      setState(() {
                                        for (int i = 0; i < isSelected.length; i++) {
                                          isSelected[i] = i == index;
                                        }

                                        var selectedValue = index == 0 ? 1 : 0;
                                        String savedValue = selectedValue.toString();

                                        controller.dataMap[field['code']] = savedValue;
                                        controller.setFieldValue(label, savedValue);
                                        controller.setInitialValue(code, savedValue);
                                      });
                                    },
                                    children:  const [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text("Yes", style:  TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),),
                                      ),
                                      Padding(
                                        padding:const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text("No", style:  TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (fieldType == 'location' && result) {


                          final locationMap = initialValue;

                          if (locationMap != null && locationMap is Map) {

                            if(locationMap.isNotEmpty){
                              controller.showTextField.value= true;
                            }

                            controller.latController.text = locationMap['lat'].toString() ?? '';
                            controller.longController.text = locationMap['lng'].toString() ?? '';

                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,  style: labelStyle,),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.location_on, color: Appcolorblue),
                                          onPressed: () {

                                            setCurrentLocation(label,code);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.remove_red_eye, color: Appcolorblue),
                                          onPressed: () async {
                                            final lat = controller.latController.text;
                                            final lng = controller.longController.text;
                                            if (lat.isEmpty || lng.isEmpty) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text("Missing Location"),
                                                  content: const Text("Location not available. Please set the location first.."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: Text("OK"),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              final Uri mapUrl = Uri.parse("https://www.google.com/maps?q=$lat,$lng");
                                              await launchUrl(mapUrl, mode: LaunchMode.platformDefault);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            _clearText(label, code);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if ( controller.showTextField.value ) ...[
                                  TextField(
                                    controller: controller.latController,
                                    readOnly: true,
                                    style: labelStyle,
                                    decoration:  InputDecoration(
                                      labelText: 'Latitude',
                                      fillColor: isDarkMode ? Colors.black : Colors.white,
                                      labelStyle: labelStyle,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: controller.longController,
                                    readOnly: true,
                                    style: labelStyle,
                                    decoration:  InputDecoration(
                                      labelText: 'Longitude',
                                      fillColor: isDarkMode ? Colors.black : Colors.white,
                                      labelStyle: labelStyle,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ],
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
                          children:
                          controller.childbuttons.where((button) {
                            switch (button.name.toLowerCase()) {
                              case 'list':
                                return controller.isread == 1;
                              case 'delete':
                                return controller.isdelete == 1;
                              case 'update':
                                return controller.isupdate == 1;
                              case 'save':
                                return controller.iscreate == 1 ||
                                    controller.isupdate == 1 &&
                                        widget.formusecaseid !=
                                            ''; // Assuming you have issave for Save button
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
                                        ? const Color(0xFF4F76E2)
                                        : const Color(0xFF1A237E),
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Center(
                                  child: Text(
                                    button.name.toUpperCase(),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ?const Color(0xFF4F76E2)
                                          :const Color(0xFF1A237E),
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
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )),
          );
        },
      )),
    );
  }

  Widget _buildImageWidget(var controller, String code) {
    String uploadedImage = controller.uploadDocument[code]?.toString() ?? "0";

    if (uploadedImage.isNotEmpty && uploadedImage != "0") {
      return CachedNetworkImage(
        imageUrl:
        "https://cuickdev.com/API/DOCS/api/doc/th/$uploadedImage?t=${DateTime.now().millisecondsSinceEpoch}",
        placeholder: (context, url) =>const CircularProgressIndicator(),
        errorWidget: (context, url, error) =>const Icon(Icons.error),
      );
    }

    String initialImage = controller.getInitialValue(code)?.toString() ?? "0";

    if (initialImage.isNotEmpty && initialImage != "0") {
      return CachedNetworkImage(
        imageUrl:
        "https://cuickdev.com/API/DOCS/api/doc/th/$initialImage?t=${DateTime.now().millisecondsSinceEpoch}",
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) =>const Icon(Icons.error),
      );
    }

    return CachedNetworkImage(
      imageUrl:
      "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }

  Widget _buildImageshowWidget(var controller, String code) {
    String uploadedImagedata = controller.uploadimage[code]?.toString() ?? "0";
    String initialImage = controller.getInitialValue(code)?.toString() ?? "0";

    if (uploadedImagedata.isNotEmpty && uploadedImagedata != "0") {
      return CachedNetworkImage(
        imageUrl:
        "https://cuickdev.com/API/DOCS/api/doc/th/$uploadedImagedata?t=${DateTime.now().millisecondsSinceEpoch}",
        placeholder: (context, url) =>const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else if (initialImage.isNotEmpty && initialImage != "0") {
      return CachedNetworkImage(
        imageUrl:
        "https://cuickdev.com/API/DOCS/api/doc/th/$initialImage?t=${DateTime.now().millisecondsSinceEpoch}",
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      return CachedNetworkImage(
        imageUrl:
        "https://cuickdev.com/API/DOCS/api/doc/th/0?t=${DateTime.now().millisecondsSinceEpoch}",
        placeholder: (context, url) =>const CircularProgressIndicator(),
        errorWidget: (context, url, error) =>const Icon(Icons.error),
      );
    }
  }
}
