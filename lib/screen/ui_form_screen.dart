import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/Uiform_controller.dart';
import 'package:cuickdevuser/screen/Menucontroller.dart';
import 'package:cuickdevuser/screen/onboding/components/camera_capture_page.dart';
import 'package:cuickdevuser/screen/utility.dart';
import 'package:cuickdevuser/service/apihelper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../controller/WelcomeController.dart';
import '../controller/tableview_controller.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../service/DBHelper.dart';
import 'package:path/path.dart' as path;
import 'package:cuickdevuser/components/constants.dart';

class UiFormScreen extends StatefulWidget {
  final String appurl;
  final String menutitle;
  final String formID;
  final int iscreate;
  final int isread;
  final int isdelete;
  final int isupdate;

  const UiFormScreen({
    super.key,
    required this.appurl,
    required this.menutitle,
    required this.formID,
    required this.iscreate,
    required this.isread,
    required this.isdelete,
    required this.isupdate,
  });

  @override
  State<UiFormScreen> createState() => _UiFormScreenState();
}

class _UiFormScreenState extends State<UiFormScreen> {

  
         String _formatDisplayValue(String value) {
    if (value.isEmpty) return '';

    double? numValue = double.tryParse(value);
    if (numValue != null) {
      if (numValue == numValue.roundToDouble()) {
        return numValue.round().toString();
      } else {
        String formatted = numValue.toStringAsFixed(3);
        return _removeTrailingZeros(formatted);
      }
    }
    return value;
  }


    // Sabse pehle method declare karein

   
     String _removeTrailingZeros(String value) {
    if (value.isEmpty) return '';
    if (!value.contains('.')) return value;

    value = value.replaceAll(RegExp(r'0+$'), '');
    if (value.endsWith('.')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
                             
                             
  String formatNumber(String value) {
    if (value.isEmpty) return '';

    double? number = double.tryParse(value);
    if (number == null) return value;

    if (number % 1 == 0) {
      return number.toInt().toString(); // 10.0 → 10
    } else {
      return number
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
      // 10.50 → 10.5
      // 10.00 → 10
    }
  }
   
  bool value = ApiBaseHelper.isFromSaveButton; 
  // 🔥 DYNAMIC CALCULATION FUNCTION - YEH USE KAREIN 🔥

 
 bool _wasOffline = false;
bool _isRefreshing = false;
bool _isFirstConnectionCheck = true;
late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final ImageUrlHelper imageUrlHelper = ImageUrlHelper();

  final Uiformcontroller controller =
      Get.put(Uiformcontroller(), permanent: true);
  final ApiBaseHelper helper = ApiBaseHelper();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String fieldvalue = "";
  // int uploadDocument = 0;
  String? selectedValue; // Store selected value
  bool isFormSubmitted = false; // Track form submission status
  int captureimage = 0;
  bool search = false;
  final ImagePicker _picker = ImagePicker();
  String? filePath;
  final Map<String, TextEditingController> _controllers = {};
  List<bool> isSelected = [false, false];
  List<dynamic> comboboxmapValues = [];
  final currentHour = DateTime.now().hour;
  bool _obscureText = true;
  late var result = false;
  bool onsavebuttonclick = false;
  bool isLocationValid = true; // if using setState
  // Map<String, String?>  controller.resulterror = {}; // Store dynamic errors
  Menucontroller menucontroller = Get.put(Menucontroller());
  final TableviewController viewcontroller = Get.put(TableviewController());
  Future<Map<String, dynamic>?> SaveFormWithimage() async {
    controller.isLoading.value = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    String applicationRoleId = prefs.getString("applicationRoleId") ?? '';
    if (sessionId.isEmpty) {
      // debugPrint("Session ID is missing.");
    }
    Map<String, dynamic> reqBody = {
      'id': controller.saveform_id.value
    }; // Add the 'id' field first
    for (var field in controller.labellist) {
      var fieldValue = controller.getFieldValue(field['label']) ?? '';
      if (controller.uploadimage != null && controller.uploadimage.isNotEmpty) {
        // Inject uploaded image IDs
        controller.uploadimage.forEach((code, imageId) {
          if (imageId != null && imageId.toString().isNotEmpty) {
            reqBody[code] = imageId;
          }
        });
      }
      if (controller.uploadDocument != null &&
          controller.uploadDocument.isNotEmpty) {
        controller.uploadDocument.forEach((code, docId) {
          if (docId != null && docId.toString().isNotEmpty) {
            reqBody[code] = docId;
          }
        });
      }

      if (field['type'] == 'location') {
        // Handle string type (wrong format)
        if (fieldValue.contains('lat') && fieldValue.contains('lng')) {
          final latLngPattern =
              RegExp(r'lat\s*:\s*([\d.]+)\s*,\s*lng\s*:\s*([\d.]+)');
          final match = latLngPattern.firstMatch(fieldValue);
          if (match != null) {
            final lat = double.tryParse(match.group(1)!);
            final lng = double.tryParse(match.group(2)!);
            if (lat != null && lng != null) {
              reqBody[field['code'].toString()] = {
                'lat': lat,
                'lng': lng,
              };
            }
          }
        }

        // Handle correct map format
        else if (fieldValue is Map &&
            fieldValue.contains('lat') &&
            fieldValue.contains('lng')) {
          reqBody[field['code'].toString()] = {
            'lat': fieldValue,
            'lng': fieldValue,
          };
        }
      }
      if (field['type'] == 'combobox') {
        var newValue = controller.getFieldValue(field['label']);

        // Check if newValue is not null or empty
        if (newValue != null && newValue.toString().trim().isNotEmpty) {
          // Add to combobox map and save if it's not already there
          if (!comboboxmapValues.contains(newValue)) {
            comboboxmapValues.add(newValue);
            await controller.Savecomboitem(widget.formID, comboboxmapValues);
          } else {
            await controller.Savecomboitem(widget.formID, comboboxmapValues);
          }
          // Add valid newValue to reqBody
          reqBody[field['code'].toString()] = newValue;
        }
      }

      // Handle other fields
      else if (fieldValue.toString().isNotEmpty) {
        reqBody[field['code'].toString()] = fieldValue;
      }
    }

    // 🌐 check internet
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;
    if (isOnline) {
      try {
        late final response;

        if (controller.isuserFilter != 1) {
          response = await helper.postApi(
            "api/v1/${controller.appCode.value}/${controller.code.value}/${controller.saveformcode.value.toString()}/saveForm;jsessionid=$sessionId",
            reqBody,
          );
        } else {
          response = await helper.postApi(
            "api/v1/${controller.appCode.value}/${controller.code.value}/${controller.saveformcode.value.toString()}/saveForm/$applicationRoleId;jsessionid=$sessionId",
            reqBody,
          );
        }
        if (response != null && response['success'] == true) {
          setState(() {
            controller.saveform_id.value = response['result']['data']['id'];
          });

          showToast();

          return response;
        } else {
          return response;
        }
      } catch (e) {
        // no internet -> save offline
        Map<String, String> offlineDocPaths = {};

        for (String code in controller.docPaths.keys) {
          String? filePath = controller.docPaths[code];

          if (filePath != null && File(filePath).existsSync()) {
            final originalFile = File(filePath);
            final appDocDir = await getApplicationDocumentsDirectory();
            final newFilePath =
                path.join(appDocDir.path, path.basename(filePath));

            await originalFile.copy(newFilePath);
            offlineDocPaths[code] = newFilePath;
          }
        }

        Map<String, String> offlineImagePaths = {};

        for (String code in controller.imagePaths.keys) {
          String? filePath = controller.imagePaths[code];

          if (filePath != null && File(filePath).existsSync()) {
            final originalFile = File(filePath);
            final appDocDir = await getApplicationDocumentsDirectory();
            final newFilePath =
                path.join(appDocDir.path, path.basename(filePath));

            await originalFile.copy(newFilePath);
            offlineImagePaths[code] = newFilePath;
          }
        }
        await DBHelper().insertForm(
          title: widget.menutitle,
          type: "FormType",
          formData: reqBody,
          appCode: controller.appCode.value,
          code: controller.code.value,
          saveformcode: controller.saveformcode.value,
          imagePaths: offlineImagePaths,
          // docpath: offlineDocPaths
        );

        return {'message': 'Saved offline due to API error'};
      } finally {
        controller.isLoading.value = false; // ✅ Stop loader
      }
    } else {
      // no internet -> save offline
      Map<String, String> offlineDocPaths = {};

      for (String code in controller.docPaths.keys) {
        String? filePath = controller.docPaths[code];
        if (filePath != null && File(filePath).existsSync()) {
          final originalFile = File(filePath);
          final appDocDir = await getApplicationDocumentsDirectory();
          final newFilePath =
              path.join(appDocDir.path, path.basename(filePath));

          await originalFile.copy(newFilePath);
          offlineDocPaths[code] = newFilePath;
        }
      }
      Map<String, String> offlineImagePaths = {};

      for (String code in controller.imagePaths.keys) {
        String? filePath = controller.imagePaths[code];

        if (filePath != null && File(filePath).existsSync()) {
          final originalFile = File(filePath);
          final appDocDir = await getApplicationDocumentsDirectory();
          final newFilePath =
              path.join(appDocDir.path, path.basename(filePath));
          await originalFile.copy(newFilePath);
          offlineImagePaths[code] = newFilePath;
        }
      }
      await DBHelper().insertForm(
        title: widget.menutitle,
        type: "FormType",
        formData: reqBody,
        appCode: controller.appCode.value,
        code: controller.code.value,
        saveformcode: controller.saveformcode.value,
        imagePaths: offlineImagePaths,
        // docpath: offlineDocPaths
      );
      // debugPrint("No internet -> saved offline");
      showToastResult("No internet. Saved offline.");
      return {'message': 'Saved offline due to no internet'};
    }
  }
// ====================================================
// COMPLETE SAVE FORM CODE - NO DUPLICATE TOASTS
// ====================================================

  /// 📌 MAIN SAVE FORM FUNCTION
  Future<Map<String, dynamic>?> SaveForm() async {
    print("🚀 SaveForm STARTED");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    String applicationRoleId = prefs.getString("applicationRoleId") ?? '';

    if (sessionId.isEmpty) {
      print("⚠ Session ID is missing");
    }

    /// =======================
    /// REQUEST BODY INIT
    /// =======================
    Map<String, dynamic> reqBody = {
      'id': controller.saveform_id.value,
    };

    print("🧾 Initial Payload => $reqBody");

    /// =======================
    /// FIELD LOOP + VALIDATION
    /// =======================
    for (var field in controller.labellist) {
      final String label = field['label'].toString();
      final String code = field['code'].toString();
      final String type = field['type'].toString();

      dynamic fieldValue = controller.getFieldValue(label);

      print(
          "🔍 FIELD CHECK => Label:$label | Code:$code | Type:$type | Value:$fieldValue");

      /// ---------- NULL / EMPTY VALIDATION ----------
      if (fieldValue == null || fieldValue.toString().trim().isEmpty) {
        print("❌ VALIDATION FAILED");
        print("➡ Field Label : $label");
        print("➡ Field Code  : $code");
        print("➡ Field Type  : $type");
        continue;
      }

      /// ---------- IDATE SPECIAL CASE ----------
      if (type == 'idate') {
        fieldValue = fieldValue ??
            controller.getFieldValue('IDate') ??
            controller.dataMap[code];

        print("📅 IDATE FINAL VALUE => $fieldValue");

        if (fieldValue == null || fieldValue.toString().isEmpty) {
          print("❌ IDATE STILL EMPTY => $code");
          continue;
        }
      }

      /// ---------- LOCATION ----------
      if (type == 'location') {
        if (fieldValue is String &&
            fieldValue.contains('lat') &&
            fieldValue.contains('lng')) {
          final match = RegExp(r'lat\s*:\s*([\d.]+)\s*,\s*lng\s*:\s*([\d.]+)')
              .firstMatch(fieldValue);

          if (match != null) {
            reqBody[code] = {
              'lat': double.parse(match.group(1)!),
              'lng': double.parse(match.group(2)!),
            };
            print("📍 Location Parsed => ${reqBody[code]}");
          } else {
            print("❌ Invalid location format => $fieldValue");
          }
        } else if (fieldValue is Map &&
            fieldValue.containsKey('lat') &&
            fieldValue.containsKey('lng')) {
          reqBody[code] = fieldValue;
        }
        continue;
      }

      /// ---------- COMBOBOX ----------
      if (type == 'combobox') {
        if (!comboboxmapValues.contains(fieldValue)) {
          comboboxmapValues.add(fieldValue);
        }
        await controller.Savecomboitem(widget.formID, comboboxmapValues);
        reqBody[code] = fieldValue;
        continue;
      }

      /// ---------- DEFAULT ----------
      reqBody[code] = fieldValue;
    }

    print("✅ FINAL PAYLOAD => $reqBody");

    /// =======================
    /// INTERNET CHECK
    /// =======================
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isOnline = connectivityResult != ConnectivityResult.none;

    /// =======================
    /// OFFLINE SAVE - NO INTERNET
    /// =======================
    if (!isOnline) {
      // 🔥 FLAG SET for save button
      ApiBaseHelper.isFromSaveButton = true;
      return await _saveOffline(reqBody);
    }

    /// =======================
    /// ONLINE SAVE
    /// =======================
    try {
      // 🔥 FLAG SET for save button
      ApiBaseHelper.isFromSaveButton = true;

      print("🌐 INTERNET AVAILABLE");

      final response = controller.isuserFilter != 1
          ? await helper.postApi(
              "api/v1/${controller.appCode.value}/${controller.code.value}/${controller.saveformcode.value}/saveForm;jsessionid=$sessionId",
              reqBody,
            )
          : await helper.postApi(
              "api/v1/${controller.appCode.value}/${controller.code.value}/${controller.saveformcode.value}/saveForm/$applicationRoleId;jsessionid=$sessionId",
              reqBody,
            );

      print("📥 API RESPONSE => $response");

      if (response != null && response['success'] == true) {
        controller.saveform_id.value = response['result']['data']['id'];

        bool hasImages =
            controller.imagePaths.values.any((p) => p != null && p.isNotEmpty);
        bool hasDocs =
            controller.docPaths.values.any((p) => p != null && p.isNotEmpty);

        if (hasImages || hasDocs) {
          await submitFormWithConditionalUploads();
        } else {
          // ✅ ONLINE SUCCESS TOAST
          showToast();
        }

        // 🔥 FLAG RESET
        ApiBaseHelper.isFromSaveButton = false;
        return response;
      }

      // 🔥 FLAG RESET - API success false
      ApiBaseHelper.isFromSaveButton = false;
      return response;
    } catch (e) {
      print("❌ API ERROR => $e");
      // ⚠️ FLAG RESET YAHAN MAT KARO - offline save ke baad hoga
      return await _saveOffline(reqBody);
    }
  }

  /// 📌 OFFLINE SAVE HELPER FUNCTION - SIRF EK TOAST
  Future<Map<String, dynamic>> _saveOffline(
      Map<String, dynamic> reqBody) async {
    print("📴 OFFLINE MODE - SAVING LOCALLY");

    Map<String, String> offlineImagePaths = {};
    Map<String, String> offlineDocPaths = {};

    // 📸 Copy image files to app documents directory
    for (var entry in controller.imagePaths.entries) {
      if (entry.value != null && File(entry.value!).existsSync()) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(entry.value!);
          final newPath = path.join(dir.path,
              'offline_images_${DateTime.now().millisecondsSinceEpoch}_$fileName');
          await File(entry.value!).copy(newPath);
          offlineImagePaths[entry.key] = newPath;
          print("✅ Image copied: $newPath");
        } catch (e) {
          print("❌ Error copying image file: $e");
        }
      }
    }

    // 📄 Copy document files to app documents directory
    for (var entry in controller.docPaths.entries) {
      if (entry.value != null && File(entry.value!).existsSync()) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(entry.value!);
          final newPath = path.join(dir.path,
              'offline_docs_${DateTime.now().millisecondsSinceEpoch}_$fileName');
          await File(entry.value!).copy(newPath);
          offlineDocPaths[entry.key] = newPath;
          print("✅ Document copied: $newPath");
        } catch (e) {
          print("❌ Error copying document file: $e");
        }
      }
    }

    // 💾 Save to local database
    try {
      await DBHelper().insertForm(
        title: widget.menutitle,
        type: "Offline",
        formData: reqBody,
        appCode: controller.appCode.value,
        code: controller.code.value,
        saveformcode: controller.saveformcode.value,
        imagePaths: offlineImagePaths,
   
      );

      // ✅ SIRF EK TOAST - OFFLINE SUCCESS
      if (mounted) {
        CherryToast.success(
          backgroundColor: const Color(0xFFBCF3BF),
          animationDuration: Durations.short1,
          title: const Text(
            "Form saved offline!",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ).show(context);

        // Form clear karein
        clearFormData();
      }

      print("✅ Offline save successful");

      // 🔥 FLAG RESET - finally mein bhi kar sakte hain
      ApiBaseHelper.isFromSaveButton = false;

      return {'message': 'Saved offline', 'success': true};
    } catch (e) {
      print("❌ Offline save error: $e");

      if (mounted) {
        CherryToast.error(
          backgroundColor: const Color(0xFFF37691),
          animationDuration: Durations.short1,
          title: Text(
            "Error saving offline",
            style: const TextStyle(color: Colors.black),
          ),
        ).show(context);
      }

      // 🔥 FLAG RESET - error case mein bhi
      ApiBaseHelper.isFromSaveButton = false;

      return {'message': 'Offline save failed', 'success': false};
    }
  }



  void handleButtonClick(String buttonType) async {
    if (buttonType == "cancel") {
      controller.saveform_id.value = 0;
      controller.uploadDocument.clear();
      controller.uploadimage.clear();
      controller.imagePaths.clear();
      controller.showTextField.value = false;
      controller.latController.clear();
      controller.longController.clear();
      controller.showTextField.value = false;
      _controllers.clear();
      controller.docPaths.clear();
      setState(() {});
      menucontroller.changeTab(0);
      controller.imagePaths.clear();
      for (var field in controller.labellist) {
        var fieldValue = controller.getFieldValue(field['label']) ?? '';

        if (fieldValue.isNotEmpty && fieldValue != "") {
          controller.imagePaths[field['code']] = null;
          controller.setFieldValue(field['label'], "");
          controller.setInitialValue(field['code'], "");
        }
      }
      controller.clearForm();
      Get.find<TableviewController>().update();
      viewcontroller.GetForm_API(viewcontroller.appurl.value);
      viewcontroller.CurrentPage.value = 0;
    } else if (buttonType == "delete") {
      if (controller.saveform_id.value != 0) {
        showDeleteConfirmationedit();
      }
    } else if (buttonType == "list") {
      setState(() {
        controller.saveform_id.value = 0;
      });
      controller.showTextField.value = false;
      controller.saveform_id.value = 0;
      controller.uploadDocument.clear();
      controller.uploadimage.clear();
      controller.imagePaths.clear();
      controller.docPaths.clear();
      _controllers.clear();
      for (var field in controller.labellist) {
        var fieldValue = controller.getFieldValue(field['label']) ?? '';

        if (fieldValue.isNotEmpty && fieldValue != "") {
          controller.imagePaths[field['code']] = null;
          controller.setFieldValue(field['label'], "");
          controller.setInitialValue(field['code'], "");
        }
      }
      controller.clearForm();
      setState(() {});
      menucontroller.changeTab(0);
      controller.latController.clear();
      controller.longController.clear();
      controller.showTextField.value = false;
      Get.find<TableviewController>().update();
      viewcontroller.GetForm_API(viewcontroller.appurl.value);
      viewcontroller.CurrentPage.value = 0;
    } else if (buttonType == "new") {
      controller.imagePaths.clear();
      controller.docPaths.clear();
      controller.showTextField.value = false;
      controller.clearForm();
      _controllers.clear();
      controller.saveform_id.value = 0;
      setState(() {});
    }
  }

  Future<void> submitFormWithConditionalUploads() async {
    try {
      bool hasImages =
          controller.imagePaths.values.any((path) => path!.isNotEmpty);
      bool hasDocs = controller.docPaths.values.any((path) => path!.isNotEmpty);

      String tempFormId = controller.saveform_id.value.toString();

      Future<bool> imageFuture = Future.value(true);
      Future<bool> docFuture = Future.value(true);

      if (hasImages) {
        imageFuture = uploadAllImagesAfterFormSave(tempFormId);
      }

      if (hasDocs) {
        docFuture = uploadDeferredDocuments(tempFormId);
      }

      List<bool> results = await Future.wait([imageFuture, docFuture]);

      bool imageUploadSuccess = results[0];
      bool docUploadSuccess = results[1];

      // Step 3: If uploads successful, save the form
      if (imageUploadSuccess && docUploadSuccess) {
        var formResponse =
            await SaveFormWithimage(); // Your final save with updated IDs

        if (formResponse != null &&
            formResponse['result']?['data']?['id'] != null) {
          controller.saveform_id.value = formResponse['result']['data']['id'];
        } else {
          CherryToast.error(
            backgroundColor: const Color(0xFFF37691),
            animationDuration: Durations.short1,
            title: const Text("Form save failed after uploads!",
                style: TextStyle(color: Colors.black)),
          ).show(Get.overlayContext!);
        }
      } else {
        CherryToast.error(
          backgroundColor: const Color(0xFFF37691),
          animationDuration: Durations.short1,
          title: const Text("File upload failed. Form not saved.",
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
      }
    } catch (e) {}
  }

  Future<bool> uploadAllImagesAfterFormSave(String formId) async {
    bool allSuccess = true;

    List<Future<void>> uploadTasks = [];

    for (String code in controller.imagePaths.keys) {
      String? filePath = controller.imagePaths[code];
      if (filePath != null &&
          filePath.isNotEmpty &&
          File(filePath).existsSync()) {
        File file = File(filePath);
        uploadTasks.add(
          _uploadImage(XFile(file.path), code, formId).catchError((e) {
            allSuccess = false;
          }),
        );
      }
    }

    await Future.wait(uploadTasks);
    return allSuccess;
  }

  Future<bool> uploadDeferredDocuments(String formId) async {
    bool allSuccess = true;

    List<Future<void>> uploadTasks = [];

    for (String id in controller.docPaths.keys) {
      String? filePath = controller.docPaths[id];

      if (filePath != null &&
          filePath.isNotEmpty &&
          File(filePath).existsSync()) {
        File file = File(filePath);
        uploadTasks.add(
          _uploadFile(file, id, formId).catchError((e) {
            allSuccess = false;
            print('❌ Error uploading doc $id: $e');
          }),
        );
      }
    }

    await Future.wait(uploadTasks);
    return allSuccess;
  }

  Future<void> _pickAndUploadImage(String code) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    // Get file timestamp
    final fileStat = await imageFile.stat();
    final DateTime timestamp = fileStat.modified; // or .changed or .accessed

    // String formattedTime = DateFormat('yyyy-MM-dd hh:mm:ss a').format(timestamp);
    String formattedTime =
        DateFormat('dd-MM-yyyy hh:mm:ss a').format(timestamp);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image uploading on ${formattedTime}'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    int imageSizeInBytes = await imageFile.length();
    int quality = 80; // Start with good quality
    const int minQuality = 20;
    // Keep compressing until size is <= 512KB or quality drops below minimum
    while (imageSizeInBytes > 512000 && quality >= minQuality) {
      imageFile = await compressImage(imageFile, quality);
      imageSizeInBytes = await imageFile.length();
      setState(() {
        controller.imagePaths[code] = imageFile.path;
      });
    }

    if (imageSizeInBytes > 512000) {
      // If image is still too big, show popup to select another image

      _showImageTooLargeDialog();
      return;
    }

    // setState(() {
    //   controller.imagePaths[code] = imageFile.path;
    // });

    final XFile compressedXFile = XFile(imageFile.path);
    // await _uploadImage(compressedXFile, code);
  }

  Future<File> compressImage(File imageFile, int quality) async {
    final int originalSize = await imageFile.length();

    final result = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: quality,
      minWidth: 400,
      // Set the target width
      minHeight: 600,
      // Set a minimum height to help maintain aspect ratio
      keepExif: true,
      autoCorrectionAngle: true,
      // Optional: keep image metadata
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }

    // Save the compressed image back to the same file or a new file
    final compressedFile = File(imageFile.path)..writeAsBytesSync(result);
    final int compressedSize = await compressedFile.length();

    return compressedFile;
  } 

  String formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";

    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024)
      return "${(bytes / 1024).toStringAsFixed(decimals)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(decimals)} MB";
  }

  void _showImageTooLargeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Image Too Large"),
          content: const Text(
              "The selected image is too large to upload, even after compression. Please choose a smaller image."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
Future<void> getImage1(String fieldCode) async {
    try {
      final String? imagePath = await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const CameraCapturePage(),
        ),
      );

      if (imagePath == null || !mounted) return;

      File imageFile = File(imagePath);

      // 🔥 OPTIONAL: final size log
      debugPrint(
          'Final image size: ${(imageFile.lengthSync() / 1024).toStringAsFixed(2)} KB');

      setState(() {
        controller.imagePaths[fieldCode] = imageFile.path;
      });
    } catch (e, s) {
      debugPrint('Camera error: $e');
      debugPrintStack(stackTrace: s);
    }
  }


  Future<void> _uploadImage(
      XFile pickedFile, String code, String formid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      return;
    }
    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.appCode.value}/${controller.code.value}/doc/${formid}/0/$code;jsessionid=$sessionId');

    var request = http.MultipartRequest('POST', uri);
    File imageFile = File(pickedFile.path);

    var file = await http.MultipartFile.fromPath('file', imageFile.path);

    request.files.add(file);

    var response = await request.send();

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
      } catch (e) {}
    } else {
      CherryToast.error(
        backgroundColor: const Color(0xFFF37691),
        animationDuration: Durations.short1,
        title: const Text('Failed to upload the file!',
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
    }
  }

  void showToastResult(String teXt) {
    CherryToast.success(
      backgroundColor: const Color(0xFFBCF3BF),
      animationDuration: Durations.short1,
      title: Text(teXt, style: TextStyle(color: Colors.black)),
    ).show(context);

    if (menucontroller.currentIndex.value == 0) {
      setState(() {
        controller.resulterror.clear(); // Clear errors if success
      });
      controller.clearForm();
      _controllers.clear();
      setState(() {});
      menucontroller.changeTab(0);
      Get.find<TableviewController>().update();
      viewcontroller.GetForm_API(viewcontroller.appurl.value);
      viewcontroller.CurrentPage.value = 0;
      controller.imagePaths.clear();
      for (var field in controller.labellist) {
        var fieldValue = controller.getFieldValue(field['label']) ?? '';

        if (fieldValue.isNotEmpty && fieldValue != "") {
          controller.imagePaths[field['code']] = null;
          controller.setFieldValue(field['label'], "");
          controller.setInitialValue(field['code'], "");
        }
      }

      for (var group in controller.grouplabellist) {
        var allFields = controller.getGroupsField(group.label);
        for (var field in allFields) {
          controller.setFieldValue(field['label'], "");
          controller.setInitialValue(field['code'], "");
        }
      }
    }
  }

  void showToast() {
    CherryToast.success(
      backgroundColor: const Color(0xFFBCF3BF),
      animationDuration: Durations.short1,
      title: const Text("Form saved successfully!",
          style: TextStyle(color: Colors.black)),
    ).show(context);
    clearFormData();
  }

  void clearFormData() {
    if (controller.saveform_id.value != 0) {
      setState(() {
        controller.saveform_id.value = 0;
      });
    }

    setState(() {
      controller.saveform_id.value = 0;
    });
    controller.imagePaths.clear();
    controller.docPaths.clear();
    controller.showTextField.value = false;
    controller.clearForm();
    _controllers.clear();

    menucontroller.changeTab(0);
    controller.update();

    setState(() {});
  }

  void showDeleteConfirmationedit() {
    Get.dialog(
      AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () {
              // JUST CLOSE THE DIALOG, NO EXTRA NAVIGATION!
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              viewcontroller.deletelistitem(
                  widget.appurl,
                  widget.menutitle,
                  controller.saveform_id.value.toString(),
                  viewcontroller.CurrentPage.value,
                  10);
              for (var field in controller.labellist) {
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
              controller.clearForm();
              for (var field in controller.labellist) {
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
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
    controller.saveform_id.value = 0;
    _initData();
     _setupConnectivityListener();
    
  }
void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> resultList) async {
      // Prevent multiple simultaneous refresh attempts
      if (_isRefreshing) return;

      try {
        final result =
            resultList.isNotEmpty ? resultList.first : ConnectivityResult.none;
        bool isOnline = result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi;

        debugPrint(
            '🌐 Connectivity changed: isOnline=$isOnline, _wasOffline=$_wasOffline, _isFirstConnectionCheck=$_isFirstConnectionCheck');

        // Case 1: First connection check - just set the flag
        if (_isFirstConnectionCheck) {
          _wasOffline = !isOnline;
          _isFirstConnectionCheck = false;
          debugPrint('📱 First connection check: wasOffline=$_wasOffline');
          return;
        }

        // Case 2: Internet just came back from offline state
        if (isOnline && _wasOffline) {
          debugPrint('🔄 Internet RESTORED - Refreshing form data');

          _isRefreshing = true;
          _wasOffline = false;


          await _refreshFormData();

          _isRefreshing = false;
        }
        // Case 3: Internet just went offline
        else if (!isOnline && !_wasOffline) {
          debugPrint('📴 Internet LOST');
          _wasOffline = true;

          if (mounted) {
           
          }
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error in connectivity listener: $e');
        debugPrintStack(stackTrace: stackTrace);
        _isRefreshing = false;
      }
    });
  }

Future<void> _refreshFormData() async {
    // Check mounted before starting async operation
    if (!mounted) return;

    try {
      await controller.GetForm_API(widget.formID);

      // Check mounted again after API call
      if (!mounted) return;

      await controller.updateappurl(
          widget.menutitle.toLowerCase(), widget.appurl);

      // Reset default values
      for (var field in controller.labellist) {
        // Check mounted for each iteration if it's a long loop
        if (!mounted) break;

        String label = field['label'];
        String fieldType = field['type'];
        int defaultToCurrentDate = field['defaultToCurrentDate'] ?? 0;
        int defaultToCurrentTime = field['defaultToCurrentTime'] ?? 0;

        if (fieldType == 'date' && defaultToCurrentDate == 1) {
          final String currentDate =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          controller.setFieldValue(label, currentDate);
        }

        if (fieldType == 'time' && defaultToCurrentTime == 1) {
          final String currentTime = DateFormat('HH:mm').format(DateTime.now());
          controller.setFieldValue(label, currentTime);
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      debugPrint('Error refreshing form: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing form: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// ✅ Method to refresh form data

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
    _controllers.clear();
  }
  Future<void> _syncOfflineForm(Map<String, dynamic> form) async {
    try {
      // Reconstruct the request body
      Map<String, dynamic> reqBody = Map.from(form['formData']);

      // Prepare image uploads if any
      Map<String, String> imagePaths = Map.from(form['imagePaths'] ?? {});
      Map<String, String> docPaths = Map.from(form['docpaths'] ?? {});

      // Save the form online
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String sessionId = prefs.getString('jsessionid') ?? '';
      String applicationRoleId = prefs.getString("applicationRoleId") ?? '';

      final response = await helper.postApi(
        "api/v1/${form['appCode']}/${form['code']}/${form['saveformcode']}/saveForm;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        String savedFormId = response['result']['data']['id'].toString();

        // Upload images if any
        if (imagePaths.isNotEmpty) {
          for (var entry in imagePaths.entries) {
            if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
              await _uploadImage(XFile(entry.value), entry.key, savedFormId);
            }
          }
        }

        // Upload documents if any
        if (docPaths.isNotEmpty) {
          for (var entry in docPaths.entries) {
            if (entry.value.isNotEmpty && File(entry.value).existsSync()) {
              await _uploadFile(File(entry.value), entry.key, savedFormId);
            }
          }
        }

        // Delete from local DB after successful sync
        await DBHelper().deleteForm(form['id']);
      }
    } catch (e) {
      debugPrint('Error syncing form: $e');
    }
  }

void _initData() async {
    try {
      // Check initial connectivity
      var connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;

      debugPrint('📱 Initial connectivity: isOnline=$isOnline');

      // Set initial offline flag
      _wasOffline = !isOnline;
      _isFirstConnectionCheck = false;

      // Load data
      await controller.getuser_role_access(widget.formID);
      await controller.GetForm_API(widget.formID);
      await controller.updateappurl(
          widget.menutitle.toLowerCase(), widget.appurl);

      // If offline, show message
      if (!isOnline && mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('You are offline. Working in offline mode.'),
        //     backgroundColor: Colors.orange,
        //     duration: Duration(seconds: 3),
        //   ),
        // );
      }
    } catch (e) {
      debugPrint('❌ Error in _initData: $e');
    }
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
      type: FileType
          .any, // Change this to `FileType.custom` for specific file types
    );

    if (pickedFile != null && pickedFile.files.single.path != null) {
      filePath = pickedFile.files.single.path!; // Update observable
      setState(() {
        controller.docPaths[id] = filePath!;
      });
      File file = File(filePath!);
      // await _uploadFile(file, id);
    } else {
      CherryToast.info(
        backgroundColor: const Color(0xFFFACA4F),
        animationDuration: Durations.short1,
        title: const Text("No file selected!",
            style: TextStyle(color: Colors.black)),
      ).show(context);
    }
  }

  Future<void> _uploadFile(File pickedFile, String id, String formId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      Get.snackbar("Session Error", "Please log in again.");
      return;
    }
    int uploadDocumentId = (controller.uploadDocument[id] ?? 0) as int;

    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.appCode.value}/${controller.code.value}/doc/${formId}/$uploadDocumentId/$id;jsessionid=$sessionId');

    var request = http.MultipartRequest('POST', uri);
    request.fields['id'] = widget.formID; // Add your id here
    request.files
        .add(await http.MultipartFile.fromPath('file', pickedFile.path));
    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        try {
          var jsonResponse = jsonDecode(responseBody);
          var dataValue = jsonResponse['result']['data'][id];
          if (dataValue is int) {
            dataValue = dataValue.toString();
          }
          setState(() {
            controller.uploadDocument[id] = dataValue;
          });
        } catch (e) {
          print('❌ e.$e');
        }
      } else {
        CherryToast.error(
          backgroundColor: const Color(0xFFF37691),
          animationDuration: Durations.short1,
          title: const Text('Failed to upload the file!',
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
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

  void updateResult(Map<String, String> reqBody, String showvalue) {
    setState(() {
      result = controller.evaluateCondition(reqBody, showvalue);
    });
  }

  void setCurrentLocation(String code) async {
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
        return;
      }
    }

    LocationData position = await location.getLocation();
    double? lat = position.latitude;
    double? lng = position.longitude;

    if (lat != null && lng != null) {
      var locationMap = {'lat': lat, 'lng': lng};
      controller.setFieldValue(code, locationMap.toString());

      setState(() {
        _controllers[code]!.text = lat.toString() ?? '';
        _controllers[code]!.text = lng.toString() ?? '';
        controller.latController.text = lat.toString() ?? '';
        controller.longController.text = lng.toString() ?? '';
        controller.showTextField.value = true;
        isLocationValid = false;
      });
    } else {
      print('❌ Failed to get location coordinates.');
    }
  }

  void _clearText(String label) {
    setState(() {
      controller.latController.clear();
      controller.longController.clear();
      controller.showTextField.value = false;
      controller.setFieldValue(label, ""); // clear stored map
    });
  }

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentTime = DateFormat('hh:mm a').parse(
      DateFormat('hh:mm a').format(now),
    );

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final labelStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
      fontSize: 15,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(

  
        backgroundColor: isDarkMode ? Colors.black : Colors.white,

      
        body: WillPopScope(  
                onWillPop: () async {
            // Check internet connection
            var connectivityResult = await Connectivity().checkConnectivity();
            bool isOnline = connectivityResult != ConnectivityResult.none;

            if (!isOnline) {
              // Show "No Internet" toast
              if (mounted) {
                CherryToast.error(
                  backgroundColor: const Color(0xFFF37691),
                  animationDuration: Durations.short1,
                  title: const Text(
                    "No Internet Connection",
                    style: TextStyle(color: Colors.black),
                  ),
                ).show(context);
              }
              // Return false to prevent back navigation
              return false;
            }

            // If online, allow back navigation
            return true;
          },
          child: Stack(children: [
            AbsorbPointer(
              absorbing: controller.isLoading.value,
              child: SingleChildScrollView(child: Obx(
                () {
                const List<String> fieldOrder = [
                    'date',
                    'time',
                    'itime',
                    'idate',
                    'dateandtime',
                    'datetime',
                  ];
          
                  int getFieldSortIndex(String fieldType) {
                    final index = fieldOrder.indexOf(fieldType);
                    return index == -1 ? fieldOrder.length : index;
                  }
          
                  // ✅ 1. मुख्य लिस्ट सॉर्ट करें
                  List<dynamic> sortedLabellist = List.from(controller.labellist)
                    ..sort((a, b) {
                      final aType = a['type']?.toString() ?? '';
                      final bType = b['type']?.toString() ?? '';
                      return getFieldSortIndex(aType)
                          .compareTo(getFieldSortIndex(bType));
                    });
          
                  // ✅ 2. ग्रुप के बिना वाले items सॉर्ट करें
                  var itemsWithoutGroup = controller.getItemsWithoutGroup();
                  List<dynamic> sortedItemsWithoutGroup =
                      List.from(itemsWithoutGroup)
                        ..sort((a, b) {
                          final aType = a['type']?.toString() ?? '';
                          final bType = b['type']?.toString() ?? '';
                          return getFieldSortIndex(aType)
                              .compareTo(getFieldSortIndex(bType));
                        });
          
          
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    child: Column(children: [
              Form(
                          key: _formKey,
                          child: controller.grouplabellist.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10),
                                  child: Column(
                                    children: [
                             ...sortedLabellist.map((field) {
                                        String label = field['label'];
                                        String code = field['code'];
                                        String fieldType = field['type'];
                                        bool isRequired = field['required'] == 1;
                                        bool isRefKey = field['refKey'] == 1;
                                        bool primaryUsecase =
                                            field['primaryUsecase'] != "";
                                        bool showDropdown =
                                            primaryUsecase && isRefKey;
                                        String yUsecase =
                                            field['primaryUsecase'] ?? "";
                                        String showvalue = field['show'] ?? "";
                                        String event = field['event'] ?? "";
                                        String rule = field['rule'] ?? "";
          
                                        int captureImage =
                                            field['captureImage'] ?? 0;
                                        Map<String, String> reqBody = {};
                                        int defaultToCurrentDate =
                                            field['defaultToCurrentDate'] ?? 0;
          
                                        String minDateStr =
                                            field['minDate'] ?? "";
                                        String maxDateStr =
                                            field['maxDate'] ?? "";
                                        int readOnly = field['readOnly'] ?? 0;
                                        for (var field in controller.labellist) {
                                          String fieldValue = controller
                                                  .getFieldValue(field['label'])
                                                  ?.toString() ??
                                              '';
                                          reqBody[field['code'].toString()] =
                                              fieldValue;
                                        }
          
                                        final result =
                                            controller.evaluateCondition(
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
          
                                        // final controllerValue =  (controller.getInitialValue(code) ?? "").toString();
                                        // if (_controllers.containsKey(label) && _controllers[label]!.text.isEmpty &&
                                        //     controllerValue != null &&
                                        //     controllerValue.toString().isNotEmpty) {
                                        //   _controllers[label]!.text = controllerValue.toString();
                                        // }
          
                            if (fieldType == 'text' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                errorText: controller
                                                    .resulterror[code],
                                                labelStyle: labelStyle,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.text,
                                              onChanged: (value) {
                                                setState(() {
                                                  // 1. Set the value
                                                  controller.setFieldValue(
                                                      label, value);
                                                  controller.dataMap[
                                                      field['code']] = value;

                                                  // 2. Update ALL expression fields
                                                  controller
                                                      .updateAllExpressionFields();
                                                });
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }
                                                final regexPattern =
                                                    field['regex'];
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                          );
                                        }
                                        if (fieldType == 'object' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                errorText:
                                                    controller.resulterror[code],
                                                labelStyle: labelStyle,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.text,
                                              onChanged: (value) {
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
                                            ),
                                          );
                                        }
                                        if (fieldType == 'location' && result) {
                                          final locationMap =
                                              controller.getFieldValue(label);
                                          if (locationMap != null &&
                                              locationMap is Map) {
                                            controller.latController.text =
                                                locationMap[0].toString() ?? '';
                                            controller.longController.text =
                                                locationMap[1].toString() ?? '';
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  label,
                                                  style: labelStyle,
                                                ),
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey,
                                                          width: 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons.location_on,
                                                              color:
                                                                  Appcolorblue),
                                                          onPressed: () {
                                                            setCurrentLocation(
                                                                label);
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons
                                                                  .remove_red_eye,
                                                              color:
                                                                  Appcolorblue),
                                                          onPressed: () async {
                                                            final lat = controller
                                                                .latController
                                                                .text
                                                                .trim();
                                                            final lng = controller
                                                                .longController
                                                                .text
                                                                .trim();
          
                                                            if (lat.isEmpty ||
                                                                lng.isEmpty) {
                                                              showDialog(
                                                                context: context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      "Missing Location"),
                                                                  content: const Text(
                                                                      "Location not available. Please set the location first.."),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.pop(
                                                                              context),
                                                                      child: Text(
                                                                          "OK"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            } else {
                                                              final Uri mapUrl =
                                                                  Uri.parse(
                                                                      "https://www.google.com/maps?q=$lat,$lng");
                                                              await launchUrl(
                                                                  mapUrl,
                                                                  mode: LaunchMode
                                                                      .platformDefault);
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.delete,
                                                              color: Colors.red),
                                                          onPressed: () {
                                                            _clearText(label);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (controller
                                                    .showTextField.value) ...[
                                                  TextFormField(
                                                    controller:
                                                        controller.latController,
                                                    readOnly: true,
                                                    style: labelStyle,
                                                    decoration: InputDecoration(
                                                      labelText: 'Latitude',
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      labelStyle: labelStyle,
                                                      border:
                                                          const OutlineInputBorder(),
                                                    ),
                                                    validator: isRequired
                                                        ? (value) {
                                                            if (value == null ||
                                                                value.isEmpty) {
                                                              return 'Please enter latitude';
                                                            }
                                                            return null;
                                                          }
                                                        : null,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  TextFormField(
                                                    controller:
                                                        controller.longController,
                                                    readOnly: true,
                                                    style: labelStyle,
                                                    decoration: InputDecoration(
                                                      labelText: 'Longitude',
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      labelStyle: labelStyle,
                                                      border:
                                                          const OutlineInputBorder(),
                                                    ),
                                                    validator: isRequired
                                                        ? (value) {
                                                            if (value == null ||
                                                                value.isEmpty) {
                                                              return 'Please enter longitude';
                                                            }
                                                            return null;
                                                          }
                                                        : null,
                                                  ),
                                                ],
                                                (onsavebuttonclick &&
                                                        (isRequired &&
                                                                controller
                                                                    .longController
                                                                    .text
                                                                    .isEmpty ||
                                                            controller
                                                                .latController
                                                                .text
                                                                .isEmpty))
                                                    ? const Text(
                                                        "Location is Required",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      )
                                                    : SizedBox()
                                              ],
                                            ),
                                          );
                                        }
                                        if (fieldType == 'email' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              style: labelStyle,
                                              controller: _controllers[label],
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType:
                                                  TextInputType.emailAddress,
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
                                            ),
                                          );
                                        }
                                        if (fieldType == 'textarea' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
          
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelStyle: labelStyle,
                                                labelText: label,
                                                errorText:
                                                    controller.resulterror[code],
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.multiline,
                                              maxLines: 3,
                                              // You can set this to null for unlimited lines
                                              onChanged: (value) {
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
                                            ),
                                          );
                                        }
                                        if (showDropdown && result) {
                                          final dropdownItems =
                                              controller.prelaodlist[yUsecase] ??
                                                  [];
          
                                          // Filter out any null items or items with a null 'id' before mapping
                                          final validDropdownItems = dropdownItems
                                              .where((item) =>
                                                  item != null &&
                                                  item['id'] != null)
                                              .toList();
          
                                          final dropdownValues =
                                              validDropdownItems
                                                  .map((item) =>
                                                      item['id'].toString())
                                                  .toSet();
          
                                          final currentValue =
                                              controller.getFieldValue(label);
                                          final dropdownValue = dropdownValues
                                                  .contains(currentValue)
                                              ? currentValue
                                              : null;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5.0,
                                            ),
                                            child:
                                                DropdownButtonFormField<String>(
                                              isExpanded: true,
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
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                                hintText:
                                                    'Select $label', // Placeholder hint text
                                              ),
                                              value: dropdownValue,
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: null,
                                                  // Placeholder value
                                                  child: Text(
                                                    'Select an $label',
                                                    maxLines: 1,
                                                    style: labelStyle,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                // Use the filtered list to create the dropdown items
                                                ...validDropdownItems.map<
                                                        DropdownMenuItem<String>>(
                                                    (item) {
                                                  return DropdownMenuItem<String>(
                                                    value: item['id'].toString(),
                                                    child: Text(
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      // Use a null-aware operator just in case '_val' is null
                                                      item['_val']?.toString() ??
                                                          '',
                                                      style: labelStyle,
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            
                                              onChanged: readOnly != 1
                                                  ? (value) async {
                                                      controller.onChange(
                                                          field, value);
                                                      if (event != "") {
                                                        await controller
                                                            .GetUserData(code,
                                                                rule, value!);
                                                        controller.admissionId =
                                                            value;
                                                        setState(() {
                                                          controller
                                                              .setFieldValue(
                                                                  label, value);
                                                        });
                                                      } else {
                                                        controller.setFieldValue(
                                                            label, value);
                                                      }
                                                    }
                                                  : null,
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
//                                         if ((fieldType == 'number' || fieldType == 'decimal') && result) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 5.0),
//     child: TextFormField(
//       style: labelStyle,
//       enabled: readOnly != 1,
//       readOnly: readOnly == 1,
//       controller: _controllers[label],
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: labelStyle,
//         errorText: controller.resulterror[code],
//         fillColor: isDarkMode ? Colors.black : Colors.white,
//         border: OutlineInputBorder(
//           borderSide: BorderSide(color: Appcolorblue),
//         ),
//       ),
//       keyboardType: TextInputType.number,
//       onChanged: (value) {
//         print('📝 Number field $label = $value');
//
//         // 1. Value set करें
//         controller.setFieldValue(label, value);
//         controller.dataMap[field['code']] = value;
//
//         // 2. 🔥 सिर्फ expression fields update करें - manual calculation नहीं
//         controller.updateAllExpressionFields();
//
//         setState(() {});
//       },
//       validator: (value) {
//         if (isRequired && (value == null || value.isEmpty)) {
//           return 'Please enter $label';
//         }
//         final regexPattern = field['regex'];
//         if (regexPattern != null && value != null && value.isNotEmpty) {
//           final regex = RegExp(regexPattern);
//           if (!regex.hasMatch(value)) {
//             return 'Invalid input for $label';
//           }
//         }
//         return null;
//       },
//     ),
//   );
// }

                                  if ((fieldType == 'number' ||
                                                fieldType == 'long' ||
                                                fieldType == 'decimal' ||
                                                fieldType == 'phone') &&
                                            result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText: controller
                                                    .resulterror[code],
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                // Leave Without Pay field (number/decimal type)
if (label == 'Leave Without Pay') {

        print('📝 Leave Without Pay changed: $value');
        
      controller.setFieldValue(label, value);
        controller.dataMap[field['code']] = value;
        controller.dataMap['leave'] = value;
        controller.dataMap['LeaveWithoutPay'] = value;
        
    
}
  

                                                if (label == 'Salary' || label == 'Salay') {

    print('💰 Salary field changed: $value');
    
    controller.setFieldValue(label, value);
    controller.dataMap[field['code']] = value;
    
    // Store in both possible locations
    controller.dataMap['salary'] = value;
    controller.dataMap['Salay'] = value;
    
    // Force expression recalculation
    controller.updateAllExpressionFields();
    
    setState(() {});
  
}
                                                // 🔥 DEBUG PRINT 1 - Input value
                                                print(
                                                    '🔴===== NUMBER/DECIMAL FIELD INPUT =====');
                                                print('📝 Field Label: $label');
                                                print('📝 Field Code: $code');
                                                print(
                                                    '📝 Input Value: "$value"');
                                                print(
                                                    '📝 Field Type: $fieldType');

                                                // Controller mein value set karein
                                                controller.setFieldValue(
                                                    label, value);
                                                controller.dataMap[
                                                    field['code']] = value;

                                                // 🔥 DEBUG PRINT 2 - After setting in controller
                                                print(
                                                    '📝 Value set in controller: "${controller.getFieldValue(label)}"');
                                                print(
                                                    '📝 Value set in dataMap: "${controller.dataMap[field['code']]}"');

                                                // ✅ Dono expression fields ko update karein
                                                print(
                                                    '🔄 Calling updateAllExpressionFields...');
                                                controller
                                                    .updateAllExpressionFields();
                                                    

                                                // UI update ke liye setState
                                                setState(() {});

                                                print('🔴===== END =====\n');
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }

                                                final regexPattern =
                                                    field['regex'];
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                          );
                                        }
if (fieldType == 'expression') {
  return Obx(() {
    String displayValue = '';
    
    // Get value based on label
    if (label == 'Working Days In Month') {
      displayValue = controller.workingDays.value;
    } else if (label == 'Per Day Salary') {
      displayValue = controller.perDaySalary.value;
    } else if (label == 'Net Salary') {
      displayValue = controller.netSalary.value;
    } else {
      displayValue = controller.getFieldValue(label) ?? '';
    }
    
    // If empty, try dataMap
    if (displayValue.isEmpty) {
      displayValue = controller.dataMap[field['code']]?.toString() ?? '';
    }
    
    // 🔥 FIX: Remove trailing zeros after decimal
    if (displayValue.contains('.')) {
      // Remove trailing zeros
      displayValue = displayValue.replaceAll(RegExp(r'0+$'), '');
      // If decimal point is at the end, remove it too
      displayValue = displayValue.replaceAll(RegExp(r'\.$'), '');
    }
    
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5.0),
      child: TextFormField(
        controller: TextEditingController(text: displayValue),
        readOnly: true,
        style: labelStyle,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          fillColor: Colors.grey[200],
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Appcolorblue),
          ),
        ),
      ),
    );
  });
}
// 🔥 Helper method for 3 decimal places
String _formatToThreeDecimals(String value) {
  if (value.isEmpty) return '';
  
  try {
    // Parse to double
    double? numValue = double.tryParse(value);
    
    if (numValue != null) {
      // अगर पूर्णांक है (जैसे 23, 500)
      if (numValue == numValue.roundToDouble()) {
        return numValue.round().toString();
      } 
      // अगर दशमलव है तो 3 decimals
      else {
        return numValue.toStringAsFixed(3);
      }
    }
    
    return value;
  } catch (e) {
    print('⚠️ Format error: $e');
    return value;
  }
}
// Helper method for formatting
                                 
// Add this helper method in your State class
                                     
                               if (fieldType == 'time' && result) {
                                          // Helper function to convert between 24-hour and AM/PM format
                                          String convert24HourToAmPm(
                                              String time24) {
                                            try {
                                              if (time24.isEmpty) return '';
                                              time24 = time24.trim();
          
                                              // Check if already in AM/PM format
                                              if (time24
                                                      .toUpperCase()
                                                      .contains('AM') ||
                                                  time24
                                                      .toUpperCase()
                                                      .contains('PM')) {
                                                return time24;
                                              }
          
                                              List<String> parts =
                                                  time24.split(':');
                                              if (parts.length != 2)
                                                return time24;
          
                                              int hour =
                                                  int.tryParse(parts[0]) ?? 0;
                                              int minute = int.tryParse(
                                                      parts[1].split(' ')[0]) ??
                                                  0;
          
                                              // Validate hour and minute
                                              if (hour < 0 ||
                                                  hour > 23 ||
                                                  minute < 0 ||
                                                  minute > 59) {
                                                return time24;
                                              }
          
                                              String period =
                                                  hour >= 12 ? 'PM' : 'AM';
                                              int hour12 = hour % 12;
                                              if (hour12 == 0) hour12 = 12;
          
                                              return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
                                            } catch (e) {
                                              return time24;
                                            }
                                          }
          
                                          // Helper function to convert AM/PM to 24-hour format
                                          String convertAmPmTo24Hour(
                                              String timeAmPm) {
                                            try {
                                              if (timeAmPm.isEmpty) return '';
                                              timeAmPm = timeAmPm.trim();
          
                                              // Check if already in 24-hour format (contains only numbers and colon)
                                              if (!timeAmPm
                                                      .toUpperCase()
                                                      .contains('AM') &&
                                                  !timeAmPm
                                                      .toUpperCase()
                                                      .contains('PM')) {
                                                return timeAmPm; // Already in 24-hour format
                                              }
          
                                              // Parse AM/PM format (hh:mm AM/PM)
                                              final timePart =
                                                  timeAmPm.split(' ')[0];
                                              final period = timeAmPm
                                                  .split(' ')[1]
                                                  .toUpperCase();
          
                                              final parts = timePart.split(':');
                                              if (parts.length != 2)
                                                return timeAmPm;
          
                                              int hour =
                                                  int.tryParse(parts[0]) ?? 0;
                                              int minute =
                                                  int.tryParse(parts[1]) ?? 0;
          
                                              // Convert to 24-hour format
                                              if (period == 'PM' && hour != 12) {
                                                hour += 12;
                                              } else if (period == 'AM' &&
                                                  hour == 12) {
                                                hour = 0;
                                              }
          
                                              return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                                            } catch (e) {
                                              return timeAmPm;
                                            }
                                          }
          
                                          // Get stored value (should be in HH:mm format)
                                          String storedTime =
                                              controller.getFieldValue(label) ??
                                                  '';
          
                                          // Convert stored time from 24-hour to display format (AM/PM)
                                          String displayTime = '';
                                          if (storedTime.isNotEmpty) {
                                            displayTime =
                                                convert24HourToAmPm(storedTime);
                                          }
          
                                          int defaultToCurrentTime =
                                              field['defaultToCurrentTime'] ?? 0;
          
                                          // Create controller for this field
                                          String fieldCode =
                                              field['code'] ?? label;
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                            () => TextEditingController(
                                                text: displayTime),
                                          );
          
                                          // Set default value if empty and defaultToCurrentTime is enabled
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              defaultToCurrentTime == 1) {
                                            // Get current time
                                            DateTime now = DateTime.now();
          
                                            // Create display time in AM/PM format
                                            String displayTimeInAmPm =
                                                DateFormat('hh:mm a').format(now);
          
                                            // Create storage time in 24-hour format
                                            String storageTimeIn24Hour =
                                                DateFormat('HH:mm').format(now);
          
                                            // Save in 24-hour format
                                            controller.setFieldValue(
                                                label, storageTimeIn24Hour);
          
                                            // Update controller with AM/PM display
                                            _controllers[fieldCode]!.text =
                                                displayTimeInAmPm;
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              style: labelStyle,
                                              controller: _controllers[fieldCode],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelStyle: labelStyle,
                                                labelText: label,
                                                suffixIcon: readOnly != 1
                                                    ? Icon(
                                                        Icons.access_time,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      )
                                                    : null,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      TimeOfDay initialTime =
                                                          TimeOfDay.now();
          
                                                      // Set initial time from current display value if available
                                                      if (_controllers[fieldCode]!
                                                          .text
                                                          .isNotEmpty) {
                                                        try {
                                                          String
                                                              currentDisplayTime =
                                                              _controllers[
                                                                      fieldCode]!
                                                                  .text;
          
                                                          // Convert display time (AM/PM) to TimeOfDay
                                                          String timePart =
                                                              currentDisplayTime
                                                                  .split(' ')[0];
                                                          String period =
                                                              currentDisplayTime
                                                                  .split(' ')[1]
                                                                  .toUpperCase();
          
                                                          List<String> parts =
                                                              timePart.split(':');
                                                          if (parts.length == 2) {
                                                            int hour =
                                                                int.tryParse(
                                                                        parts[
                                                                            0]) ??
                                                                    0;
                                                            int minute =
                                                                int.tryParse(
                                                                        parts[
                                                                            1]) ??
                                                                    0;
          
                                                            // Convert to 24-hour for TimeOfDay
                                                            if (period == 'PM' &&
                                                                hour != 12) {
                                                              hour += 12;
                                                            } else if (period ==
                                                                    'AM' &&
                                                                hour == 12) {
                                                              hour = 0;
                                                            }
          
                                                            initialTime =
                                                                TimeOfDay(
                                                                    hour: hour,
                                                                    minute:
                                                                        minute);
                                                          }
                                                        } catch (e) {
                                                          print(
                                                              'Error parsing initial time: $e');
                                                        }
                                                      }
          
                                                      TimeOfDay? selectedTime =
                                                          await showTimePicker(
                                                        context: context,
                                                        initialTime: initialTime,
                                                        builder:
                                                            (context, child) {
                                                          return MediaQuery(
                                                            data: MediaQuery.of(
                                                                    context)
                                                                .copyWith(
                                                              alwaysUse24HourFormat:
                                                                  false, // AM/PM mode enable
                                                            ),
                                                            child: child!,
                                                          );
                                                        },
                                                      );
          
                                                      if (selectedTime != null) {
                                                        final now =
                                                            DateTime.now();
                                                        final dateTime = DateTime(
                                                          now.year,
                                                          now.month,
                                                          now.day,
                                                          selectedTime.hour,
                                                          selectedTime.minute,
                                                        );
          
                                                        // ✅ DISPLAY: AM/PM format में
                                                        String
                                                            formattedDisplayTime =
                                                            DateFormat('hh:mm a')
                                                                .format(dateTime);
          
                                                        // ✅ STORAGE: HH:mm format में
                                                        String storageTime =
                                                            DateFormat('HH:mm')
                                                                .format(dateTime);
          
                                                        setState(() {
                                                          // Save in controller (24-hour format में)
                                                          controller
                                                              .setFieldValue(
                                                                  label,
                                                                  storageTime);
                                                          // Update display text (AM/PM format में)
                                                          _controllers[fieldCode]!
                                                                  .text =
                                                              formattedDisplayTime;
                                                        });
                                                      }
                                                    }
                                                  : null,
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
                                          // Set current date if defaultToCurrentDate is 1 and field is empty
                                          if (defaultToCurrentDate == 1 &&
                                              (controller.getFieldValue(label) ==
                                                      null ||
                                                  controller
                                                      .getFieldValue(label)!
                                                      .isEmpty)) {
                                            final String currentDate =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(DateTime.now());
          
                                            controller.setFieldValue(
                                                label, currentDate);
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 2.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              // disables input if readOnly == 1
                                              style: labelStyle,
                                              controller: TextEditingController(
                                                text: controller
                                                    .getFieldValue(label),
                                              ),
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                suffixIcon: readOnly != 1
                                                    ? Icon(
                                                        Icons.calendar_today,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      )
                                                    : null,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      DateTime? selectedDate;
                                                      if (minDateStr.isEmpty &&
                                                          maxDateStr.isEmpty) {
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
                                                      } else {
                                                        DateTime minDate =
                                                            DateTime.parse(
                                                                minDateStr);
                                                        DateTime maxDate =
                                                            DateTime.parse(
                                                                maxDateStr);
                                                        DateTime initial =
                                                            DateTime.now();
                                                        if (initial
                                                            .isBefore(minDate)) {
                                                          initial = minDate;
                                                        } else if (initial
                                                            .isAfter(maxDate)) {
                                                          initial = maxDate;
                                                        }
                                                        selectedDate =
                                                            await showDatePicker(
                                                          context: context,
                                                          initialDate: initial,
                                                          firstDate: minDate,
                                                          lastDate: maxDate,
                                                        );
                                                      }
          
                                                      if (selectedDate != null) {
                                                        // String formattedDate = "${selectedDate.toLocal()}".split(' ')[0];
                                                        String formattedDate =
                                                            DateFormat(
                                                                    'yyyy-MM-dd')
                                                                .format(
                                                                    selectedDate);
                                                        if (event != "") {
                                                          var response = await controller
                                                              .validateAndSubmitDate(
                                                                  rule,
                                                                  formattedDate);
          
                                                          if (response != null &&
                                                              response[
                                                                      'success'] ==
                                                                  false) {
                                                            String errorMessage =
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
                                                            setState(() {
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      formattedDate);
                                                            });
                                                          }
                                                        } else {
                                                          setState(() {
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    formattedDate);
                                                          });
                                                        }
                                                      }
                                                    }
                                                  : null,
          
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
          
                               if (fieldType == 'dateandtime' &&
                                            result) {
                                          // ✅ Field code & label
                                          String fieldCode =
                                              field['code']; // e.g. 'dateTime'
                                          String fieldLabel =
                                              field['label']; // e.g. 'DateTime'
          
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                            () => TextEditingController(),
                                          );
          
                                          // ✅ Prefill if value already exists
                                          String? storedValue = controller
                                              .getFieldValue(fieldLabel);
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              storedValue != null) {
                                            DateTime dt =
                                                DateTime.parse(storedValue)
                                                    .toLocal();
          
                                            // UI display
                                            String displayValue =
                                                DateFormat('yyyy-MM-dd HH:mm')
                                                    .format(dt);
                                            _controllers[fieldCode]!.text =
                                                displayValue;
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              style: labelStyle,
                                              controller: _controllers[fieldCode],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelStyle: labelStyle,
                                                errorText: controller
                                                    .resulterror[fieldCode],
                                                labelText: fieldLabel,
                                                suffixIcon: readOnly != 1
                                                    ? Icon(
                                                        Icons.calendar_today,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      )
                                                    : null,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      // 1️⃣ Pick Date
                                                      DateTime? selectedDate =
                                                          await showDatePicker(
                                                        context: context,
                                                        initialDate:
                                                            DateTime.now(),
                                                        firstDate: DateTime(1900),
                                                        lastDate: DateTime(2100),
                                                      );
          
                                                      if (selectedDate != null) {
                                                        // 2️⃣ Pick Time
                                                        TimeOfDay? selectedTime =
                                                            await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                              TimeOfDay.now(),
                                                        );
          
                                                        if (selectedTime !=
                                                            null) {
                                                          final combinedDateTime =
                                                              DateTime(
                                                            selectedDate.year,
                                                            selectedDate.month,
                                                            selectedDate.day,
                                                            selectedTime.hour,
                                                            selectedTime.minute,
                                                          );
          
                                                          // UI display
                                                          String displayValue =
                                                              DateFormat(
                                                                      'yyyy-MM-dd HH:mm')
                                                                  .format(
                                                                      combinedDateTime);
          
                                                          // ✅ STORAGE → ISO UTC format
                                                          final isoValue =
                                                              combinedDateTime
                                                                  .toUtc()
                                                                  .toIso8601String();
          
                                                          setState(() {
                                                            _controllers[
                                                                        fieldCode]!
                                                                    .text =
                                                                displayValue;
                                                            controller
                                                                .setFieldValue(
                                                                    fieldLabel,
                                                                    isoValue);
                                                          });
                                                        }
                                                      }
                                                    }
                                                  : null,
                                              validator: isRequired
                                                  ? (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please select $fieldLabel';
                                                      }
                                                      return null;
                                                    }
                                                  : null,
                                            ),
                                          );
                                        }
          
                  if (fieldType == 'idate' && result) {
                                          // ✅ Field code & label
                                          String fieldCode =
                                              field['code']; // e.g. 'iDate'
                                          String fieldLabel =
                                              field['label']; // e.g. 'IDate'
          
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                            () => TextEditingController(),
                                          );
          
                                          // ✅ Prefill from datetime (if exists)
                                          if (defaultToCurrentDate == 1 &&
                                              (controller.getFieldValue(fieldLabel) == null ||
                                                  controller.getFieldValue(fieldLabel)!.isEmpty)) {
                                            final now = DateTime.now();
          
                                            // STORAGE → FIXED (UTC MIDNIGHT)
                                            final isoDate = DateTime.utc(now.year, now.month, now.day).toIso8601String();
                                            controller.setFieldValue(fieldLabel, isoDate);
          
                                            // UI display
                                            String displayDate = DateFormat('yyyy-MM-dd').format(now);
                                            _controllers[fieldCode]!.text = displayDate;
                                          }
          
                                          // ✅ Prefill from datetime (if exists)
                                          String? dateTimeValue = controller.getFieldValue('dateTime');
                                          if (_controllers[fieldCode]!.text.isEmpty && dateTimeValue != null) {
                                            DateTime dt = DateTime.parse(dateTimeValue).toLocal();
                                            String displayDate = DateFormat('yyyy-MM-dd').format(dt);
                                            _controllers[fieldCode]!.text = displayDate;
          
                                            final isoDate = DateTime.utc(dt.year, dt.month, dt.day).toIso8601String();
                                            controller.setFieldValue(fieldLabel, isoDate);
                                          }
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              dateTimeValue != null) {
                                            DateTime dt =
                                                DateTime.parse(dateTimeValue)
                                                    .toLocal();
          
                                            // UI display
                                            String displayDate =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(dt);
                                            _controllers[fieldCode]!.text =
                                                displayDate;
          
                                            // ✅ STORAGE → FIXED (UTC MIDNIGHT)
                                            final isoDate = DateTime.utc(
                                              // 🔥 FIX
                                              dt.year,
                                              dt.month,
                                              dt.day,
                                            ).toIso8601String();
          
                                            controller.setFieldValue(
                                                fieldLabel, isoDate);
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              controller: _controllers[fieldCode],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                filled: true,
                                                labelStyle: labelStyle,
                                                labelText: fieldLabel,
                                                suffixIcon: Icon(
                                                  Icons.calendar_today,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      DateTime? pickedDate =
                                                          await showDatePicker(
                                                        context: context,
                                                        initialDate:
                                                            DateTime.now(),
                                                        firstDate: DateTime(1900),
                                                        lastDate: DateTime(2100),
                                                      );
          
                                                      if (pickedDate != null) {
                                                        String displayDate =
                                                            DateFormat(
                                                                    'dd-MM-yyyy')
                                                                .format(
                                                                    pickedDate);
                                                        _controllers[fieldCode]!
                                                            .text = displayDate;
          
                                                        // ✅ STORAGE → FIXED (UTC MIDNIGHT)
                                                        final isoDate =
                                                            DateTime.utc(
                                                          // 🔥 FIX
                                                          pickedDate.year,
                                                          pickedDate.month,
                                                          pickedDate.day,
                                                        ).toIso8601String();
          
                                                        controller.setFieldValue(
                                                            fieldLabel, isoDate);
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          );
                                        }
          
          
                                        if (fieldType == 'itime' && result) {
                                          // ✅ Field code & label
                                          String fieldCode = field['code']; // e.g. 'itime'
                                          String fieldLabel = field['label']; // e.g. 'ITime'
          
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                                () => TextEditingController(),
                                          );
          
                                          int defaultToCurrentTime = field['defaultToCurrentTime'] ?? 0;
          
                                          // ✅ Set default current time if field is empty and defaultToCurrentTime is 1
                                          if (defaultToCurrentTime == 1 &&
                                              (controller.getFieldValue(fieldLabel) == null ||
                                                  controller.getFieldValue(fieldLabel)!.isEmpty)) {
                                            final now = DateTime.now();
          
                                            // ✅ STORAGE → ISO time with fixed date (1970-01-01)
                                            final isoTime = DateTime(1970, 1, 1, now.hour, now.minute).toUtc().toIso8601String();
                                            controller.setFieldValue(fieldLabel, isoTime);
          
                                            // ✅ UI display (AM/PM)
                                            String displayTime = DateFormat('hh:mm a').format(now);
                                            _controllers[fieldCode]!.text = displayTime;
                                          }
          
                                          // ✅ Prefill from dateTime (if exists) - only if controller is empty
                                          String? dateTimeValue = controller.getFieldValue('dateTime');
                                          if (_controllers[fieldCode]!.text.isEmpty && dateTimeValue != null) {
                                            DateTime dt = DateTime.parse(dateTimeValue).toLocal();
          
                                            // UI display (AM/PM)
                                            String displayTime = DateFormat('hh:mm a').format(dt);
                                            _controllers[fieldCode]!.text = displayTime;
          
                                            // ✅ STORAGE → ISO time with fixed date
                                            final isoTime = DateTime(1970, 1, 1, dt.hour, dt.minute).toUtc().toIso8601String();
                                            controller.setFieldValue(fieldLabel, isoTime);
                                          }
          
                                          // ✅ Also check if there's already a value stored for itime field itself
                                          String? storedTimeValue = controller.getFieldValue(fieldLabel);
                                          if (_controllers[fieldCode]!.text.isEmpty && storedTimeValue != null && storedTimeValue.isNotEmpty) {
                                            try {
                                              // Parse the stored ISO time
                                              DateTime dt = DateTime.parse(storedTimeValue).toLocal();
          
                                              // UI display (AM/PM)
                                              String displayTime = DateFormat('hh:mm a').format(dt);
                                              _controllers[fieldCode]!.text = displayTime;
                                            } catch (e) {
                                              print('Error parsing stored itime value: $e');
                                            }
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 5),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              controller: _controllers[fieldCode],
                                              style: labelStyle, // ✅
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white, // ✅
                                                filled: true,
                                                labelStyle: labelStyle, // ✅
                                                labelText: fieldLabel,
                                                suffixIcon: Icon(
                                                  Icons.access_time,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black, // ✅
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                TimeOfDay? pickedTime =
                                                await showTimePicker(
                                                  context: context,
                                                  initialTime:
                                                  TimeOfDay.now(),
                                                  builder:
                                                      (context, child) {
                                                    return MediaQuery(
                                                      data: MediaQuery.of(
                                                          context)
                                                          .copyWith(
                                                        alwaysUse24HourFormat:
                                                        false,
                                                      ),
                                                      child: child!,
                                                    );
                                                  },
                                                );
          
                                                if (pickedTime != null) {
                                                  final now =
                                                  DateTime.now();
                                                  final dt = DateTime(
                                                    now.year,
                                                    now.month,
                                                    now.day,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                  );
          
                                                  String displayTime =
                                                  DateFormat('hh:mm a')
                                                      .format(dt);
                                                  _controllers[fieldCode]!
                                                      .text = displayTime;
          
                                                  final isoTime = DateTime(
                                                    1970,
                                                    1,
                                                    1,
                                                    pickedTime.hour,
                                                    pickedTime.minute,
                                                  )
                                                      .toUtc()
                                                      .toIso8601String();
          
                                                  controller.setFieldValue(
                                                      fieldLabel, isoTime);
                                                }
                                              }
                                                  : null,
                                            ),
                                          );
                                        }
          
if (fieldType == 'list' && result) {
  final List<dynamic> uniqueValues = (field['values'] ?? []).toSet().toList();

  return Obx(() {
    String? selectedValue = controller.getFieldValue(label);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 7),
      child: DropdownButtonFormField<String>(
        style: labelStyle,
        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          fillColor: isDarkMode ? Colors.black : Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Appcolorblue),
          ),
          hintText: 'Select $label',
        ),
        value: selectedValue,
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('Select an $label', style: labelStyle),
          ),
          ...uniqueValues.map<DropdownMenuItem<String>>((value) {
            return DropdownMenuItem<String>(
              value: value.toString(),
              child: Text(value.toString(), style: labelStyle),
            );
          }).toList(),
        ],
        onChanged: readOnly != 1 ? (value) async {
       if (label == 'Non Working Saturday In Month' || 
            label == 'Saturday In Month') {
          // Set for both field names
          controller.setFieldValue('Non Working Saturday In Month', value);
          controller.setFieldValue('Saturday In Month', value);
          controller.dataMap['nonWorkingSaturdayInMonth'] = value;
          controller.dataMap['saturdayInMonth'] = value;
          controller.dataMap['Saturday In Month'] = value;
        } 
        else if (label == 'Sundays In Month') {
          controller.setFieldValue(label, value);
          controller.dataMap['sundaysInMonth'] = value;
        }
        else if (label == 'Days') {
          controller.setFieldValue(label, value);
          controller.dataMap['days'] = value;
        }
        else if (label == 'Salay' || label == 'Salary') {
          controller.setFieldValue('Salay', value);
          controller.setFieldValue('Salary', value);
          controller.dataMap['salay'] = value;
          controller.dataMap['salary'] = value;
        }
        else {
          controller.setFieldValue(label, value);
          controller.dataMap[field['code']] = value;
        }
        
        // Always recalculate
        controller.calculateAllFields();
      
          
          
          // Force UI update
          setState(() {});
        } : null,
     
     
     
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
  });
}
                                        if (fieldType == 'map' && result) {
                                          List<dynamic> mapValues =
                                              field['values'] ?? [];
          
                                          // Create dropdown items
                                          List<DropdownMenuItem<String>>
                                              dropdownItems = [];
          
                                          // Add placeholder first
                                          dropdownItems.add(
                                            DropdownMenuItem<String>(
                                              value:
                                                  '', // empty string for placeholder
                                              child: Text(
                                                'Select $label',
                                                style: labelStyle,
                                              ),
                                            ),
                                          );
          
                                          // Add map values (store key - value together)
                                          dropdownItems.addAll(
                                            mapValues
                                                .map<DropdownMenuItem<String>>(
                                                    (item) {
                                              final String key =
                                                  (item['key'] ?? '').toString();
                                              final String valueText =
                                                  (item['value'] ?? '')
                                                      .toString();
                                              final String combined =
                                                  "$key - $valueText"; // ✅ combined
                                              return DropdownMenuItem<String>(
                                                value:
                                                    combined, // store combined string
                                                child: Text(
                                                  combined, // display combined string
                                                  style: labelStyle,
                                                ),
                                              );
                                            }).toList(),
                                          );
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8),
                                            child:
                                                DropdownButtonFormField<String>(
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
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              value: controller
                                                          .getFieldValue(label)
                                                          ?.isEmpty ??
                                                      true
                                                  ? ''
                                                  : controller
                                                      .getFieldValue(label),
                                              items: dropdownItems,
                                              // Selected item builder
                                              selectedItemBuilder:
                                                  (BuildContext context) {
                                                List<Widget> selectedWidgets = [
                                                  Text(
                                                    'Select $label',
                                                    style: labelStyle,
                                                  ),
                                                ];
                                                selectedWidgets.addAll(
                                                    mapValues.map<Widget>((item) {
                                                  final String key =
                                                      (item['key'] ?? '')
                                                          .toString();
                                                  final String valueText =
                                                      (item['value'] ?? '')
                                                          .toString();
                                                  return Text(
                                                    "$key - $valueText",
                                                    style: labelStyle,
                                                  );
                                                }).toList());
                                                return selectedWidgets;
                                              },
                                              onChanged: readOnly != 1
                                                  ? (value) async {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        controller.setFieldValue(
                                                            label, '');
                                                        controller.admissionId =
                                                            '';
                                                      } else {
                                                        if (event != "") {
                                                          await controller
                                                              .GetUserData(code,
                                                                  rule, value);
                                                          controller.admissionId =
                                                              value;
                                                        }
                                                        setState(() {
                                                          controller.setFieldValue(
                                                              label,
                                                              value); // ✅ stores "1 - a"
                                                        });
                                                      }
                                                    }
                                                  : null,
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
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // File input field
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 8.0),
                                                  child: TextFormField(
                                                    style: labelStyle,
                                                    readOnly: true,
                                                    onTap: () {
                                                      _pickAndUploadFile(code);
                                                    },
                                                    controller:
                                                        TextEditingController(
                                                      text: controller.docPaths[
                                                                  code] !=
                                                              null
                                                          ? controller
                                                              .docPaths[code]!
                                                              .split('/')
                                                              .last
                                                          : '',
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: label,
                                                      labelStyle: labelStyle,
                                                      errorText: controller
                                                          .resulterror[code],
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      border:
                                                          const OutlineInputBorder(
                                                        borderSide: BorderSide(
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
                                                          _pickAndUploadFile(
                                                              code);
                                                        },
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        controller
                                                                .docPaths[code] =
                                                            value;
                                                        controller.setFieldValue(
                                                            label, '0');
                                                        controller
                                                            .setInitialValue(
                                                                label, '0');
                                                      });
                                                    },
                                                  ),
                                                ),
          
                                                // File preview
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 16.0),
                                                  child: controller
                                                              .docPaths[code] !=
                                                          null
                                                      ? Image.file(
                                                          File(controller
                                                              .docPaths[code]!),
                                                          width: 100,
                                                          height: 100,
                                                        )
                                                      : GestureDetector(
                                                          onTap: () async {
                                                            final docId =
                                                                _controllers[
                                                                        label]
                                                                    ?.text;
                                                            if (docId != null &&
                                                                docId
                                                                    .isNotEmpty) {
                                                              final Uri testUrl =
                                                                  Uri.parse(
                                                                "https://cuickdev.com/API/DOCS/api/doc/$docId",
                                                              );
                                                              await launchUrl(
                                                                  testUrl);
                                                            }
                                                          },
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl: (_controllers[
                                                                            label]
                                                                        ?.text
                                                                        .isNotEmpty ??
                                                                    false)
                                                                ? "https://cuickdev.com/API/DOCS/api/doc/th/${_controllers[label]!.text}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                                : imageUrlHelper
                                                                    .applogourl,
                                                            width: 100,
                                                            height: 100,
                                                            errorWidget: (context,
                                                                    url, error) =>
                                                                const Icon(Icons
                                                                    .picture_as_pdf), // or Icons.error
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
          
                                        if (fieldType == 'file' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
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
                                                   getImage1(code);
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
                                                          ? controller
                                                              .imagePaths[code]!
                                                              .split('/')
                                                              .last
                                                          : "",
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: label,
                                                      labelStyle: labelStyle,
                                                      errorText: controller
                                                          .resulterror[code],
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      border:
                                                          const OutlineInputBorder(
                                                        borderSide: BorderSide(
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
                                               getImage1(code);
                                                          } else {
                                                            _pickAndUploadImage(
                                                                code);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        controller.imagePaths[
                                                            code] = value;
                                                      });
                                                      controller.setFieldValue(
                                                          label, '0');
                                                      controller.setInitialValue(
                                                          label, '0');
                                                    },
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 16.0),
                                                  child: controller
                                                              .imagePaths[code] !=
                                                          null
                                                      ? Image.file(
                                                          File(controller
                                                              .imagePaths[code]!),
                                                          width: 100,
                                                          height: 100,
                                                        )
                                                      : CachedNetworkImage(
                                                          imageUrl: (_controllers[
                                                                          label]
                                                                      ?.text
                                                                      .isNotEmpty ??
                                                                  false)
                                                              ? "https://cuickdev.com/API/DOCS/api/doc/th/${_controllers[label]!.text}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                              : imageUrlHelper
                                                                  .applogourl,
                                                          width: 100,
                                                          height: 100,
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
          
                                        if (fieldType == 'url' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              decoration: InputDecoration(
                                                errorText:
                                                    controller.resulterror[code],
                                                labelStyle: labelStyle,
                                                labelText: label,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.url,
                                              onChanged: readOnly != 1
                                                  ? (value) {
                                                      controller.setFieldValue(
                                                          label, value);
                                                    }
                                                  : null,
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              obscureText: _obscureText,
                                              decoration: InputDecoration(
                                                errorText:
                                                    controller.resulterror[code],
                                                labelStyle: labelStyle,
                                                labelText: label,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureText
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscureText =
                                                          !_obscureText;
                                                    });
                                                  },
                                                ),
                                              ),
                                              onChanged: (value) {
                                                controller.setFieldValue(
                                                    label, value);
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }
          
                                                final regexPattern = field[
                                                    'regex']; // e.g., "^[1-5]$"
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
          
                                                return null;
                                              },
                                            ),
                                          );
                                        }
          
                                        if (fieldType == 'boolean' && result) {
                                          String? savedValue = controller
                                              .dataMap[field['code']]
                                              .toString();
                                          if (savedValue == '1') {
                                            isSelected = [true, false];
                                          } else if (savedValue == '0') {
                                            isSelected = [false, true];
                                          } else {
                                            isSelected = [false, false];
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 9),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Text(label,
                                                        style: labelStyle)),
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: ToggleButtons(
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                    selectedColor: Colors.white,
                                                    borderColor: isDarkMode
                                                        ? const Color(0xFF4F76E2)
                                                        : const Color(0xFF1A237E),
                                                    fillColor: isDarkMode
                                                        ? const Color(0xFF4F76E2)
                                                        : const Color(0xFF1A237E),
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    isSelected: isSelected,
                                                    onPressed: (index) {
                                                      setState(() {
                                                        for (int i = 0;
                                                            i < isSelected.length;
                                                            i++) {
                                                          isSelected[i] = i ==
                                                              index; // Set the selected index to true
                                                        }
                                                        var selectedValue =
                                                            index == 0 ? 1 : 0;
                                                        String savedValue =
                                                            selectedValue
                                                                .toString();
                                                        setState(() {
                                                          controller.dataMap[
                                                                  field['code']] =
                                                              savedValue;
                                                          controller
                                                              .setFieldValue(
                                                                  label,
                                                                  savedValue);
                                                        });
                                                      });
                                                    },
                                                    children: const [
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric( 
                                                            horizontal: 16),
                                                        child: Text(
                                                          "Yes",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 16),
                                                        child: Text(
                                                          "No",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        if (fieldType == 'combobox' && result) {
                                          comboboxmapValues =
                                              field['values'] ?? [];
                                          List<String> _options =
                                              List<String>.from(
                                            comboboxmapValues.isNotEmpty
                                                ? comboboxmapValues
                                                : [
                                                    'Apple',
                                                    'Banana',
                                                    'Cherry',
                                                    'Date'
                                                  ],
                                          );
          
                                          List<String> _filteredOptions =
                                              List.from(_options);
          
                                          return StatefulBuilder(
                                            builder: (context, setInnerState) {
                                              void _saveValue(String value) {
                                                controller
                                                        .dataMap[field['code']] =
                                                    value;
                                                controller.setFieldValue(
                                                    label, value);
                                              }
          
                                              void _onTextChanged(String value) {
                                                _saveValue(value);
                                                setInnerState(() {
                                                  _filteredOptions = _options
                                                      .where((item) => item
                                                          .toLowerCase()
                                                          .contains(value
                                                              .toLowerCase()))
                                                      .toList();
                                                });
                                              }
          
                                              void _onItemSelected(String value) {
                                                _controllers[label]!.text = value;
                                                _saveValue(value);
                                                FocusScope.of(context).unfocus();
                                                setInnerState(() {
                                                  _filteredOptions = _options;
                                                });
                                              }
          
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0),
                                                child: TextField(
                                                  controller: _controllers[label],
                                                  enabled: readOnly != 1,
                                                  // disable input if readOnly
                                                  onChanged: readOnly != 1
                                                      ? _onTextChanged
                                                      : null,
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    labelText: 'Select a $label',
                                                    suffixIcon: readOnly != 1
                                                        ? PopupMenuButton<String>(
                                                            icon: const Icon(Icons
                                                                .arrow_drop_down),
                                                            itemBuilder:
                                                                (context) {
                                                              return _filteredOptions
                                                                  .map((String
                                                                      option) {
                                                                return PopupMenuItem<
                                                                    String>(
                                                                  value: option,
                                                                  child: Text(
                                                                      option,
                                                                      style:
                                                                          labelStyle),
                                                                );
                                                              }).toList();
                                                            },
                                                            onSelected:
                                                                _onItemSelected,
                                                          )
                                                        : null,
                                                    // Hide dropdown icon if read-only
                                                    border:
                                                        const OutlineInputBorder(),
                                                  ),
                                                ),
                                              );
                                            },
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
                                              controller.buttons.where((button) {
                                            switch (button.name.toLowerCase()) {
                                              case 'list':
                                                return widget.isread == 1;
                                              case 'delete':
                                                return widget.isdelete == 1;
                                              case 'update':
                                                return widget.isupdate == 1;
                                              case 'save':
                                                return widget.iscreate ==
                                                    1; // Assuming you have issave for Save button
                                              case 'new':
                                                return widget.iscreate == 1;
                                              case 'cancel':
                                                return widget.iscreate == 1;
                                              default:
                                                return true; // Hide button if it doesn't match any case
                                            }
                                          }).map((button) {
                                            return GestureDetector(
                                              onTap: () async {
                                                if (button.name.toLowerCase() ==
                                                    'save') {
                                                  if (isSaving)
                                                    return; // 🛑 Prevent multiple submissions
          
                                                  setState(() {
                                                    onsavebuttonclick = true;
                                                    isSaving = true;
                                                  });
          
                                                  if (_formKey.currentState
                                                          ?.validate() ??
                                                      false) {
                                                    Map<String, dynamic>?
                                                        response =
                                                        await SaveForm();
          
                                                    if (response != null &&
                                                        response['success']) {
                                                      setState(() {
                                                        controller.saveform_id
                                                                .value =
                                                            response['result']
                                                                ['data']['id'];
                                                      });
          
                                                      // Optional: show success toast
                                                    } else {
                                                      var inputError =
                                                          response?['result']
                                                              ['inputerror'];
                                                      setState(() {
                                                        controller.resulterror
                                                            .clear();
          
                                                        if (inputError != null) {
                                                          inputError.forEach(
                                                              (key, value) {
                                                            controller
                                                                    .resulterror[
                                                                key] = value;
                                                            CherryToast.error(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFFF8D0D9),
                                                              animationDuration:
                                                                  Durations
                                                                      .short1,
                                                              title: const Text(
                                                                  "Error Saving Form",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black)),
                                                            ).show(Get
                                                                .overlayContext!);
                                                          });
                                                        } else {
                                                          print(
                                                              'No input error found in response');
                                                        }
                                                      });
                                                    }
                                                  }
          
                                                  setState(() {
                                                    isSaving =
                                                        false; // ✅ Re-enable button after save attempt
                                                  });
                                                } else {
                                                  // Other buttons
                                                  handleButtonClick(
                                                      button.name.toLowerCase());
                                                }
                                              },
          
                                              // {
                                              //   handleButtonClick(
                                              //       button.name.toLowerCase());
                                              // },
                                              child: Opacity(
                                                opacity:
                                                    (button.name.toLowerCase() ==
                                                                'save' &&
                                                            isSaving)
                                                        ? 0.5
                                                        : 1.0,
                                                child: Container(
                                                  height: 45,
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (button.name.toLowerCase() ==
                                                                    'save' &&
                                                                isSaving)
                                                            ? Colors.grey.shade300
                                                            : null,
                                                    border: Border.all(
                                                      color: isDarkMode
                                                          ? const Color(
                                                              0xFF4F76E2)
                                                          : const Color(
                                                              0xFF1A237E),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      button.name.toUpperCase(),
                                                      style: TextStyle(
                                                        color: isDarkMode
                                                            ? const Color(
                                                                0xFF4F76E2)
                                                            : const Color(
                                                                0xFF1A237E),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Lato',
                                                        fontSize: 15,
                                                      ),
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
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (controller.grouplabellist.isNotEmpty)
                                        ...controller.grouplabellist
                                            .where((field) {
                                          try {
                                            final startTimeStr =
                                                '${field.allowedTimeStart ?? '12:00'} ${field.allowedTimeStartMeridian ?? 'AM'}';
                                            final endTimeStr =
                                                '${field.allowedTimeEnd ?? '11:59'} ${field.allowedTimeEndMeridian ?? 'PM'}';
          
                                            final startTime =
                                                DateFormat('hh:mm a')
                                                    .parse(startTimeStr);
                                            final endTime = DateFormat('hh:mm a')
                                                .parse(endTimeStr);
          
                                            return currentTime
                                                    .isAfter(startTime) &&
                                                currentTime.isBefore(endTime);
                                          } catch (e) {
                                            // If parsing fails, show the field by default
                                            return true;
                                          }
                                        }).map((field) {
                                          var filteredFields = controller
                                              .getGroupsField(field.label);
          
                                          return filteredFields.isNotEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10.0,
                                                          vertical: 8),
                                                  child: SizedBox(
                                                    child: InputDecorator(
                                                      decoration: InputDecoration(
                                                        labelText: field.label,
                                                        labelStyle: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 19,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        fillColor: isDarkMode
                                                            ? Colors.black
                                                            : Colors.white,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10.0),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          ...filteredFields
                                                              .map((field) {
                                                            // print('=====grup==labellist===========');
                                                            String label =
                                                                field['label'];
                                                            String code =
                                                                field['code'];
                                                            String fieldType =
                                                                field['type'];
          
                                                            bool isRequired =
                                                                field['required'] ==
                                                                    1;
                                                            int defaultToCurrentDate =
                                                                field['defaultToCurrentDate'] ??
                                                                    0;
                                                            int defaultToCurrentTime =
                                                                field['defaultToCurrentTime'] ??
                                                                    0;
                                                           int readOnly = field[
                                                                    'readOnly'] ??
                                                                0;
                                                            bool isRefKey =
                                                                field['refKey'] ==
                                                                    1;
                                                            bool primaryUsecase =
                                                                field['primaryUsecase'] !=
                                                                    "";
                                                            String? showvalue =
                                                                field.containsKey(
                                                                        "show")
                                                                    ? field[
                                                                        "show"]
                                                                    : null;
                                                            String event =
                                                                field['event'] ??
                                                                    "";
                                                            String rule =
                                                                field['rule'] ??
                                                                    "";
                                                            bool showDropdown =
                                                                primaryUsecase &&
                                                                    isRefKey;
                                                            String yUsecase =
                                                                field['primaryUsecase'] ??
                                                                    "";
                                                            String minDateStr =
                                                                field['minDate'] ??
                                                                    "";
                                                            String maxDateStr =
                                                                field['maxDate'] ??
                                                                    "";
                                                            String parentfilter =
                                                                field['parentFilter'] ??
                                                                    "";
                                                            int captureImage =
                                                                field['captureImage'] ??
                                                                    0;
                                                            if (parentfilter !=
                                                                    "" &&
                                                                parentfilter
                                                                    .isNotEmpty) {
                                                              // controller.addParentFilter();
                                                            }
          
                                                            Map<String, String>
                                                                reqBody = {};
                                                            for (var group
                                                                in controller
                                                                    .grouplabellist) {
                                                              var allFields = controller
                                                                  .getGroupsField(
                                                                      group
                                                                          .label);
                                                              for (var field
                                                                  in allFields) {
                                                                String fieldValue = controller
                                                                        .getFieldValue(
                                                                            field[
                                                                                'label'])
                                                                        ?.toString() ??
                                                                    '';
                                                                reqBody[field[
                                                                            'code']
                                                                        .toString()] =
                                                                    fieldValue;
                                                              }
                                                            }
          
                                                            final result = controller
                                                                .evaluateCondition(
                                                                    reqBody,
                                                                    showvalue!);
          
                                                            if (field['system'] ==
                                                                1) {
                                                              return const SizedBox
                                                                  .shrink();
                                                            }
          
                                                            _controllers.putIfAbsent(
                                                                label,
                                                                () =>
                                                                    TextEditingController());
          
                                                            _controllers[label]!
                                                                .text = (controller
                                                                        .getInitialValues(
                                                                            field[
                                                                                'code'],
                                                                            label) ??
                                                                    "")
                                                                .toString();
          
                                                            // final controllerValue = controller.getFieldValue(label);
                                                            // if (_controllers.containsKey(label) &&
                                                            //     _controllers[label]!.text.isEmpty &&
                                                            //     controllerValue != null &&
                                                            //     controllerValue.toString().isNotEmpty) {
                                                            //   _controllers[label]!.text = controllerValue.toString();
                                                            // }
          
                                                            if (fieldType ==
                                                                    'text' &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    TextFormField(
                                                                  style:
                                                                      labelStyle,
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    border: OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue)),
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .text,
                                                                  onChanged:
                                                                      (value) async {
                                                                    if (event !=
                                                                        "") {
                                                                      await controller
                                                                          .GetUserData(
                                                                              code,
                                                                              rule,
                                                                              value);
                                                                      setState(
                                                                          () {
                                                                        controller
                                                                                .dataMap[
                                                                            field[
                                                                                'code']] = value;
          
                                                                        controller.setFieldValue(
                                                                            label,
                                                                            value);
                                                                        updateResult(
                                                                            reqBody,
                                                                            showvalue);
                                                                      });
                                                                    } else {
                                                                      setState(
                                                                          () {
                                                                        controller
                                                                                .dataMap[
                                                                            field[
                                                                                'code']] = value;
                                                                        controller.setFieldValue(
                                                                            label,
                                                                            value);
                                                                        updateResult(
                                                                            reqBody,
                                                                            showvalue);
                                                                      });
                                                                    }
                                                                  },
                                                                  validator:
                                                                      (value) {
                                                                    if (isRequired &&
                                                                        (value ==
                                                                                null ||
                                                                            value
                                                                                .isEmpty)) {
                                                                      return 'Please enter $label';
                                                                    }
          
                                                                    final regexPattern =
                                                                        field[
                                                                            'regex']; // e.g., "^[1-5]$"
                                                                    if (regexPattern !=
                                                                            null &&
                                                                        value !=
                                                                            null &&
                                                                        value
                                                                            .isNotEmpty) {
                                                                      final regex =
                                                                          RegExp(
                                                                              regexPattern);
                                                                      if (!regex
                                                                          .hasMatch(
                                                                              value)) {
                                                                        return 'Invalid input for $label';
                                                                      }
                                                                    }
          
                                                                    return null;
                                                                  },
                                                                  // validator: isRequired
                                                                  //     ? (value) {
                                                                  //         if (value ==
                                                                  //                 null ||
                                                                  //             value
                                                                  //                 .isEmpty) {
                                                                  //           return 'Please enter $label';
                                                                  //         }
                                                                  //         return null;
                                                                  //       }
                                                                  //     : null,
                                                                ),
                                                              );
                                                            }
                                                            if (fieldType ==
                                                                    'email' &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    TextFormField(
                                                                  style:
                                                                      labelStyle,
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    border: OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue)),
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .emailAddress,
                                                                  onChanged:
                                                                      (value) async {
                                                                    setState(() {
                                                                      controller
                                                                              .dataMap[
                                                                          field[
                                                                              'code']] = value;
                                                                      controller
                                                                          .setFieldValue(
                                                                              label,
                                                                              value);
                                                                    });
                                                                  },
                                                                  validator:
                                                                      isRequired
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
                                                            if (fieldType ==
                                                                    'url' &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    TextFormField(
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  style:
                                                                      labelStyle,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    labelText:
                                                                        label,
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    border: OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue)),
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .url,
                                                                  onChanged:
                                                                      (value) async {
                                                                    if (event !=
                                                                        "") {
                                                                      await controller
                                                                          .GetUserData(
                                                                              code,
                                                                              rule,
                                                                              value);
                                                                      setState(
                                                                          () {
                                                                        controller
                                                                                .dataMap[
                                                                            field[
                                                                                'code']] = value;
          
                                                                        controller.setFieldValue(
                                                                            label,
                                                                            value);
                                                                        updateResult(
                                                                            reqBody,
                                                                            showvalue);
                                                                      });
                                                                    } else {
                                                                      setState(
                                                                          () {
                                                                        controller
                                                                                .dataMap[
                                                                            field[
                                                                                'code']] = value;
                                                                        controller.setFieldValue(
                                                                            label,
                                                                            value);
                                                                        updateResult(
                                                                            reqBody,
                                                                            showvalue);
                                                                      });
                                                                    }
                                                                  },
                                                                  validator:
                                                                      isRequired
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
                                                            if (fieldType ==
                                                                    'password' &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            5.0),
                                                                child:
                                                                    TextFormField(
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  style:
                                                                      labelStyle,
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  obscureText:
                                                                      _obscureText,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    labelText:
                                                                        label,
                                                                    fillColor: isDarkMode
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
                                                                    suffixIcon:
                                                                        IconButton(
                                                                      icon: Icon(
                                                                        _obscureText
                                                                            ? Icons
                                                                                .visibility_off
                                                                            : Icons
                                                                                .visibility,
                                                                      ),
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          _obscureText =
                                                                              !_obscureText;
                                                                        });
                                                                      },
                                                                    ),
                                                                  ),
                                                                  onChanged:
                                                                      (value) {
                                                                    controller
                                                                        .setFieldValue(
                                                                            label,
                                                                            value);
                                                                  },
                                                                  validator:
                                                                      (value) {
                                                                    if (isRequired &&
                                                                        (value ==
                                                                                null ||
                                                                            value
                                                                                .isEmpty)) {
                                                                      return 'Please enter $label';
                                                                    }
          
                                                                    final regexPattern =
                                                                        field[
                                                                            'regex']; // e.g., "^[1-5]$"
                                                                    if (regexPattern !=
                                                                            null &&
                                                                        value !=
                                                                            null &&
                                                                        value
                                                                            .isNotEmpty) {
                                                                      final regex =
                                                                          RegExp(
                                                                              regexPattern);
                                                                      if (!regex
                                                                          .hasMatch(
                                                                              value)) {
                                                                        return 'Invalid input for $label';
                                                                      }
                                                                    }
          
                                                                    return null;
                                                                  },
                                                                ),
                                                              );
                                                            }
                                                            if (fieldType ==
                                                                    'object' &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  vertical: 5.0,
                                                                ),
                                                                child:
                                                                    TextFormField(
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  style:
                                                                      labelStyle,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    border: OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue)),
                                                                  ),
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .text,
                                                                  onChanged:
                                                                      (value) {
                                                                    setState(() {
                                                                      controller
                                                                              .dataMap[
                                                                          field[
                                                                              'code']] = value;
                                                                      controller
                                                                          .setFieldValue(
                                                                              label,
                                                                              value);
                                                                      updateResult(
                                                                          reqBody,
                                                                          showvalue);
                                                                    });
                                                                  },
                                                                  validator:
                                                                      isRequired
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
                                                            if (fieldType ==
                                                                    'location' &&
                                                                result) {
                                                              final locationMap =
                                                                  controller
                                                                      .getFieldValue(
                                                                          label);
                                                              if (locationMap !=
                                                                      null &&
                                                                  locationMap
                                                                      is Map) {
                                                                controller
                                                                    .latController
                                                                    .text = locationMap[
                                                                            0]
                                                                        .toString() ??
                                                                    '';
                                                                controller
                                                                    .longController
                                                                    .text = locationMap[
                                                                            1]
                                                                        .toString() ??
                                                                    '';
                                                              }
                                                              if (isRequired) {
                                                                if (controller
                                                                        .latController
                                                                        .text
                                                                        .isEmpty ||
                                                                    controller
                                                                        .longController
                                                                        .text
                                                                        .isEmpty) {
                                                                  isLocationValid =
                                                                      false;
                                                                } else {
                                                                  isLocationValid =
                                                                      true;
                                                                }
                                                              } else {
                                                                // If not required, then it's always valid (even if empty)
                                                                isLocationValid =
                                                                    true;
                                                              }
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  vertical: 5.0,
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      label,
                                                                      style:
                                                                          labelStyle,
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            8),
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .topLeft,
                                                                      child:
                                                                          Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border: Border.all(
                                                                              color:
                                                                                  Colors.grey,
                                                                              width: 1),
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            IconButton(
                                                                              icon:
                                                                                  Icon(Icons.location_on, color: Appcolorblue),
                                                                              onPressed:
                                                                                  () {
                                                                                setCurrentLocation(label);
                                                                              },
                                                                            ),
                                                                            IconButton(
                                                                              icon:
                                                                                  Icon(Icons.remove_red_eye, color: Appcolorblue),
                                                                              onPressed:
                                                                                  () async {
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
                                                                              icon:
                                                                                  Icon(Icons.delete, color: Colors.red),
                                                                              onPressed:
                                                                                  () {
                                                                                _clearText(label);
                                                                              },
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            8),
                                                                    if (controller
                                                                        .showTextField
                                                                        .value) ...[
                                                                      TextFormField(
                                                                        controller:
                                                                            controller
                                                                                .latController,
                                                                        readOnly:
                                                                            true,
                                                                        style:
                                                                            labelStyle,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              'Latitude',
                                                                          fillColor: isDarkMode
                                                                              ? Colors.black
                                                                              : Colors.white,
                                                                          labelStyle:
                                                                              labelStyle,
                                                                          border:
                                                                              const OutlineInputBorder(),
                                                                        ),
                                                                        validator: isRequired
                                                                            ? (value) {
                                                                                if (value == null || value.isEmpty) {
                                                                                  return 'Please enter latitude';
                                                                                }
                                                                                return null;
                                                                              }
                                                                            : null,
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              10),
                                                                      TextFormField(
                                                                        controller:
                                                                            controller
                                                                                .longController,
                                                                        readOnly:
                                                                            true,
                                                                        style:
                                                                            labelStyle,
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              'Longitude',
                                                                          fillColor: isDarkMode
                                                                              ? Colors.black
                                                                              : Colors.white,
                                                                          labelStyle:
                                                                              labelStyle,
                                                                          border:
                                                                              const OutlineInputBorder(),
                                                                        ),
                                                                        validator: isRequired
                                                                            ? (value) {
                                                                                if (value == null || value.isEmpty) {
                                                                                  return 'Please enter longitude';
                                                                                }
                                                                                return null;
                                                                              }
                                                                            : null,
                                                                      ),
                                                                    ],
                                                                    // (!isLocationValid)
                                                                    //     ? const Text(
                                                                    //   "Location is Required",
                                                                    //   style: TextStyle(
                                                                    //     color: Colors.red,
                                                                    //     fontSize: 15,
                                                                    //     fontWeight: FontWeight.w400,
                                                                    //   ),
                                                                    // )
                                                                    //     : const SizedBox(),
                                                                    (onsavebuttonclick &&
                                                                            (isRequired && controller.longController.text.isEmpty ||
                                                                                controller.latController.text.isEmpty))
                                                                        ? const Text(
                                                                            "Location is Required",
                                                                            style:
                                                                                TextStyle(
                                                                              color:
                                                                                  Colors.red,
                                                                              fontSize:
                                                                                  15,
                                                                              fontWeight:
                                                                                  FontWeight.w400,
                                                                            ),
                                                                          )
                                                                        : SizedBox()
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                            if (showDropdown &&
                                                                result) {
                                                              final dropdownItems =
                                                                  controller.prelaodlist[
                                                                          yUsecase] ??
                                                                      [];
          
                                                              // Ensure only unique items based on 'id', filter out nulls
                                                              final uniqueItems =
                                                                  {
                                                                for (var item in dropdownItems
                                                                    .where((item) =>
                                                                        item !=
                                                                            null &&
                                                                        item['id'] !=
                                                                            null &&
                                                                        item['_val'] !=
                                                                            null))
                                                                  item['id']
                                                                          .toString():
                                                                      item
                                                              }.values.toList();
          
                                                              final currentValue =
                                                                  controller
                                                                      .getFieldValue(
                                                                          label);
                                                              final dropdownValues =
                                                                  uniqueItems
                                                                      .map((item) =>
                                                                          item['id']
                                                                              .toString())
                                                                      .toSet();
                                                              final dropdownValue =
                                                                  dropdownValues
                                                                          .contains(
                                                                              currentValue)
                                                                      ? currentValue
                                                                      : null;
          
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    DropdownButtonFormField<
                                                                        String>(
                                                                  isExpanded:
                                                                      true,
                                                                  dropdownColor:
                                                                      isDarkMode
                                                                          ? Colors.grey[
                                                                              800]
                                                                          : Colors
                                                                              .white,
                                                                  style:
                                                                      labelStyle,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
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
                                                                        'Select $label',
                                                                    hintStyle:
                                                                        labelStyle,
                                                                  ),
                                                                  value:
                                                                      dropdownValue,
                                                                  items: [
                                                                    // Placeholder item
                                                                    DropdownMenuItem<
                                                                        String>(
                                                                      value: null,
                                                                      child: Text(
                                                                        'Select an $label',
                                                                        style:
                                                                            labelStyle,
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                    // Real items
                                                                    ...uniqueItems
                                                                        .map<DropdownMenuItem<String>>(
                                                                            (item) {
                                                                      return DropdownMenuItem<
                                                                          String>(
                                                                        value: item[
                                                                                'id']
                                                                            .toString(),
                                                                        child:
                                                                            Text(
                                                                          item[
                                                                              '_val'],
                                                                          style:
                                                                              labelStyle,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          maxLines:
                                                                              1,
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ],
                                                   onChanged:
                                                                      readOnly !=
                                                                              1
                                                                          ? (value) async {
                                                                              // Check internet before API call
                                                                              var connectivityResult =
                                                                                  await Connectivity().checkConnectivity();
                                                                              bool
                                                                                  isOnline =
                                                                                  connectivityResult != ConnectivityResult.none;
          
                                                                              if (!isOnline &&
                                                                                  event != "") {
                                                                                // Show toast for offline mode
                                                                                CherryToast.info(
                                                                                  backgroundColor: const Color(0xFFFACA4F),
                                                                                  animationDuration: Durations.short1,
                                                                                  title: const Text("You are offline. Data will be saved locally.", style: TextStyle(color: Colors.black)),
                                                                                ).show(context);
          
                                                                                // Still save the value locally
                                                                                controller.setFieldValue(label, value);
                                                                                return;
                                                                              }
          
                                                                              controller.onChange(field,
                                                                                  value);
                                                                              if (event !=
                                                                                  "") {
                                                                                await controller.GetUserData(code, rule, value!);
                                                                                controller.admissionId = value;
                                                                                setState(() {
                                                                                  controller.setFieldValue(label, value);
                                                                                });
                                                                              } else {
                                                                                controller.setFieldValue(label, value);
                                                                              }
                                                                            }
                                                                          : null,
                                                                  validator:
                                                                      isRequired
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
          
                                                            if (fieldType ==
                                                                    'boolean' &&
                                                                result) {
                                                              String? savedValue =
                                                                  controller
                                                                      .dataMap[field[
                                                                          'code']]
                                                                      .toString();
                                                              if (savedValue ==
                                                                  '1') {
                                                                isSelected = [
                                                                  true,
                                                                  false
                                                                ];
                                                              } else if (savedValue ==
                                                                  '0') {
                                                                isSelected = [
                                                                  false,
                                                                  true
                                                                ];
                                                              } else {
                                                                isSelected = [
                                                                  false,
                                                                  false
                                                                ];
                                                              }
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0,
                                                                        horizontal:
                                                                            9),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Align(
                                                                        alignment:
                                                                            Alignment
                                                                                .topLeft,
                                                                        child: Text(
                                                                            label,
                                                                            style:
                                                                                labelStyle)),
                                                                    const SizedBox(
                                                                        height:
                                                                            10),
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .topLeft,
                                                                      child:
                                                                          ToggleButtons(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                                5),
                                                                        selectedColor:
                                                                            Colors
                                                                                .white,
                                                                        borderColor: isDarkMode
                                                                            ? const Color(
                                                                                0xFF4F76E2)
                                                                            : const Color(
                                                                                0xFF1A237E),
                                                                        fillColor: isDarkMode
                                                                            ? const Color(
                                                                                0xFF4F76E2)
                                                                            : const Color(
                                                                                0xFF1A237E),
                                                                        color: isDarkMode
                                                                            ? Colors
                                                                                .white
                                                                            : Colors
                                                                                .black,
                                                                        isSelected:
                                                                            isSelected,
                                                                        onPressed:
                                                                            (index) {
                                                                          setState(
                                                                              () {
                                                                            for (int i = 0;
                                                                                i < isSelected.length;
                                                                                i++) {
                                                                              isSelected[i] =
                                                                                  i == index; // Set the selected index to true
                                                                            }
                                                                            var selectedValue = index == 0
                                                                                ? 1
                                                                                : 0;
                                                                            String
                                                                                savedValue =
                                                                                selectedValue.toString();
                                                                            setState(
                                                                                () {
                                                                              controller.dataMap[field['code']] =
                                                                                  savedValue;
                                                                              controller.setFieldValue(label,
                                                                                  savedValue);
                                                                            });
                                                                          });
                                                                        },
                                                                        children: const [
                                                                          Padding(
                                                                            padding: const EdgeInsets
                                                                                .symmetric(
                                                                                horizontal: 16),
                                                                            child:
                                                                                Text(
                                                                              "Yes",
                                                                              style:
                                                                                  TextStyle(
                                                                                fontSize: 15,
                                                                                fontWeight: FontWeight.w400,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: const EdgeInsets
                                                                                .symmetric(
                                                                                horizontal: 16),
                                                                            child:
                                                                                Text(
                                                                              "No",
                                                                              style:
                                                                                  TextStyle(
                                                                                fontSize: 15,
                                                                                fontWeight: FontWeight.w400,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                            if ((fieldType ==
                                                                        'number' ||
                                                                    fieldType ==
                                                                        'phone' ||
                                                                    fieldType ==
                                                                        'long' ||
                                                                    fieldType ==
                                                                        'decimal') &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    TextFormField(
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  style:
                                                                      labelStyle,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    border: OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue)),
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
                                                                  validator:
                                                                      (value) {
                                                                    if (isRequired &&
                                                                        (value ==
                                                                                null ||
                                                                            value
                                                                                .isEmpty)) {
                                                                      return 'Please enter $label';
                                                                    }
          
                                                                    final regexPattern =
                                                                        field[
                                                                            'regex']; // e.g., "^[1-5]$"
                                                                    if (regexPattern !=
                                                                            null &&
                                                                        value !=
                                                                            null &&
                                                                        value
                                                                            .isNotEmpty) {
                                                                      final regex =
                                                                          RegExp(
                                                                              regexPattern);
                                                                      if (!regex
                                                                          .hasMatch(
                                                                              value)) {
                                                                        return 'Invalid input for $label';
                                                                      }
                                                                    }
          
                                                                    return null;
                                                                  },
                                                                  // validator: isRequired
                                                                  //     ? (value) {
                                                                  //         if (value ==
                                                                  //                 null ||
                                                                  //             value
                                                                  //                 .isEmpty) {
                                                                  //           return 'Please enter $label';
                                                                  //         }
                                                                  //         return null;
                                                                  //       }
                                                                  //     : null,
                                                                ),
                                                              );
                                                            }
          
                                                            if (fieldType ==
                                                                    'date' &&
                                                                result) {
                                                              // Set current date if defaultToCurrentDate is 1 and field is empty
                                                              if (defaultToCurrentDate ==
                                                                      1 &&
                                                                  (controller.getFieldValue(
                                                                              label) ==
                                                                          null ||
                                                                      controller
                                                                          .getFieldValue(
                                                                              label)!
                                                                          .isEmpty)) {
                                                                final String
                                                                    currentDate =
                                                                    DateFormat(
                                                                            'yyyy-MM-dd')
                                                                        .format(DateTime
                                                                            .now());
          
                                                                controller
                                                                    .setFieldValue(
                                                                        label,
                                                                        currentDate);
                                                              }
          
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            5.0,
                                                                        horizontal:
                                                                            2.0),
                                                                child:
                                                                    TextFormField(
                                                                  readOnly: true,
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  // disables input if readOnly == 1
                                                                  style:
                                                                      labelStyle,
                                                                  controller:
                                                                      TextEditingController(
                                                                    text: controller
                                                                        .getFieldValue(
                                                                            label),
                                                                  ),
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    suffixIcon:
                                                                        readOnly !=
                                                                                1
                                                                            ? Icon(
                                                                                Icons.calendar_today,
                                                                                color: isDarkMode ? Colors.white : Colors.black,
                                                                              )
                                                                            : null,
                                                                    border:
                                                                        OutlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide(
                                                                              color:
                                                                                  Appcolorblue),
                                                                    ),
                                                                  ),
                                                                  onTap: readOnly !=
                                                                          1
                                                                      ? () async {
                                                                          DateTime?
                                                                              selectedDate;
                                                                          if (minDateStr.isEmpty &&
                                                                              maxDateStr.isEmpty) {
                                                                            selectedDate =
                                                                                await showDatePicker(
                                                                              context:
                                                                                  context,
                                                                              initialDate:
                                                                                  DateTime.now(),
                                                                              firstDate:
                                                                                  DateTime(1900),
                                                                              lastDate:
                                                                                  DateTime(2100),
                                                                            );
                                                                          } else {
                                                                            DateTime
                                                                                minDate =
                                                                                DateTime.parse(minDateStr);
                                                                            DateTime
                                                                                maxDate =
                                                                                DateTime.parse(maxDateStr);
                                                                            DateTime
                                                                                initial =
                                                                                DateTime.now();
                                                                            if (initial.isBefore(
                                                                                minDate)) {
                                                                              initial =
                                                                                  minDate;
                                                                            } else if (initial
                                                                                .isAfter(maxDate)) {
                                                                              initial =
                                                                                  maxDate;
                                                                            }
                                                                            selectedDate =
                                                                                await showDatePicker(
                                                                              context:
                                                                                  context,
                                                                              initialDate:
                                                                                  initial,
                                                                              firstDate:
                                                                                  minDate,
                                                                              lastDate:
                                                                                  maxDate,
                                                                            );
                                                                          }
          
                                                                          // DateTime? selectedDate = await showDatePicker(
                                                                          //   context: context,
                                                                          //   initialDate: DateTime.now(),
                                                                          //   firstDate: DateTime(1900),
                                                                          //   lastDate: DateTime(2100),
                                                                          // );
          
                                                                          if (selectedDate !=
                                                                              null) {
                                                                            // String formattedDate = "${selectedDate.toLocal()}".split(' ')[0];
                                                                            String
                                                                                formattedDate =
                                                                                DateFormat('yyyy-MM-dd').format(selectedDate);
                                                                            if (event !=
                                                                                "") {
                                                                              var response =
                                                                                  await controller.validateAndSubmitDate(rule, formattedDate);
          
                                                                              if (response != null &&
                                                                                  response['success'] == false) {
                                                                                String errorMessage = response['result']?['message'] ?? 'An error occurred while validating the date.';
                                                                                showPopup(context, 'Error', errorMessage);
                                                                              } else if (response != null && response['success'] == true) {
                                                                                setState(() {
                                                                                  controller.setFieldValue(label, formattedDate);
                                                                                });
                                                                              }
                                                                            } else {
                                                                              setState(() {
                                                                                controller.setFieldValue(label, formattedDate);
                                                                              });
                                                                            }
                                                                          }
                                                                        }
                                                                      : null,
          
                                                                  validator:
                                                                      isRequired
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
          
                                                            if (fieldType ==
                                                                    'time' &&
                                                                result) {
                                                              // Initialize controller if not already present
                                                              _controllers
                                                                  .putIfAbsent(
                                                                      label,
                                                                      () =>
                                                                          TextEditingController());
          
                                                              // Prefill with current time if empty and defaultToCurrentTime == 1
                                                              int defaultToCurrentTime =
                                                                  field['defaultToCurrentTime'] ??
                                                                      0;
                                                              if (_controllers[
                                                                      label]!
                                                                  .text
                                                                  .isEmpty) {
                                                                if (defaultToCurrentTime ==
                                                                    1) {
                                                                  String
                                                                      currentTime =
                                                                      DateFormat(
                                                                              'HH:mm')
                                                                          .format(
                                                                              DateTime.now());
                                                                  _controllers[
                                                                              label]!
                                                                          .text =
                                                                      currentTime;
                                                                  controller
                                                                      .setFieldValue(
                                                                          label,
                                                                          currentTime);
                                                                } else {
                                                                  _controllers[
                                                                          label]!
                                                                      .text = controller
                                                                          .getFieldValue(
                                                                              label) ??
                                                                      '';
                                                                }
                                                              }
          
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    TextFormField(
                                                                  readOnly: true,
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  style:
                                                                      labelStyle,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelStyle:
                                                                        labelStyle,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
                                                                            code],
                                                                    labelText:
                                                                        label,
                                                                    suffixIcon:
                                                                        readOnly !=
                                                                                1
                                                                            ? Icon(
                                                                                Icons.access_time,
                                                                                color: isDarkMode ? Colors.white : Colors.black,
                                                                              )
                                                                            : null,
                                                                    border: OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue)),
                                                                  ),
                                                                  onTap: readOnly !=
                                                                          1
                                                                      ? () async {
                                                                          TimeOfDay?
                                                                              selectedTime =
                                                                              await showTimePicker(
                                                                            context:
                                                                                context,
                                                                            initialTime:
                                                                                TimeOfDay.now(),
                                                                          );
                                                                          if (selectedTime !=
                                                                              null) {
                                                                            final now =
                                                                                DateTime.now();
                                                                            final dateTime = DateTime(
                                                                                now.year,
                                                                                now.month,
                                                                                now.day,
                                                                                selectedTime.hour,
                                                                                selectedTime.minute);
          
                                                                            String
                                                                                formattedTime =
                                                                                DateFormat('HH:mm').format(dateTime);
          
                                                                            setState(
                                                                                () {
                                                                              _controllers[label]!.text =
                                                                                  formattedTime;
                                                                              controller.setFieldValue(label,
                                                                                  formattedTime);
                                                                            });
                                                                          }
                                                                        }
                                                                      : null,
                                                                  validator:
                                                                      isRequired
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
                                                            if (fieldType ==
                                                                    'combobox' &&
                                                                result) {
                                                              comboboxmapValues =
                                                                  field['values'] ??
                                                                      [];
                                                              List<
                                                                  String> _options = List<
                                                                      String>.from(
                                                                  comboboxmapValues
                                                                          .isNotEmpty
                                                                      ? comboboxmapValues
                                                                      : [
                                                                          'Apple',
                                                                          'Banana',
                                                                          'Cherry',
                                                                          'Date'
                                                                        ]);
          
                                                              List<String>
                                                                  _filteredOptions =
                                                                  List.from(
                                                                      _options);
          
                                                              return StatefulBuilder(
                                                                builder: (context,
                                                                    setInnerState) {
                                                                  void _saveValue(
                                                                      String
                                                                          value) {
                                                                    controller.dataMap[
                                                                            field[
                                                                                'code']] =
                                                                        value;
                                                                    controller
                                                                        .setFieldValue(
                                                                            label,
                                                                            value);
                                                                  }
          
                                                                  void _onTextChanged(
                                                                      String
                                                                          value) {
                                                                    _saveValue(
                                                                        value); // Save while typing
                                                                    setInnerState(
                                                                        () {
                                                                      _filteredOptions = _options
                                                                          .where((item) => item
                                                                              .toLowerCase()
                                                                              .contains(value.toLowerCase()))
                                                                          .toList();
                                                                    });
                                                                  }
          
                                                                  void _onItemSelected(
                                                                      String
                                                                          value) {
                                                                    _controllers[
                                                                            label]!
                                                                        .text = value;
                                                                    _saveValue(
                                                                        value); // Save on dropdown selection
                                                                    FocusScope.of(
                                                                            context)
                                                                        .unfocus();
                                                                    setInnerState(
                                                                        () {
                                                                      _filteredOptions =
                                                                          _options;
                                                                    });
                                                                  }
          
                                                                  return Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .symmetric(
                                                                      vertical:
                                                                          5.0,
                                                                    ),
                                                                    child:
                                                                        TextField(
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      enabled:
                                                                          readOnly !=
                                                                              1,
                                                                      // disable input if readOnly
                                                                      onChanged: readOnly !=
                                                                              1
                                                                          ? _onTextChanged
                                                                          : null,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isDarkMode
                                                                            ? Colors
                                                                                .black
                                                                            : Colors
                                                                                .white,
                                                                        labelText:
                                                                            'Select a $label',
                                                                        suffixIcon:
                                                                            PopupMenuButton<
                                                                                String>(
                                                                          icon: const Icon(
                                                                              Icons.arrow_drop_down),
                                                                          itemBuilder:
                                                                              (context) {
                                                                            return _filteredOptions.map((String
                                                                                option) {
                                                                              return PopupMenuItem<String>(
                                                                                value: option,
                                                                                child: Text(
                                                                                  option,
                                                                                  style: labelStyle,
                                                                                ),
                                                                              );
                                                                            }).toList();
                                                                          },
                                                                          onSelected:
                                                                              _onItemSelected,
                                                                        ),
                                                                        border:
                                                                            const OutlineInputBorder(),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              );
                                                            }
          
                                                            if (fieldType ==
                                                                    'map' &&
                                                                result) {
                                                              List<dynamic>
                                                                  mapValues =
                                                                  field['values'] ??
                                                                      [];
          
                                                              // Dropdown items
                                                              List<
                                                                      DropdownMenuItem<
                                                                          String>>
                                                                  dropdownItems =
                                                                  [];
          
                                                              // Add placeholder
                                                              dropdownItems.add(
                                                                DropdownMenuItem<
                                                                    String>(
                                                                  value: '',
                                                                  child: Text(
                                                                    'Select $label',
                                                                    style:
                                                                        labelStyle,
                                                                  ),
                                                                ),
                                                              );
          
                                                              // Add map values (store "key - value")
                                                              dropdownItems
                                                                  .addAll(
                                                                mapValues.map<
                                                                    DropdownMenuItem<
                                                                        String>>((item) {
                                                                  final key = item[
                                                                              'key']
                                                                          ?.toString() ??
                                                                      '';
                                                                  final val =
                                                                      item['value']
                                                                              ?.toString() ??
                                                                          '';
                                                                  final display =
                                                                      '$key - $val';
                                                                  return DropdownMenuItem<
                                                                      String>(
                                                                    value:
                                                                        display, // ✅ store key - value
                                                                    child: Text(
                                                                      display,
                                                                      style:
                                                                          labelStyle,
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              );
          
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0,
                                                                        horizontal:
                                                                            8),
                                                                child:
                                                                    DropdownButtonFormField<
                                                                        String>(
                                                                  style:
                                                                      labelStyle,
                                                                  dropdownColor:
                                                                      isDarkMode
                                                                          ? Colors.grey[
                                                                              800]
                                                                          : Colors
                                                                              .white,
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
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
                                                                  value: controller
                                                                              .getFieldValue(
                                                                                  label)
                                                                              ?.isEmpty ??
                                                                          true
                                                                      ? '' // placeholder
                                                                      : controller
                                                                          .getFieldValue(
                                                                              label), // ✅ must match "key - value"
                                                                  items:
                                                                      dropdownItems,
                                                                  selectedItemBuilder:
                                                                      (BuildContext
                                                                          context) {
                                                                    List<Widget>
                                                                        selectedWidgets =
                                                                        [
                                                                      Text(
                                                                          'Select $label',
                                                                          style:
                                                                              labelStyle),
                                                                    ];
                                                                    selectedWidgets
                                                                        .addAll(mapValues
                                                                            .map<Widget>(
                                                                                (item) {
                                                                      final key =
                                                                          item['key']?.toString() ??
                                                                              '';
                                                                      final val =
                                                                          item['value']?.toString() ??
                                                                              '';
                                                                      return Text(
                                                                          '$key - $val',
                                                                          style:
                                                                              labelStyle);
                                                                    }).toList());
                                                                    return selectedWidgets;
                                                                  },
                                                                  onChanged:
                                                                      readOnly !=
                                                                              1
                                                                          ? (value) async {
                                                                              if (value == null ||
                                                                                  value.isEmpty) {
                                                                                controller.setFieldValue(label, '');
                                                                                controller.admissionId = '';
                                                                              } else {
                                                                                if (event != "") {
                                                                                  await controller.GetUserData(code, rule, value);
                                                                                  controller.admissionId = value;
                                                                                }
                                                                                setState(() {
                                                                                  controller.setFieldValue(label, value); // ✅ saves "1 - a"
                                                                                });
                                                                              }
                                                                            }
                                                                          : null,
                                                                  validator:
                                                                      isRequired
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
          
                                                            if (fieldType ==
                                                                    'list' &&
                                                                result) {
                                                              final List<dynamic>
                                                                  values =
                                                                  field['values'] ??
                                                                      [];
                                                              final uniqueValues =
                                                                  values
                                                                      .toSet()
                                                                      .toList();
                                                              String?
                                                                  selectedValue =
                                                                  controller
                                                                      .getFieldValue(
                                                                          label);
          
                                                              if (!uniqueValues
                                                                  .contains(
                                                                      selectedValue)) {
                                                                selectedValue =
                                                                    null;
                                                              }
          
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    ConstrainedBox(
                                                                  constraints:
                                                                      BoxConstraints(
                                                                    maxWidth: MediaQuery.of(
                                                                                context)
                                                                            .size
                                                                            .width *
                                                                        0.88,
                                                                  ),
                                                                  child:
                                                                      DropdownButtonFormField<
                                                                          String>(
                                                                    isExpanded:
                                                                        true,
                                                                    style:
                                                                        labelStyle,
                                                                    dropdownColor: isDarkMode
                                                                        ? Colors.grey[
                                                                            800]
                                                                        : Colors
                                                                            .white,
                                                                    decoration:
                                                                        InputDecoration(
                                                                      labelText:
                                                                          label,
                                                                      labelStyle:
                                                                          labelStyle,
                                                                      fillColor: isDarkMode
                                                                          ? Colors
                                                                              .black
                                                                          : Colors
                                                                              .white,
                                                                      border:
                                                                          OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(
                                                                                color: Appcolorblue),
                                                                      ),
                                                                      hintText:
                                                                          'Select $label',
                                                                      hintStyle: const TextStyle(
                                                                          fontSize:
                                                                              10),
                                                                    ),
                                                                    value:
                                                                        selectedValue,
                                                                    items: [
                                                                      DropdownMenuItem<
                                                                          String>(
                                                                        value:
                                                                            null, // Placeholder clears the value
                                                                        child:
                                                                            ConstrainedBox(
                                                                          constraints:
                                                                              BoxConstraints(
                                                                            maxWidth:
                                                                                MediaQuery.of(context).size.width * 0.7,
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Select an $label',
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                2,
                                                                            style:
                                                                                labelStyle,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      ...uniqueValues
                                                                          .map<DropdownMenuItem<String>>(
                                                                              (value) {
                                                                        return DropdownMenuItem<
                                                                            String>(
                                                                          value:
                                                                              value,
                                                                          child:
                                                                              ConstrainedBox(
                                                                            constraints:
                                                                                BoxConstraints(
                                                                              maxWidth:
                                                                                  MediaQuery.of(context).size.width * 0.7,
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              value,
                                                                              overflow:
                                                                                  TextOverflow.ellipsis,
                                                                              maxLines:
                                                                                  2,
                                                                              style:
                                                                                  labelStyle,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                    ],
                                                                    onChanged:
                                                                        readOnly !=
                                                                                1
                                                                            ? (value) async {
                                                                                // Use empty string if placeholder selected to clear previous value
                                                                                final newValue = value ?? '';
                                                                                controller.setFieldValue(label, newValue);
          
                                                                                if (value != null && event != "") {
                                                                                  await controller.GetUserData(code, rule, value);
                                                                                  controller.admissionId = value;
                                                                                }
          
                                                                                setState(() {
                                                                                  updateResult(reqBody, showvalue);
                                                                                });
                                                                              }
                                                                            : null,
                                                                    validator:
                                                                        isRequired
                                                                            ? (value) {
                                                                                if (value == null || value.isEmpty) {
                                                                                  return 'Please select $label';
                                                                                }
                                                                                return null;
                                                                              }
                                                                            : null,
                                                                  ),
                                                                ),
                                                              );
                                                            }
          
                                                            if (fieldType ==
                                                                    'file' &&
                                                                result) {
                                                              return Padding(
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
                                                                    /// File input field
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
                                                                                code);
                                                                          } else {
                                                                            _pickAndUploadImage(
                                                                                code);
                                                                          }
                                                                        },
                                                                        style:
                                                                            labelStyle,
                                                                        readOnly:
                                                                            true,
                                                                        controller:
                                                                            TextEditingController(
                                                                          text: controller.imagePaths[code] !=
                                                                                  null
                                                                              ? controller.imagePaths[code]!.split('/').last
                                                                              : '',
                                                                        ),
                                                                        decoration:
                                                                            InputDecoration(
                                                                          errorText:
                                                                              controller.resulterror[code],
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
                                                                                BorderSide(color: Colors.green),
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
                                                                              if (captureImage ==
                                                                                  1) {
          getImage1(code);
                                                                              } else {
                                                                                _pickAndUploadImage(code);
                                                                              }
                                                                            },
                                                                          ),
                                                                        ),
                                                                        onChanged:
                                                                            (value) {
                                                                          setState(
                                                                              () {
                                                                            controller.imagePaths[code] =
                                                                                value;
                                                                            controller.setFieldValue(
                                                                                label,
                                                                                '0');
                                                                            controller.setInitialValue(
                                                                                label,
                                                                                '0');
                                                                          });
                                                                        },
                                                                      ),
                                                                    ),
          
                                                                    /// File preview
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              16.0),
                                                                      child: controller.imagePaths[code] !=
                                                                              null
                                                                          ? Image
                                                                              .file(
                                                                              File(controller.imagePaths[code]!),
                                                                              width:
                                                                                  100,
                                                                              height:
                                                                                  100,
                                                                            )
                                                                          : CachedNetworkImage(
                                                                              imageUrl: (_controllers[label]?.text.isNotEmpty ?? false)
                                                                                  ? "https://cuickdev.com/API/DOCS/api/doc/th/${_controllers[label]!.text}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                                                  : imageUrlHelper.applogourl,
                                                                              width:
                                                                                  100,
                                                                              height:
                                                                                  100,
                                                                              errorWidget: (context, url, error) =>
                                                                                  const Icon(Icons.error),
                                                                            ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
          
                                                            if (fieldType ==
                                                                    'doc' &&
                                                                result) {
                                                              return Padding(
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
                                                                    // Input field
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              8.0),
                                                                      child:
                                                                          TextFormField(
                                                                        style:
                                                                            labelStyle,
                                                                        onTap: () =>
                                                                            _pickAndUploadFile(
                                                                                code),
                                                                        readOnly:
                                                                            true,
                                                                        controller:
                                                                            TextEditingController(
                                                                          text: controller.docPaths[code] !=
                                                                                  null
                                                                              ? controller.docPaths[code]!.split('/').last
                                                                              : '',
                                                                        ),
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              label,
                                                                          labelStyle:
                                                                              labelStyle,
                                                                          errorText:
                                                                              controller.resulterror[code],
                                                                          fillColor: isDarkMode
                                                                              ? Colors.black
                                                                              : Colors.white,
                                                                          border:
                                                                              const OutlineInputBorder(
                                                                            borderSide:
                                                                                BorderSide(color: Colors.green),
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
                                                                            onPressed: () =>
                                                                                _pickAndUploadFile(code),
                                                                          ),
                                                                        ),
                                                                        onChanged:
                                                                            (value) {
                                                                          setState(
                                                                              () {
                                                                            controller.docPaths[code] =
                                                                                value;
                                                                            controller.setFieldValue(
                                                                                label,
                                                                                '0');
                                                                            controller.setInitialValue(
                                                                                label,
                                                                                '0');
                                                                          });
                                                                        },
                                                                      ),
                                                                    ),
          
                                                                    // Preview
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          vertical:
                                                                              16.0),
                                                                      child: controller.docPaths[code] !=
                                                                              null
                                                                          ? Image
                                                                              .file(
                                                                              File(controller.docPaths[code]!),
                                                                              width:
                                                                                  100,
                                                                              height:
                                                                                  100,
                                                                            )
                                                                          : GestureDetector(
                                                                              onTap:
                                                                                  () async {
                                                                                final docId = _controllers[label]?.text;
                                                                                if (docId != null && docId.isNotEmpty) {
                                                                                  final Uri testUrl = Uri.parse(
                                                                                    "https://cuickdev.com/API/DOCS/api/doc/$docId",
                                                                                  );
                                                                                  await launchUrl(testUrl);
                                                                                }
                                                                              },
                                                                              child:
                                                                                  CachedNetworkImage(
                                                                                width: 100,
                                                                                height: 100,
                                                                                imageUrl: (_controllers[label]?.text.isNotEmpty ?? false) ? "https://cuickdev.com/API/DOCS/api/doc/th/${_controllers[label]!.text}?t=${DateTime.now().millisecondsSinceEpoch}" : imageUrlHelper.applogourl,
                                                                                errorWidget: (context, url, error) => const Icon(Icons.picture_as_pdf),
                                                                              ),
                                                                            ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
          
                                                            if (fieldType ==
                                                                    'textarea' &&
                                                                result) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child:
                                                                    TextFormField(
                                                                  style:
                                                                      labelStyle,
                                                                  enabled:
                                                                      readOnly !=
                                                                          1,
                                                                  readOnly:
                                                                      readOnly ==
                                                                          1,
                                                                  controller:
                                                                      _controllers[
                                                                          label],
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor: isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                    labelText:
                                                                        label,
                                                                    errorText:
                                                                        controller
                                                                                .resulterror[
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
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .multiline,
                                                                  maxLines: null,
                                                                  // Allows the textarea to expand based on input
                                                                  onChanged:
                                                                      (value) async {
                                                                    setState(() {
                                                                      controller
                                                                              .dataMap[
                                                                          field[
                                                                              'code']] = value;
                                                                      controller
                                                                          .setFieldValue(
                                                                              label,
                                                                              value);
                                                                    });
                                                                  },
                                                                  validator:
                                                                      isRequired
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
          
                                                            return const SizedBox
                                                                .shrink();
                                                          }).toList(),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : SizedBox.shrink();
                                        }).toList(),
                                      
                                      ...itemsWithoutGroup.map((field) {
                                        String label = field['label'];
                                        String code = field['code'];
                                        String fieldType = field['type'];
                                        bool isRequired = field['required'] == 1;
                                        bool isRefKey = field['refKey'] == 1;
                                        bool primaryUsecase =
                                            field['primaryUsecase'] != "";
                                        int defaultToCurrentDate =
                                            field['defaultToCurrentDate'] ?? 0;
                                        int defaultToCurrentTime =
                                            field['defaultToCurrentTime'] ?? 0;
                                        int readOnly = field['readOnly'] ?? 0;
                                        bool showDropdown =
                                            primaryUsecase && isRefKey;
                                        String yUsecase =
                                            field['primaryUsecase'] ?? "";
          
                                        String showvalue = field['show'] ?? "";
                                        String event = field['event'] ?? "";
                                        String rule = field['rule'] ?? "";
                                        String minDateStr =
                                            field['minDate'] ?? "";
                                        String maxDateStr =
                                            field['maxDate'] ?? "";
                                        String parentfilter =
                                            field['parentFilter'] ?? "";
                                        int captureImage =
                                            field['captureImage'] ?? 0;
                                        if (parentfilter != "" &&
                                            parentfilter.isNotEmpty) {
                                          // controller.addParentFilter();
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
          
                                        final result =
                                            controller.evaluateCondition(
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
                                        // final controllerValue = controller.getFieldValue(label);
                                        // if (_controllers.containsKey(label) && _controllers[label]!.text.isEmpty &&
                                        //     controllerValue != null &&
                                        //     controllerValue.toString().isNotEmpty) {
                                        //    _controllers[label]!.text = controllerValue.toString();
                                        // }
                                        // Group section के भीतर field display loop में निम्न कोड जोड़ें:
          
          // idate field के लिए
                 if ((fieldType == 'number' ||
                                                fieldType == 'long' ||
                                                fieldType == 'decimal' ||
                                                fieldType == 'phone') &&
                                            result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0),
                                            child: TextFormField(
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText: controller
                                                    .resulterror[code],
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (value) {
                                                // Leave Without Pay field (number/decimal type)
                                                if (label ==
                                                    'Leave Without Pay') {
                                                  print(
                                                      '📝 Leave Without Pay changed: $value');

                                                  controller.setFieldValue(
                                                      label, value);
                                                  controller.dataMap[
                                                      field['code']] = value;
                                                  controller.dataMap['leave'] =
                                                      value;
                                                  controller.dataMap[
                                                          'LeaveWithoutPay'] =
                                                      value;
                                                }

                                                if (label == 'Salary' ||
                                                    label == 'Salay') {
                                                  print(
                                                      '💰 Salary field changed: $value');

                                                  controller.setFieldValue(
                                                      label, value);
                                                  controller.dataMap[
                                                      field['code']] = value;

                                                  // Store in both possible locations
                                                  controller.dataMap['salary'] =
                                                      value;
                                                  controller.dataMap['Salay'] =
                                                      value;

                                                  // Force expression recalculation
                                                  controller
                                                      .updateAllExpressionFields();

                                                  setState(() {});
                                                }
                                                // 🔥 DEBUG PRINT 1 - Input value
                                                print(
                                                    '🔴===== NUMBER/DECIMAL FIELD INPUT =====');
                                                print('📝 Field Label: $label');
                                                print('📝 Field Code: $code');
                                                print(
                                                    '📝 Input Value: "$value"');
                                                print(
                                                    '📝 Field Type: $fieldType');

                                                // Controller mein value set karein
                                                controller.setFieldValue(
                                                    label, value);
                                                controller.dataMap[
                                                    field['code']] = value;

                                                // 🔥 DEBUG PRINT 2 - After setting in controller
                                                print(
                                                    '📝 Value set in controller: "${controller.getFieldValue(label)}"');
                                                print(
                                                    '📝 Value set in dataMap: "${controller.dataMap[field['code']]}"');

                                                // ✅ Dono expression fields ko update karein
                                                print(
                                                    '🔄 Calling updateAllExpressionFields...');
                                                controller
                                                     .updateAllExpressionFields();

                                                // UI update ke liye setState
                                                setState(() {});

                                                print('🔴===== END =====\n');
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }

                                                final regexPattern =
                                                    field['regex'];
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
                                                return null;
                                              },
                                            ),
                                          );
                                        }

          if (fieldType == 'expression') {
                                          return Obx(() {
                                            String displayValue = '';

                                            // Get value based on label
                                            if (label ==
                                                'Working Days In Month') {
                                              displayValue =
                                                  controller.workingDays.value;
                                            } else if (label ==
                                                'Per Day Salary') {
                                              displayValue =
                                                  controller.perDaySalary.value;
                                            } else if (label == 'Net Salary') {
                                              displayValue =
                                                  controller.netSalary.value;
                                            } else {
                                              displayValue = controller
                                                      .getFieldValue(label) ??
                                                  '';
                                            }

                                            // If empty, try dataMap
                                            if (displayValue.isEmpty) {
                                              displayValue = controller
                                                      .dataMap[field['code']]
                                                      ?.toString() ??
                                                  '';
                                            }

                                            // 🔥 FIX: Remove trailing zeros after decimal
                                            if (displayValue.contains('.')) {
                                              // Remove trailing zeros
                                              displayValue =
                                                  displayValue.replaceAll(
                                                      RegExp(r'0+$'), '');
                                              // If decimal point is at the end, remove it too
                                              displayValue =
                                                  displayValue.replaceAll(
                                                      RegExp(r'\.$'), '');
                                            }

                                return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5.0),
                                              child: TextFormField(
                                                controller: TextEditingController(
                                                    text: displayValue),
                                                readOnly: true,
                                                style: labelStyle,
                                                decoration: InputDecoration(
                                                  labelText: label,
                                                  labelStyle: labelStyle,
                                                  fillColor: Colors.grey[200],
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue),
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                        }
                                        if (fieldType == 'idate' && result) {
                                          // ✅ Field code & label
                                          String fieldCode =
                                              field['code']; // e.g. 'iDate'
                                          String fieldLabel =
                                              field['label']; // e.g. 'IDate'
          
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                            () => TextEditingController(),
                                          );
          
                                          // ✅ Prefill from datetime (if exists)
                                          if (defaultToCurrentDate == 1 &&
                                              (controller.getFieldValue(
                                                          fieldLabel) ==
                                                      null ||
                                                  controller
                                                      .getFieldValue(fieldLabel)!
                                                      .isEmpty)) {
                                            final now = DateTime.now();
          
                                            // STORAGE → FIXED (UTC MIDNIGHT)
                                            final isoDate = DateTime.utc(
                                                    now.year, now.month, now.day)
                                                .toIso8601String();
                                            controller.setFieldValue(
                                                fieldLabel, isoDate);
          
                                            // UI display
                                            String displayDate =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(now);
                                            _controllers[fieldCode]!.text =
                                                displayDate;
                                          }
          
                                          // ✅ Prefill from datetime (if exists)
                                          String? dateTimeValue = controller
                                              .getFieldValue('dateTime');
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              dateTimeValue != null) {
                                            DateTime dt =
                                                DateTime.parse(dateTimeValue)
                                                    .toLocal();
                                            String displayDate =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(dt);
                                            _controllers[fieldCode]!.text =
                                                displayDate;
          
                                            final isoDate = DateTime.utc(
                                                    dt.year, dt.month, dt.day)
                                                .toIso8601String();
                                            controller.setFieldValue(
                                                fieldLabel, isoDate);
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              controller: _controllers[fieldCode],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                filled: true,
                                                labelStyle: labelStyle,
                                                labelText: fieldLabel,
                                                suffixIcon: Icon(
                                                  Icons.calendar_today,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      DateTime? pickedDate =
                                                          await showDatePicker(
                                                        context: context,
                                                        initialDate:
                                                            DateTime.now(),
                                                        firstDate: DateTime(1900),
                                                        lastDate: DateTime(2100),
                                                      );
          
                                                      if (pickedDate != null) {
                                                        String displayDate =
                                                            DateFormat(
                                                                    'dd-MM-yyyy')
                                                                .format(
                                                                    pickedDate);
                                                        _controllers[fieldCode]!
                                                            .text = displayDate;
          
                                                        // ✅ STORAGE → FIXED (UTC MIDNIGHT)
                                                        final isoDate =
                                                            DateTime.utc(
                                                          pickedDate.year,
                                                          pickedDate.month,
                                                          pickedDate.day,
                                                        ).toIso8601String();
          
                                                        controller.setFieldValue(
                                                            fieldLabel, isoDate);
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          );
                                        }
          
          // itime field के लिए
                                        if (fieldType == 'itime' && result) {
                                          // ✅ Field code & label
                                          String fieldCode =
                                              field['code']; // e.g. 'itime'
                                          String fieldLabel =
                                              field['label']; // e.g. 'ITime'
          
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                            () => TextEditingController(),
                                          );
          
                                          int defaultToCurrentTime =
                                              field['defaultToCurrentTime'] ?? 0;
          
                                          // ✅ Set default current time if field is empty and defaultToCurrentTime is 1
                                          if (defaultToCurrentTime == 1 &&
                                              (controller.getFieldValue(
                                                          fieldLabel) ==
                                                      null ||
                                                  controller
                                                      .getFieldValue(fieldLabel)!
                                                      .isEmpty)) {
                                            final now = DateTime.now();
          
                                            // ✅ STORAGE → ISO time with fixed date (1970-01-01)
                                            final isoTime = DateTime(1970, 1, 1,
                                                    now.hour, now.minute)
                                                .toUtc()
                                                .toIso8601String();
                                            controller.setFieldValue(
                                                fieldLabel, isoTime);
          
                                            // ✅ UI display (AM/PM)
                                            String displayTime =
                                                DateFormat('hh:mm a').format(now);
                                            _controllers[fieldCode]!.text =
                                                displayTime;
                                          }
          
                                          // ✅ Prefill from dateTime (if exists) - only if controller is empty
                                          String? dateTimeValue = controller
                                              .getFieldValue('dateTime');
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              dateTimeValue != null) {
                                            DateTime dt =
                                                DateTime.parse(dateTimeValue)
                                                    .toLocal();
          
                                            // UI display (AM/PM)
                                            String displayTime =
                                                DateFormat('hh:mm a').format(dt);
                                            _controllers[fieldCode]!.text =
                                                displayTime;
          
                                            // ✅ STORAGE → ISO time with fixed date
                                            final isoTime = DateTime(1970, 1, 1,
                                                    dt.hour, dt.minute)
                                                .toUtc()
                                                .toIso8601String();
                                            controller.setFieldValue(
                                                fieldLabel, isoTime);
                                          }
          
                                          // ✅ Also check if there's already a value stored for itime field itself
                                          String? storedTimeValue = controller
                                              .getFieldValue(fieldLabel);
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              storedTimeValue != null &&
                                              storedTimeValue.isNotEmpty) {
                                            try {
                                              // Parse the stored ISO time
                                              DateTime dt =
                                                  DateTime.parse(storedTimeValue)
                                                      .toLocal();
          
                                              // UI display (AM/PM)
                                              String displayTime =
                                                  DateFormat('hh:mm a')
                                                      .format(dt);
                                              _controllers[fieldCode]!.text =
                                                  displayTime;
                                            } catch (e) {
                                              print(
                                                  'Error parsing stored itime value: $e');
                                            }
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              controller: _controllers[fieldCode],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                filled: true,
                                                labelStyle: labelStyle,
                                                labelText: fieldLabel,
                                                suffixIcon: Icon(
                                                  Icons.access_time,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      TimeOfDay? pickedTime =
                                                          await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                            TimeOfDay.now(),
                                                        builder:
                                                            (context, child) {
                                                          return MediaQuery(
                                                            data: MediaQuery.of(
                                                                    context)
                                                                .copyWith(
                                                              alwaysUse24HourFormat:
                                                                  false,
                                                            ),
                                                            child: child!,
                                                          );
                                                        },
                                                      );
          
                                                      if (pickedTime != null) {
                                                        final now =
                                                            DateTime.now();
                                                        final dt = DateTime(
                                                          now.year,
                                                          now.month,
                                                          now.day,
                                                          pickedTime.hour,
                                                          pickedTime.minute,
                                                        );
          
                                                        String displayTime =
                                                            DateFormat('hh:mm a')
                                                                .format(dt);
                                                        _controllers[fieldCode]!
                                                            .text = displayTime;
          
                                                        final isoTime = DateTime(
                                                          1970,
                                                          1,
                                                          1,
                                                          pickedTime.hour,
                                                          pickedTime.minute,
                                                        )
                                                            .toUtc()
                                                            .toIso8601String();
          
                                                        controller.setFieldValue(
                                                            fieldLabel, isoTime);
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          );
                                        }
                                        if (fieldType == 'dateandtime' &&
                                            result) {
                                          // ✅ Field code & label
                                          String fieldCode =
                                              field['code']; // e.g. 'dateTime'
                                          String fieldLabel =
                                              field['label']; // e.g. 'DateTime'
          
                                          _controllers.putIfAbsent(
                                            fieldCode,
                                            () => TextEditingController(),
                                          );
          
                                          // ✅ Prefill if value already exists
                                          String? storedValue = controller
                                              .getFieldValue(fieldLabel);
                                          if (_controllers[fieldCode]!
                                                  .text
                                                  .isEmpty &&
                                              storedValue != null) {
                                            DateTime dt =
                                                DateTime.parse(storedValue)
                                                    .toLocal();
          
                                            // UI display
                                            String displayValue =
                                                DateFormat('yyyy-MM-dd HH:mm')
                                                    .format(dt);
                                            _controllers[fieldCode]!.text =
                                                displayValue;
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              style: labelStyle,
                                              controller: _controllers[fieldCode],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelStyle: labelStyle,
                                                errorText: controller
                                                    .resulterror[fieldCode],
                                                labelText: fieldLabel,
                                                suffixIcon: readOnly != 1
                                                    ? Icon(
                                                        Icons.calendar_today,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      )
                                                    : null,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      // 1️⃣ Pick Date
                                                      DateTime? selectedDate =
                                                          await showDatePicker(
                                                        context: context,
                                                        initialDate:
                                                            DateTime.now(),
                                                        firstDate: DateTime(1900),
                                                        lastDate: DateTime(2100),
                                                      );
          
                                                      if (selectedDate != null) {
                                                        // 2️⃣ Pick Time
                                                        TimeOfDay? selectedTime =
                                                            await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                              TimeOfDay.now(),
                                                        );
          
                                                        if (selectedTime !=
                                                            null) {
                                                          final combinedDateTime =
                                                              DateTime(
                                                            selectedDate.year,
                                                            selectedDate.month,
                                                            selectedDate.day,
                                                            selectedTime.hour,
                                                            selectedTime.minute,
                                                          );
          
                                                          // UI display
                                                          String displayValue =
                                                              DateFormat(
                                                                      'yyyy-MM-dd HH:mm')
                                                                  .format(
                                                                      combinedDateTime);
          
                                                          // ✅ STORAGE → ISO UTC format
                                                          final isoValue =
                                                              combinedDateTime
                                                                  .toUtc()
                                                                  .toIso8601String();
          
                                                          setState(() {
                                                            _controllers[
                                                                        fieldCode]!
                                                                    .text =
                                                                displayValue;
                                                            controller
                                                                .setFieldValue(
                                                                    fieldLabel,
                                                                    isoValue);
                                                          });
                                                        }
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          );
                                        }
                                        if (fieldType == 'text' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              style: labelStyle,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.text,
                                              onChanged: (value) async {
                                                if (event != "") {
                                                  await controller.GetUserData(
                                                      code, rule, value);
                                                  setState(() {
                                                    //controller.dataMap[field['code']] = value;
                                                    controller.setFieldValue(
                                                        label, value);
                                                  });
                                                } else {
                                                  setState(() {
                                                    controller.dataMap[
                                                        field['code']] = value;
                                                    controller.setFieldValue(
                                                        label, value);
                                                  });
                                                }
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }
          
                                                final regexPattern = field[
                                                    'regex']; // e.g., "^[1-5]$"
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
          
                                                return null;
                                              },
                                            ),
                                          );
                                        }
                                        if (fieldType == 'email' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              style: labelStyle,
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              onChanged: (value) async {
                                                setState(() {
                                                  controller.dataMap[
                                                      field['code']] = value;
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
                                        if (showDropdown && result) {
                                          final dropdownItems =
                                              controller.prelaodlist[yUsecase] ??
                                                  [];
          
                                          // Safely get a set of valid dropdown values, ignoring any null items
                                          final dropdownValues = dropdownItems
                                              .where((item) =>
                                                  item != null &&
                                                  item['id'] != null)
                                              .map(
                                                  (item) => item['id'].toString())
                                              .toSet();
          
                                          final currentValue =
                                              controller.getFieldValue(label);
                                          final dropdownValue = dropdownValues
                                                  .contains(currentValue)
                                              ? currentValue
                                              : null;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 8.0),
                                            child:
                                                DropdownButtonFormField<String>(
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
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                                hintText:
                                                    'Select $label', // Placeholder hint text
                                              ),
                                              value: dropdownValue,
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: null,
                                                  // Placeholder value
                                                  child: Text('Select an $label',
                                                      style: labelStyle
                                                      //     TextStyle(color: Colors.black),
                                                      ),
                                                ),
                                                // Filter out null items before mapping to DropdownMenuItem
                                                ...dropdownItems
                                                    .where((item) =>
                                                        item != null &&
                                                        item['_val'] != null &&
                                                        item['id'] != null)
                                                    .map<
                                                        DropdownMenuItem<
                                                            String>>((item) {
                                                  return DropdownMenuItem<String>(
                                                    value: item['id'].toString(),
                                                    child: Text(item['_val']),
                                                  );
                                                }).toList(),
                                              ],
                                              onChanged: readOnly != 1
                                                  ? (value) async {
                                                      controller.onChange(
                                                          field, value);
                                                      if (event != "") {
                                                        await controller
                                                            .GetUserData(code,
                                                                rule, value!);
                                                        controller.admissionId =
                                                            value;
                                                        setState(() {
                                                          controller
                                                              .setFieldValue(
                                                                  label, value);
                                                        });
                                                      } else {
                                                        controller.setFieldValue(
                                                            label, value!);
                                                      }
                                                    }
                                                  : null,
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
                                        if ((fieldType == 'number' ||
                                                fieldType == 'phone' ||
                                                fieldType == 'long' ||
                                                fieldType == 'decimal') &&
                                            result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              style: labelStyle,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) async {
                                                controller
                                                        .dataMap[field['code']] =
                                                    value; // Directly updating dataMap
                                                controller.setInitialValue(
                                                    field['code'], value);
                                                controller.setFieldValue(
                                                    label, value);
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }
          
                                                final regexPattern = field[
                                                    'regex']; // e.g., "^[1-5]$"
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
          
                                                return null;
                                              },
                                            ),
                                          );
                                        }
                                        if (fieldType == 'date' && result) {
                                          // Set current date if defaultToCurrentDate is 1 and field is empty
                                          if (defaultToCurrentDate == 1 &&
                                              (controller.getFieldValue(label) ==
                                                      null ||
                                                  controller
                                                      .getFieldValue(label)!
                                                      .isEmpty)) {
                                            final String currentDate =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(DateTime.now());
          
                                            controller.setFieldValue(
                                                label, currentDate);
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 2.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              // disables input if readOnly == 1
                                              style: labelStyle,
                                              controller: TextEditingController(
                                                text: controller
                                                    .getFieldValue(label),
                                              ),
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                suffixIcon: readOnly != 1
                                                    ? Icon(
                                                        Icons.calendar_today,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      )
                                                    : null,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      DateTime? selectedDate;
                                                      if (minDateStr.isEmpty &&
                                                          maxDateStr.isEmpty) {
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
                                                      } else {
                                                        DateTime minDate =
                                                            DateTime.parse(
                                                                minDateStr);
                                                        DateTime maxDate =
                                                            DateTime.parse(
                                                                maxDateStr);
                                                        DateTime initial =
                                                            DateTime.now();
                                                        if (initial
                                                            .isBefore(minDate)) {
                                                          initial = minDate;
                                                        } else if (initial
                                                            .isAfter(maxDate)) {
                                                          initial = maxDate;
                                                        }
                                                        selectedDate =
                                                            await showDatePicker(
                                                          context: context,
                                                          initialDate: initial,
                                                          firstDate: minDate,
                                                          lastDate: maxDate,
                                                        );
                                                      }
          
                                                      if (selectedDate != null) {
                                                        // String formattedDate = "${selectedDate.toLocal()}".split(' ')[0];
                                                        String formattedDate =
                                                            DateFormat(
                                                                    'yyyy-MM-dd')
                                                                .format(
                                                                    selectedDate);
                                                        if (event != "") {
                                                          var response = await controller
                                                              .validateAndSubmitDate(
                                                                  rule,
                                                                  formattedDate);
          
                                                          if (response != null &&
                                                              response[
                                                                      'success'] ==
                                                                  false) {
                                                            String errorMessage =
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
                                                            setState(() {
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      formattedDate);
                                                            });
                                                          }
                                                        } else {
                                                          setState(() {
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    formattedDate);
                                                          });
                                                        }
                                                      }
                                                    }
                                                  : null,
          
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
                                          // Initialize controller if not already present
                                          _controllers.putIfAbsent(label,
                                              () => TextEditingController());
          
                                          // Prefill with current time if empty and defaultToCurrentTime == 1
                                          int defaultToCurrentTime =
                                              field['defaultToCurrentTime'] ?? 0;
                                          if (_controllers[label]!.text.isEmpty) {
                                            if (defaultToCurrentTime == 1) {
                                              String currentTime =
                                                  DateFormat('HH:mm')
                                                      .format(DateTime.now());
                                              _controllers[label]!.text =
                                                  currentTime;
                                              controller.setFieldValue(
                                                  label, currentTime);
                                            } else {
                                              _controllers[label]!.text =
                                                  controller
                                                          .getFieldValue(label) ??
                                                      '';
                                            }
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: TextFormField(
                                              readOnly: true,
                                              enabled: readOnly != 1,
                                              style: labelStyle,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                labelText: label,
                                                suffixIcon: readOnly != 1
                                                    ? Icon(
                                                        Icons.access_time,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      )
                                                    : null,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              onTap: readOnly != 1
                                                  ? () async {
                                                      TimeOfDay? selectedTime =
                                                          await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                            TimeOfDay.now(),
                                                      );
                                                      if (selectedTime != null) {
                                                        final now =
                                                            DateTime.now();
                                                        final dateTime = DateTime(
                                                            now.year,
                                                            now.month,
                                                            now.day,
                                                            selectedTime.hour,
                                                            selectedTime.minute);
          
                                                        String formattedTime =
                                                            DateFormat('HH:mm')
                                                                .format(dateTime);
          
                                                        setState(() {
                                                          _controllers[label]!
                                                                  .text =
                                                              formattedTime;
                                                          controller
                                                              .setFieldValue(
                                                                  label,
                                                                  formattedTime);
                                                        });
                                                      }
                                                    }
                                                  : null,
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
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                errorText:
                                                    controller.resulterror[code],
                                                labelStyle: labelStyle,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.text,
                                              onChanged: (value) {
                                                setState(() {
                                                  controller.dataMap[
                                                      field['code']] = value;
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
                                        if (fieldType == 'location' && result) {
                                          final locationMap =
                                              controller.getFieldValue(label);
                                          if (locationMap != null &&
                                              locationMap is Map) {
                                            controller.latController.text =
                                                locationMap[0].toString() ?? '';
                                            controller.longController.text =
                                                locationMap[1].toString() ?? '';
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  label,
                                                  style: labelStyle,
                                                ),
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey,
                                                          width: 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons.location_on,
                                                              color:
                                                                  Appcolorblue),
                                                          onPressed: () {
                                                            setCurrentLocation(
                                                                label);
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons
                                                                  .remove_red_eye,
                                                              color:
                                                                  Appcolorblue),
                                                          onPressed: () async {
                                                            final lat = controller
                                                                .latController
                                                                .text;
                                                            final lng = controller
                                                                .longController
                                                                .text;
                                                            if (lat.isEmpty ||
                                                                lng.isEmpty) {
                                                              showDialog(
                                                                context: context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      "Missing Location"),
                                                                  content: const Text(
                                                                      "Location not available. Please set the location first.."),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.pop(
                                                                              context),
                                                                      child: Text(
                                                                          "OK"),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            } else {
                                                              final Uri mapUrl =
                                                                  Uri.parse(
                                                                      "https://www.google.com/maps?q=$lat,$lng");
                                                              await launchUrl(
                                                                  mapUrl,
                                                                  mode: LaunchMode
                                                                      .platformDefault);
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.delete,
                                                              color: Colors.red),
                                                          onPressed: () {
                                                            _clearText(label);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (controller
                                                    .showTextField.value) ...[
                                                  TextFormField(
                                                    controller:
                                                        controller.latController,
                                                    readOnly: true,
                                                    style: labelStyle,
                                                    decoration: InputDecoration(
                                                      labelText: 'Latitude',
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      labelStyle: labelStyle,
                                                      border:
                                                          const OutlineInputBorder(),
                                                    ),
                                                    validator: isRequired
                                                        ? (value) {
                                                            if (value == null ||
                                                                value.isEmpty) {
                                                              return 'Please enter latitude';
                                                            }
                                                            return null;
                                                          }
                                                        : null,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  TextFormField(
                                                    controller:
                                                        controller.longController,
                                                    readOnly: true,
                                                    style: labelStyle,
                                                    decoration: InputDecoration(
                                                      labelText: 'Longitude',
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      labelStyle: labelStyle,
                                                      border:
                                                          const OutlineInputBorder(),
                                                    ),
                                                    validator: isRequired
                                                        ? (value) {
                                                            if (value == null ||
                                                                value.isEmpty) {
                                                              return 'Please enter longitude';
                                                            }
                                                            return null;
                                                          }
                                                        : null,
                                                  ),
                                                ],
                                                (onsavebuttonclick &&
                                                        (controller.longController
                                                                .text
                                                                .trim()
                                                                .isEmpty ||
                                                            controller
                                                                .latController
                                                                .text
                                                                .trim()
                                                                .isEmpty))
                                                    ? Text(
                                                        "Location is Required",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      )
                                                    : SizedBox()
                                                /* if (controller.showTextField.value) ...[
                                              TextField(
                                                controller: controller.latController,
                                                readOnly: true,
                                                style: labelStyle,
                                                decoration: InputDecoration(
                                                  labelText: 'Latitude',
                                                  fillColor: isDarkMode
                                                      ? Colors.black
                                                      : Colors.white,
                                                  labelStyle: labelStyle,
                                                  border: const OutlineInputBorder(),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: controller.longController,
                                                readOnly: true,
                                                style: labelStyle,
                                                decoration: InputDecoration(
                                                  labelText: 'Longitude',
                                                  fillColor: isDarkMode
                                                      ? Colors.black
                                                      : Colors.white,
                                                  labelStyle: labelStyle,
                                                  border: const OutlineInputBorder(),
                                                ),
                                              ),
                                            ],*/
                                              ],
                                            ),
                                          );
                                        }
                                        if (fieldType == 'combobox' && result) {
                                          comboboxmapValues =
                                              field['values'] ?? [];
                                          List<String> _options =
                                              List<String>.from(
                                                  comboboxmapValues.isNotEmpty
                                                      ? comboboxmapValues
                                                      : [
                                                          'Apple',
                                                          'Banana',
                                                          'Cherry',
                                                          'Date'
                                                        ]);
          
                                          List<String> _filteredOptions =
                                              List.from(_options);
          
                                          return StatefulBuilder(
                                            builder: (context, setInnerState) {
                                              void _saveValue(String value) {
                                                controller
                                                        .dataMap[field['code']] =
                                                    value;
                                                controller.setFieldValue(
                                                    label, value);
                                              }
          
                                              void _onTextChanged(String value) {
                                                _saveValue(
                                                    value); // Save while typing
                                                setInnerState(() {
                                                  _filteredOptions = _options
                                                      .where((item) => item
                                                          .toLowerCase()
                                                          .contains(value
                                                              .toLowerCase()))
                                                      .toList();
                                                });
                                              }
          
                                              void _onItemSelected(String value) {
                                                _controllers[label]!.text = value;
                                                _saveValue(
                                                    value); // Save on dropdown selection
                                                FocusScope.of(context).unfocus();
                                                setInnerState(() {
                                                  _filteredOptions = _options;
                                                });
                                              }
          
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0,
                                                        horizontal: 5),
                                                child: TextField(
                                                  controller: _controllers[label],
                                                  enabled: readOnly != 1,
                                                  // disable input if readOnly
                                                  onChanged: readOnly != 1
                                                      ? _onTextChanged
                                                      : null,
                                                  decoration: InputDecoration(
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    labelText: 'Select a $label',
                                                    suffixIcon:
                                                        PopupMenuButton<String>(
                                                      icon: const Icon(
                                                          Icons.arrow_drop_down),
                                                      itemBuilder: (context) {
                                                        return _filteredOptions
                                                            .map((String option) {
                                                          return PopupMenuItem<
                                                              String>(
                                                            value: option,
                                                            child: Text(
                                                              option,
                                                              style: labelStyle,
                                                            ),
                                                          );
                                                        }).toList();
                                                      },
                                                      onSelected: _onItemSelected,
                                                    ),
                                                    border:
                                                        const OutlineInputBorder(),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                        if (fieldType == 'map' && result) {
                                          List<dynamic> mapValues =
                                              field['values'] ?? [];
          
                                          // Dropdown items
                                          List<DropdownMenuItem<String>>
                                              dropdownItems = [];
          
                                          // Add placeholder
                                          dropdownItems.add(
                                            DropdownMenuItem<String>(
                                              value: '', // empty string for none
                                              child: Text(
                                                'Select $label',
                                                style: labelStyle,
                                              ),
                                            ),
                                          );
          
                                          // Add map values (store "key - value")
                                          dropdownItems.addAll(
                                            mapValues
                                                .map<DropdownMenuItem<String>>(
                                                    (item) {
                                              final String key =
                                                  (item['key'] ?? '').toString();
                                              final String val =
                                                  (item['value'] ?? '')
                                                      .toString();
                                              final String combined =
                                                  '$key - $val';
                                              return DropdownMenuItem<String>(
                                                value:
                                                    combined, // ✅ store key - value
                                                child: Text(
                                                  combined,
                                                  style: labelStyle,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              );
                                            }).toList(),
                                          );
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 8),
                                            child:
                                                DropdownButtonFormField<String>(
                                              style: labelStyle,
                                              isExpanded: true,
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
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              value: controller
                                                          .getFieldValue(label)
                                                          ?.isEmpty ??
                                                      true
                                                  ? '' // empty if no value
                                                  : controller.getFieldValue(
                                                      label), // ✅ now matches "key - value"
                                              items: dropdownItems,
          
                                              // Placeholder and selected text
                                              selectedItemBuilder:
                                                  (BuildContext context) {
                                                List<Widget> selectedWidgets = [
                                                  Text('Select $label',
                                                      style: labelStyle),
                                                ];
                                                selectedWidgets.addAll(
                                                    mapValues.map<Widget>((item) {
                                                  final String key =
                                                      (item['key'] ?? '')
                                                          .toString();
                                                  final String val =
                                                      (item['value'] ?? '')
                                                          .toString();
                                                  return Text(
                                                    '$key - $val',
                                                    style: labelStyle,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  );
                                                }).toList());
                                                return selectedWidgets;
                                              },
          
                                              onChanged: readOnly != 1
                                                  ? (value) async {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        controller.setFieldValue(
                                                            label, '');
                                                        controller.admissionId =
                                                            '';
                                                      } else {
                                                        if (event != "") {
                                                          await controller
                                                              .GetUserData(code,
                                                                  rule, value);
                                                          controller.admissionId =
                                                              value;
                                                        }
                                                        setState(() {
                                                          controller.setFieldValue(
                                                              label,
                                                              value); // ✅ saves "1 - Apple"
                                                        });
                                                      }
                                                    }
                                                  : null,
          
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
          
                                        if (fieldType == 'boolean' && result) {
                                          String? savedValue = controller
                                              .dataMap[field['code']]
                                              .toString();
                                          if (savedValue == '1') {
                                            isSelected = [true, false];
                                          } else if (savedValue == '0') {
                                            isSelected = [false, true];
                                          } else {
                                            isSelected = [false, false];
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 9),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Text(label,
                                                        style: labelStyle)),
                                                const SizedBox(height: 10),
                                                Align(
                                                  alignment: Alignment.topLeft,
                                                  child: ToggleButtons(
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                    selectedColor: Colors.white,
                                                    borderColor: isDarkMode
                                                        ? const Color(0xFF4F76E2)
                                                        : const Color(0xFF1A237E),
                                                    fillColor: isDarkMode
                                                        ? const Color(0xFF4F76E2)
                                                        : const Color(0xFF1A237E),
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    isSelected: isSelected,
                                                    onPressed: (index) {
                                                      setState(() {
                                                        for (int i = 0;
                                                            i < isSelected.length;
                                                            i++) {
                                                          isSelected[i] = i ==
                                                              index; // Set the selected index to true
                                                        }
                                                        var selectedValue =
                                                            index == 0 ? 1 : 0;
                                                        String savedValue =
                                                            selectedValue
                                                                .toString();
                                                        setState(() {
                                                          controller.dataMap[
                                                                  field['code']] =
                                                              savedValue;
                                                          controller
                                                              .setFieldValue(
                                                                  label,
                                                                  savedValue);
                                                        });
                                                      });
                                                    },
                                                    children: const [
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 16),
                                                        child: Text(
                                                          "Yes",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 16),
                                                        child: Text(
                                                          "No",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        if (fieldType == 'list' && result) {
                                          final List<dynamic> uniqueValues =
                                              (field['values'] ?? [])
                                                  .toSet()
                                                  .toList();
                                          String? selectedValue =
                                              controller.getFieldValue(label);
          
                                          if (!uniqueValues
                                              .contains(selectedValue)) {
                                            selectedValue = null;
                                          }
          
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0, horizontal: 7),
                                            child:
                                                DropdownButtonFormField<String>(
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
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                                hintText: 'Select $label',
                                                hintStyle:
                                                    const TextStyle(fontSize: 10),
                                              ),
                                              value: selectedValue,
                                              items: [
                                                // Placeholder
                                                DropdownMenuItem<String>(
                                                  value: null,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                    ),
                                                    child: Text(
                                                      'Select an $label',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      style: labelStyle,
                                                    ),
                                                  ),
                                                ),
                                                ...uniqueValues.map<
                                                        DropdownMenuItem<String>>(
                                                    (value) {
                                                  return DropdownMenuItem<String>(
                                                    value: value,
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxWidth:
                                                            MediaQuery.of(context)
                                                                    .size
                                                                    .width *
                                                                0.7,
                                                      ),
                                                      child: Text(
                                                        value,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        maxLines: 2,
                                                        style: labelStyle,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                              onChanged: readOnly != 1
                                                  ? (value) async {
                                                      // Clear the field if placeholder is selected
                                                      final newValue =
                                                          value ?? '';
                                                      controller.setFieldValue(
                                                          label, newValue);
          
                                                      if (value != null &&
                                                          event != "") {
                                                        await controller
                                                            .GetUserData(code,
                                                                rule, value);
                                                        controller.admissionId =
                                                            value;
                                                      }
          
                                                      setState(() {
                                                        updateResult(
                                                            reqBody, showvalue);
                                                      });
                                                    }
                                                  : null,
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
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // File input field
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 8.0),
                                                  child: TextFormField(
                                                    onTap: () {
                                                      if (captureImage == 1) {
                                                      getImage1(code);
                                                      } else {
                                                        _pickAndUploadImage(code);
                                                      }
                                                    },
                                                    style: labelStyle,
                                                    readOnly: true,
                                                    controller:
                                                        TextEditingController(
                                                      text: controller.imagePaths[
                                                                  code] !=
                                                              null
                                                          ? controller
                                                              .imagePaths[code]!
                                                              .split('/')
                                                              .last
                                                          : '',
                                                    ),
                                                    decoration: InputDecoration(
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      errorText: controller
                                                          .resulterror[code],
                                                      labelText: label,
                                                      labelStyle: labelStyle,
                                                      border:
                                                          const OutlineInputBorder(
                                                        borderSide: BorderSide(
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
                                                           getImage1(code);
                                                          } else {
                                                            _pickAndUploadImage(
                                                                code);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        controller.setFieldValue(
                                                            label, value);
                                                      });
                                                    },
                                                  ),
                                                ),
          
                                                // File preview
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 16.0),
                                                  child: controller
                                                              .imagePaths[code] !=
                                                          null
                                                      ? Image.file(
                                                          File(controller
                                                              .imagePaths[code]!),
                                                          width: 100,
                                                          height: 100,
                                                        )
                                                      : GestureDetector(
                                                          onTap: () async {
                                                            final docId =
                                                                _controllers[
                                                                        label]
                                                                    ?.text;
                                                            if (docId != null &&
                                                                docId
                                                                    .isNotEmpty) {
                                                              final Uri testUrl =
                                                                  Uri.parse(
                                                                "https://cuickdev.com/API/DOCS/api/doc/$docId",
                                                              );
                                                              await launchUrl(
                                                                  testUrl);
                                                            }
                                                          },
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl: (_controllers[
                                                                            label]
                                                                        ?.text
                                                                        .isNotEmpty ??
                                                                    false)
                                                                ? "https://cuickdev.com/API/DOCS/api/doc/th/${_controllers[label]!.text}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                                : imageUrlHelper
                                                                    .applogourl,
                                                            width: 100,
                                                            height: 100,
                                                            errorWidget: (context,
                                                                    url, error) =>
                                                                const Icon(
                                                                    Icons.error),
                                                          ),
                                                        ),
                                                )
                                              ],
                                            ),
                                          );
                                        }
          
                                        if (fieldType == 'doc' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Input field
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 8.0),
                                                  child: TextFormField(
                                                    style: labelStyle,
                                                    onTap: () =>
                                                        _pickAndUploadFile(code),
                                                    readOnly: true,
                                                    controller:
                                                        TextEditingController(
                                                      text: controller.docPaths[
                                                                  code] !=
                                                              null
                                                          ? controller
                                                              .docPaths[code]!
                                                              .split('/')
                                                              .last
                                                          : '',
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: label,
                                                      labelStyle: labelStyle,
                                                      errorText: controller
                                                          .resulterror[code],
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      border:
                                                          const OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Colors.green),
                                                      ),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          Icons.attachment,
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                        onPressed: () =>
                                                            _pickAndUploadFile(
                                                                code),
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        controller
                                                                .docPaths[code] =
                                                            value;
                                                        controller.setFieldValue(
                                                            label, '0');
                                                        controller
                                                            .setInitialValue(
                                                                label, '0');
                                                      });
                                                    },
                                                  ),
                                                ),
          
                                                // Preview area
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          vertical: 16.0),
                                                  child: controller
                                                              .docPaths[code] !=
                                                          null
                                                      // Show local picked file
                                                      ? Image.file(
                                                          File(controller
                                                              .docPaths[code]!),
                                                          width: 100,
                                                          height: 100,
                                                        )
                                                      // Otherwise try remote doc thumbnail
                                                      : GestureDetector(
                                                          onTap: () async {
                                                            final docId =
                                                                _controllers[
                                                                        label]
                                                                    ?.text;
                                                            if (docId != null &&
                                                                docId
                                                                    .isNotEmpty) {
                                                              final Uri url =
                                                                  Uri.parse(
                                                                      "https://cuickdev.com/API/DOCS/api/doc/$docId");
                                                              await launchUrl(
                                                                  url);
                                                            }
                                                          },
                                                          child:
                                                              CachedNetworkImage(
                                                            width: 100,
                                                            height: 100,
                                                            imageUrl: (_controllers[
                                                                            label]
                                                                        ?.text
                                                                        .isNotEmpty ??
                                                                    false)
                                                                ? "https://cuickdev.com/API/DOCS/api/doc/th/${_controllers[label]!.text}?t=${DateTime.now().millisecondsSinceEpoch}"
                                                                : imageUrlHelper
                                                                    .applogourl,
                                                            errorWidget: (context,
                                                                    url, error) =>
                                                                const Icon(
                                                                    Icons
                                                                        .picture_as_pdf,
                                                                    size: 40),
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
          
                                        if (fieldType == 'url' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                errorText:
                                                    controller.resulterror[code],
                                                labelStyle: labelStyle,
                                                labelText: label,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                              ),
                                              keyboardType: TextInputType.url,
                                              onChanged: (value) async {
                                                if (event != "") {
                                                  await controller.GetUserData(
                                                      code, rule, value);
                                                  setState(() {
                                                    controller.dataMap[
                                                        field['code']] = value;
          
                                                    controller.setFieldValue(
                                                        label, value);
                                                    updateResult(
                                                        reqBody, showvalue);
                                                  });
                                                } else {
                                                  setState(() {
                                                    controller.dataMap[
                                                        field['code']] = value;
                                                    controller.setFieldValue(
                                                        label, value);
                                                    updateResult(
                                                        reqBody, showvalue);
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
                                        if (fieldType == 'password' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              controller: _controllers[label],
                                              style: labelStyle,
                                              decoration: InputDecoration(
                                                errorText:
                                                    controller.resulterror[code],
                                                labelStyle: labelStyle,
                                                labelText: label,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue)),
                                                // suffixIcon: Icon(Icons.lock), // Password icon
                                              ),
                                              onChanged: (value) async {
                                                if (event != "") {
                                                  await controller.GetUserData(
                                                      code, rule, value);
                                                  setState(() {
                                                    controller.dataMap[
                                                        field['code']] = value;
          
                                                    controller.setFieldValue(
                                                        label, value);
                                                    updateResult(
                                                        reqBody, showvalue);
                                                  });
                                                } else {
                                                  setState(() {
                                                    controller.dataMap[
                                                        field['code']] = value;
                                                    controller.setFieldValue(
                                                        label, value);
                                                    updateResult(
                                                        reqBody, showvalue);
                                                  });
                                                }
                                              },
                                              validator: (value) {
                                                if (isRequired &&
                                                    (value == null ||
                                                        value.isEmpty)) {
                                                  return 'Please enter $label';
                                                }
          
                                                final regexPattern = field[
                                                    'regex']; // e.g., "^[1-5]$"
                                                if (regexPattern != null &&
                                                    value != null &&
                                                    value.isNotEmpty) {
                                                  final regex =
                                                      RegExp(regexPattern);
                                                  if (!regex.hasMatch(value)) {
                                                    return 'Invalid input for $label';
                                                  }
                                                }
          
                                                return null;
                                              },
                                              // validator: isRequired
                                              //     ? (value) {
                                              //         if (value == null || value.isEmpty) {
                                              //           return 'Please enter $label';
                                              //         }
                                              //         return null;
                                              //       }
                                              //     : null,
                                            ),
                                          );
                                        }
                                        if (fieldType == 'textarea' && result) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5.0, horizontal: 8.0),
                                            child: TextFormField(
                                              enabled: readOnly != 1,
                                              readOnly: readOnly == 1,
                                              style: labelStyle,
                                              controller: _controllers[label],
                                              decoration: InputDecoration(
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                labelText: label,
                                                labelStyle: labelStyle,
                                                errorText:
                                                    controller.resulterror[code],
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Appcolorblue),
                                                ),
                                              ),
                                              keyboardType:
                                                  TextInputType.multiline,
                                              maxLines: null,
                                              // Allows the textarea to expand based on input
                                              onChanged: (value) async {
                                                setState(() {
                                                  controller.dataMap[
                                                      field['code']] = value;
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
                                        return const SizedBox.shrink();
                                      }).toList(),
                                      
                                      
                                      const SizedBox(height: 23),
                                      Center(
                                        child: Wrap(
                                          spacing: 10.0,
                                          runSpacing: 10.0,
                                          alignment: WrapAlignment.center,
                                          children:
                                              controller.buttons.where((button) {
                                            switch (button.name.toLowerCase()) {
                                              case 'list':
                                                return widget.isread == 1;
                                              case 'delete':
                                                return widget.isdelete == 1;
                                              case 'update':
                                                return widget.isupdate == 1;
                                              case 'save':
                                                return widget.iscreate == 1;
                                              case 'new':
                                                return widget.iscreate == 1;
                                              case 'cancel':
                                                return widget.iscreate == 1;
                                              default:
                                                return true;
                                            }
                                          }).map((button) {
                                            return GestureDetector(
                                              onTap: () async {
                                                if (button.name.toLowerCase() ==
                                                    'save') {
                                                  if (isSaving)
                                                    return; // 🛑 Prevent multiple submissions
          
                                                  setState(() {
                                                    onsavebuttonclick = true;
                                                    isSaving = true;
                                                  });
          
                                                  if (_formKey.currentState
                                                          ?.validate() ??
                                                      false) {
                                                    if (isLocationValid) {
                                                      Map<String, dynamic>?
                                                          response =
                                                          await SaveForm();
          
                                                      if (response != null &&
                                                          response['success']) {
                                                        setState(() {
                                                          controller.saveform_id
                                                                  .value =
                                                              response['result']
                                                                  ['data']['id'];
                                                        });
          
                                                        // Optional: show success toast
                                                      } else {
                                                        var inputError =
                                                            response?['result']
                                                                ['inputerror'];
                                                        setState(() {
                                                          controller.resulterror
                                                              .clear();
          
                                                          if (inputError !=
                                                              null) {
                                                            inputError.forEach(
                                                                (key, value) {
                                                              controller
                                                                      .resulterror[
                                                                  key] = value;
                                                              CherryToast.error(
                                                                backgroundColor:
                                                                    const Color(
                                                                        0xFFF8D0D9),
                                                                animationDuration:
                                                                    Durations
                                                                        .short1,
                                                                title: const Text(
                                                                    "Error Saving Form",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black)),
                                                              ).show(Get
                                                                  .overlayContext!);
                                                            });
                                                          } else {
                                                            print(
                                                                'No input error found in response');
                                                            CherryToast.error(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFFF8D0D9),
                                                              animationDuration:
                                                                  Durations
                                                                      .short1,
                                                              title: const Text(
                                                                  "Location is required. Form not submitted",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black)),
                                                            ).show(Get
                                                                .overlayContext!);
                                                          }
                                                        });
                                                      }
                                                    } else {}
                                                  }
          
                                                  setState(() {
                                                    isSaving =
                                                        false; // ✅ Re-enable button after save attempt
                                                  });
                                                } else {
                                                  // Other buttons
                                                  handleButtonClick(
                                                      button.name.toLowerCase());
                                                }
                                              },
                                              child: Opacity(
                                                opacity:
                                                    (button.name.toLowerCase() ==
                                                                'save' &&
                                                            isSaving)
                                                        ? 0.5
                                                        : 1.0,
                                                child: Container(
                                                  height: 45,
                                                  width: 120,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (button.name.toLowerCase() ==
                                                                    'save' &&
                                                                isSaving)
                                                            ? Colors.grey.shade300
                                                            : null,
                                                    border: Border.all(
                                                      color: isDarkMode
                                                          ? const Color(
                                                              0xFF4F76E2)
                                                          : const Color(
                                                              0xFF1A237E),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(5),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      button.name.toUpperCase(),
                                                      style: TextStyle(
                                                        color: isDarkMode
                                                            ? const Color(
                                                                0xFF4F76E2)
                                                            : const Color(
                                                                0xFF1A237E),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Lato',
                                                        fontSize: 15,
                                                      ),
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
               
                    ]),
                  );
                },
              )),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            }),
          ]),
        ));
  }
}