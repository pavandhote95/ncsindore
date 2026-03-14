import 'dart:convert';
import 'dart:io';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/login_controller.dart';
import '../controller/tableview_controller.dart';
import 'DBHelper.dart';
import 'apihelper.dart';

class FormSyncService {
  final TableviewController viewcontroller = Get.put(TableviewController());
  static final FormSyncService _instance = FormSyncService._internal();
  factory FormSyncService() => _instance;
  final ApiBaseHelper helper = ApiBaseHelper();
  FormSyncService._internal();
  final LoginController controller = Get.put(LoginController(), permanent: true);
  void initialize() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results != ConnectivityResult.none) {
        debugPrint('Internet available! Trying to sync forms...');
        syncOfflineForms();
        // controller.GetorgDetails();
      } else {
        debugPrint('No internet connectionnnnn.');
      }
    });
  }
  Future<void> syncOfflineForms() async {
    debugPrint('syncOfflineForms---------------------->>>>');
    final forms = await DBHelper().getAllForms();
    debugPrint('forms----------------------//...$forms.');
    if (forms.isEmpty) {
      debugPrint('No offline forms to sync.');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    for (var form in forms) {
      try {
        final Map<String, dynamic> reqBody = jsonDecode(form['data']);
        final Map<String, dynamic> docPaths = jsonDecode(form['docPaths'] ?? '{}');
        final Map<String, dynamic> imagePaths = jsonDecode(form['imagePaths'] ?? '{}');

        String appCode = form['appCode'];
        String code = form['code'];
        String saveFormCode = form['saveformcode'];

        // 👉 Step 1: Save form initially (to get a valid formId)
        final response = await helper.postApi(
          "api/v1/$appCode/$code/$saveFormCode/saveForm;jsessionid=$sessionId",
          reqBody,
        );

        if (response != null && response['success'] == true) {
          String formId = response['result']['data']['id'].toString();
          bool uploadSuccess = true;

          // 👉 Step 2: Upload documents
          for (String key in docPaths.keys) {
            String localPath = docPaths[key];
            if (File(localPath).existsSync()) {
              bool success = await _uploadFile(File(localPath), key, formId,appCode,code);
              if (!success) uploadSuccess = false;
            } else {
              debugPrint('❌ Missing document for $key at $localPath');
              uploadSuccess = false;
            }
          }
          // 👉 Step 3: Upload images
          for (String key in imagePaths.keys) {
            String localPath = imagePaths[key];
            if (File(localPath).existsSync()) {
              bool success = await _uploadImage(XFile(localPath), key, formId,appCode,code);
              if (!success) uploadSuccess = false;
            } else {
              debugPrint('❌ Missing image for $key at $localPath');
              uploadSuccess = false;
            }
          }

          // 👉 Step 4: Re-save the form with updated image/doc values
          if (uploadSuccess) {
            reqBody['id'] = formId.toString();

            final updateResponse = await helper.postApi(
              "api/v1/$appCode/$code/$saveFormCode/saveForm;jsessionid=$sessionId",
              reqBody,
            );

            if (updateResponse != null && updateResponse['success'] == true) {

              Get.find<TableviewController>().update();
              viewcontroller.GetForm_API(viewcontroller.appurl.value);
              viewcontroller.CurrentPage.value = 0;

              await DBHelper().deleteForm(form['id']);
            } else {
              debugPrint('⚠️ Form $formId partial sync, upload ok, but save failed → ${updateResponse['message']}');
            }
          } else {
            debugPrint('⚠️ File uploads failed for form $formId. Not updating form.');
          }
        } else {
          debugPrint('❌ Failed to save form initially → ${response?['message']}');
        }
      } catch (e) {
        debugPrint('❌ Exception syncing form: $e');
      }
    }
  }

  Map<String, String> uploadDocument = {};
  Future<bool> _uploadImage(XFile pickedFile, String code, String formId, String appcode, String codevalue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    if (sessionId.isEmpty) return false;

    final uri = Uri.parse(
      'https://api.ncsindore.com/api/v1/${appcode}/${codevalue}/doc/$formId/0/$code;jsessionid=$sessionId',
    );
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        var dataValue = jsonResponse['result']['data'][code];
        // controller.uploadimage[code] = dataValue.toString();
        return true;
      } else {
        debugPrint('❌ Image upload failed: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Image upload error: $e');
      return false;
    }
  }
  Future<bool> _uploadFile(File pickedFile, String id, String formId,String appcode ,String codevalue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    if (sessionId.isEmpty) return false;
    int uploadDocumentId = (uploadDocument[id] ?? 0) as int;
    final uri = Uri.parse(
      'https://api.ncsindore.com/api/v1/${appcode}/${codevalue}/doc/$formId/$uploadDocumentId/$id;jsessionid=$sessionId',
    );
    var request = http.MultipartRequest('POST', uri);
    request.fields['id'] = formId;
    request.files.add(await http.MultipartFile.fromPath('file', pickedFile.path));

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        var dataValue = jsonResponse['result']['data'][id];
        uploadDocument[id] = dataValue.toString();
        return true;
      } else {
        debugPrint('❌ Document upload failed: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Document upload error: $e');
      return false;
    }
  }

  Future<void> syncForms() async {
    final forms = await DBHelper().getAllForms();
    if (forms.isEmpty) {
      debugPrint('No offline forms to sync.');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    for (var form in forms) {
      try {
        final Map<String, dynamic> reqBody = jsonDecode(form['data']);

        final response = await helper.postApi(
          "api/v1/${form['appCode']}/${form['code']}/${form['saveformcode']}/saveForm;jsessionid=$sessionId",
          // "api/v1/${form['appCode']}/${form['formCode']}/saveForm;jsessionid=$sessionId",
          reqBody,
        );

        if (response != null && response['success'] == true) {
          debugPrint('Form ID ${form['id']} synced successfully.');
          await DBHelper().deleteForm(form['id']);
        } else {
          debugPrint('Failed to sync form ID ${form['id']} → ${response['message']}');
        }
      } catch (e) {
        debugPrint('Error syncing form ID ${form['id']} → $e');
      }
    }
  }
}
