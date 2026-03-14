import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cuickdevuser/screen/onboding/components/camera_capture_page.dart';
import 'package:cuickdevuser/screen/utility.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/editform_controller.dart';
import 'package:cuickdevuser/screen/ChildUiform_Screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:cuickdevuser/screen/Menu_view.dart';
import 'dart:typed_data';
import 'package:cuickdevuser/service/apihelper.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:http/http.dart' as http;
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/Childcontroller.dart';
import '../controller/tableview_controller.dart';
import '../service/DBHelper.dart';
import 'Editchildform.dart';
import 'package:cuickdevuser/components/constants.dart';

class EditFormScreen extends StatefulWidget {
  final int id;
  final String appurl;
  final String formID;
  final String menutitle;
  final String userstoryName;
  final int iscreate;
  final int isread;
  final int isdelete;
  final int isupdate;

  const EditFormScreen({
    super.key,
    required this.id,
    required this.appurl,
    required this.formID,
    required this.userstoryName,
    required this.menutitle,
    required this.iscreate,
    required this.isread,
    required this.isdelete,
    required this.isupdate,
  });

  @override
  State<EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<EditFormScreen> {
String formatDecimal(String value) {
    final double? number = double.tryParse(value);
    if (number == null) return value;

    if (number % 1 == 0) {
      return number.toInt().toString(); // 10.0 -> 10
    } else {
      return number
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }
 
  final ImageUrlHelper imageUrlHelper = ImageUrlHelper();
//   final WelcomeController welcontroller = Get.put(WelcomeController());
//
// // ✅ Dynamic getter
//   String get applogourl {
//     final imageId = welcontroller.imageId.value;
//
//     if (imageId == 0) {
//       return "https://cuickdev.com/API/DOCS/api/doc/0?t=0";
//     }
//
//     return "https://cuickdev.com/API/DOCS/api/doc/$imageId?t=${DateTime.now().millisecondsSinceEpoch}";
//   }
  final EditformController controller = Get.put(EditformController());
  final ApiBaseHelper helper = ApiBaseHelper();
  final _formKey = GlobalKey<FormState>();
  String fieldvalue = "";
  HttpServices httpServices = HttpServices();
  int currentId = 0;
  var selectedComment = "".obs;
  var selecteddesc = "".obs;
  var id = 0.obs;
  bool isNewClicked = false;

  Future<void> Sendmail() async {
    var res = await httpServices.Sharepdftomail(
        appurl: controller.appCode.value,
        field: controller.code.value,
        formId: widget.formID,
        fieldid: widget.id,
        name: namecontroller.text,
        email: Emailcontroller.text);

    if (res != null && res['success'] == true) {
      var dataResponse = res['result'];
      String msg = dataResponse['message']; // Cast to List<dynamic>

      Emailcontroller.clear();
      namecontroller.clear();
      CherryToast.success(
        backgroundColor: Color(0xFFDDF4DE),
        animationDuration: Durations.short1,
        title: Text(msg, style: TextStyle(color: Colors.black)),
      ).show(context);
    } else {
      CherryToast.error(
        backgroundColor: Colors.red.shade200,
        animationDuration: Durations.short1,
        title: const Text('Error in sending mail',
            style: TextStyle(color: Colors.black)),
      ).show(context);
    }
  }

  // ----------------------
// Function to download & open PDF
// ----------------------
  Future<void> ExportpdfFunction(String url, String field) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String sessionId = prefs.getString('jsessionid') ?? '';
      Map<String, dynamic> reqBody = {};

      // Use pdfexportpostApi instead of exportpostApi
      final responseData = await helper.pdfexportpostApi(
        "api/v1/${controller.appCode.value}/${controller.code.value}/downloadpdf/${widget.id}/${widget.formID};jsessionid=$sessionId",
        reqBody,
      );

      if (responseData == null || responseData.isEmpty) {
        CherryToast.error(
          title: const Text('Error: PDF not generated'),
        ).show(context);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/downloaded_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(filePath);
      await file.writeAsBytes(responseData);

      await OpenFile.open(filePath);

      CherryToast.success(
        title: const Text('PDF downloaded successfully'),
      ).show(context);
    } catch (e) {
      CherryToast.error(
        title: Text('Failed: $e', style: const TextStyle(color: Colors.black)),
      ).show(context);
    }
  }

  Future<void> saveAndLaunchpdfFile(Uint8List pdfData, String filename) async {
    // await requestStoragePermission();
    String directory = '/storage/emulated/0/Download/';

    final path = Platform.isAndroid
        ? directory
        : (await getApplicationDocumentsDirectory()).path;

    // Check for file name uniqueness
    int counter = 1;
    String finalFileName = filename;

    while (await File('$path/$finalFileName').exists()) {
      finalFileName = filename.replaceFirst('.pdf', '($counter).pdf');
      counter++;
    }

    final file = File('$path/$finalFileName');
    await file.writeAsBytes(pdfData, flush: true);

    OpenFile.open('$path/$finalFileName');
  }

  Map<String, String?> resulterror = {};
  Future<Map<String, dynamic>?> SaveForm() async {
    controller.isLoading.value = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    String applicationRoleId = prefs.getString("applicationRoleId") ?? '';
    // Initialize reqBody with 'id' first
    Map<String, dynamic> reqBody = {'id': currentId};

    for (var field in controller.labellist) {
      var fieldValue =
          controller.getInitialValue(field['code'])?.toString() ?? '';

      var controllervalue = _controllers[field['label']];
      var controllersData = controllervalue?.text ?? "";

      if (controllersData.isNotEmpty) {
        reqBody[field['code'].toString()] = controllersData;
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
      } else {
        // reqBody[field['code'].toString()] = null;
      }
    }

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

      if (response['success'] == true) {
        showToast(); // Show success message or toast
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
      // API error -> save offline
      Map<String, String> offlineImagePaths = {};

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
      setState(() {
        isSaving = true;
      });
      print('==========docPaths============>>${controller.docPaths}');
      print('=============imagePaths=========>>${controller.imagePaths}');
      await DBHelper()
          .insertForm(
        title: widget.menutitle,
        type: "Offline",
        formData: reqBody,
        appCode: controller.appCode.value,
        code: controller.code.value,
        saveformcode: controller.saveformcode.value,
        imagePaths: offlineImagePaths,
        // docpath:  offlineDocPaths,
      )
          .then((value) {
        debugPrint('✅ Form inserted successfully with ID: $value');
      }).catchError((e) {
        debugPrint('❌ Error inserting form: $e');
      });
      debugPrint("Error in SaveForm: $e");
      CherryToast.success(
        backgroundColor: const Color(0xFFBCF3BF),
        animationDuration: Durations.short1,
        title: Text("No Internet. Saved offline",
            style: TextStyle(color: Colors.black)),
      ).show(context);
      Get.back();
      viewcontroller.update();
      viewcontroller.GetForm_API(widget.formID);
      viewcontroller.CurrentPage.value = 0;
      return {'message': 'Saved offline due to API error'};
    } finally {
      controller.isLoading.value = false; // ✅ Stop loader
    }

    return null; // Return null when the save is successful
  }

  void showToastResult(String teXt) {
    CherryToast.success(
      backgroundColor: const Color(0xFFBCF3BF),
      animationDuration: Durations.short1,
      title: Text(teXt, style: const TextStyle(color: Colors.black)),
    ).show(context);
  }

  bool isSaving = false;
  void handleButtonClick(String buttonType) async {
    // if (buttonType == "save") {
    //   if (_formKey.currentState?.validate() ?? false) {
    //     Map<String, dynamic>? response = await SaveForm();
    //     if (response != null && response['success']) {
    //       showToast();
    //     } else {
    //       var inputError = response?['result']['inputerror'];
    //       if (!mounted) return; // <-- very important here
    //       setState(() {
    //       resulterror.clear();
    //
    //         if (inputError != null) {
    //           inputError.forEach((key, value) {
    //             resulterror[key] = value;
    //             CherryToast.error(
    //               backgroundColor: const Color(0xFFF8D0D9),
    //               animationDuration: Durations.short1,
    //               title: const Text("Error Saving Form",
    //                   style: TextStyle(color: Colors.black)),
    //             ).show(Get.overlayContext!);
    //           });
    //         } else {
    //           // Optional: handle no inputError case
    //           print('No input error found in response');
    //         }
    //
    //       });
    //     }
    //   }
    // } else
    if (buttonType == "list") {
      debugPrint('Navigating to list...');
      Get.off(() => MenuViewscreen(
            appurl: widget.appurl,
            menutitle: widget.menutitle,
            formID: widget.formID,
            initialTabIndex: 0,
          ));
    } else if (buttonType == "new") {
      // 1. Call the comprehensive controller cleanup
      controller.clearForm();

      // 2. Set the UI-specific local state
      setState(() {
        currentId = 0; // Local ID state reset
        isNewClicked = true; // Local flag set
      });
    } else if (buttonType == "cancel") {
      Get.back();
    } else if (buttonType == "delete") {
      showDeleteConfirmationedit();
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
              viewcontroller.deletelistitem(widget.appurl, widget.menutitle,
                  currentId.toString(), viewcontroller.CurrentPage.value, 10);
              for (var field in controller.labellist) {
                controller.setFieldValue(
                    field['label'], ""); // Reset field value
                controller.setInitialValue(field['code'], "");
              }
              controller.dataMap.clear();

              setState(() {
                currentId = 0;
              });
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false, // Prevents accidental dismiss
    );
  }

  void clearForm() {
    _formKey.currentState?.reset();
    for (var field in controller.labellist) {
      controller.setFieldValue(field['label'], ""); // Reset field value
      controller.clearInitialValue(field['code']);
      controller.latController.clear();
      controller.longController.clear();
      controller.showTextField.value = false;
    }
  }

  final ImagePicker _picker = ImagePicker();

  final TableviewController viewcontroller = Get.put(TableviewController());

  Future<void> _uploadImage(XFile pickedFile, int imageid, String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.appCode.value}/${controller.code.value}/doc/${widget.id}/$imageid/$code;jsessionid=$sessionId');

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

          CherryToast.success(
            backgroundColor: const Color(0xFFBCF3BF),
            animationDuration: Durations.short1,
            title: const Text("Image uploaded successfully!",
                style: TextStyle(color: Colors.black)),
          ).show(context);
        } catch (e) {
          print('Failed to decode JSON response: $e');
        }
      } else {
        CherryToast.error(
          backgroundColor: const Color(0xFFF37691),
          animationDuration: Durations.short1,
          title: const Text('Failed to upload the image!',
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
      }
    } catch (e) {
      print('Error occurred: $e');
      // Handle error
    }
  }

  void showToast() {
    CherryToast.success(
      backgroundColor: const Color(0xFFDDF4DE),
      animationDuration: Durations.short1,
      title: const Text("Form saved successfully!",
          style: TextStyle(color: Colors.black)),
    ).show(context);
    Get.back();
    viewcontroller.update();
    viewcontroller.GetForm_API(widget.formID);
    viewcontroller.CurrentPage.value = 0;
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
      CherryToast.info(
        backgroundColor: const Color(0xFFFACA4F),
        animationDuration: Durations.short1,
        title: const Text("No file selected!",
            style: TextStyle(color: Colors.black)),
      ).show(context);
    }
  }

  String? filePath;

  Future<void> getImage1(
    int imageid,
    String fieldCode,
    ImageSource source, // ab unused rahega
  ) async {
    try {
      // 🔥 CUSTOM CAMERA SCREEN OPEN
      final String? imagePath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCapturePage(),
        ),
      );

      if (imagePath == null) return;

      File imageFile = File(imagePath);

      /// 🔽 optional compression (safe)
      int imageSizeInBytes = await imageFile.length();
      int quality = 70;

      while (imageSizeInBytes > 512000 && quality > 10) {
        final compressed = await compressImage(imageFile, quality);
        if (compressed == null) break;

        imageFile = compressed;
        imageSizeInBytes = await imageFile.length();
        quality -= 10;
      }

      if (!mounted) return;

      /// 🧠 UI update
      setState(() {
        controller.imagePaths[fieldCode] = imageFile.path;
      });

      /// 🚀 upload
      final XFile xFile = XFile(imageFile.path);
      await _uploadImage(xFile, imageid, fieldCode);
    } catch (e, s) {
      debugPrint("❌ Camera capture error: $e");
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _pickAndUploadImage(int imageid, String code) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    int imageSizeInBytes = await imageFile.length();
    int quality = 60; // Start with good quality
    const int minQuality = 20;

    // Keep compressing until size is <= 512KB or quality drops below minimum
    while (imageSizeInBytes > 512000 && quality >= minQuality) {
      imageFile = await compressImage(imageFile, quality);
      imageSizeInBytes = await imageFile.length();

      quality -= 10;
    }

    if (imageSizeInBytes > 512000) {
      _showImageTooLargeDialog();
      return;
    }

    setState(() {
      controller.imagePaths[code] = imageFile.path;
    });

    final XFile compressedXFile = XFile(imageFile.path);
    await _uploadImage(compressedXFile, imageid, code);
  }

  Future<File> compressImage(File imageFile, int quality) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      quality: quality,
    );

    if (result == null) {
      throw Exception("Image compression failed");
    }

    return File(imageFile.path)..writeAsBytesSync(result);
  }

  void _showImageTooLargeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Image Too Large"),
          content: Text(
              "The selected image is too large to upload, even after compression. Please choose a smaller image."),
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

  Future<void> _uploadFile(File pickedFile, String code, int imageid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      print('Session ID is empty. Please log in again.');

      return;
    }

    // Replace `id` with the actual document ID you need to send
    final uri = Uri.parse(
        'https://api.ncsindore.com/api/v1/${controller.appCode.value}/${controller.code.value}/doc/${widget.id}/$imageid/$code;jsessionid=$sessionId');

    var request = http.MultipartRequest('POST', uri);

    var file = await http.MultipartFile.fromPath('file', pickedFile.path);
    request.files.add(file);

    try {
      var response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        CherryToast.success(
          backgroundColor: const Color(0xFFBCF3BF),
          animationDuration: Durations.short1,
          title: const Text("File uploaded successfully!",
              style: TextStyle(color: Colors.black)),
        ).show(context);
        try {
          var jsonResponse = jsonDecode(responseBody);
          var dataValue = jsonResponse['result']['data'][code];
          if (dataValue is int) {
            dataValue = dataValue.toString();
          }
          setState(() {
            controller.uploadDocument[code] = dataValue;
          });
        } catch (e) {
          print('Failed to decode JSON response: $e');
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    currentId = widget.id;
    controller.updateappurl(
        widget.menutitle.toLowerCase(), widget.id.toString());
    controller.getuser_role_access(widget.formID);
    controller.GetForm_API(widget.formID).then((_) {
      controller.getComments(widget.formID, widget.id.toString()).then((_) {
        controller.getattachment(widget.formID, widget.id.toString());

        childcontroller.getchildlist(currentId);
      });
    });
  }

  final Childcontroller childcontroller = Get.put(Childcontroller());
  Map<String, TextEditingController> _controllers = {};

  void showAddCommentDialog() {
    TextEditingController commentController = TextEditingController();
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Comment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Get.back(); // Close Dialog
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Comment Input Field
              TextField(
                controller: commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter your comment...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      String newComment = commentController.text.trim();
                      if (newComment.isEmpty) {
                        Get.snackbar("Error", "Comment cannot be empty!",
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }

                      id.value = 0;

                      bool isSuccess = await controller.saveComments(id.value,
                          newComment, widget.formID, widget.id.toString());
                      if (isSuccess) {
                        Get.back();
                        CherryToast.success(
                          backgroundColor: Color(0xFFDDF4DE),
                          animationDuration: Durations.short1,
                          title: const Text("Comment added successfully!",
                              style: TextStyle(color: Colors.black)),
                        ).show(context);
                        // Get.snackbar("Success", "Comment added successfully!",
                        //     backgroundColor: Colors.green,
                        //     colorText: Colors.white);
                        setState(() {
                          commentController.text = "";
                          commentController.clear();
                        });
                        controller.getComments(
                            widget.formID, widget.id.toString());
                      } else {
                        CherryToast.error(
                          backgroundColor: const Color(0xFFF8D0D9),
                          animationDuration: Durations.short3,
                          animationCurve: Curves.easeInCubic,
                          title: const Text('Failed to add comment!',
                              style: TextStyle(color: Colors.black)),
                        ).show(Get.overlayContext!);
                      }
                    },
                    child: Container(
                      height: 50,
                      width: 110,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.blue
                                : const Color(0xFF1A237E),
                          )),
                      child: Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.blue
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
                      setState(() {
                        commentController.text = "";
                        commentController.clear();
                      });
                      Get.back();
                    },
                    child: Container(
                      height: 50,
                      width: 110,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.blue
                                : const Color(0xFF1A237E),
                          )),
                      child: Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: isDarkMode ? Colors.blue : Color(0xFF1A237E),
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
          ),
        ),
      ),
    );
  }

  Future<void> fetchCommentById(String commentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';

    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
          "api/v1/cuickdev/page-comment/get/$commentId;jsessionid=$jsessionid",
          reqBody);

      if (response != null &&
          response['success'] == true &&
          response['result'] != null) {
        var commentData = response['result']['data'];
        id.value = commentData['id']; // Store comment ID
        selectedComment.value = commentData['comment']; // Store comment text
        showEditCommentDialog(); // Open the edit popup
      } else {
        Get.snackbar("Error", "Failed to fetch comment",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Error fetching comment: $e");
      Get.snackbar("Error", "Something went wrong!",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void showEditCommentDialog() {
    TextEditingController commentController =
        TextEditingController(text: selectedComment.value);
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Edit Comment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Edit your comment...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      String newComment = commentController.text.trim();
                      if (newComment.isEmpty) {
                        Get.snackbar("Error", "Comment cannot be empty!",
                            backgroundColor: Colors.red,
                            colorText: Colors.white);
                        return;
                      }

                      bool isSuccess = await controller.saveComments(id.value,
                          newComment, widget.formID, widget.id.toString());
                      if (isSuccess) {
                        Get.back();
                        CherryToast.success(
                          backgroundColor: Color(0xFFDDF4DE),
                          animationDuration: Durations.short1,
                          title: const Text("Comment updated successfully!",
                              style: TextStyle(color: Colors.black)),
                        ).show(context);

                        commentController.clear();
                        setState(() {
                          commentController.text = "";
                        });
                        controller.getComments(
                            widget.formID, widget.id.toString());
                        // Close Dialog
                      } else {
                        CherryToast.error(
                          backgroundColor: const Color(0xFFF8D0D9),
                          animationDuration: Durations.short3,
                          animationCurve: Curves.easeInCubic,
                          title: const Text("Failed to update comment!",
                              style: TextStyle(color: Colors.black)),
                        ).show(Get.overlayContext!);
                      }
                    },
                    child: Container(
                      height: 50,
                      width: 110,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.blue
                                : const Color(0xFF1A237E),
                          )),
                      child: Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.blue
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
                      commentController.clear();
                      setState(() {
                        commentController.text = "";
                      });
                      Get.back();
                    },
                    child: Container(
                      height: 50,
                      width: 110,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.blue
                                : const Color(0xFF1A237E),
                          )),
                      child: Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.blue
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
          ),
        ),
      ),
    );
  }

  void showDeleteConfirmation(String commentId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this comment?"),
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
              Get.back();
              deleteComment(commentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false, // Prevents accidental dismiss
    );
  }

  Future<void> deleteComment(String commentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';

    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
          "api/v1/cuickdev/page-comment/delete/$commentId;jsessionid=$jsessionid",
          reqBody);

      if (response != null && response['success'] == true) {
        CherryToast.success(
          backgroundColor: const Color(0xFFA3F8A6),
          animationDuration: Durations.short1,
          title: const Text("Comment deleted successfully!",
              style: TextStyle(color: Colors.black)),
        ).show(context);

        await controller.getComments(widget.formID, widget.id.toString());
      } else {
        CherryToast.error(
          backgroundColor: const Color(0xFFFABECC),
          animationDuration: Durations.short3,
          animationCurve: Curves.easeInCubic,
          title: const Text('Failed to delete comment',
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
      }
    } catch (e) {
      debugPrint("Error deleting comment: $e");
      Get.snackbar("Error", "Something went wrong!",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void showCommentInfoPopup(Map<String, dynamic> commentData) {
    String formattedCreatedDate = formatDate(commentData["createdDatetime"]);
    String formattedModifiedDate = formatDate(commentData["modifiedDatetime"]);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 600),
          // Width constraint for horizontal scroll
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Comment Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Get.back(); // Close Dialog
                    },
                  ),
                ],
              ),
              const Divider(),

              // Scrollable Content (Horizontal & Vertical)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scroll
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical, // Enable vertical scroll
                  child: Column(
                    children: [
                      infoRow("Organization", commentData["orgName"]),
                      infoRow("Version", commentData["version"].toString()),
                      infoRow("Created By", commentData["createdBy"]),
                      infoRow("Created Date", formattedCreatedDate),
                      infoRow("Modified By", commentData["modifiedBy"]),
                      infoRow("Modified Date", formattedModifiedDate),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTimeForApi(String displayTime, int timeFormat) {
    try {
      if (timeFormat == 24) return displayTime;
      final dt = DateFormat("h:mm a").parse(displayTime);
      return DateFormat("HH:mm").format(dt); // 19:53
    } catch (e) {
      return displayTime;
    }
  }

  Widget infoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150, // Fixed width for key column
            child: Text(
              key,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 200),
            // Minimum width for value column
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, yyyy, hh:mm:ss a').format(dateTime);
  }

  void showAddAttachmentDialog(BuildContext context, bool isDarkMode) {
    File? selectedFile;
    String fileName = "No file chosen";
    TextEditingController descontroller =
        TextEditingController(text: selecteddesc.value);
    TextEditingController fileNameController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upload Attachment",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      Get.back(); // Close Dialog
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descontroller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                controller: fileNameController,
                onTap: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.any, // Allows any file type
                  );
                  if (result != null) {
                    setState(() {
                      selectedFile = File(result.files.single.path!);
                      fileName = result.files.single.name;
                      fileNameController.text = fileName;
                    });
                  } else {}
                },
                decoration: InputDecoration(
                  hintText: "Select file",
                  focusColor: Colors.red,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: GestureDetector(
                    onTap: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.any, // Allows any file type
                      );

                      if (result != null) {
                        setState(() {
                          selectedFile = File(result.files.single.path!);
                          fileName = result.files.single.name;
                          fileNameController.text = fileName;
                        });
                      } else {}
                    },
                    child: const Icon(Icons.attachment,
                        size: 30, color: Colors.indigo),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (selectedFile != null) {
                        Get.dialog(
                          const Center(child: CircularProgressIndicator()),
                          barrierDismissible:
                              false, // Prevents closing during upload
                        );
                        bool isSuccess = await controller.uploadAttachment(
                          selectedFile!,
                          widget.formID,
                          widget.id.toString(),
                          descontroller.text,
                        );

                        Get.back(); // Close loading dialog

                        if (isSuccess) {
                          Get.back(); // Close popup
                          CherryToast.success(
                            backgroundColor: Color(0xFFA6EFA9),
                            animationDuration: Durations.short1,
                            title: const Text("Attachment upload successfully!",
                                style: TextStyle(color: Colors.black)),
                          ).show(context);

                          controller.getattachment(widget.formID,
                              widget.id.toString()); // Refresh attachment list
                        } else {
                          CherryToast.error(
                            backgroundColor: Color(0xFFF1B2C0),
                            animationDuration: Durations.short3,
                            animationCurve: Curves.easeInCubic,
                            title: const Text('"Failed to upload attachment!',
                                style: TextStyle(color: Colors.black)),
                          ).show(Get.overlayContext!);
                        }
                      } else {
                        Get.snackbar(
                          "Error",
                          "Select the file!",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Container(
                      height: 45,
                      width: 100,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? Colors.blue : Color(0xFF1A237E),
                          )),
                      child: Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: isDarkMode ? Colors.blue : Color(0xFF1A237E),
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
                      Get.back();
                    },
                    child: Container(
                      height: 45,
                      width: 100,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? Colors.blue : Color(0xFF1A237E),
                          )),
                      child: Center(
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: isDarkMode ? Colors.blue : Color(0xFF1A237E),
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
          ),
        ),
      ),
    );
  }

  Future<File?> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void onEditPressed(String attachmentId) async {
    // Show loading indicator
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';

    try {
      var response = await http.get(
        Uri.parse(
            "https://api.ncsindore.com/api/v1/cuickdev/page-attachment/get/$attachmentId;jsessionid=$jsessionid"),
      );

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse["success"] == true) {
        var imageUrl =
            "https://cuickdev.com/API/DOCS/api/doc/th/${jsonResponse["result"]["data"]["attachment"]}";

        var attachmentData = jsonResponse['result']['data'];

        selecteddesc.value =
            attachmentData['description'] ?? ""; // Store comment text

        Get.back(); // Close loading dialog

        showEditAttachmentDialog(
            imageUrl, attachmentId); // Open image edit dialog
      } else {
        Get.back();
        Get.snackbar("Error", "Failed to load image!",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Something went wrong!",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void showEditAttachmentDialog(String filePathOrUrl, String attachmentId,
      {File? selectedFile}) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    TextEditingController descontroller =
        TextEditingController(text: selecteddesc.value);
    TextEditingController fileNameController = TextEditingController();
    String fileName = "No file chosen";

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Update Attachment",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Get.back(); // Close Dialog
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Description TextField
                TextField(
                  controller: descontroller,
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() {
                      descontroller.text = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Enter Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 10),

                // File Selection TextField
                TextField(
                  readOnly: true,
                  controller: fileNameController,
                  onTap: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.any, // Allows any file type
                    );

                    if (result != null) {
                      setState(() {
                        selectedFile = File(result.files.single.path!);
                        String fileName = result.files.single.name;
                        fileNameController.text = fileName;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Select file",
                    focusColor: Colors.red,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    suffixIcon: GestureDetector(
                      onTap: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.any, // Allows any file type
                        );

                        if (result != null) {
                          setState(() {
                            selectedFile = File(result.files.single.path!);
                            fileName = result.files.single.name;
                            fileNameController.text = fileName;
                          });
                        }
                      },
                      child: const Icon(Icons.attachment,
                          size: 30, color: Colors.indigo), // Attachment icon
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Display Existing or Newly Selected File
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: selectedFile != null
                      ? Image.file(selectedFile!,
                          width: 120, height: 120, fit: BoxFit.fill)
                      : Image.network(filePathOrUrl,
                          width: 120, height: 120, fit: BoxFit.fill),
                ),
                SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        bool success = await controller.updateImage(
                            attachmentId,
                            selectedFile,
                            widget.formID,
                            widget.id.toString(),
                            descontroller.text);

                        if (success) {
                          Get.back();
                          CherryToast.success(
                            backgroundColor: Color(0xFF97F19B),
                            animationDuration: Durations.short1,
                            title: const Text(
                                "Attachment updated successfully!",
                                style: TextStyle(color: Colors.black)),
                          ).show(context);

                          controller.getattachment(widget.formID,
                              widget.id.toString()); // Refresh attachment list
                        } else {
                          CherryToast.error(
                            backgroundColor: Color(0xFFF3A2B4),
                            animationDuration: Durations.short3,
                            animationCurve: Curves.easeInCubic,
                            title: const Text('Failed to update Attachment',
                                style: TextStyle(color: Colors.black)),
                          ).show(Get.overlayContext!);
                        }
                      },
                      child: Container(
                        height: 45,
                        width: 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isDarkMode ? Colors.blue : Color(0xFF1A237E),
                            )),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.blue : Color(0xFF1A237E),
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
                        Get.back();
                      },
                      child: Container(
                        height: 45,
                        width: 100,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isDarkMode ? Colors.blue : Color(0xFF1A237E),
                            )),
                        child: Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.blue : Color(0xFF1A237E),
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
                // Close Button
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showattachmentDeleteConfirmation(String attachmentId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this attachment?"),
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
              Get.back(); // Close dialog before deleting
              deleteAttachment(attachmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false, // Prevent accidental dismiss
    );
  }

  Future<void> deleteAttachment(String attachmentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';

    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
          "api/v1/cuickdev/page-attachment/delete/$attachmentId;jsessionid=$jsessionid",
          reqBody);

      if (response != null && response['success'] == true) {
        CherryToast.success(
          backgroundColor: Color(0xFFDDF4DE),
          animationDuration: Durations.short1,
          title: const Text("Attachment deleted successfully!",
              style: TextStyle(color: Colors.black)),
        ).show(context);

        await controller.getattachment(
            widget.formID, widget.id.toString()); // Refresh attachment list
      } else {
        CherryToast.error(
          backgroundColor: Color(0xFFF8D0D9),
          animationDuration: Durations.short3,
          animationCurve: Curves.easeInCubic,
          title: const Text('Failed to delete attachment',
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
      }
    } catch (e) {
      debugPrint("Error deleting attachment: $e");

      Get.snackbar("Error", "Something went wrong!",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void setCurrentLocation(String label, String code) async {
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
        _controllers[label]!.text = lat.toString() ?? "";
        _controllers[label]!.text = lng.toString() ?? "";
        controller.latController.text = lat.toString() ?? "";
        controller.longController.text = lng.toString() ?? "";
        controller.showTextField.value = true;
      });
      print('📍 Location set: Lat = $lat, Lng = $lng');
    } else {
      print('❌ Failed to get location coordinates.');
    }
  }

  void _clearText(String label, String code) {
    setState(() {
      controller.latController.clear();
      controller.longController.clear();
      controller.showTextField.value = false;
      controller.setFieldValue(label, ""); // clear stored map
      controller.setInitialValue(code, "");
    });
  }

  List<bool> isSelected = [false, false];
  List<dynamic> comboboxmapValues = [];
  final currentHour = DateTime.now().hour;
  bool _obscureText = true;
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
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
          title: const Text('Form',
              style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: controller.isLoading.value,
              child: SingleChildScrollView(
                child: Obx(() {
                  var itemsWithoutGroup = controller.getItemsWithoutGroup();
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            controller.exportEnabled.value == 1
                                ? GestureDetector(
                                    onTap: () {
                                      ExportpdfFunction(
                                        widget.appurl,
                                        controller.userstoryName.value
                                            .toLowerCase(),
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/icons/export-pdf.png',
                                      width: 30,
                                      height: 30,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Appcolorblue,
                                    ),
                                  )
                                : const SizedBox(),
                            const SizedBox(
                              width: 10,
                            ),
                            controller.emailEnabled.value == 1
                                ? GestureDetector(
                                    onTap: () {
                                      ShareBottomSheet();
                                    },
                                    child: Image.asset(
                                      'assets/icons/shereicon.png',
                                      width: 30,
                                      height: 30,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Appcolorblue,
                                    ),
                                  )
                                : SizedBox()
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      controller.grouplabellist.isEmpty &&
                              controller.labellist.isEmpty
                          ? Center(
                              child: Padding(
                              padding: const EdgeInsets.only(top: 60.0),
                              child: LoadingAnimationWidget.threeArchedCircle(
                                size: 50,
                                color: Appcolorblue,
                              ),
                            ))
                          : Form(
                              key: _formKey,
                              child: controller.grouplabellist.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Obx(
                                        () {
                                          print(
                                              '=labellist============>>${controller.labellist.length}');
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ...controller.labellist
                                                  .map((field) {
                                                String label = field['label'];
                                                String code = field['code'];
                                                String fieldType =
                                                    field['type'];
                                                String show = field['show'];
                                                bool isRequired =
                                                    field['required'] == 1;
                                                bool systemValueIsOne = field[
                                                        'system'] ==
                                                    1; // Check if systemValue is 1
                                                String event =
                                                    field['event'] ?? "";
                                                String rule =
                                                    field['rule'] ?? "";
                                                bool isRefKey =
                                                    field['refKey'] == 1;
                                                bool primaryUsecase =
                                                    field['primaryUsecase'] !=
                                                        "";
                                                String yUsecase =
                                                    field['primaryUsecase'] ??
                                                        "";
                                                bool showDropdown =
                                                    primaryUsecase == true &&
                                                        isRefKey == true;

                                                int readOnly =
                                                    field['readOnly'] ?? 0;
                                                int captureImage =
                                                    field['captureImage'] ?? 0;
                                                if (systemValueIsOne) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                String minDateStr =
                                                    field['minDate'] ?? "";
                                                String maxDateStr =
                                                    field['maxDate'] ?? "";
                                                // Request body for dynamic field value
                                                Map<String, String> reqBody =
                                                    {};
                                                for (var field
                                                    in controller.labellist) {
                                                  String fieldValue = controller
                                                          .getInitialValue(
                                                              field['label'])
                                                          ?.toString() ??
                                                      '';
                                                  reqBody[field['code']
                                                      .toString()] = fieldValue;
                                                }

                                                bool result = controller
                                                    .evaluateCondition(
                                                        reqBody, show);
                                                final initialValue =
                                                    controller.getInitialValue(
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
                                                if (fieldType == 'text' &&
                                                    result) {
                                                  final initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);

                                                  // Normalize allowChangeAfterInitial to int
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      enabled: isEditable,
                                                      readOnly: !isEditable,
                                                      controller:
                                                          _controllers[label],
                                                      style: labelStyle,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      onChanged: isEditable
                                                          ? (value) {
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value);
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value);
                                                            }
                                                          : null,
                                                      validator: (value) {
                                                        if (isRequired &&
                                                            (value == null ||
                                                                value
                                                                    .isEmpty)) {
                                                          return 'Please enter $label';
                                                        }
                                                        final regexPattern =
                                                            field['regex'];
                                                        if (regexPattern !=
                                                                null &&
                                                            value != null &&
                                                            value.isNotEmpty) {
                                                          final regex = RegExp(
                                                              regexPattern);
                                                          if (!regex.hasMatch(
                                                              value)) {
                                                            return 'Invalid input for $label';
                                                          }
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  );
                                                }

                                                if (fieldType == 'email' &&
                                                    result) {
                                                  final String initialValue =
                                                      controller
                                                              .getInitialValue(
                                                                  code) ??
                                                          "";

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  // Apply edit rules
                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Ensure controller is initialized with initial value
                                                  _controllers[label] ??=
                                                      TextEditingController(
                                                          text: initialValue);

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      style: labelStyle,
                                                      enabled: isEditable,
                                                      readOnly: !isEditable,
                                                      controller:
                                                          _controllers[label],
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
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
                                                              .emailAddress,
                                                      onChanged: isEditable
                                                          ? (value) {
                                                              setState(() {
                                                                controller.dataMap[
                                                                        code] =
                                                                    value;
                                                                controller
                                                                    .setInitialValue(
                                                                        code,
                                                                        value);
                                                                controller
                                                                    .setFieldValue(
                                                                        label,
                                                                        value);
                                                              });
                                                            }
                                                          : null,
                                                      validator: (value) {
                                                        if (isRequired &&
                                                            (value == null ||
                                                                value
                                                                    .isEmpty)) {
                                                          return 'Please enter $label';
                                                        }
                                                        // Basic email validation
                                                        if (value != null &&
                                                            value.isNotEmpty) {
                                                          final emailRegex = RegExp(
                                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                                          if (!emailRegex
                                                              .hasMatch(
                                                                  value)) {
                                                            return 'Please enter a valid email address';
                                                          }
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  );
                                                }

                                                if (fieldType == 'url' &&
                                                    result) {
                                                  final initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Ensure controller exists with initial value
                                                  _controllers[label] ??=
                                                      TextEditingController(
                                                    text: initialValue
                                                            ?.toString() ??
                                                        "",
                                                  );

                                                  return TextFormField(
                                                    controller:
                                                        _controllers[label],
                                                    enabled: isEditable,
                                                    readOnly: !isEditable,
                                                    style: labelStyle,
                                                    decoration: InputDecoration(
                                                      errorText:
                                                          resulterror[code],
                                                      labelStyle: labelStyle,
                                                      labelText: label,
                                                      fillColor: isEditable
                                                          ? (isDarkMode
                                                              ? Colors.black
                                                              : Colors.white)
                                                          : Colors.grey[200],
                                                      filled: true,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color:
                                                                Appcolorblue),
                                                      ),
                                                    ),
                                                    keyboardType:
                                                        TextInputType.url,
                                                    onChanged: isEditable
                                                        ? (value) {
                                                            controller
                                                                .setInitialValue(
                                                                    code,
                                                                    value);
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    value);
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
                                                  );
                                                }

                                                if (fieldType == 'password' &&
                                                    result) {
                                                  final String initialValue =
                                                      controller
                                                              .getInitialValue(
                                                                  code) ??
                                                          "";

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  // Apply edit rules
                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Ensure controller is initialized with initial value
                                                  _controllers[label] ??=
                                                      TextEditingController(
                                                          text: initialValue);

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 5.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _controllers[label],
                                                      style: labelStyle,
                                                      enabled: isEditable,
                                                      readOnly: !isEditable,
                                                      obscureText: _obscureText,
                                                      decoration:
                                                          InputDecoration(
                                                        errorText:
                                                            resulterror[code],
                                                        labelStyle: labelStyle,
                                                        labelText: label,
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                        suffixIcon: isEditable
                                                            ? IconButton(
                                                                icon: Icon(
                                                                  _obscureText
                                                                      ? Icons
                                                                          .visibility_off
                                                                      : Icons
                                                                          .visibility,
                                                                ),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    _obscureText =
                                                                        !_obscureText;
                                                                  });
                                                                },
                                                              )
                                                            : null,
                                                      ),
                                                      onChanged: isEditable
                                                          ? (value) {
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value);
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value);
                                                            }
                                                          : null,
                                                      validator: (value) {
                                                        if (isRequired &&
                                                            (value == null ||
                                                                value
                                                                    .isEmpty)) {
                                                          return 'Please enter $label';
                                                        }

                                                        final regexPattern = field[
                                                            'regex']; // e.g., "^(?=.*[0-9])(?=.*[A-Z]).{8,}$"
                                                        if (regexPattern !=
                                                                null &&
                                                            value != null &&
                                                            value.isNotEmpty) {
                                                          final regex = RegExp(
                                                              regexPattern);
                                                          if (!regex.hasMatch(
                                                              value)) {
                                                            return 'Invalid input for $label';
                                                          }
                                                        }

                                                        return null;
                                                      },
                                                    ),
                                                  );
                                                }

                                                if (fieldType == 'textarea' &&
                                                    result) {
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      controller:
                                                          _controllers[label],
                                                      style: labelStyle,
                                                      enabled: readOnly != 1,
                                                      readOnly: readOnly == 1,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isDarkMode
                                                            ? Colors.black
                                                            : Colors.white,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
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
                                                                  code, value),
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
                                                if (fieldType == 'boolean' &&
                                                    result) {
                                                  // Initialize isSelected based on saved value
                                                  String? savedValue =
                                                      initialValue.toString();
                                                  if (savedValue == '1') {
                                                    isSelected = [true, false];
                                                  } else if (savedValue ==
                                                      '0') {
                                                    isSelected = [false, true];
                                                  } else {
                                                    isSelected = [false, false];
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 9),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Align(
                                                            alignment: Alignment
                                                                .topLeft,
                                                            child: Text(label,
                                                                style:
                                                                    labelStyle)),
                                                        const SizedBox(
                                                            height: 10),
                                                        Align(
                                                          alignment:
                                                              Alignment.topLeft,
                                                          child: ToggleButtons(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                            selectedColor:
                                                                Colors.white,
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
                                                                ? Colors.white
                                                                : Colors.black,
                                                            isSelected:
                                                                isSelected,
                                                            onPressed: (index) {
                                                              setState(() {
                                                                for (int i = 0;
                                                                    i <
                                                                        isSelected
                                                                            .length;
                                                                    i++) {
                                                                  isSelected[
                                                                          i] =
                                                                      i ==
                                                                          index;
                                                                }

                                                                var selectedValue =
                                                                    index == 0
                                                                        ? 1
                                                                        : 0;
                                                                String
                                                                    savedValue =
                                                                    selectedValue
                                                                        .toString();

                                                                controller.dataMap[
                                                                        field[
                                                                            'code']] =
                                                                    savedValue;
                                                                controller
                                                                    .setFieldValue(
                                                                        label,
                                                                        savedValue);
                                                                controller
                                                                    .setInitialValue(
                                                                        code,
                                                                        savedValue);
                                                              });
                                                            },
                                                            children: const [
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16),
                                                                child: Text(
                                                                  "Yes",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16),
                                                                child: Text(
                                                                  "No",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
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
                                                if (fieldType == 'location' &&
                                                    result) {
                                                  final locationMap =
                                                      initialValue;

                                                  if (locationMap != null &&
                                                      locationMap is Map) {
                                                    if (locationMap
                                                        .isNotEmpty) {
                                                      controller.showTextField
                                                          .value = true;
                                                    }

                                                    controller.latController
                                                            .text =
                                                        locationMap['lat']
                                                                .toString() ??
                                                            '';
                                                    controller.longController
                                                            .text =
                                                        locationMap['lng']
                                                                .toString() ??
                                                            '';
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          label,
                                                          style: labelStyle,
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Align(
                                                          alignment:
                                                              Alignment.topLeft,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .location_on,
                                                                      color:
                                                                          Appcolorblue),
                                                                  onPressed:
                                                                      () {
                                                                    setCurrentLocation(
                                                                        label,
                                                                        code);
                                                                  },
                                                                ),
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .remove_red_eye,
                                                                      color:
                                                                          Appcolorblue),
                                                                  onPressed:
                                                                      () async {
                                                                    final lat =
                                                                        controller
                                                                            .latController
                                                                            .text;
                                                                    final lng =
                                                                        controller
                                                                            .longController
                                                                            .text;
                                                                    if (lat.isEmpty ||
                                                                        lng.isEmpty) {
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (context) =>
                                                                                AlertDialog(
                                                                          title:
                                                                              const Text("Missing Location"),
                                                                          content:
                                                                              const Text("Location not available. Please set the location first.."),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () => Navigator.pop(context),
                                                                              child: Text("OK"),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      final Uri
                                                                          mapUrl =
                                                                          Uri.parse(
                                                                              "https://www.google.com/maps?q=$lat,$lng");
                                                                      await launchUrl(
                                                                          mapUrl,
                                                                          mode:
                                                                              LaunchMode.platformDefault);
                                                                    }
                                                                  },
                                                                ),
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color: Colors
                                                                          .red),
                                                                  onPressed:
                                                                      () {
                                                                    _clearText(
                                                                        label,
                                                                        code);
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        if (controller
                                                            .showTextField
                                                            .value) ...[
                                                          TextField(
                                                            controller: controller
                                                                .latController,
                                                            readOnly: true,
                                                            style: labelStyle,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'Latitude',
                                                              fillColor:
                                                                  isDarkMode
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .white,
                                                              labelStyle:
                                                                  labelStyle,
                                                              border:
                                                                  const OutlineInputBorder(),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 10),
                                                          TextField(
                                                            controller: controller
                                                                .longController,
                                                            readOnly: true,
                                                            style: labelStyle,
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'Longitude',
                                                              fillColor:
                                                                  isDarkMode
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .white,
                                                              labelStyle:
                                                                  labelStyle,
                                                              border:
                                                                  const OutlineInputBorder(),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  );
                                                }
                                                if (showDropdown && result) {
                                                  final dropdownItems =
                                                      controller.prelaodlist[
                                                              yUsecase] ??
                                                          [];

                                                  // Ensure unique dropdown items based on 'id'
                                                  final uniqueItems = dropdownItems
                                                      .map((e) =>
                                                          e['id'].toString())
                                                      .toSet()
                                                      .map((id) => dropdownItems
                                                          .firstWhere((item) =>
                                                              item['id']
                                                                  .toString() ==
                                                              id))
                                                      .toList();

                                                  final currentValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);
                                                  final validValue =
                                                      uniqueItems.any((item) =>
                                                              item['id']
                                                                  .toString() ==
                                                              currentValue)
                                                          ? currentValue
                                                          : null;

                                                  // normalize allowChangeAfterInitial (0 = lock after first set, 1 = editable until set, 2 = always editable)
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              "0") ??
                                                          0;

                                                  final bool isEditable = readOnly !=
                                                          1 &&
                                                      (allowChange ==
                                                              2 || // always editable
                                                          (allowChange == 1 &&
                                                              (validValue ==
                                                                      null ||
                                                                  validValue
                                                                      .isEmpty)) || // editable until first set
                                                          (allowChange == 0 &&
                                                              validValue ==
                                                                  null) // only editable if nothing chosen yet
                                                      );

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                      isExpanded: true,
                                                      dropdownColor: isDarkMode
                                                          ? Colors.grey[850]
                                                          : Colors.white,
                                                      style: labelStyle,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        errorText:
                                                            resulterror[code],
                                                        labelStyle: labelStyle,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      value: (validValue
                                                                  ?.isEmpty ??
                                                              true)
                                                          ? null
                                                          : validValue,
                                                      items: [
                                                        DropdownMenuItem<
                                                            String>(
                                                          value: null,
                                                          child: Text(
                                                              "Select $label",
                                                              style: labelStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1),
                                                        ),
                                                        ...uniqueItems.map<
                                                            DropdownMenuItem<
                                                                String>>((item) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: item['id']
                                                                .toString(),
                                                            child: Text(
                                                              item['_val'],
                                                              style: labelStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ],
                                                      onChanged: isEditable
                                                          ? (value) async {
                                                              controller
                                                                  .onChange(
                                                                      field,
                                                                      value);
                                                              if (event != "") {
                                                                await controller
                                                                    .GetUserData(
                                                                        code,
                                                                        rule,
                                                                        value!);
                                                                controller
                                                                        .admissionId =
                                                                    value;
                                                              }
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value ??
                                                                          "");
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value ??
                                                                          "");
                                                            }
                                                          : null,
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

                                       // Find this block in your code (around line 2469-2556) and replace it with:
if (fieldType == 'number' && result) {
  final dynamic initialValue = controller.getInitialValue(code);

  // Normalize allowChangeAfterInitial
  final int allowChange = int.tryParse(
          field['allowChangeAfterInitial']?.toString() ?? "0") ??
      0;

  final bool isEditable = readOnly != 1 && allowChange == 0;

  // Format number for display
  String formatNumber(String value) {
    if (value.isEmpty) return '';
    final double? number = double.tryParse(value);
    if (number == null) return value;

    if (number % 1 == 0) {
      return number.toInt().toString(); // 10.0 -> 10
    } else {
      return number.toString(); // 10.5 -> 10.5
    }
  }

  final String currentStr = formatNumber(initialValue?.toString() ?? "");

  // Update controller if needed
  if (_controllers[label]?.text != currentStr) {
    _controllers[label]?.text = currentStr;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      enabled: isEditable,
      readOnly: !isEditable,
      controller: _controllers[label],
      style: labelStyle,
      decoration: InputDecoration(
        fillColor: isEditable
            ? (isDarkMode ? Colors.black : Colors.white)
            : Colors.grey[200],
        filled: true,
        labelText: label,
        errorText: resulterror[code],
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Appcolorblue),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: isEditable
          ? (value) {
              // Debug print
              print('📝 Number field changed (group): $label = $value');

              // ✅ STEP 1: Parse and store the number value
              if (value.isNotEmpty) {
                double? numericValue = double.tryParse(value);
                if (numericValue != null) {
                  // Store integer without decimals, float with decimals
                  if (numericValue == numericValue.toInt()) {
                    controller.dataMap[field['code']] =
                        numericValue.toInt().toString();
                  } else {
                    controller.dataMap[field['code']] =
                        numericValue.toString();
                  }
                } else {
                  controller.dataMap[field['code']] = value;
                }
              } else {
                controller.dataMap[field['code']] = "";
              }

              // ✅ STEP 2: Save to controllers
              controller.setInitialValue(code, value);
              controller.setFieldValue(label, value);

              // ✅ STEP 3: UPDATE ALL EXPRESSION FIELDS
              controller.updateAllExpressionFields();

              // ✅ STEP 4: Refresh UI
              setState(() {});

              // Debug print after update
              print('✅ Expression fields updated from group field');
            }
          : null,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }

        final regexPattern = field['regex'];
        if (regexPattern != null && value != null && value.isNotEmpty) {
          final regex = RegExp(regexPattern);
          if (!regex.hasMatch(value)) {
            return 'Invalid input for $label';
          }
        }

        // Optional: validate that it's a valid number
        if (value != null && value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }

        return null;
      },
    ),
  );
}

                                                if (fieldType == 'long' &&
                                                    result) {
                                                  final initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Ensure controller exists with initial value
                                                  _controllers[label] ??=
                                                      TextEditingController(
                                                    text: initialValue
                                                            ?.toString() ??
                                                        "",
                                                  );

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      enabled: isEditable,
                                                      readOnly: !isEditable,
                                                      controller:
                                                          _controllers[label],
                                                      style: labelStyle,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        errorText:
                                                            resulterror[code],
                                                        labelStyle: labelStyle,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: isEditable
                                                          ? (value) {
                                                              if (value
                                                                  .isNotEmpty) {
                                                                int?
                                                                    numericValue =
                                                                    int.tryParse(
                                                                        value);
                                                                if (numericValue !=
                                                                    null) {
                                                                  controller.dataMap[
                                                                          field[
                                                                              'code']] =
                                                                      numericValue
                                                                          .toString(); // store as integer string
                                                                }
                                                              } else {
                                                                controller.dataMap[
                                                                        field[
                                                                            'code']] =
                                                                    value; // empty/null
                                                              }

                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value);
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value);
                                                            }
                                                          : null,
                                                      validator: (value) {
                                                        if (isRequired &&
                                                            (value == null ||
                                                                value
                                                                    .isEmpty)) {
                                                          return 'Please enter $label';
                                                        }

                                                        final regexPattern = field[
                                                            'regex']; // e.g., "^[1-5]$"
                                                        if (regexPattern !=
                                                                null &&
                                                            value != null &&
                                                            value.isNotEmpty) {
                                                          final regex = RegExp(
                                                              regexPattern);
                                                          if (!regex.hasMatch(
                                                              value)) {
                                                            return 'Invalid input for $label';
                                                          }
                                                        }

                                                        return null;
                                                      },
                                                    ),
                                                  );
                                                }

           if (fieldType == 'decimal' &&
                                                    result) {
                                                  final dynamic initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);

                                                  // Normalize allowChangeAfterInitial to int
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              "0") ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Initialize controller with initial value if it exists
                                                  if (_controllers[label] ==
                                                      null) {
                                                    _controllers[label] =
                                                        TextEditingController();
                                                  }

                                                  // Set initial value if available and controller is empty
                                                  if (_controllers[label]!
                                                          .text
                                                          .isEmpty &&
                                                      initialValue != null &&
                                                      initialValue
                                                          .toString()
                                                          .isNotEmpty) {
                                                    _controllers[label]!.text =
                                                        initialValue.toString();
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      enabled: isEditable,
                                                      readOnly: !isEditable,
                                                      controller:
                                                          _controllers[label],
                                                      style: labelStyle,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        errorText:
                                                            resulterror[code],
                                                        labelStyle: labelStyle,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(
                                                              decimal: true),
                                                      onChanged: isEditable
                                                          ? (value) {
                                                              // Debug print to verify it's working
                                                              print(
                                                                  '📝 Decimal field changed: $label = $value');

                                                              // Store the raw value
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value);
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value);

                                                              // Store in dataMap
                                                              if (value
                                                                  .isNotEmpty) {
                                                                controller.dataMap[
                                                                        field[
                                                                            'code']] =
                                                                    value;
                                                              } else {
                                                                controller
                                                                        .dataMap[
                                                                    field[
                                                                        'code']] = "";
                                                              }

                                                              // IMPORTANT: Update all expression fields
                                                              controller
                                                                  .updateAllExpressionFields();

                                                              // Force UI update for Obx widgets
                                                              setState(() {});
                                                            }
                                                          : null,
                                                      validator: (value) {
                                                        if (isRequired &&
                                                            (value == null ||
                                                                value
                                                                    .isEmpty)) {
                                                          return 'Please enter $label';
                                                        }

                                                        final regexPattern =
                                                            field['regex'];
                                                        if (regexPattern !=
                                                                null &&
                                                            value != null &&
                                                            value.isNotEmpty) {
                                                          final regex = RegExp(
                                                              regexPattern);
                                                          if (!regex.hasMatch(
                                                              value)) {
                                                            return 'Invalid input for $label';
                                                          }
                                                        }

                                                        // Validate decimal number
                                                        if (value != null &&
                                                            value.isNotEmpty) {
                                                          if (double.tryParse(
                                                                  value) ==
                                                              null) {
                                                            return 'Please enter a valid decimal number';
                                                          }
                                                        }

                                                        return null;
                                                      },
                                                    ),
                                                  );
                                                }
                                      // Expression field widget - DONO JAGAH (main list + group fields)
                               if (fieldType == 'expression' &&
                                                    result) {
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5.0,
                                                        vertical: 5.0),
                                                    child: Obx(() {
                                                      // ← Important: Wrap with Obx
                                                      String currentValue =
                                                          controller
                                                                  .getFieldValue(
                                                                      label) ??
                                                              '';

                                                      // Update controller if needed
                                                      if (_controllers[label]
                                                              ?.text !=
                                                          currentValue) {
                                                        _controllers[label]
                                                                ?.text =
                                                            currentValue;
                                                      }

                                                      return TextFormField(
                                                        controller:
                                                            _controllers[label],
                                                        readOnly: true,
                                                        enabled: false,
                                                        style:
                                                            labelStyle.copyWith(
                                                                color: Colors
                                                                    .grey[700]),
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: label,
                                                          labelStyle:
                                                              labelStyle,
                                                          filled: true,
                                                          fillColor:
                                                              Colors.grey[200],
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .grey),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  );
                                                }
                                                if (fieldType == 'date' &&
                                                    result) {
                                                  final String initialValue =
                                                      controller
                                                              .getInitialValue(
                                                                  code) ??
                                                          "";

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      style: labelStyle,
                                                      enabled: isEditable,
                                                      readOnly: true,
                                                      controller:
                                                          TextEditingController(
                                                              text:
                                                                  initialValue),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: label,
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        suffixIcon: isEditable
                                                            ? Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                              )
                                                            : null,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      onTap: isEditable
                                                          ? () async {
                                                              DateTime?
                                                                  selectedDate;

                                                              if (minDateStr
                                                                      .isEmpty &&
                                                                  maxDateStr
                                                                      .isEmpty) {
                                                                selectedDate =
                                                                    await showDatePicker(
                                                                  context:
                                                                      context,
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
                                                              } else {
                                                                DateTime
                                                                    minDate =
                                                                    DateTime.parse(
                                                                        minDateStr);
                                                                DateTime
                                                                    maxDate =
                                                                    DateTime.parse(
                                                                        maxDateStr);
                                                                DateTime
                                                                    initial =
                                                                    DateTime
                                                                        .now();

                                                                if (initial
                                                                    .isBefore(
                                                                        minDate)) {
                                                                  initial =
                                                                      minDate;
                                                                } else if (initial
                                                                    .isAfter(
                                                                        maxDate)) {
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

                                                              if (selectedDate !=
                                                                  null) {
                                                                String
                                                                    formattedDate =
                                                                    DateFormat(
                                                                            'yyyy-MM-dd')
                                                                        .format(
                                                                            selectedDate);

                                                                if (event !=
                                                                    "") {
                                                                  var response =
                                                                      await controller.validateAndSubmitDate(
                                                                          rule,
                                                                          formattedDate);

                                                                  if (response !=
                                                                          null &&
                                                                      response[
                                                                              'success'] ==
                                                                          false) {
                                                                    String
                                                                        errorMessage =
                                                                        response['result']?['message'] ??
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
                                                                    controller.setFieldValue(
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
                                                                    controller.setFieldValue(
                                                                        label,
                                                                        formattedDate);
                                                                  });
                                                                }
                                                              }
                                                            }
                                                          : null,
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
                                                if (fieldType == 'time' &&
                                                    result) {
                                                  final initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);

                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              '0') ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  _controllers[label] ??=
                                                      TextEditingController();

                                                  // 🔹 Set initial value (24-hour display)
                                                  if (_controllers[label]!
                                                          .text
                                                          .isEmpty &&
                                                      initialValue != null &&
                                                      initialValue
                                                          .toString()
                                                          .isNotEmpty) {
                                                    _controllers[label]!.text =
                                                        initialValue
                                                            .toString(); // HH:mm
                                                  }

                                                  // 🔹 Default current time
                                                  final int
                                                      defaultToCurrentTime =
                                                      field['defaultToCurrentTime'] ??
                                                          0;

                                                  if (_controllers[label]!
                                                          .text
                                                          .isEmpty &&
                                                      defaultToCurrentTime ==
                                                          1) {
                                                    final now = DateTime.now();

                                                    // 👉 FIELD DISPLAY → 24 hour
                                                    String displayTime =
                                                        DateFormat('HH:mm')
                                                            .format(now);

                                                    _controllers[label]!.text =
                                                        displayTime;

                                                    controller.setInitialValue(
                                                        code, displayTime);
                                                    controller.setFieldValue(
                                                        label, displayTime);
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    child: TextFormField(
                                                      readOnly: true,
                                                      enabled: isEditable,
                                                      controller:
                                                          _controllers[label],
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: label,
                                                        errorText:
                                                            resulterror[code],
                                                        suffixIcon: isEditable
                                                            ? const Icon(Icons
                                                                .access_time)
                                                            : null,
                                                        filled: true,
                                                      ),
                                                      onTap: isEditable
                                                          ? () async {
                                                              TimeOfDay?
                                                                  picked =
                                                                  await showTimePicker(
                                                                context:
                                                                    context,
                                                                initialTime:
                                                                    TimeOfDay
                                                                        .now(),
                                                                builder:
                                                                    (context,
                                                                        child) {
                                                                  return MediaQuery(
                                                                    data: MediaQuery.of(
                                                                            context)
                                                                        .copyWith(
                                                                      alwaysUse24HourFormat:
                                                                          false, // ✅ ALWAYS AM/PM WATCH
                                                                    ),
                                                                    child:
                                                                        child!,
                                                                  );
                                                                },
                                                              );

                                                              if (picked !=
                                                                  null) {
                                                                final now =
                                                                    DateTime
                                                                        .now();
                                                                final dt =
                                                                    DateTime(
                                                                  now.year,
                                                                  now.month,
                                                                  now.day,
                                                                  picked.hour,
                                                                  picked.minute,
                                                                );

                                                                // 👉 FIELD DISPLAY → 24-hour (20:35)
                                                                String
                                                                    displayTime =
                                                                    DateFormat(
                                                                            'HH:mm')
                                                                        .format(
                                                                            dt);

                                                                setState(() {
                                                                  _controllers[
                                                                              label]!
                                                                          .text =
                                                                      displayTime;
                                                                  controller
                                                                      .setInitialValue(
                                                                          code,
                                                                          displayTime);
                                                                  controller
                                                                      .setFieldValue(
                                                                          label,
                                                                          displayTime);
                                                                });
                                                              }
                                                            }
                                                          : null,
                                                      validator: isRequired
                                                          ? (v) => v == null ||
                                                                  v.isEmpty
                                                              ? 'Please select $label'
                                                              : null
                                                          : null,
                                                    ),
                                                  );
                                                }

                                                if (fieldType == 'idate' &&
                                                    result) {
                                                  final String initialValue =
                                                      controller
                                                              .getInitialValue(
                                                                  code) ??
                                                          "";

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              '0') ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Get timeFormat (12 or 24 hour)
                                                  dynamic timeFormatValue =
                                                      field['timeFormat'];
                                                  int timeFormat =
                                                      24; // Default
                                                  if (timeFormatValue != null) {
                                                    if (timeFormatValue
                                                        is int) {
                                                      timeFormat =
                                                          timeFormatValue;
                                                    } else if (timeFormatValue
                                                        is String) {
                                                      timeFormat = int.tryParse(
                                                              timeFormatValue) ??
                                                          24;
                                                    }
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: TextFormField(
                                                      readOnly: true,
                                                      enabled: isEditable,
                                                      style: labelStyle,
                                                      controller:
                                                          TextEditingController(
                                                        text: controller
                                                            .formatIDateForDisplay(
                                                                initialValue),
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        suffixIcon: isEditable
                                                            ? Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                              )
                                                            : null,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      onTap: isEditable
                                                          ? () async {
                                                              DateTime?
                                                                  selectedDate =
                                                                  await showDatePicker(
                                                                context:
                                                                    context,
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
                                                                // Format as dd-MM-yyyy for display
                                                                String
                                                                    formattedDate =
                                                                    DateFormat(
                                                                            'dd-MM-yyyy')
                                                                        .format(
                                                                            selectedDate);

                                                                // Convert to UTC ISO format for API
                                                                String
                                                                    apiFormat =
                                                                    controller
                                                                        .formatIDateForApi(
                                                                            formattedDate);

                                                                setState(() {
                                                                  controller
                                                                      .setInitialValue(
                                                                          code,
                                                                          apiFormat);
                                                                  controller
                                                                      .setFieldValue(
                                                                          label,
                                                                          apiFormat);
                                                                });
                                                              }
                                                            }
                                                          : null,
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

// ITIME फील्ड
                                                else if (fieldType == 'itime' &&
                                                    result) {
                                                  final String initialValue =
                                                      controller
                                                              .getInitialValue(
                                                                  code) ??
                                                          "";

                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              '0') ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // ⏱ timeFormat (12 / 24)
                                                  int timeFormat = int.tryParse(
                                                          field['timeFormat']
                                                                  ?.toString() ??
                                                              '12') ??
                                                      12;

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    child: TextFormField(
                                                      readOnly: true,
                                                      enabled: isEditable,
                                                      style: labelStyle,
                                                      controller:
                                                          TextEditingController(
                                                        text: controller
                                                            .formatITimeForDisplay(
                                                                initialValue,
                                                                timeFormat),
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        filled: true,
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        suffixIcon: isEditable
                                                            ? const Icon(Icons
                                                                .access_time)
                                                            : null,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                      ),
                                                      onTap: isEditable
                                                          ? () async {
                                                              TimeOfDay?
                                                                  pickedTime =
                                                                  await showTimePicker(
                                                                context:
                                                                    context,
                                                                initialTime:
                                                                    TimeOfDay
                                                                        .now(),
                                                                builder:
                                                                    (context,
                                                                        child) {
                                                                  return MediaQuery(
                                                                    data: MediaQuery.of(
                                                                            context)
                                                                        .copyWith(
                                                                      alwaysUse24HourFormat:
                                                                          timeFormat ==
                                                                              24,
                                                                    ),
                                                                    child:
                                                                        child!,
                                                                  );
                                                                },
                                                              );

                                                              if (pickedTime !=
                                                                  null) {
                                                                // 🕒 Display Format
                                                                String
                                                                    displayTime;
                                                                if (timeFormat ==
                                                                    24) {
                                                                  displayTime =
                                                                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                                                                } else {
                                                                  // ✅ AM / PM clearly shown
                                                                  displayTime =
                                                                      DateFormat(
                                                                              'hh:mm a')
                                                                          .format(
                                                                    DateTime(
                                                                      2024,
                                                                      1,
                                                                      1,
                                                                      pickedTime
                                                                          .hour,
                                                                      pickedTime
                                                                          .minute,
                                                                    ),
                                                                  );
                                                                }

                                                                // 📦 API format (ISO / backend safe)
                                                                String apiTime =
                                                                    controller
                                                                        .formatITimeForApi(
                                                                            displayTime);

                                                                setState(() {
                                                                  controller
                                                                      .setInitialValue(
                                                                          code,
                                                                          apiTime);
                                                                  controller
                                                                      .setFieldValue(
                                                                          label,
                                                                          apiTime);
                                                                });
                                                              }
                                                            }
                                                          : null,
                                                      validator: isRequired
                                                          ? (value) => value ==
                                                                      null ||
                                                                  value.isEmpty
                                                              ? 'Please select $label'
                                                              : null
                                                          : null,
                                                    ),
                                                  );
                                                } else if ((fieldType ==
                                                            'datetime' ||
                                                        fieldType ==
                                                            'dateandtime') &&
                                                    result) {
                                                  final String initialValue =
                                                      controller
                                                              .getInitialValue(
                                                                  code) ??
                                                          "";

                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              '0') ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // ⏱ timeFormat (same as before – NOT used for display)
                                                  dynamic timeFormatValue =
                                                      field['timeFormat'];
                                                  int timeFormat = 24;
                                                  if (timeFormatValue != null) {
                                                    if (timeFormatValue
                                                        is int) {
                                                      timeFormat =
                                                          timeFormatValue;
                                                    } else if (timeFormatValue
                                                        is String) {
                                                      timeFormat = int.tryParse(
                                                              timeFormatValue) ??
                                                          24;
                                                    }
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    child: TextFormField(
                                                      readOnly: true,
                                                      enabled: isEditable,
                                                      style: labelStyle,
                                                      controller:
                                                          TextEditingController(
                                                        // 🔒 DISPLAY SAME AS BEFORE
                                                        text: controller
                                                            .formatDateTimeForDisplay(
                                                                initialValue,
                                                                timeFormat),
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        filled: true,
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        suffixIcon: isEditable
                                                            ? Icon(
                                                                Icons
                                                                    .date_range,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                            : null,
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                      ),
                                                      onTap: isEditable
                                                          ? () async {
                                                              // 📅 Date picker (UNCHANGED)
                                                              DateTime?
                                                                  selectedDate =
                                                                  await showDatePicker(
                                                                context:
                                                                    context,
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

                                                              if (selectedDate ==
                                                                  null) return;

                                                              // ⏰ Time picker (ONLY CHANGE HERE)
                                                              TimeOfDay?
                                                                  selectedTime =
                                                                  await showTimePicker(
                                                                context:
                                                                    context,
                                                                initialTime:
                                                                    TimeOfDay
                                                                        .now(),
                                                                builder:
                                                                    (context,
                                                                        child) {
                                                                  return MediaQuery(
                                                                    data: MediaQuery.of(
                                                                            context)
                                                                        .copyWith(
                                                                      // ✅ FORCE AM / PM
                                                                      alwaysUse24HourFormat:
                                                                          false,
                                                                    ),
                                                                    child:
                                                                        child!,
                                                                  );
                                                                },
                                                              );

                                                              if (selectedTime ==
                                                                  null) return;

                                                              // 🔗 Combine date + time (UNCHANGED)
                                                              final DateTime
                                                                  combinedDateTime =
                                                                  DateTime(
                                                                selectedDate
                                                                    .year,
                                                                selectedDate
                                                                    .month,
                                                                selectedDate
                                                                    .day,
                                                                selectedTime
                                                                    .hour,
                                                                selectedTime
                                                                    .minute,
                                                              );

                                                              // 🔒 API format (UNCHANGED)
                                                              String apiFormat =
                                                                  controller.formatDateTimeForApi(
                                                                      combinedDateTime
                                                                          .toString());

                                                              setState(() {
                                                                controller
                                                                    .setInitialValue(
                                                                        code,
                                                                        apiFormat);
                                                                controller
                                                                    .setFieldValue(
                                                                        label,
                                                                        apiFormat);
                                                              });
                                                            }
                                                          : null,
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

                                                if (fieldType == 'map' &&
                                                    result) {
                                                  List<dynamic> mapValues =
                                                      field['values'] ?? [];

                                                  final dynamic initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);
                                                  String? currentValue =
                                                      (initialValue == null ||
                                                              initialValue
                                                                  .toString()
                                                                  .trim()
                                                                  .isEmpty)
                                                          ? null
                                                          : initialValue
                                                              .toString()
                                                              .trim();

                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                      'allowChangeAfterInitial']
                                                                  ?.toString() ??
                                                              "0") ??
                                                          0;
                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Map key -> value for easy lookup
                                                  Map<String, String>
                                                      keyValueMap = {
                                                    for (var item in mapValues)
                                                      (item['key'] ?? '')
                                                              .toString()
                                                              .trim():
                                                          (item['value'] ?? '')
                                                              .toString()
                                                  };

                                                  // Reset if currentValue not valid
                                                  if (currentValue != null &&
                                                      !mapValues.any((item) {
                                                        final String key =
                                                            (item['key'] ?? '')
                                                                .toString()
                                                                .trim();
                                                        final String valueText =
                                                            (item['value'] ??
                                                                    '')
                                                                .toString();
                                                        return currentValue ==
                                                            "$key - $valueText";
                                                      })) {
                                                    currentValue = null;
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child:
                                                        DropdownButtonFormField<
                                                            String?>(
                                                      isExpanded: true,
                                                      dropdownColor: isDarkMode
                                                          ? Colors.grey[850]
                                                          : Colors.white,
                                                      style: labelStyle,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : (isDarkMode
                                                                ? Colors
                                                                    .grey[800]
                                                                : Colors
                                                                    .grey[200]),
                                                        filled: true,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      value: currentValue,
                                                      items: [
                                                        if (!isRequired)
                                                          DropdownMenuItem<
                                                              String?>(
                                                            value: null,
                                                            child: Text(
                                                              'Select $label',
                                                              style: labelStyle
                                                                  .copyWith(
                                                                      color: Colors
                                                                          .grey),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ...mapValues.map<
                                                                DropdownMenuItem<
                                                                    String?>>(
                                                            (item) {
                                                          final String key =
                                                              (item['key'] ??
                                                                      '')
                                                                  .toString()
                                                                  .trim();
                                                          final String
                                                              valueText =
                                                              (item['value'] ??
                                                                      '')
                                                                  .toString();
                                                          final String
                                                              keyValue =
                                                              "$key - $valueText"; // ✅ combined
                                                          return DropdownMenuItem<
                                                              String?>(
                                                            value: keyValue,
                                                            child: Text(
                                                              keyValue,
                                                              style: labelStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ],
                                                      selectedItemBuilder:
                                                          (BuildContext
                                                              context) {
                                                        List<Widget>
                                                            selectedWidgets =
                                                            [];
                                                        if (!isRequired) {
                                                          selectedWidgets
                                                              .add(Text(
                                                            'Select $label',
                                                            style: labelStyle
                                                                .copyWith(
                                                                    color: Colors
                                                                        .grey),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ));
                                                        }
                                                        selectedWidgets.addAll(
                                                            mapValues
                                                                .map<Widget>(
                                                                    (item) {
                                                          final String key =
                                                              (item['key'] ??
                                                                      '')
                                                                  .toString()
                                                                  .trim();
                                                          final String
                                                              valueText =
                                                              (item['value'] ??
                                                                      '')
                                                                  .toString();
                                                          return Text(
                                                            "$key - $valueText",
                                                            style: labelStyle,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          );
                                                        }).toList());
                                                        return selectedWidgets;
                                                      },
                                                      onChanged: isEditable
                                                          ? (value) async {
                                                              if (event != "") {
                                                                await controller
                                                                    .GetUserData(
                                                                        code,
                                                                        rule,
                                                                        value ??
                                                                            "");
                                                                controller
                                                                        .admissionId =
                                                                    value;
                                                              }
                                                              controller.dataMap[
                                                                      code] =
                                                                  value ??
                                                                      ""; // ✅ store "1 - a"
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value ??
                                                                          "");
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value ??
                                                                          "");
                                                            }
                                                          : null,
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

                                                if (fieldType == 'combobox' &&
                                                    result) {
                                                  comboboxmapValues =
                                                      field['values'] ?? [];
                                                  List<String> _options = List<
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
                                                      List.from(_options);

                                                  return StatefulBuilder(
                                                    builder: (context,
                                                        setInnerState) {
                                                      void _saveValue(
                                                          String value) {
                                                        controller.dataMap[
                                                                field['code']] =
                                                            value;
                                                        controller
                                                            .setFieldValue(
                                                                label, value);
                                                        controller
                                                            .setInitialValue(
                                                                code, value);
                                                      }

                                                      void _onTextChanged(
                                                          String value) {
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

                                                      void _onItemSelected(
                                                          String value) {
                                                        _controllers[label]!
                                                            .text = value;
                                                        _saveValue(
                                                            value); // Save on dropdown selection
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                        setInnerState(() {
                                                          _filteredOptions =
                                                              _options;
                                                        });
                                                      }

                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          vertical: 5.0,
                                                        ),
                                                        child: TextField(
                                                          controller:
                                                              _controllers[
                                                                  label],
                                                          enabled:
                                                              readOnly != 1,
                                                          readOnly:
                                                              readOnly == 1,
                                                          onChanged: readOnly !=
                                                                  1
                                                              ? _onTextChanged
                                                              : null,
                                                          decoration:
                                                              InputDecoration(
                                                            fillColor:
                                                                isDarkMode
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                            labelText:
                                                                'Select a $label',
                                                            suffixIcon:
                                                                PopupMenuButton<
                                                                    String>(
                                                              icon: const Icon(Icons
                                                                  .arrow_drop_down),
                                                              itemBuilder:
                                                                  (context) {
                                                                return _filteredOptions
                                                                    .map((String
                                                                        option) {
                                                                  return PopupMenuItem<
                                                                      String>(
                                                                    value:
                                                                        option,
                                                                    child: Text(
                                                                      option,
                                                                      style:
                                                                          labelStyle,
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
                                                if (fieldType == 'list' &&
                                                    result) {
                                                  final values =
                                                      field['values'] ?? [];
                                                  final initialValue =
                                                      controller
                                                          .getInitialValue(
                                                              code);

                                                  // Normalize allowChangeAfterInitial
                                                  final int allowChange =
                                                      int.tryParse(field[
                                                                  'allowChangeAfterInitial']
                                                              .toString()) ??
                                                          0;

                                                  final bool isEditable =
                                                      readOnly != 1 &&
                                                          allowChange == 0;

                                                  // Ensure valid initial value
                                                  final validInitialValue =
                                                      values.contains(
                                                              initialValue)
                                                          ? initialValue
                                                          : null;

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                      isExpanded: true,
                                                      dropdownColor: isDarkMode
                                                          ? Colors.grey[850]
                                                          : Colors.white,
                                                      style: labelStyle,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isEditable
                                                            ? (isDarkMode
                                                                ? Colors.black
                                                                : Colors.white)
                                                            : Colors.grey[200],
                                                        filled: true,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide: BorderSide(
                                                              color:
                                                                  Appcolorblue),
                                                        ),
                                                      ),
                                                      value: (validInitialValue ==
                                                                  null ||
                                                              validInitialValue
                                                                  .toString()
                                                                  .isEmpty)
                                                          ? null
                                                          : validInitialValue
                                                              .toString(),
                                                      items: [
                                                        if (!isRequired)
                                                          DropdownMenuItem<
                                                              String>(
                                                            value: null,
                                                            child: Text(
                                                              'Select $label',
                                                              style: labelStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ...values.map<
                                                                DropdownMenuItem<
                                                                    String>>(
                                                            (value) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: value,
                                                            child: Text(
                                                              value,
                                                              style: labelStyle,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ],
                                                      onChanged: isEditable
                                                          ? (value) async {
                                                                          // ✅ STEP 3: UPDATE ALL EXPRESSION FIELDS
                                                              controller
                                                                  .updateAllExpressionFields();

                                                              // ✅ STEP 4: Refresh UI
                                                              setState(() {});

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
                                                                        code] =
                                                                    value;
                                                                controller
                                                                    .setInitialValue(
                                                                        code,
                                                                        value ??
                                                                            "");
                                                                controller
                                                                    .setFieldValue(
                                                                        label,
                                                                        value ??
                                                                            "");
                                                              } else {
                                                                controller.dataMap[
                                                                        code] =
                                                                    value;
                                                                controller
                                                                    .setInitialValue(
                                                                        code,
                                                                        value ??
                                                                            "");
                                                                controller
                                                                    .setFieldValue(
                                                                        label,
                                                                        value ??
                                                                            "");
                                                              }
                                                            }
                                                          : null,
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

                                                if (fieldType == 'doc' &&
                                                    result) {
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
                                                              borderSide:
                                                                  const BorderSide(
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
                                                                        int.tryParse(controller.getInitialValue(code)?.toString() ??
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
                                                              controller
                                                                      .imagePaths[
                                                                  code] = value;
                                                            });
                                                            controller.dataMap[
                                                                    field[
                                                                        'code']] =
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
                                                      controller.imagePaths[
                                                                  code] !=
                                                              null
                                                          ? CachedNetworkImage(
                                                              width: 100,
                                                              height: 100,
                                                              imageUrl:
                                                                  "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadDocument[code]}?t=${DateTime.now().millisecondsSinceEpoch}",
                                                              placeholder: (context,
                                                                      url) =>
                                                                  CircularProgressIndicator(),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  Icon(Icons
                                                                      .error),
                                                            )
                                                          : Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          16.0),
                                                              child: Image.network(
                                                                  width: 100,
                                                                  height: 100,
                                                                  controller.getInitialValue(
                                                                              code) ==
                                                                          null
                                                                      ? imageUrlHelper
                                                                          .applogourl
                                                                      : "https://cuickdev.com/API/DOCS/api/doc/th/${controller.getInitialValue(code).toString()}?t=0"), // Display the selected image (optional)
                                                            )
                                                    ],
                                                  );
                                                }
                                                if (fieldType == 'file' &&
                                                    result) {
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
                                                                vertical: 8.0),
                                                        child: TextFormField(
                                                          style: labelStyle,
                                                          onTap: () {
                                                            if (captureImage ==
                                                                1) {
                                                              getImage1(
                                                                  int.tryParse(controller
                                                                              .getInitialValue(
                                                                                  code)
                                                                              ?.toString() ??
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
                                                              borderSide:
                                                                  const BorderSide(
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
                                                                      if (captureImage ==
                                                                          1) {
                                                                        getImage1(
                                                                            int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ??
                                                                                0,
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
                                                            // Save the file path (or name) to the controller
                                                            setState(() {
                                                              controller.imagePaths[
                                                                      code] =
                                                                  value; // Optionally save the file path here
                                                            });
                                                            controller.dataMap[
                                                                    field[
                                                                        'code']] =
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
                                                      controller.imagePaths[
                                                                  code] !=
                                                              null
                                                          ? Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          16.0),
                                                              child: Image.file(
                                                                File(controller
                                                                        .imagePaths[
                                                                    code]!),
                                                                width: 100,
                                                                height: 100,
                                                              ), // Display the selected image (optional)
                                                            )
                                                          : Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          16.0),
                                                              child: Image.network(
                                                                  width: 100,
                                                                  height: 100,
                                                                  controller.getInitialValue(
                                                                              code) ==
                                                                          null
                                                                      ? imageUrlHelper
                                                                          .applogourl
                                                                      : "https://cuickdev.com/API/DOCS/api/doc/th/${controller.getInitialValue(code).toString()}?t=0"), // Display the selected image (
                                                            )
                                                    ],
                                                  );
                                                }
                                                return SizedBox();
                                              }).toList(),
                                              const SizedBox(height: 20),
                                              Center(
                                                child: Wrap(
                                                  spacing: 10.0,
                                                  runSpacing: 10.0,
                                                  alignment:
                                                      WrapAlignment.center,
                                                  children: controller.buttons
                                                      .where((button) {
                                                    switch (button.name
                                                        .toLowerCase()) {
                                                      case 'list':
                                                        return widget.isread ==
                                                            1;
                                                      case 'delete':
                                                        return widget
                                                                    .isdelete ==
                                                                1 &&
                                                            !isNewClicked;
                                                        ;
                                                      case 'update':
                                                        return widget
                                                                .isupdate ==
                                                            1;
                                                      case 'save':
                                                        return widget
                                                                    .iscreate ==
                                                                1 ||
                                                            widget.isupdate ==
                                                                    1 &&
                                                                widget.formID !=
                                                                    ''; // Assuming you have issave for Save button
                                                      case 'new':
                                                        return widget
                                                                .iscreate ==
                                                            1;
                                                      case 'cancel':
                                                        return widget
                                                                .iscreate ==
                                                            1;
                                                      default:
                                                        return true; // Hide button if it doesn't match any case
                                                    }
                                                  }).map((button) {
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        if (button.name
                                                                .toLowerCase() ==
                                                            'save') {
                                                          if (isSaving)
                                                            return; // 🛑 Prevent multiple submissions

                                                          setState(() {
                                                            isSaving = true;
                                                          });

                                                          if (_formKey
                                                                  .currentState
                                                                  ?.validate() ??
                                                              false) {
                                                            Map<String,
                                                                    dynamic>?
                                                                response =
                                                                await SaveForm();
                                                            if (response !=
                                                                    null &&
                                                                response[
                                                                    'success']) {
                                                              showToast();
                                                            } else {
                                                              var inputError =
                                                                  response?[
                                                                          'result']
                                                                      [
                                                                      'inputerror'];
                                                              if (!mounted)
                                                                return; // <-- very important here
                                                              setState(() {
                                                                resulterror
                                                                    .clear();

                                                                if (inputError !=
                                                                    null) {
                                                                  inputError
                                                                      .forEach((key,
                                                                          value) {
                                                                    resulterror[
                                                                            key] =
                                                                        value;
                                                                    CherryToast
                                                                        .error(
                                                                      backgroundColor:
                                                                          const Color(
                                                                              0xFFF8D0D9),
                                                                      animationDuration:
                                                                          Durations
                                                                              .short1,
                                                                      title: const Text(
                                                                          "Error Saving Form",
                                                                          style:
                                                                              TextStyle(color: Colors.black)),
                                                                    ).show(Get
                                                                        .overlayContext!);
                                                                  });
                                                                } else {
                                                                  // Optional: handle no inputError case
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
                                                          handleButtonClick(button
                                                              .name
                                                              .toLowerCase());
                                                        }
                                                      },

                                                      // {
                                                      //   handleButtonClick(
                                                      //       button.name.toLowerCase());
                                                      // },
                                                      child: Opacity(
                                                        opacity: (button.name
                                                                        .toLowerCase() ==
                                                                    'save' &&
                                                                isSaving)
                                                            ? 0.5
                                                            : 1.0,
                                                        child: Container(
                                                          height: 45,
                                                          width: 120,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: (button.name
                                                                            .toLowerCase() ==
                                                                        'save' &&
                                                                    isSaving)
                                                                ? Colors.grey
                                                                    .shade300
                                                                : null,
                                                            border: Border.all(
                                                              color: isDarkMode
                                                                  ? const Color(
                                                                      0xFF4F76E2)
                                                                  : const Color(
                                                                      0xFF1A237E),
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              button.name
                                                                  .toUpperCase(),
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? const Color(
                                                                        0xFF4F76E2)
                                                                    : const Color(
                                                                        0xFF1A237E),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontFamily:
                                                                    'Lato',
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      // Container(
                                                      //   height: 45,
                                                      //   width: 120,
                                                      //   decoration: BoxDecoration(
                                                      //     border: Border.all(
                                                      //       color: isDarkMode
                                                      //           ? const Color(0xFF4F76E2)
                                                      //           : const Color(0xFF1A237E),
                                                      //     ),
                                                      //     borderRadius:
                                                      //         BorderRadius.circular(5),
                                                      //   ),
                                                      //   child: Center(
                                                      //     child: Text(
                                                      //       button.name.toUpperCase(),
                                                      //       style: TextStyle(
                                                      //         color: isDarkMode
                                                      //             ? const Color(
                                                      //                 0xFF4F76E2)
                                                      //             : const Color(
                                                      //                 0xFF1A237E),
                                                      //         fontWeight: FontWeight.w500,
                                                      //         fontFamily: 'Lato',
                                                      //         fontSize: 15,
                                                      //       ),
                                                      //     ),
                                                      //   ),
                                                      // ),
                                                    );
                                                    /*GestureDetector(
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
                                                    fontWeight:
                                                    FontWeight.w500,
                                                    fontFamily: 'Lato',
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );*/
                                                  }).toList(),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              childcontroller.filteredData
                                                          .isEmpty &&
                                                      childcontroller
                                                          .childlabellist
                                                          .isEmpty
                                                  ? SizedBox()
                                                  : Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    5),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .grey[200],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  "${childcontroller.Childtitle.value}",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                childcontroller
                                                                            .iscreate !=
                                                                        0
                                                                    ? GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          Get.to(ChilduiformScreen(
                                                                              title: childcontroller.Childtitle.value,
                                                                              editid: 0));
                                                                        },
                                                                        child: Container(
                                                                            height: 40,
                                                                            width: 50,
                                                                            decoration: BoxDecoration(
                                                                                color: isDarkMode ? Color(0xFF4F76E2) : Appcolorblue,
                                                                                border: Border.all(
                                                                                  color: Appcolorblue,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(20)),
                                                                            child: const Icon(
                                                                              Icons.add,
                                                                              size: 40,
                                                                              color: Colors.white,
                                                                              // color: Color(0xFF2962FF),
                                                                            )),
                                                                      )
                                                                    : SizedBox()
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(height: 10),
                                                          childcontroller
                                                                      .filteredData
                                                                      .isEmpty &&
                                                                  childcontroller
                                                                      .childlabellist
                                                                      .isEmpty
                                                              ? SizedBox()
                                                              : childcontroller
                                                                          .isread !=
                                                                      0
                                                                  ? SingleChildScrollView(
                                                                      scrollDirection:
                                                                          Axis.horizontal,
                                                                      physics:
                                                                          const BouncingScrollPhysics(),
                                                                      child:
                                                                          DataTable(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: Get.isDarkMode
                                                                              ? Colors.black
                                                                              : const Color(0xFFF5F5F5),
                                                                        ),
                                                                        border:
                                                                            TableBorder.all(
                                                                          color: Get.isDarkMode
                                                                              ? Colors.white
                                                                              : const Color(0xFFE0E0E0),
                                                                        ),
                                                                        columnSpacing:
                                                                            20,
                                                                        dividerThickness:
                                                                            0.2,
                                                                        columns: [
                                                                          DataColumn(
                                                                            label:
                                                                                Text(
                                                                              'SNo.',
                                                                              style: TextStyle(
                                                                                fontSize: 15,
                                                                                color: isDarkMode ? Colors.white : Colors.black,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          ...List
                                                                              .generate(
                                                                            childcontroller.childlabellist.length,
                                                                            (index) {
                                                                              final item = childcontroller.childlabellist[index];

                                                                              final displayLabel = item['refKey'] == 1 && item['depAttribute'] != null ? _capitalize(item['label']) : _capitalize(item['label']);

                                                                              return DataColumn(
                                                                                label: Text(
                                                                                  displayLabel,
                                                                                  style: TextStyle(
                                                                                    fontSize: 15,
                                                                                    color: isDarkMode ? Colors.white : Colors.black,
                                                                                    fontWeight: FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                          if (childcontroller.isdelete != 0 ||
                                                                              childcontroller.isupdate != 0)
                                                                            DataColumn(
                                                                              label: Text(
                                                                                'Action',
                                                                                style: TextStyle(
                                                                                  fontSize: 15,
                                                                                  color: Get.isDarkMode ? Colors.white : Colors.black,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                        rows: List<
                                                                            DataRow>.generate(
                                                                          childcontroller
                                                                              .filteredData
                                                                              .length,
                                                                          (rowIndex) {
                                                                            int indexcount =
                                                                                rowIndex + 1;
                                                                            final attribute =
                                                                                childcontroller.filteredData[rowIndex];

                                                                            final dynamicValues =
                                                                                childcontroller.childlabellist.map((label) {
                                                                              if (label['refKey'] == 1 && label['depAttribute'] != null) {
                                                                                return attribute[label['depAttribute']];
                                                                              }
                                                                              return attribute[label['code']];
                                                                            }).toList();

                                                                            return DataRow(
                                                                              color: WidgetStateProperty.resolveWith<Color?>(
                                                                                (Set<WidgetState> states) => isDarkMode ? (rowIndex.isEven ? Colors.grey[900] : Colors.grey[800]) : (rowIndex.isEven ? Colors.white : Colors.grey[200]),
                                                                              ),
                                                                              cells: [
                                                                                DataCell(
                                                                                  Text(
                                                                                    indexcount.toString(),
                                                                                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                                                                  ),
                                                                                ),
                                                                                ...List.generate(
                                                                                  dynamicValues.length,
                                                                                  (columnIndex) {
                                                                                    final label = childcontroller.childlabellist[columnIndex]['code'];
                                                                                    final type = childcontroller.childlabellist[columnIndex]['type'];

                                                                                    if (type == 'file') {
                                                                                      final imageId = dynamicValues[columnIndex] ?? 0;
                                                                                      final imageUrl = (imageId != null && imageId != 0 && imageId != "") ? "https://cuickdev.com/API/DOCS/api/doc/th/${imageId}?t=${DateTime.now().millisecondsSinceEpoch}" : imageUrlHelper.applogourl;
                                                                                      return DataCell(
                                                                                        imageUrl.isNotEmpty
                                                                                            ? GestureDetector(
                                                                                                onTap: () async {
                                                                                                  final Uri testUrl = Uri.parse(imageUrl);
                                                                                                  await launchUrl(testUrl);
                                                                                                },
                                                                                                child: CachedNetworkImage(
                                                                                                  imageUrl: imageUrl,
                                                                                                  width: 50,
                                                                                                  height: 50,
                                                                                                  fit: BoxFit.cover,
                                                                                                  placeholder: (context, url) => SizedBox(
                                                                                                    width: 24, // Set your desired width
                                                                                                    height: 24, // Set your desired height
                                                                                                    // child: CircularProgressIndicator(
                                                                                                    //
                                                                                                    // ),
                                                                                                  ),
                                                                                                  errorWidget: (context, url, error) => Icon(Icons.error), // Show an error icon if the image fails to load
                                                                                                ))
                                                                                            : Text('-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                                                                      );
                                                                                    }
                                                                                    if (type == 'doc') {
                                                                                      final imageId = dynamicValues[columnIndex] ?? 0;

                                                                                      final imageUrl = (imageId != null && imageId != 0 && imageId != "") ? "https://cuickdev.com/API/DOCS/api/doc/th/${imageId}?t=${DateTime.now().millisecondsSinceEpoch}" : imageUrlHelper.applogourl;
                                                                                      return DataCell(
                                                                                        imageUrl.isNotEmpty
                                                                                            ? GestureDetector(
                                                                                                onTap: () async {
                                                                                                  var finalimageId = (imageId == null || imageId == 0) ? 0 : imageId;
                                                                                                  final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/$finalimageId');
                                                                                                  await launchUrl(testUrl);
                                                                                                },
                                                                                                child: CachedNetworkImage(
                                                                                                  imageUrl: imageUrl,
                                                                                                  width: 50,
                                                                                                  height: 50,
                                                                                                  fit: BoxFit.cover,
                                                                                                  placeholder: (context, url) => SizedBox(
                                                                                                    width: 24, // Set your desired width
                                                                                                    height: 24, // Set your desired height
                                                                                                    // child: CircularProgressIndicator(
                                                                                                    //
                                                                                                    // ),
                                                                                                  ), // Show a loading indicator while the image is loading
                                                                                                  errorWidget: (context, url, error) => Icon(Icons.error), // Show an error icon if the image fails to load
                                                                                                ))
                                                                                            : Text('-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                                                                      );
                                                                                    } else {
                                                                                      return DataCell(
                                                                                        Text(
                                                                                          dynamicValues[columnIndex]?.toString() ?? '-',
                                                                                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  },
                                                                                ),
                                                                                if (childcontroller.isdelete != 0 || childcontroller.isupdate != 0)
                                                                                  DataCell(
                                                                                    Row(
                                                                                      children: [
                                                                                        if (childcontroller.isupdate != 0)
                                                                                          IconButton(
                                                                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                                                                            onPressed: () {
                                                                                              int? itemId = attribute['id']; // Extract the item ID
                                                                                              if (itemId != null) {
                                                                                                Get.to(Editchildform(title: childcontroller.Childtitle.value, editid: itemId, formusecaseid: currentId));
                                                                                              } else {}
                                                                                            },
                                                                                          ),
                                                                                        if (childcontroller.isdelete != 0)
                                                                                          IconButton(
                                                                                            icon: const Icon(Icons.delete, color: Colors.red),
                                                                                            onPressed: () {
                                                                                              int? itemId = attribute['id']; // Extract the item ID
                                                                                              if (itemId != null) {
                                                                                                showchileDeleteConfirmation(itemId, childcontroller.deleteListItem);
                                                                                              } else {}
                                                                                            },
                                                                                          ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                              ],
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : SizedBox()
                                                        ]),
                                              const SizedBox(height: 20),
                                              Obx(
                                                  () =>
                                                      controller.commentEnabled
                                                                  .value ==
                                                              1
                                                          ? Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          10),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                            .grey[
                                                                        200],
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(8),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      const Text(
                                                                        "Comments",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                18,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      GestureDetector(
                                                                        onTap:
                                                                            () {
                                                                          showAddCommentDialog();
                                                                        },
                                                                        child: Container(
                                                                            height: 40,
                                                                            width: 50,
                                                                            decoration: BoxDecoration(
                                                                                color: isDarkMode ? Color(0xFF4F76E2) : Appcolorblue,
                                                                                border: Border.all(
                                                                                  color: Appcolorblue,
                                                                                ),
                                                                                borderRadius: BorderRadius.circular(20)),
                                                                            child: const Icon(
                                                                              Icons.add,
                                                                              size: 40,
                                                                              color: Colors.white,
                                                                              // color: Color(0xFF2962FF),
                                                                            )),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 10),
                                                                controller
                                                                        .commentsList
                                                                        .isEmpty
                                                                    ? SizedBox()
                                                                    : SingleChildScrollView(
                                                                        scrollDirection:
                                                                            Axis.horizontal,
                                                                        physics:
                                                                            const BouncingScrollPhysics(),
                                                                        child:
                                                                            DataTable(
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color: isDarkMode
                                                                                ? Colors.black
                                                                                : Color(0xFFF5F5F5),
                                                                          ),
                                                                          border:
                                                                              TableBorder.all(color: isDarkMode ? Colors.white : const Color(0xFFE0E0E0)),
                                                                          columnSpacing:
                                                                              20,
                                                                          dividerThickness:
                                                                              0.2,
                                                                          headingRowHeight:
                                                                              0, // Removes header space

                                                                          columns: const [
                                                                            DataColumn(label: SizedBox.shrink()), // No header
                                                                            DataColumn(label: SizedBox.shrink()), // No header
                                                                            DataColumn(label: SizedBox.shrink()), // No header
                                                                            DataColumn(label: SizedBox.shrink()), // No header
                                                                          ],

                                                                          rows: controller
                                                                              .commentsList
                                                                              .asMap()
                                                                              .entries
                                                                              .map((entry) {
                                                                            int index =
                                                                                entry.key + 1;
                                                                            var commentData =
                                                                                entry.value; // Extracting data dynamically

                                                                            return DataRow(cells: [
                                                                              DataCell(Text(index.toString())),
                                                                              DataCell(Text(
                                                                                commentData['comment'] ?? '-',
                                                                                style: TextStyle(
                                                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                                                ),
                                                                              )),
                                                                              DataCell(
                                                                                Row(
                                                                                  children: [
                                                                                    Tooltip(
                                                                                      message: commentData['userFirstname'] ?? '',
                                                                                      child: CircleAvatar(
                                                                                        backgroundColor: Colors.blue.shade50,
                                                                                        child: Text(
                                                                                          (commentData['userFirstname'] != null && commentData['userFirstname'].isNotEmpty)
                                                                                              ? commentData['userFirstname']!
                                                                                                  .split(' ')
                                                                                                  .where((e) => (e as String).isNotEmpty) // Explicit cast to String
                                                                                                  .map((e) => e[0])
                                                                                                  .join()
                                                                                                  .padRight(2, '-')
                                                                                                  .substring(0, 2)
                                                                                                  .toUpperCase()
                                                                                              : '-',
                                                                                          style: TextStyle(
                                                                                            color: Colors.blue,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),

                                                                                    const SizedBox(width: 8),
                                                                                    Text(
                                                                                      formatDateview(commentData['modifiedDatetime'] ?? 0),
                                                                                      style: TextStyle(
                                                                                        color: isDarkMode ? Colors.white : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    // Display formatted date
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              DataCell(Row(
                                                                                children: [
                                                                                  IconButton(
                                                                                    icon: Icon(Icons.info, color: Colors.blue),
                                                                                    onPressed: () {
                                                                                      showCommentInfoPopup(commentData);
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.edit, color: Colors.green),
                                                                                    onPressed: () {
                                                                                      String commentId = commentData["id"].toString();
                                                                                      fetchCommentById(commentId); //
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                                                    onPressed: () {
                                                                                      String commentId = commentData["id"].toString();
                                                                                      showDeleteConfirmation(commentId);
                                                                                    },
                                                                                  ),
                                                                                ],
                                                                              )),
                                                                            ]);
                                                                          }).toList(),
                                                                        ),
                                                                      ),
                                                              ],
                                                            )
                                                          : const SizedBox
                                                              .shrink()),
                                              const SizedBox(height: 20),
                                              Obx(() =>
                                                  controller.attachmentEnabled
                                                              .value ==
                                                          1
                                                      ? Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            // Header
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey[200],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  const Text(
                                                                    "Attachments",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      showAddAttachmentDialog(
                                                                          context,
                                                                          isDarkMode);
                                                                    },
                                                                    child: Container(
                                                                        height: 40,
                                                                        width: 50,
                                                                        decoration: BoxDecoration(
                                                                            color: isDarkMode ? const Color(0xFF4F76E2) : Appcolorblue,
                                                                            border: Border.all(
                                                                              color: Appcolorblue,
                                                                            ),
                                                                            borderRadius: BorderRadius.circular(20)),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .add,
                                                                          size:
                                                                              40,
                                                                          color:
                                                                              Colors.white,
                                                                          // color: Color(0xFF2962FF),
                                                                        )),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                                height: 10),

                                                            controller
                                                                    .attachmentList
                                                                    .isEmpty
                                                                ? const SizedBox()
                                                                : SingleChildScrollView(
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    physics:
                                                                        const BouncingScrollPhysics(),
                                                                    child:
                                                                        DataTable(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: isDarkMode
                                                                            ? Colors.black
                                                                            : const Color(0xFFF5F5F5),
                                                                      ),
                                                                      border:
                                                                          TableBorder
                                                                              .all(
                                                                        color: isDarkMode
                                                                            ? Colors.white
                                                                            : const Color(0xFFE0E0E0),
                                                                      ),
                                                                      columnSpacing:
                                                                          20,
                                                                      dividerThickness:
                                                                          0.2,
                                                                      headingRowHeight:
                                                                          0, // Removes header space

                                                                      columns: const [
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                      ],

                                                                      rows: controller
                                                                          .attachmentList
                                                                          .asMap()
                                                                          .entries
                                                                          .map(
                                                                              (entry) {
                                                                        int index =
                                                                            entry.key +
                                                                                1;
                                                                        var attachmentData =
                                                                            entry.value; // Extracting data dynamically
                                                                        final imageUrl =
                                                                            attachmentData['attachmentUrl'];

                                                                        return DataRow(
                                                                            cells: [
                                                                              DataCell(Text(
                                                                                index.toString(),
                                                                                style: TextStyle(
                                                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                                                ),
                                                                              )),
                                                                              // Serial number
                                                                              DataCell(GestureDetector(
                                                                                onTap: () async {
                                                                                  final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/${attachmentData['attachment']}?t=${DateTime.now().millisecondsSinceEpoch}');
                                                                                  // final Uri testUrl = Uri.parse(imageUrl);

                                                                                  await launchUrl(testUrl);
                                                                                },
                                                                                child: Image.network(
                                                                                  imageUrl,
                                                                                  width: 50,
                                                                                  height: 50,
                                                                                  fit: BoxFit.cover,
                                                                                  errorBuilder: (context, error, stackTrace) {
                                                                                    return const Icon(Icons.broken_image, color: Colors.red); // Show error icon if image fails
                                                                                  },
                                                                                ),
                                                                              )),

                                                                              DataCell(Text(
                                                                                attachmentData['description'] ?? '-',
                                                                                style: TextStyle(
                                                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                                                ),
                                                                              )),
                                                                              // User
                                                                              DataCell(
                                                                                Row(
                                                                                  children: [
                                                                                    Tooltip(
                                                                                      message: attachmentData['userFirstname'] ?? '',
                                                                                      child: CircleAvatar(
                                                                                        backgroundColor: Colors.blue.shade50,
                                                                                        child: Text(
                                                                                          (attachmentData['userFirstname'] != null && attachmentData['userFirstname'].isNotEmpty)
                                                                                              ? attachmentData['userFirstname']!
                                                                                                  .split(' ')
                                                                                                  .where((e) => (e as String).isNotEmpty) // Explicit cast to String
                                                                                                  .map((e) => e[0])
                                                                                                  .join()
                                                                                                  .padRight(2, '-')
                                                                                                  .substring(0, 2)
                                                                                                  .toUpperCase()
                                                                                              : '-',
                                                                                          style: const TextStyle(
                                                                                            color: Colors.blue,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),

                                                                                    const SizedBox(width: 8),
                                                                                    Text(
                                                                                      formatDateview(attachmentData['modifiedDatetime'] ?? 0),
                                                                                      style: TextStyle(
                                                                                        color: isDarkMode ? Colors.white : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    // Display formatted date
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                              // DataCell(Text(
                                                                              //     attachmentData[
                                                                              //             'userFirstname'] ??
                                                                              //         '-')),

                                                                              // Action Buttons
                                                                              DataCell(Row(
                                                                                children: [
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.info, color: Colors.blue),
                                                                                    onPressed: () {
                                                                                      showCommentInfoPopup(attachmentData);
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.edit, color: Colors.green),
                                                                                    onPressed: () {
                                                                                      String attachmentId = attachmentData["id"].toString();
                                                                                      onEditPressed(attachmentId);
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                                                    onPressed: () {
                                                                                      String attachmentId = attachmentData["id"].toString();
                                                                                      showattachmentDeleteConfirmation(attachmentId);
                                                                                    },
                                                                                  ),
                                                                                ],
                                                                              )),
                                                                            ]);
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                          ],
                                                        )
                                                      : const SizedBox
                                                          .shrink()),
                                              const SizedBox(height: 20),
                                            ],
                                          );
                                        },
                                      ))
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (controller
                                              .grouplabellist.isNotEmpty)
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
                                                final endTime =
                                                    DateFormat('hh:mm a')
                                                        .parse(endTimeStr);

                                                return currentTime
                                                        .isAfter(startTime) &&
                                                    currentTime
                                                        .isBefore(endTime);
                                              } catch (e) {
                                                // If parsing fails, show the field by default
                                                return true;
                                              }
                                            }).map((field) {
                                              var filteredFields = controller
                                                  .getGroupsField(field.label);

                                              return filteredFields.isNotEmpty
                                                  ? Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10.0,
                                                          vertical: 8),
                                                      child: SizedBox(
                                                        child: InputDecorator(
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                field.label,
                                                            labelStyle:
                                                                TextStyle(
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                              fontSize: 19,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            fillColor:
                                                                isDarkMode
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              ...filteredFields
                                                                  .map((field) {
                                                                String label =
                                                                    field[
                                                                        'label'];
                                                                String code =
                                                                    field[
                                                                        'code'];
                                                                int defaultToCurrentDate =
                                                                    field['defaultToCurrentDate'] ??
                                                                        0;

                                                                int defaultToCurrentTime =
                                                                    field['defaultToCurrentTime'] ??
                                                                        0;

                                                                int readOnly =
                                                                    field['readOnly'] ??
                                                                        0;
                                                                String
                                                                    fieldType =
                                                                    field[
                                                                        'type'];
                                                                bool
                                                                    isRequired =
                                                                    field['required'] ==
                                                                        1;
                                                                bool isRefKey =
                                                                    field['refKey'] ==
                                                                        1;
                                                                bool
                                                                    primaryUsecase =
                                                                    field['primaryUsecase'] !=
                                                                        "";

                                                                bool
                                                                    showDropdown =
                                                                    primaryUsecase &&
                                                                        isRefKey;
                                                                String
                                                                    yUsecase =
                                                                    field['primaryUsecase'] ??
                                                                        "";
                                                                String
                                                                    showvalue =
                                                                    field['show'] ??
                                                                        "";
                                                                String
                                                                    minDateStr =
                                                                    field['minDate'] ??
                                                                        "";
                                                                String
                                                                    maxDateStr =
                                                                    field['maxDate'] ??
                                                                        "";
                                                                Map<String,
                                                                        String>
                                                                    reqBody =
                                                                    {};
                                                                for (var group
                                                                    in controller
                                                                        .grouplabellist) {
                                                                  var allFields =
                                                                      controller
                                                                          .getGroupsField(
                                                                              group.label);
                                                                  for (var field
                                                                      in allFields) {
                                                                    String
                                                                        fieldValue =
                                                                        controller.getInitialValue(field['code'])?.toString() ??
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
                                                                    field['event'] ??
                                                                        "";
                                                                String rule =
                                                                    field['rule'] ??
                                                                        "";

                                                                if (field[
                                                                        'system'] ==
                                                                    1) {
                                                                  return const SizedBox
                                                                      .shrink();
                                                                }

                                                                bool result = controller
                                                                    .evaluateCondition(
                                                                        reqBody,
                                                                        showvalue);
                                                                final initialValue =
                                                                    controller
                                                                        .getInitialValue(
                                                                            field['code']);

                                                                if (initialValue !=
                                                                        null &&
                                                                    initialValue
                                                                        .toString()
                                                                        .isNotEmpty) {
                                                                  result =
                                                                      true; // Ensure the field is visible if it has data
                                                                }

                                                                _controllers
                                                                    .putIfAbsent(
                                                                        label,
                                                                        () =>
                                                                            TextEditingController());
                                                                _controllers[
                                                                            label]!
                                                                        .text =
                                                                    (initialValue ??
                                                                            "")
                                                                        .toString();

                                                                _controllers
                                                                    .putIfAbsent(
                                                                        label,
                                                                        () =>
                                                                            TextEditingController());

                                                                _controllers[
                                                                        label]!
                                                                    .text = (controller
                                                                            .getInitialValue(code) ??
                                                                        "")
                                                                    .toString();

                                                                if (fieldType ==
                                                                        'text' &&
                                                                    result) {
                                                                  final initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial to int
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      enabled:
                                                                          isEditable,
                                                                      readOnly:
                                                                          !isEditable,
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      onChanged: isEditable
                                                                          ? (value) {
                                                                              controller.setInitialValue(code, value);
                                                                              controller.setFieldValue(label, value);
                                                                            }
                                                                          : null,
                                                                      validator:
                                                                          (value) {
                                                                        if (isRequired &&
                                                                            (value == null ||
                                                                                value.isEmpty)) {
                                                                          return 'Please enter $label';
                                                                        }
                                                                        final regexPattern =
                                                                            field['regex'];
                                                                        if (regexPattern != null &&
                                                                            value !=
                                                                                null &&
                                                                            value.isNotEmpty) {
                                                                          final regex =
                                                                              RegExp(regexPattern);
                                                                          if (!regex
                                                                              .hasMatch(value)) {
                                                                            return 'Invalid input for $label';
                                                                          }
                                                                        }
                                                                        return null;
                                                                      },
                                                                    ),
                                                                  );
                                                                }

                                                                if (fieldType ==
                                                                        'boolean' &&
                                                                    result) {
                                                                  // Initialize isSelected based on saved value
                                                                  String?
                                                                      savedValue =
                                                                      initialValue
                                                                          .toString();
                                                                  if (savedValue ==
                                                                      '1') {
                                                                    isSelected =
                                                                        [
                                                                      true,
                                                                      false
                                                                    ];
                                                                  } else if (savedValue ==
                                                                      '0') {
                                                                    isSelected =
                                                                        [
                                                                      false,
                                                                      true
                                                                    ];
                                                                  } else {
                                                                    isSelected =
                                                                        [
                                                                      false,
                                                                      false
                                                                    ];
                                                                  }

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0,
                                                                        horizontal:
                                                                            9),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Align(
                                                                            alignment:
                                                                                Alignment.topLeft,
                                                                            child: Text(label, style: labelStyle)),
                                                                        const SizedBox(
                                                                            height:
                                                                                10),
                                                                        Align(
                                                                          alignment:
                                                                              Alignment.topLeft,
                                                                          child:
                                                                              ToggleButtons(
                                                                            borderRadius:
                                                                                BorderRadius.circular(5),
                                                                            selectedColor:
                                                                                Colors.white,
                                                                            borderColor: isDarkMode
                                                                                ? const Color(0xFF4F76E2)
                                                                                : const Color(0xFF1A237E),
                                                                            fillColor: isDarkMode
                                                                                ? const Color(0xFF4F76E2)
                                                                                : const Color(0xFF1A237E),
                                                                            color: isDarkMode
                                                                                ? Colors.white
                                                                                : Colors.black,
                                                                            isSelected:
                                                                                isSelected,
                                                                            onPressed:
                                                                                (index) {
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
                                                                            children: const [
                                                                              Padding(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                                                child: Text(
                                                                                  "Yes",
                                                                                  style: TextStyle(
                                                                                    fontSize: 15,
                                                                                    fontWeight: FontWeight.w400,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Padding(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                                                child: Text(
                                                                                  "No",
                                                                                  style: TextStyle(
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
                                                                if (fieldType ==
                                                                        'url' &&
                                                                    result) {
                                                                  final initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure controller exists with initial value
                                                                  _controllers[
                                                                          label] ??=
                                                                      TextEditingController(
                                                                    text: initialValue
                                                                            ?.toString() ??
                                                                        "",
                                                                  );

                                                                  return TextFormField(
                                                                    controller:
                                                                        _controllers[
                                                                            label],
                                                                    enabled:
                                                                        isEditable,
                                                                    readOnly:
                                                                        !isEditable,
                                                                    style:
                                                                        labelStyle,
                                                                    decoration:
                                                                        InputDecoration(
                                                                      errorText:
                                                                          resulterror[
                                                                              code],
                                                                      labelStyle:
                                                                          labelStyle,
                                                                      labelText:
                                                                          label,
                                                                      fillColor: isEditable
                                                                          ? (isDarkMode
                                                                              ? Colors.black
                                                                              : Colors.white)
                                                                          : Colors.grey[200],
                                                                      filled:
                                                                          true,
                                                                      border:
                                                                          OutlineInputBorder(
                                                                        borderSide:
                                                                            BorderSide(color: Appcolorblue),
                                                                      ),
                                                                    ),
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .url,
                                                                    onChanged:
                                                                        isEditable
                                                                            ? (value) {
                                                                                controller.setInitialValue(code, value);
                                                                                controller.setFieldValue(label, value);
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
                                                                  );
                                                                }

                                                                if (fieldType ==
                                                                        'password' &&
                                                                    result) {
                                                                  final String
                                                                      initialValue =
                                                                      controller
                                                                              .getInitialValue(code) ??
                                                                          "";

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  // Apply edit rules
                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure controller is initialized with initial value
                                                                  _controllers[
                                                                          label] ??=
                                                                      TextEditingController(
                                                                          text:
                                                                              initialValue);

                                                                  return Padding(
                                                                    padding: const EdgeInsets
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
                                                                          isEditable,
                                                                      readOnly:
                                                                          !isEditable,
                                                                      obscureText:
                                                                          _obscureText,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        errorText:
                                                                            resulterror[code],
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        labelText:
                                                                            label,
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                        suffixIcon: isEditable
                                                                            ? IconButton(
                                                                                icon: Icon(
                                                                                  _obscureText ? Icons.visibility_off : Icons.visibility,
                                                                                ),
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    _obscureText = !_obscureText;
                                                                                  });
                                                                                },
                                                                              )
                                                                            : null,
                                                                      ),
                                                                      onChanged: isEditable
                                                                          ? (value) {
                                                                              controller.setInitialValue(code, value);
                                                                              controller.setFieldValue(label, value);
                                                                            }
                                                                          : null,
                                                                      validator:
                                                                          (value) {
                                                                        if (isRequired &&
                                                                            (value == null ||
                                                                                value.isEmpty)) {
                                                                          return 'Please enter $label';
                                                                        }

                                                                        final regexPattern =
                                                                            field['regex']; // e.g., "^(?=.*[0-9])(?=.*[A-Z]).{8,}$"
                                                                        if (regexPattern != null &&
                                                                            value !=
                                                                                null &&
                                                                            value.isNotEmpty) {
                                                                          final regex =
                                                                              RegExp(regexPattern);
                                                                          if (!regex
                                                                              .hasMatch(value)) {
                                                                            return 'Invalid input for $label';
                                                                          }
                                                                        }

                                                                        return null;
                                                                      },
                                                                    ),
                                                                  );
                                                                }

                                                                if (fieldType ==
                                                                        'email' &&
                                                                    result) {
                                                                  final String
                                                                      initialValue =
                                                                      controller
                                                                              .getInitialValue(code) ??
                                                                          "";

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  // Apply edit rules
                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure controller is initialized with initial value
                                                                  _controllers[
                                                                          label] ??=
                                                                      TextEditingController(
                                                                          text:
                                                                              initialValue);

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      style:
                                                                          labelStyle,
                                                                      enabled:
                                                                          isEditable,
                                                                      readOnly:
                                                                          !isEditable,
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .emailAddress,
                                                                      onChanged: isEditable
                                                                          ? (value) {
                                                                              setState(() {
                                                                                controller.dataMap[code] = value;
                                                                                controller.setInitialValue(code, value);
                                                                                controller.setFieldValue(label, value);
                                                                              });
                                                                            }
                                                                          : null,
                                                                      validator:
                                                                          (value) {
                                                                        if (isRequired &&
                                                                            (value == null ||
                                                                                value.isEmpty)) {
                                                                          return 'Please enter $label';
                                                                        }
                                                                        // Basic email validation
                                                                        if (value !=
                                                                                null &&
                                                                            value.isNotEmpty) {
                                                                          final emailRegex =
                                                                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                                                          if (!emailRegex
                                                                              .hasMatch(value)) {
                                                                            return 'Please enter a valid email address';
                                                                          }
                                                                        }
                                                                        return null;
                                                                      },
                                                                    ),
                                                                  );
                                                                }
                                                                if (fieldType ==
                                                                        'textarea' &&
                                                                    result) {
                                                                  return Padding(
                                                                    padding: const EdgeInsets
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
                                                                        fillColor: isDarkMode
                                                                            ? Colors.black
                                                                            : Colors.white,
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .multiline,
                                                                      maxLines:
                                                                          3,
                                                                      // You can set this to null for unlimited lines
                                                                      onChanged:
                                                                          (value) {
                                                                        controller.dataMap[code] =
                                                                            value; // Directly updating dataMap
                                                                        controller.setInitialValue(
                                                                            code,
                                                                            value);
                                                                        controller.setFieldValue(
                                                                            label,
                                                                            value);
                                                                      },
                                                                      validator: isRequired
                                                                          ? (value) {
                                                                              if (value == null || value.isEmpty) {
                                                                                return 'Please enter $label';
                                                                              }
                                                                              return null;
                                                                            }
                                                                          : null,
                                                                    ),
                                                                  );
                                                                }
                                                                if (showDropdown &&
                                                                    result) {
                                                                  final dropdownItems =
                                                                      controller
                                                                              .prelaodlist[yUsecase] ??
                                                                          [];

                                                                  // Ensure unique dropdown items based on 'id'
                                                                  final uniqueItems = dropdownItems
                                                                      .map((e) =>
                                                                          e['id']
                                                                              .toString())
                                                                      .toSet()
                                                                      .map((id) =>
                                                                          dropdownItems.firstWhere((item) =>
                                                                              item['id'].toString() ==
                                                                              id))
                                                                      .toList();

                                                                  final currentValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);
                                                                  final validValue = uniqueItems.any((item) =>
                                                                          item['id']
                                                                              .toString() ==
                                                                          currentValue)
                                                                      ? currentValue
                                                                      : null;

                                                                  // normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(field['allowChangeAfterInitial']?.toString() ??
                                                                              "0") ??
                                                                          0;

                                                                  // determine editability
                                                                  final bool isEditable = readOnly !=
                                                                          1 &&
                                                                      (allowChange ==
                                                                              2 || // always editable
                                                                          (allowChange == 1 &&
                                                                              (validValue == null || validValue.isEmpty)) || // editable until first set
                                                                          (allowChange == 0 && validValue == null) // only editable if nothing chosen yet
                                                                      );

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child: DropdownButtonFormField<
                                                                        String>(
                                                                      isExpanded:
                                                                          true,
                                                                      dropdownColor: isDarkMode
                                                                          ? Colors.grey[
                                                                              850]
                                                                          : Colors
                                                                              .white,
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      value: (validValue?.isEmpty ??
                                                                              true)
                                                                          ? null
                                                                          : validValue,
                                                                      items: [
                                                                        DropdownMenuItem<
                                                                            String>(
                                                                          value:
                                                                              null,
                                                                          child:
                                                                              Text(
                                                                            "Select $label",
                                                                            style:
                                                                                labelStyle,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                        ...uniqueItems
                                                                            .map<DropdownMenuItem<String>>((item) {
                                                                          return DropdownMenuItem<
                                                                              String>(
                                                                            value:
                                                                                item['id'].toString(),
                                                                            child:
                                                                                Text(
                                                                              item['_val'],
                                                                              style: labelStyle,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ],
                                                                      onChanged: isEditable
                                                                          ? (value) async {
                                                                              controller.onChange(field, value);
                                                                              if (event != "") {
                                                                                await controller.GetUserData(code, rule, value!);
                                                                                controller.admissionId = value;
                                                                              }
                                                                              controller.setFieldValue(label, value ?? "");
                                                                              controller.setInitialValue(code, value ?? "");
                                                                            }
                                                                          : null,
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

                                                                if (fieldType ==
                                                                        'object' &&
                                                                    result) {
                                                                  final initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure controller exists with initial value
                                                                  _controllers[
                                                                          label] ??=
                                                                      TextEditingController(
                                                                    text: initialValue
                                                                            ?.toString() ??
                                                                        "",
                                                                  );

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      enabled:
                                                                          isEditable,
                                                                      readOnly:
                                                                          !isEditable,
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .text,
                                                                      onChanged: isEditable
                                                                          ? (value) {
                                                                              controller.setInitialValue(code, value);
                                                                              controller.setFieldValue(label, value);
                                                                            }
                                                                          : null,
                                                                      validator: isRequired
                                                                          ? (value) {
                                                                              if (value == null || value.isEmpty) {
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
                                                                      initialValue;

                                                                  if (locationMap !=
                                                                          null &&
                                                                      locationMap
                                                                          is Map) {
                                                                    if (locationMap
                                                                        .isNotEmpty) {
                                                                      controller
                                                                          .showTextField
                                                                          .value = true;
                                                                    }

                                                                    controller
                                                                        .latController
                                                                        .text = locationMap['lat']
                                                                            .toString() ??
                                                                        '';
                                                                    controller
                                                                        .longController
                                                                        .text = locationMap['lng']
                                                                            .toString() ??
                                                                        '';
                                                                  }

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        Column(
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
                                                                              Alignment.topLeft,
                                                                          child:
                                                                              Container(
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              border: Border.all(color: Colors.grey, width: 1),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                IconButton(
                                                                                  icon: Icon(Icons.location_on, color: Appcolorblue),
                                                                                  onPressed: () {
                                                                                    setCurrentLocation(label, code);
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
                                                                        const SizedBox(
                                                                            height:
                                                                                8),
                                                                        if (controller
                                                                            .showTextField
                                                                            .value) ...[
                                                                          TextField(
                                                                            controller:
                                                                                controller.latController,
                                                                            readOnly:
                                                                                true,
                                                                            style:
                                                                                labelStyle,
                                                                            decoration:
                                                                                InputDecoration(
                                                                              labelText: 'Latitude',
                                                                              fillColor: isDarkMode ? Colors.black : Colors.white,
                                                                              labelStyle: labelStyle,
                                                                              border: const OutlineInputBorder(),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 10),
                                                                          TextField(
                                                                            controller:
                                                                                controller.longController,
                                                                            readOnly:
                                                                                true,
                                                                            style:
                                                                                labelStyle,
                                                                            decoration:
                                                                                InputDecoration(
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
                                                                if ((fieldType == 'number' ||
                                                                        fieldType ==
                                                                            'phone' ||
                                                                        fieldType ==
                                                                            'long' ||
                                                                        fieldType ==
                                                                            'decimal') &&
                                                                    result) {
                                                                  final initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure controller exists with initial value
                                                                  _controllers[
                                                                          label] ??=
                                                                      TextEditingController(
                                                                    text: initialValue
                                                                            ?.toString() ??
                                                                        "",
                                                                  );

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      enabled:
                                                                          isEditable,
                                                                      readOnly:
                                                                          !isEditable,
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .number,
                                                                      onChanged: isEditable
                                                                          ? (value) {
                                                                              controller.updateAllExpressionFields();
                                                                              controller.dataMap[code] = value; // update data map
                                                                              controller.setInitialValue(code, value);
                                                                            }
                                                                          : null,
                                                                      validator:
                                                                          (value) {
                                                                        if (isRequired &&
                                                                            (value == null ||
                                                                                value.isEmpty)) {
                                                                          return 'Please enter $label';
                                                                        }

                                                                        final regexPattern =
                                                                            field['regex']; // optional regex check
                                                                        if (regexPattern != null &&
                                                                            value !=
                                                                                null &&
                                                                            value.isNotEmpty) {
                                                                          final regex =
                                                                              RegExp(regexPattern);
                                                                          if (!regex
                                                                              .hasMatch(value)) {
                                                                            return 'Invalid input for $label';
                                                                          }
                                                                        }

                                                                        return null;
                                                                      },
                                                                    ),
                                                                  );
                                                                }
                                                        if (fieldType ==
                                                                        'number' &&
                                                                    result) {
                                                                  final dynamic
                                                                      initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(field['allowChangeAfterInitial']?.toString() ??
                                                                              "0") ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Format number for display
                                                                  String formatNumber(
                                                                      String
                                                                          value) {
                                                                    if (value
                                                                        .isEmpty)
                                                                      return '';
                                                                    final double?
                                                                        number =
                                                                        double.tryParse(
                                                                            value);
                                                                    if (number ==
                                                                        null)
                                                                      return value;

                                                                    if (number %
                                                                            1 ==
                                                                        0) {
                                                                      return number
                                                                          .toInt()
                                                                          .toString(); // 10.0 -> 10
                                                                    } else {
                                                                      return number
                                                                          .toString(); // 10.5 -> 10.5
                                                                    }
                                                                  }

                                                                  final String
                                                                      currentStr =
                                                                      formatNumber(
                                                                          initialValue?.toString() ??
                                                                              "");

                                                                  // Update controller if needed
                                                                  if (_controllers[
                                                                              label]
                                                                          ?.text !=
                                                                      currentStr) {
                                                                    _controllers[label]
                                                                            ?.text =
                                                                        currentStr;
                                                                  }

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      enabled:
                                                                          isEditable,
                                                                      readOnly:
                                                                          !isEditable,
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .number,
                                                                      onChanged: isEditable
                                                                          ? (value) {
                                                                              // Debug print
                                                                              print('📝 Number field changed: $label = $value');

                                                                              // ✅ STEP 1: Parse and store the number value
                                                                              if (value.isNotEmpty) {
                                                                                double? numericValue = double.tryParse(value);
                                                                                if (numericValue != null) {
                                                                                  // Store integer without decimals, float with decimals
                                                                                  if (numericValue == numericValue.toInt()) {
                                                                                    controller.dataMap[field['code']] = numericValue.toInt().toString();
                                                                                  } else {
                                                                                    controller.dataMap[field['code']] = numericValue.toString();
                                                                                  }
                                                                                } else {
                                                                                  controller.dataMap[field['code']] = value;
                                                                                }
                                                                              } else {
                                                                                controller.dataMap[field['code']] = "";
                                                                              }

                                                                              // ✅ STEP 2: Save to controllers
                                                                              controller.setInitialValue(code, value);
                                                                              controller.setFieldValue(label, value);

                                                                              // Debug print before update
                                                                              print('🔄 Calling updateAllExpressionFields()...');

                                                                              // ✅ STEP 3: UPDATE ALL EXPRESSION FIELDS - YEH LINE SABSE IMPORTANT HAI
                                                                              controller.updateAllExpressionFields();

                                                                              // ✅ STEP 4: Refresh UI
                                                                              setState(() {});

                                                                              // Debug print after update
                                                                              print('✅ Expression fields updated');
                                                                            }
                                                                          : null,
                                                                      validator:
                                                                          (value) {
                                                                        if (isRequired &&
                                                                            (value == null ||
                                                                                value.isEmpty)) {
                                                                          return 'Please enter $label';
                                                                        }

                                                                        final regexPattern =
                                                                            field['regex'];
                                                                        if (regexPattern != null &&
                                                                            value !=
                                                                                null &&
                                                                            value.isNotEmpty) {
                                                                          final regex =
                                                                              RegExp(regexPattern);
                                                                          if (!regex
                                                                              .hasMatch(value)) {
                                                                            return 'Invalid input for $label';
                                                                          }
                                                                        }

                                                                        // Optional: validate that it's a valid number
                                                                        if (value !=
                                                                                null &&
                                                                            value.isNotEmpty) {
                                                                          if (double.tryParse(value) ==
                                                                              null) {
                                                                            return 'Please enter a valid number';
                                                                          }
                                                                        }

                                                                        return null;
                                                                      },
                                                                    ),
                                                                  );
                                                                }

                                                if (fieldType ==
                                                                        'expression' &&
                                                                    result) {
                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            5.0,
                                                                        vertical:
                                                                            5.0),
                                                                    child:
                                                                        Obx(() {
                                                                      // ← Wrap with Obx
                                                                      String
                                                                          currentValue =
                                                                          controller.getFieldValue(label) ??
                                                                              '';

                                                                      if (currentValue
                                                                          .isEmpty) {
                                                                        currentValue =
                                                                            controller.dataMap[field['code']]?.toString() ??
                                                                                '';
                                                                      }

                                                                      if (currentValue
                                                                          .contains(
                                                                              '.')) {
                                                                        currentValue = currentValue.replaceAll(
                                                                            RegExp(r'0+$'),
                                                                            '');
                                                                        currentValue = currentValue.replaceAll(
                                                                            RegExp(r'\.$'),
                                                                            '');
                                                                      }

                                                                      return TextFormField(
                                                                        controller:
                                                                            TextEditingController(text: currentValue),
                                                                        readOnly:
                                                                            true,
                                                                        enabled:
                                                                            false,
                                                                        style: labelStyle.copyWith(
                                                                            color:
                                                                                Colors.grey[700]),
                                                                        decoration:
                                                                            InputDecoration(
                                                                          labelText:
                                                                              label,
                                                                          labelStyle:
                                                                              labelStyle,
                                                                          filled:
                                                                              true,
                                                                          fillColor:
                                                                              Colors.grey[200],
                                                                          border:
                                                                              OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(5),
                                                                            borderSide:
                                                                                BorderSide(color: Colors.grey),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }),
                                                                  );
                                                                }
                                                                if (fieldType ==
                                                                        'time' &&
                                                                    result) {
                                                                  final initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(field['allowChangeAfterInitial']?.toString() ??
                                                                              '0') ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure controller exists
                                                                  _controllers[
                                                                          label] ??=
                                                                      TextEditingController(
                                                                    text: initialValue
                                                                            ?.toString() ??
                                                                        "",
                                                                  );

                                                                  // Prefill with current time if empty and defaultToCurrentTime == 1
                                                                  final int
                                                                      defaultToCurrentTime =
                                                                      field['defaultToCurrentTime'] ??
                                                                          0;
                                                                  if (_controllers[
                                                                              label]!
                                                                          .text
                                                                          .isEmpty &&
                                                                      defaultToCurrentTime ==
                                                                          1) {
                                                                    String
                                                                        currentTime =
                                                                        DateFormat('HH:mm')
                                                                            .format(DateTime.now());
                                                                    _controllers[label]!
                                                                            .text =
                                                                        currentTime;
                                                                    controller
                                                                        .setInitialValue(
                                                                            code,
                                                                            currentTime);
                                                                    controller.setFieldValue(
                                                                        label,
                                                                        currentTime);
                                                                  }

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      readOnly:
                                                                          true, // always readonly, we pick time via picker
                                                                      enabled:
                                                                          isEditable,
                                                                      style:
                                                                          labelStyle,
                                                                      controller:
                                                                          _controllers[
                                                                              label],
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        labelText:
                                                                            label,
                                                                        suffixIcon: isEditable
                                                                            ? Icon(
                                                                                Icons.access_time,
                                                                                color: isDarkMode ? Colors.white : Colors.black,
                                                                              )
                                                                            : null,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      onTap: isEditable
                                                                          ? () async {
                                                                              TimeOfDay? selectedTime = await showTimePicker(
                                                                                context: context,
                                                                                initialTime: TimeOfDay.now(),
                                                                              );
                                                                              if (selectedTime != null) {
                                                                                final now = DateTime.now();
                                                                                final dateTime = DateTime(
                                                                                  now.year,
                                                                                  now.month,
                                                                                  now.day,
                                                                                  selectedTime.hour,
                                                                                  selectedTime.minute,
                                                                                );

                                                                                String formattedTime = DateFormat('HH:mm').format(dateTime);

                                                                                setState(() {
                                                                                  _controllers[label]?.text = formattedTime;
                                                                                  controller.setInitialValue(code, formattedTime);
                                                                                  controller.setFieldValue(label, formattedTime);
                                                                                });
                                                                              }
                                                                            }
                                                                          : null,
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

                                                                if (fieldType ==
                                                                        'date' &&
                                                                    result) {
                                                                  final String
                                                                      initialValue =
                                                                      controller
                                                                              .getInitialValue(code) ??
                                                                          "";

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  // Apply edit logic
                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child:
                                                                        TextFormField(
                                                                      readOnly:
                                                                          true, // User should always pick from date picker
                                                                      controller:
                                                                          TextEditingController(
                                                                              text: initialValue),
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        errorText:
                                                                            resulterror[code],
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        suffixIcon: isEditable
                                                                            ? Icon(
                                                                                Icons.calendar_today,
                                                                                color: isDarkMode ? Colors.white : Colors.black,
                                                                              )
                                                                            : null,
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      onTap: isEditable
                                                                          ? () async {
                                                                              DateTime? selectedDate;

                                                                              if (minDateStr.isEmpty && maxDateStr.isEmpty) {
                                                                                selectedDate = await showDatePicker(
                                                                                  context: context,
                                                                                  initialDate: DateTime.now(),
                                                                                  firstDate: DateTime(1900),
                                                                                  lastDate: DateTime(2100),
                                                                                );
                                                                              } else {
                                                                                DateTime minDate = DateTime.parse(minDateStr);
                                                                                DateTime maxDate = DateTime.parse(maxDateStr);
                                                                                DateTime initial = DateTime.now();

                                                                                if (initial.isBefore(minDate)) {
                                                                                  initial = minDate;
                                                                                } else if (initial.isAfter(maxDate)) {
                                                                                  initial = maxDate;
                                                                                }

                                                                                selectedDate = await showDatePicker(
                                                                                  context: context,
                                                                                  initialDate: initial,
                                                                                  firstDate: minDate,
                                                                                  lastDate: maxDate,
                                                                                );
                                                                              }

                                                                              if (selectedDate != null) {
                                                                                String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

                                                                                if (event != "") {
                                                                                  var response = await controller.validateAndSubmitDate(rule, formattedDate);

                                                                                  if (response != null && response['success'] == false) {
                                                                                    String errorMessage = response['result']?['message'] ?? 'An error occurred while validating the date.';
                                                                                    showPopup(context, 'Error', errorMessage);
                                                                                  } else if (response != null && response['success'] == true) {
                                                                                    controller.setFieldValue(label, formattedDate);
                                                                                    controller.setInitialValue(code, formattedDate);
                                                                                  }
                                                                                } else {
                                                                                  setState(() {
                                                                                    controller.setInitialValue(code, formattedDate);
                                                                                    controller.setFieldValue(label, formattedDate);
                                                                                  });
                                                                                }
                                                                              }
                                                                            }
                                                                          : null,
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

                                                                // EditFormScreen के build method में, अन्य field types के साथ ये cases जोड़ें:

                                                                if (fieldType ==
                                                                        'list' &&
                                                                    result) {
                                                                  final values =
                                                                      field['values'] ??
                                                                          [];
                                                                  final initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);

                                                                  // Normalize allowChangeAfterInitial
                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(
                                                                              field['allowChangeAfterInitial'].toString()) ??
                                                                          0;

                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Ensure valid initial value
                                                                  final validInitialValue =
                                                                      values.contains(
                                                                              initialValue)
                                                                          ? initialValue
                                                                          : null;

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child: DropdownButtonFormField<
                                                                        String>(
                                                                      isExpanded:
                                                                          true,
                                                                      dropdownColor: isDarkMode
                                                                          ? Colors.grey[
                                                                              850]
                                                                          : Colors
                                                                              .white,
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : Colors.grey[200],
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      value: (validInitialValue == null ||
                                                                              validInitialValue.toString().isEmpty)
                                                                          ? null
                                                                          : validInitialValue.toString(),
                                                                      items: [
                                                                        if (!isRequired)
                                                                          DropdownMenuItem<
                                                                              String>(
                                                                            value:
                                                                                null,
                                                                            child:
                                                                                Text(
                                                                              'Select $label',
                                                                              style: labelStyle,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                            ),
                                                                          ),
                                                                        ...values
                                                                            .map<DropdownMenuItem<String>>((value) {
                                                                          return DropdownMenuItem<
                                                                              String>(
                                                                            value:
                                                                                value,
                                                                            child:
                                                                                Text(
                                                                              value,
                                                                              style: labelStyle,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ],
                                                                      onChanged: isEditable
                                                                          ? (value) async {
                                                                              if (event != "") {
                                                                                await controller.GetUserData(code, rule, value!);
                                                                                controller.admissionId = value;

                                                                                controller.dataMap[code] = value;
                                                                                controller.setInitialValue(code, value ?? "");
                                                                                controller.setFieldValue(label, value ?? "");
                                                                              } else {
                                                                                controller.dataMap[code] = value;
                                                                                controller.setInitialValue(code, value ?? "");
                                                                                controller.setFieldValue(label, value ?? "");
                                                                              }
                                                                            }
                                                                          : null,
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

                                                                if (fieldType ==
                                                                        'map' &&
                                                                    result) {
                                                                  List<dynamic>
                                                                      mapValues =
                                                                      field['values'] ??
                                                                          [];

                                                                  final dynamic
                                                                      initialValue =
                                                                      controller
                                                                          .getInitialValue(
                                                                              code);
                                                                  String? currentValue = (initialValue ==
                                                                              null ||
                                                                          initialValue
                                                                              .toString()
                                                                              .trim()
                                                                              .isEmpty)
                                                                      ? null
                                                                      : initialValue
                                                                          .toString()
                                                                          .trim();

                                                                  final int
                                                                      allowChange =
                                                                      int.tryParse(field['allowChangeAfterInitial']?.toString() ??
                                                                              "0") ??
                                                                          0;
                                                                  final bool
                                                                      isEditable =
                                                                      readOnly !=
                                                                              1 &&
                                                                          allowChange ==
                                                                              0;

                                                                  // Build full "key - value" list
                                                                  List<String>
                                                                      combinedValues =
                                                                      mapValues
                                                                          .map((v) =>
                                                                              "${(v['key'] ?? '').toString().trim()} - ${(v['value'] ?? '').toString()}")
                                                                          .toList();

                                                                  // Reset if currentValue is not a valid "key - value"
                                                                  if (currentValue !=
                                                                          null &&
                                                                      !combinedValues
                                                                          .contains(
                                                                              currentValue)) {
                                                                    currentValue =
                                                                        null;
                                                                  }

                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                    child: DropdownButtonFormField<
                                                                        String?>(
                                                                      isExpanded:
                                                                          true,
                                                                      dropdownColor: isDarkMode
                                                                          ? Colors.grey[
                                                                              850]
                                                                          : Colors
                                                                              .white,
                                                                      style:
                                                                          labelStyle,
                                                                      decoration:
                                                                          InputDecoration(
                                                                        fillColor: isEditable
                                                                            ? (isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white)
                                                                            : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                                                                        filled:
                                                                            true,
                                                                        labelText:
                                                                            label,
                                                                        labelStyle:
                                                                            labelStyle,
                                                                        errorText:
                                                                            resulterror[code],
                                                                        border:
                                                                            OutlineInputBorder(
                                                                          borderSide:
                                                                              BorderSide(color: Appcolorblue),
                                                                        ),
                                                                      ),
                                                                      value:
                                                                          currentValue,
                                                                      items: [
                                                                        if (!isRequired)
                                                                          DropdownMenuItem<
                                                                              String?>(
                                                                            value:
                                                                                null,
                                                                            child:
                                                                                Text(
                                                                              'Select $label',
                                                                              style: labelStyle.copyWith(color: Colors.grey),
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                            ),
                                                                          ),
                                                                        ...mapValues
                                                                            .map<DropdownMenuItem<String?>>((item) {
                                                                          final String
                                                                              key =
                                                                              (item['key'] ?? '').toString().trim();
                                                                          final String
                                                                              valueText =
                                                                              (item['value'] ?? '').toString();
                                                                          final String
                                                                              keyValue =
                                                                              "$key - $valueText"; // ✅ combined
                                                                          return DropdownMenuItem<
                                                                              String?>(
                                                                            value:
                                                                                keyValue,
                                                                            child:
                                                                                Text(
                                                                              keyValue,
                                                                              style: labelStyle,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                      ],
                                                                      onChanged: isEditable
                                                                          ? (value) async {
                                                                              if (event != "") {
                                                                                await controller.GetUserData(code, rule, value ?? "");
                                                                                controller.admissionId = value;
                                                                              }
                                                                              controller.dataMap[code] = value ?? ""; // ✅ stores "1 - a"
                                                                              controller.setFieldValue(label, value ?? ""); // ✅ stores "1 - a"
                                                                              controller.setInitialValue(code, value ?? ""); // ✅ stores "1 - a"
                                                                            }
                                                                          : null,
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

                                                                if (fieldType ==
                                                                        'doc' &&
                                                                    result) {
                                                                  return Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      // Custom file input field that looks like a TextField
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
                                                                              int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                                              code.toString(),
                                                                            );
                                                                          },
                                                                          readOnly:
                                                                              true,
                                                                          controller:
                                                                              TextEditingController(text: controller.imagePaths[code] != null ? controller.imagePaths[code]!.split('/').last : ''),
                                                                          // Display the file name or path
                                                                          decoration:
                                                                              InputDecoration(
                                                                            errorText:
                                                                                resulterror[code],
                                                                            fillColor: isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white,
                                                                            labelText:
                                                                                label,
                                                                            hintText:
                                                                                label,
                                                                            labelStyle:
                                                                                labelStyle,
                                                                            border:
                                                                                OutlineInputBorder(
                                                                              borderRadius: BorderRadius.circular(5),
                                                                              borderSide: const BorderSide(color: Colors.green),
                                                                            ),
                                                                            suffixIcon: IconButton(
                                                                                icon: Icon(Icons.attachment, color: isDarkMode ? Colors.white : Colors.black),
                                                                                onPressed: () {
                                                                                  _pickAndUploadFile(
                                                                                    int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                                                    code.toString(),
                                                                                  );
                                                                                } // Trigger the file picker on tap

                                                                                ),
                                                                          ),
                                                                          onChanged:
                                                                              (value) {
                                                                            // Save the file path (or name) to the controller
                                                                            setState(() {
                                                                              controller.imagePaths[code] = value; // Optionally save the file path here
                                                                            });
                                                                            controller.dataMap[code] =
                                                                                value; // Directly updating dataMap
                                                                            controller.setInitialValue(code,
                                                                                value);
                                                                            controller.setFieldValue(label,
                                                                                value);
                                                                          },
                                                                        ),
                                                                      ),

                                                                      controller.imagePaths[code] !=
                                                                              null
                                                                          ? CachedNetworkImage(
                                                                              width: 100,
                                                                              height: 100,
                                                                              imageUrl: "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadimage[code]}?t=${DateTime.now().millisecondsSinceEpoch}",
                                                                              placeholder: (context, url) => const CircularProgressIndicator(),
                                                                              errorWidget: (context, url, error) => Icon(Icons.error),
                                                                            )
                                                                          : Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                                              child: Image.network(width: 100, height: 100, controller.getInitialValue(code) == null ? imageUrlHelper.applogourl : "https://cuickdev.com/API/DOCS/api/doc/th/${controller.getInitialValue(code).toString()}?t=0"), // Display the selected image (optional)
                                                                            )
                                                                    ],
                                                                  );
                                                                }
                                                                if (fieldType ==
                                                                        'file' &&
                                                                    result) {
                                                                  return Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      // Custom file input field that looks like a TextField
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
                                                                              getImage1(int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0, code.toString(), ImageSource.camera);
                                                                            } else {
                                                                              _pickAndUploadImage(
                                                                                int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                                                code.toString(),
                                                                              );
                                                                              _pickAndUploadImage(
                                                                                int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                                                code.toString(),
                                                                              );
                                                                            }
                                                                          },
                                                                          readOnly:
                                                                              true,
                                                                          style:
                                                                              labelStyle,
                                                                          controller:
                                                                              TextEditingController(text: controller.imagePaths[code] != null ? controller.imagePaths[code]!.split('/').last : ''),
                                                                          // Display the file name or path
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
                                                                                OutlineInputBorder(
                                                                              borderRadius: BorderRadius.circular(5),
                                                                              borderSide: const BorderSide(color: Colors.green),
                                                                            ),
                                                                            suffixIcon: IconButton(
                                                                                icon: Icon(
                                                                                  Icons.attachment,
                                                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                                                ),
                                                                                onPressed: () {
                                                                                  if (captureImage == 1) {
                                                                                    getImage1(int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0, code.toString(), ImageSource.camera);
                                                                                  } else {
                                                                                    _pickAndUploadImage(
                                                                                      int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                                                      code.toString(),
                                                                                    );
                                                                                    _pickAndUploadImage(
                                                                                      int.tryParse(controller.getInitialValue(code)?.toString() ?? '0') ?? 0,
                                                                                      code.toString(),
                                                                                    );
                                                                                  }
                                                                                } // Trigger the file picker on tap

                                                                                ),
                                                                          ),
                                                                          onChanged:
                                                                              (value) {
                                                                            setState(() {
                                                                              controller.imagePaths[code] = value; // Optionally save the file path here
                                                                            });
                                                                            controller.dataMap[code] =
                                                                                value; // Directly updating dataMap
                                                                            controller.setInitialValue(code,
                                                                                '0');
                                                                          },
                                                                        ),
                                                                      ),
                                                                      controller.imagePaths[code] !=
                                                                              null
                                                                          ? Padding(
                                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16.0),
                                                                              child: Image.file(
                                                                                File(controller.imagePaths[code]!),
                                                                                width: 100,
                                                                                height: 100,
                                                                              ), // Display the selected image (optional)
                                                                            )
                                                                          : Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                                                                              child: Image.network(width: 100, height: 100, controller.getInitialValue(code) == null ? imageUrlHelper.applogourl : "https://cuickdev.com/API/DOCS/api/doc/th/${controller.getInitialValue(code).toString()}?t=0"), // Display the selected image (optional)
                                                                            )
                                                                    ],
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
                                            int readOnly =
                                                field['readOnly'] ?? 0;
                                            String fieldType = field['type'];
                                            bool isRequired =
                                                field['required'] == 1;
                                            bool isRefKey =
                                                field['refKey'] == 1;
                                            bool primaryUsecase =
                                                field['primaryUsecase'] != "";
                                            String minDateStr =
                                                field['minDate'] ?? "";
                                            String maxDateStr =
                                                field['maxDate'] ?? "";
                                            bool showDropdown =
                                                primaryUsecase && isRefKey;
                                            String yUsecase =
                                                field['primaryUsecase'] ?? "";
                                            String showvalue =
                                                field['show'] ?? "";

                                            // Request body for dynamic field value
                                            Map<String, String> reqBody = {};
                                            for (var field
                                                in itemsWithoutGroup) {
                                              String fieldValue = controller
                                                      .getInitialValue(label)
                                                      ?.toString() ??
                                                  '';
                                              reqBody[code.toString()] =
                                                  fieldValue;
                                            }
                                            final result =
                                                controller.evaluateCondition(
                                                    reqBody, showvalue);

                                            String event = field['event'] ?? "";
                                            String rule = field['rule'] ?? "";
                                            int captureImage =
                                                field['captureImage'] ?? 0;

                                            if (field['system'] == 1) {
                                              return const SizedBox.shrink();
                                            }

                                            dynamic initialValue = controller
                                                .getInitialValue(code);

                                            _controllers.putIfAbsent(label,
                                                () => TextEditingController());

                                            _controllers[label]!.text =
                                                (controller.getInitialValue(
                                                            code) ??
                                                        "")
                                                    .toString();

                                            if (fieldType == 'text' && result) {
                                              final initialValue = controller
                                                  .getInitialValue(code);

                                              // Normalize allowChangeAfterInitial to int
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: TextFormField(
                                                  enabled: isEditable,
                                                  readOnly: !isEditable,
                                                  controller:
                                                      _controllers[label],
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    errorText:
                                                        resulterror[code],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  onChanged: isEditable
                                                      ? (value) {
                                                          controller
                                                              .setInitialValue(
                                                                  code, value);
                                                          controller
                                                              .setFieldValue(
                                                                  label, value);
                                                        }
                                                      : null,
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
                                                      if (!regex
                                                          .hasMatch(value)) {
                                                        return 'Invalid input for $label';
                                                      }
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              );
                                            }

                                            if (fieldType == 'url' && result) {
                                              final initialValue = controller
                                                  .getInitialValue(code);

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Ensure controller exists with initial value
                                              _controllers[label] ??=
                                                  TextEditingController(
                                                text:
                                                    initialValue?.toString() ??
                                                        "",
                                              );

                                              return TextFormField(
                                                controller: _controllers[label],
                                                enabled: isEditable,
                                                readOnly: !isEditable,
                                                style: labelStyle,
                                                decoration: InputDecoration(
                                                  errorText: resulterror[code],
                                                  labelStyle: labelStyle,
                                                  labelText: label,
                                                  fillColor: isEditable
                                                      ? (isDarkMode
                                                          ? Colors.black
                                                          : Colors.white)
                                                      : Colors.grey[200],
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Appcolorblue),
                                                  ),
                                                ),
                                                keyboardType: TextInputType.url,
                                                onChanged: isEditable
                                                    ? (value) {
                                                        controller
                                                            .setInitialValue(
                                                                code, value);
                                                        controller
                                                            .setFieldValue(
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
                                              );
                                            }

                                            if (fieldType == 'password' &&
                                                result) {
                                              final String initialValue =
                                                  controller.getInitialValue(
                                                          code) ??
                                                      "";

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              // Apply edit rules
                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Ensure controller is initialized with initial value
                                              _controllers[label] ??=
                                                  TextEditingController(
                                                      text: initialValue);

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5.0),
                                                child: TextFormField(
                                                  controller:
                                                      _controllers[label],
                                                  style: labelStyle,
                                                  enabled: isEditable,
                                                  readOnly: !isEditable,
                                                  obscureText: _obscureText,
                                                  decoration: InputDecoration(
                                                    errorText:
                                                        resulterror[code],
                                                    labelStyle: labelStyle,
                                                    labelText: label,
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                    suffixIcon: isEditable
                                                        ? IconButton(
                                                            icon: Icon(
                                                              _obscureText
                                                                  ? Icons
                                                                      .visibility_off
                                                                  : Icons
                                                                      .visibility,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                _obscureText =
                                                                    !_obscureText;
                                                              });
                                                            },
                                                          )
                                                        : null,
                                                  ),
                                                  onChanged: isEditable
                                                      ? (value) {
                                                          controller
                                                              .setInitialValue(
                                                                  code, value);
                                                          controller
                                                              .setFieldValue(
                                                                  label, value);
                                                        }
                                                      : null,
                                                  validator: (value) {
                                                    if (isRequired &&
                                                        (value == null ||
                                                            value.isEmpty)) {
                                                      return 'Please enter $label';
                                                    }

                                                    final regexPattern = field[
                                                        'regex']; // e.g., "^(?=.*[0-9])(?=.*[A-Z]).{8,}$"
                                                    if (regexPattern != null &&
                                                        value != null &&
                                                        value.isNotEmpty) {
                                                      final regex =
                                                          RegExp(regexPattern);
                                                      if (!regex
                                                          .hasMatch(value)) {
                                                        return 'Invalid input for $label';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                ),
                                              );
                                            }

                                            if (fieldType == 'textarea' &&
                                                result) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5.0,
                                                        vertical: 5.0),
                                                child: TextFormField(
                                                  enabled: readOnly != 1,
                                                  readOnly: readOnly == 1,
                                                  controller:
                                                      _controllers[label],
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    errorText:
                                                        resulterror[code],
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
                                                    controller.dataMap[code] =
                                                        value; // Directly updating dataMap
                                                    controller.setInitialValue(
                                                        code, value);
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
                                              final dropdownItems = controller
                                                      .prelaodlist[yUsecase] ??
                                                  [];

                                              // Ensure unique IDs in the dropdown items
                                              final uniqueDropdownItems =
                                                  dropdownItems
                                                      .toSet()
                                                      .toList();

                                              final currentValue =
                                                  controller.getInitialValue(
                                                      field['code']);

                                              final validValue =
                                                  uniqueDropdownItems
                                                          .any((item) =>
                                                              item['id']
                                                                  .toString() ==
                                                              currentValue)
                                                      ? currentValue
                                                      : null;

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              final bool isEditable = readOnly !=
                                                      1 &&
                                                  (allowChange == 0 ||
                                                      (allowChange == 1 &&
                                                          (validValue == null ||
                                                              validValue
                                                                  .isEmpty)));

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  isExpanded: true,
                                                  dropdownColor: isDarkMode
                                                      ? Colors.grey[850]
                                                      : Colors.white,
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelText: label,
                                                    errorText:
                                                        resulterror[code],
                                                    labelStyle: labelStyle,
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  value: validValue?.isEmpty ??
                                                          true
                                                      ? null
                                                      : validValue,
                                                  items: [
                                                    if (!isRequired)
                                                      DropdownMenuItem<String>(
                                                        value: null,
                                                        child: Text(
                                                          'Select $label',
                                                          style: labelStyle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ...uniqueDropdownItems.map<
                                                        DropdownMenuItem<
                                                            String>>((item) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: item['id']
                                                            .toString(),
                                                        child: Text(
                                                          item['_val'],
                                                          style: labelStyle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ],
                                                  onChanged: isEditable
                                                      ? (value) async {
                                                          controller.onChange(
                                                              field, value);
                                                          if (event != "") {
                                                            await controller
                                                                .GetUserData(
                                                                    code,
                                                                    rule,
                                                                    value!);
                                                            controller
                                                                    .admissionId =
                                                                value;
                                                            setState(() {
                                                              controller
                                                                  .setFieldValue(
                                                                      label,
                                                                      value ??
                                                                          "");
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      value ??
                                                                          "");
                                                            });
                                                          } else {
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    value ??
                                                                        "");
                                                            controller
                                                                .setInitialValue(
                                                                    code,
                                                                    value ??
                                                                        "");
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

                                            if (fieldType == 'object' &&
                                                result) {
                                              final initialValue = controller
                                                  .getInitialValue(code);

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Ensure controller exists with initial value
                                              _controllers[label] ??=
                                                  TextEditingController(
                                                text:
                                                    initialValue?.toString() ??
                                                        "",
                                              );

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: TextFormField(
                                                  enabled: isEditable,
                                                  readOnly: !isEditable,
                                                  controller:
                                                      _controllers[label],
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelText: label,
                                                    errorText:
                                                        resulterror[code],
                                                    labelStyle: labelStyle,
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  onChanged: isEditable
                                                      ? (value) {
                                                          controller
                                                              .setInitialValue(
                                                                  code, value);
                                                          controller
                                                              .setFieldValue(
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

                                            if (fieldType == 'location' &&
                                                result) {
                                              final locationMap = initialValue;

                                              if (locationMap != null &&
                                                  locationMap is Map) {
                                                if (locationMap.isNotEmpty) {
                                                  controller.showTextField
                                                      .value = true;
                                                }

                                                controller.latController.text =
                                                    locationMap['lat']
                                                            .toString() ??
                                                        '';
                                                controller.longController.text =
                                                    locationMap['lng']
                                                            .toString() ??
                                                        '';
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 12),
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
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  Colors.grey,
                                                              width: 1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(
                                                                  Icons
                                                                      .location_on,
                                                                  color:
                                                                      Appcolorblue),
                                                              onPressed: () {
                                                                setCurrentLocation(
                                                                    label,
                                                                    code);
                                                              },
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                  Icons
                                                                      .remove_red_eye,
                                                                  color:
                                                                      Appcolorblue),
                                                              onPressed:
                                                                  () async {
                                                                final lat =
                                                                    controller
                                                                        .latController
                                                                        .text;
                                                                final lng =
                                                                    controller
                                                                        .longController
                                                                        .text;
                                                                if (lat.isEmpty ||
                                                                    lng.isEmpty) {
                                                                  showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) =>
                                                                            AlertDialog(
                                                                      title: const Text(
                                                                          "Missing Location"),
                                                                      content:
                                                                          const Text(
                                                                              "Location not available. Please set the location first.."),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(context),
                                                                          child:
                                                                              Text("OK"),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                } else {
                                                                  final Uri
                                                                      mapUrl =
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
                                                                  color: Colors
                                                                      .red),
                                                              onPressed: () {
                                                                _clearText(
                                                                    label,
                                                                    code);
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (controller.showTextField
                                                        .value) ...[
                                                      TextField(
                                                        controller: controller
                                                            .latController,
                                                        readOnly: true,
                                                        style: labelStyle,
                                                        decoration:
                                                            InputDecoration(
                                                          labelText: 'Latitude',
                                                          fillColor: isDarkMode
                                                              ? Colors.black
                                                              : Colors.white,
                                                          labelStyle:
                                                              labelStyle,
                                                          border:
                                                              const OutlineInputBorder(),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 10),
                                                      TextField(
                                                        controller: controller
                                                            .longController,
                                                        readOnly: true,
                                                        style: labelStyle,
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
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }

                                   if ((fieldType == 'number' ||
                                                    fieldType == 'phone' ||
                                                    fieldType == 'long' ||
                                                    fieldType == 'decimal') &&
                                                result) {
                                              final dynamic initialValue =
                                                  controller
                                                      .getInitialValue(code);

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Format number for display (remove trailing .0 if integer)
                                              String formatNumberForDisplay(
                                                  String value) {
                                                if (value.isEmpty) return '';
                                                final double? number =
                                                    double.tryParse(value);
                                                if (number == null)
                                                  return value;

                                                if (number == number.toInt()) {
                                                  return number
                                                      .toInt()
                                                      .toString(); // 10.0 -> 10
                                                } else {
                                                  // For decimal fields, keep up to 3 decimal places
                                                  if (fieldType == 'decimal') {
                                                    return number
                                                        .toStringAsFixed(3);
                                                  }
                                                  return number.toString();
                                                }
                                              }
                                              

                                              // Ensure controller exists with formatted initial value
                                              _controllers[label] ??=
                                                  TextEditingController();

                                              // Set formatted value
                                              String formattedValue =
                                                  formatNumberForDisplay(
                                                      initialValue
                                                              ?.toString() ??
                                                          "");
                                              if (_controllers[label]!.text !=
                                                  formattedValue) {
                                                _controllers[label]!.text =
                                                    formattedValue;
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: TextFormField(
                                                  enabled: isEditable,
                                                  readOnly: !isEditable,
                                                  controller:
                                                      _controllers[label],
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    errorText:
                                                        resulterror[code],
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  keyboardType: fieldType ==
                                                          'decimal'
                                                      ? const TextInputType
                                                          .numberWithOptions(
                                                          decimal: true)
                                                      : TextInputType.number,
                                                  onChanged: isEditable
                                                      ? (value) {
                                                          // Debug print
                                                          print(
                                                              '📝 Field changed: $label = $value');

                                                          // ✅ STEP 1: Update dataMap and controllers
                                                          controller.dataMap[
                                                                  code] =
                                                              value; // update data map
                                                          controller
                                                              .setInitialValue(
                                                                  code, value);
                                                          controller
                                                              .setFieldValue(
                                                                  label, value);

                                                          // ✅ STEP 2: Store in both possible locations for Salary field
                                                          if (label ==
                                                                  'Salary' ||
                                                              label ==
                                                                  'Salay') {
                                                            controller.dataMap[
                                                                    'salary'] =
                                                                value;
                                                            controller.dataMap[
                                                                    'salay'] =
                                                                value;
                                                            controller
                                                                .setFieldValue(
                                                                    'Salary',
                                                                    value);
                                                            controller
                                                                .setFieldValue(
                                                                    'Salay',
                                                                    value);
                                                          }

                                                          // ✅ STEP 3: IMPORTANT - Update all expression fields
                                                          controller
                                                              .updateAllExpressionFields();

                                                          // ✅ STEP 4: Force UI update
                                                          setState(() {});
                                                        }
                                                      : null,
                                                  validator: (value) {
                                                    if (isRequired &&
                                                        (value == null ||
                                                            value.isEmpty)) {
                                                      return 'Please enter $label';
                                                    }

                                                    final regexPattern = field[
                                                        'regex']; // optional regex check
                                                    if (regexPattern != null &&
                                                        value != null &&
                                                        value.isNotEmpty) {
                                                      final regex =
                                                          RegExp(regexPattern);
                                                      if (!regex
                                                          .hasMatch(value)) {
                                                        return 'Invalid input for $label';
                                                      }
                                                    }

                                                    // Validate number format
                                                    if (value != null &&
                                                        value.isNotEmpty) {
                                                      if (fieldType ==
                                                          'decimal') {
                                                        if (double.tryParse(
                                                                value) ==
                                                            null) {
                                                          return 'Please enter a valid decimal number';
                                                        }
                                                      } else {
                                                        if (int.tryParse(
                                                                    value) ==
                                                                null &&
                                                            double.tryParse(
                                                                    value) ==
                                                                null) {
                                                          return 'Please enter a valid number';
                                                        }
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                ),
                                              );
                                            }
                                
                                            // Add this after the 'time' field handling (around line 2500-2600)
if (fieldType == 'idate' && result) {
  final String initialValue = controller.getInitialValue(code) ?? "";

  final int allowChange = int.tryParse(
          field['allowChangeAfterInitial']?.toString() ?? '0') ??
      0;

  final bool isEditable = readOnly != 1 && allowChange == 0;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      readOnly: true,
      enabled: isEditable,
      style: labelStyle,
      controller: TextEditingController(
        text: controller.formatIDateForDisplay(initialValue),
      ),
      decoration: InputDecoration(
        fillColor: isEditable
            ? (isDarkMode ? Colors.black : Colors.white)
            : Colors.grey[200],
        filled: true,
        labelText: label,
        labelStyle: labelStyle,
        errorText: resulterror[code],
        suffixIcon: isEditable
            ? Icon(
                Icons.calendar_today,
                color: isDarkMode ? Colors.white : Colors.black,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Appcolorblue),
        ),
      ),
      onTap: isEditable
          ? () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );

              if (selectedDate != null) {
                String formattedDate =
                    DateFormat('dd-MM-yyyy').format(selectedDate);

                String apiFormat =
                    controller.formatIDateForApi(formattedDate);

                setState(() {
                  controller.setInitialValue(code, apiFormat);
                  controller.setFieldValue(label, apiFormat);
                });
              }
            }
          : null,
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

// Add this after the 'idate' field handling
if (fieldType == 'itime' && result) {
  final String initialValue = controller.getInitialValue(code) ?? "";

  final int allowChange = int.tryParse(
          field['allowChangeAfterInitial']?.toString() ?? '0') ??
      0;

  final bool isEditable = readOnly != 1 && allowChange == 0;

  // Get timeFormat (12 or 24)
  int timeFormat = int.tryParse(field['timeFormat']?.toString() ?? '12') ?? 12;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      readOnly: true,
      enabled: isEditable,
      style: labelStyle,
      controller: TextEditingController(
        text: controller.formatITimeForDisplay(initialValue, timeFormat),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        errorText: resulterror[code],
        filled: true,
        fillColor: isEditable
            ? (isDarkMode ? Colors.black : Colors.white)
            : Colors.grey[200],
        suffixIcon: isEditable
            ? const Icon(Icons.access_time)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      onTap: isEditable
          ? () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: timeFormat == 24,
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedTime != null) {
                String displayTime;
                if (timeFormat == 24) {
                  displayTime =
                      '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                } else {
                  displayTime = DateFormat('hh:mm a').format(
                    DateTime(
                      2024,
                      1,
                      1,
                      pickedTime.hour,
                      pickedTime.minute,
                    ),
                  );
                }

                String apiTime = controller.formatITimeForApi(displayTime);

                setState(() {
                  controller.setInitialValue(code, apiTime);
                  controller.setFieldValue(label, apiTime);
                });
              }
            }
          : null,
      validator: isRequired
          ? (value) => value == null || value.isEmpty
              ? 'Please select $label'
              : null
          : null,
    ),
  );
}

// Add this after the 'itime' field handling
if ((fieldType == 'datetime' || fieldType == 'dateandtime') && result) {
  final String initialValue = controller.getInitialValue(code) ?? "";

  final int allowChange = int.tryParse(
          field['allowChangeAfterInitial']?.toString() ?? '0') ??
      0;

  final bool isEditable = readOnly != 1 && allowChange == 0;

  // Get timeFormat
  int timeFormat = int.tryParse(field['timeFormat']?.toString() ?? '24') ?? 24;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      readOnly: true,
      enabled: isEditable,
      style: labelStyle,
      controller: TextEditingController(
        text: controller.formatDateTimeForDisplay(initialValue, timeFormat),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        errorText: resulterror[code],
        filled: true,
        fillColor: isEditable
            ? (isDarkMode ? Colors.black : Colors.white)
            : Colors.grey[200],
        suffixIcon: isEditable
            ? Icon(
                Icons.date_range,
                color: isDarkMode ? Colors.white : Colors.black)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      onTap: isEditable
          ? () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );

              if (selectedDate == null) return;

              TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat: false, // Force AM/PM for UI
                    ),
                    child: child!,
                  );
                },
              );

              if (selectedTime == null) return;

              final DateTime combinedDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              String apiFormat =
                  controller.formatDateTimeForApi(combinedDateTime.toString());

              setState(() {
                controller.setInitialValue(code, apiFormat);
                controller.setFieldValue(label, apiFormat);
              });
            }
          : null,
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

if (fieldType == 'expression' && result) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
    child: Obx(() {
      // Get value from controller - use controller.getFieldValue()
      String currentValue = controller.getFieldValue(label) ?? '';
      
      // Also check dataMap as fallback
      if (currentValue.isEmpty) {
        currentValue = controller.dataMap[code]?.toString() ?? '';
      }
      
      // Clean up decimal display
      if (currentValue.contains('.')) {
        currentValue = currentValue.replaceAll(RegExp(r'0+$'), '');
        currentValue = currentValue.replaceAll(RegExp(r'\.$'), '');
      }
      
      // Debug print to verify updates
      print('🔄 Expression field "$label" updated to: $currentValue');
      
      // Initialize controller if needed
      _controllers.putIfAbsent(label, () => TextEditingController());
      
      // Update controller text if changed
      if (_controllers[label]!.text != currentValue) {
        _controllers[label]!.text = currentValue;
      }
      
      return TextFormField(
        controller: _controllers[label],
        readOnly: true,
        enabled: false,
        style: labelStyle.copyWith(color: Colors.grey[700]),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      );
    }),
  );
}

                                            if (fieldType == 'email' &&
                                                result) {
                                              final String initialValue =
                                                  controller.getInitialValue(
                                                          code) ??
                                                      "";

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              // Apply edit rules
                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Ensure controller is initialized with initial value
                                              _controllers[label] ??=
                                                  TextEditingController(
                                                      text: initialValue);

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: TextFormField(
                                                  style: labelStyle,
                                                  enabled: isEditable,
                                                  readOnly: !isEditable,
                                                  controller:
                                                      _controllers[label],
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    errorText:
                                                        resulterror[code],
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  onChanged: isEditable
                                                      ? (value) {
                                                          setState(() {
                                                            controller.dataMap[
                                                                code] = value;
                                                            controller
                                                                .setInitialValue(
                                                                    code,
                                                                    value);
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    value);
                                                          });
                                                        }
                                                      : null,
                                                  validator: (value) {
                                                    if (isRequired &&
                                                        (value == null ||
                                                            value.isEmpty)) {
                                                      return 'Please enter $label';
                                                    }
                                                    // Basic email validation
                                                    if (value != null &&
                                                        value.isNotEmpty) {
                                                      final emailRegex = RegExp(
                                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                                      if (!emailRegex
                                                          .hasMatch(value)) {
                                                        return 'Please enter a valid email address';
                                                      }
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              );
                                            }
                                            // Handle date fields
                                            if (fieldType == 'time' && result) {
                                              final initialValue = controller
                                                  .getInitialValue(code);

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange = int.tryParse(
                                                      field['allowChangeAfterInitial']
                                                              ?.toString() ??
                                                          '0') ??
                                                  0;

                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Ensure controller exists
                                              _controllers[label] ??=
                                                  TextEditingController(
                                                text:
                                                    initialValue?.toString() ??
                                                        "",
                                              );

                                              // Prefill with current time if empty and defaultToCurrentTime == 1
                                              final int defaultToCurrentTime =
                                                  field['defaultToCurrentTime'] ??
                                                      0;
                                              if (_controllers[label]!
                                                      .text
                                                      .isEmpty &&
                                                  defaultToCurrentTime == 1) {
                                                String currentTime =
                                                    DateFormat('HH:mm')
                                                        .format(DateTime.now());
                                                _controllers[label]!.text =
                                                    currentTime;
                                                controller.setInitialValue(
                                                    code, currentTime);
                                                controller.setFieldValue(
                                                    label, currentTime);
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: TextFormField(
                                                  readOnly:
                                                      true, // always readonly, we pick time via picker
                                                  enabled: isEditable,
                                                  style: labelStyle,
                                                  controller:
                                                      _controllers[label],
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelStyle: labelStyle,
                                                    errorText:
                                                        resulterror[code],
                                                    labelText: label,
                                                    suffixIcon: isEditable
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
                                                  onTap: isEditable
                                                      ? () async {
                                                          TimeOfDay?
                                                              selectedTime =
                                                              await showTimePicker(
                                                            context: context,
                                                            initialTime:
                                                                TimeOfDay.now(),
                                                          );
                                                          if (selectedTime !=
                                                              null) {
                                                            final now =
                                                                DateTime.now();
                                                            final dateTime =
                                                                DateTime(
                                                              now.year,
                                                              now.month,
                                                              now.day,
                                                              selectedTime.hour,
                                                              selectedTime
                                                                  .minute,
                                                            );

                                                            String
                                                                formattedTime =
                                                                DateFormat(
                                                                        'HH:mm')
                                                                    .format(
                                                                        dateTime);

                                                            setState(() {
                                                              _controllers[
                                                                          label]
                                                                      ?.text =
                                                                  formattedTime;
                                                              controller
                                                                  .setInitialValue(
                                                                      code,
                                                                      formattedTime);
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

                                            if (fieldType == 'date' && result) {
                                              final String initialValue =
                                                  controller.getInitialValue(
                                                          code) ??
                                                      "";

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              // Apply edit logic
                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: TextFormField(
                                                  readOnly:
                                                      true, // User should always pick from date picker
                                                  controller:
                                                      TextEditingController(
                                                          text: initialValue),
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    errorText:
                                                        resulterror[code],
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    suffixIcon: isEditable
                                                        ? Icon(
                                                            Icons
                                                                .calendar_today,
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                          )
                                                        : null,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  onTap: isEditable
                                                      ? () async {
                                                          DateTime?
                                                              selectedDate;

                                                          if (minDateStr
                                                                  .isEmpty &&
                                                              maxDateStr
                                                                  .isEmpty) {
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
                                                                .isBefore(
                                                                    minDate)) {
                                                              initial = minDate;
                                                            } else if (initial
                                                                .isAfter(
                                                                    maxDate)) {
                                                              initial = maxDate;
                                                            }

                                                            selectedDate =
                                                                await showDatePicker(
                                                              context: context,
                                                              initialDate:
                                                                  initial,
                                                              firstDate:
                                                                  minDate,
                                                              lastDate: maxDate,
                                                            );
                                                          }

                                                          if (selectedDate !=
                                                              null) {
                                                            String
                                                                formattedDate =
                                                                DateFormat(
                                                                        'yyyy-MM-dd')
                                                                    .format(
                                                                        selectedDate);

                                                            if (event != "") {
                                                              var response =
                                                                  await controller
                                                                      .validateAndSubmitDate(
                                                                          rule,
                                                                          formattedDate);

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

                                            if (fieldType == 'list' && result) {
                                              final values =
                                                  field['values'] ?? [];
                                              final initialValue = controller
                                                  .getInitialValue(code);

                                              // Normalize allowChangeAfterInitial
                                              final int allowChange =
                                                  int.tryParse(field[
                                                              'allowChangeAfterInitial']
                                                          .toString()) ??
                                                      0;

                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Ensure valid initial value
                                              final validInitialValue =
                                                  values.contains(initialValue)
                                                      ? initialValue
                                                      : null;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  isExpanded: true,
                                                  dropdownColor: isDarkMode
                                                      ? Colors.grey[850]
                                                      : Colors.white,
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : Colors.grey[200],
                                                    filled: true,
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    errorText:
                                                        resulterror[code],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  value: (validInitialValue ==
                                                              null ||
                                                          validInitialValue
                                                              .toString()
                                                              .isEmpty)
                                                      ? null
                                                      : validInitialValue
                                                          .toString(),
                                                  items: [
                                                    if (!isRequired)
                                                      DropdownMenuItem<String>(
                                                        value: null,
                                                        child: Text(
                                                          'Select $label',
                                                          style: labelStyle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ...values.map<
                                                        DropdownMenuItem<
                                                            String>>((value) {
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: value,
                                                        child: Text(
                                                          value,
                                                          style: labelStyle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ],
                                                  onChanged: isEditable
                                                      ? (value) async {
                                                                      // ✅ STEP 3: UPDATE ALL EXPRESSION FIELDS
                                                          controller
                                                              .updateAllExpressionFields();

                                                          // ✅ STEP 4: Refresh UI
                                                          setState(() {});

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
                                                                code] = value;
                                                            controller
                                                                .setInitialValue(
                                                                    code,
                                                                    value ??
                                                                        "");
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    value ??
                                                                        "");
                                                          } else {
                                                            controller.dataMap[
                                                                code] = value;
                                                            controller
                                                                .setInitialValue(
                                                                    code,
                                                                    value ??
                                                                        "");
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    value ??
                                                                        "");
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

                                            if (fieldType == 'map' && result) {
                                              List<dynamic> mapValues =
                                                  field['values'] ?? [];

                                              final dynamic initialValue =
                                                  controller
                                                      .getInitialValue(code);
                                              String? currentValue =
                                                  (initialValue == null ||
                                                          initialValue
                                                              .toString()
                                                              .trim()
                                                              .isEmpty)
                                                      ? null
                                                      : initialValue
                                                          .toString()
                                                          .trim();

                                              final int allowChange = int.tryParse(
                                                      field['allowChangeAfterInitial']
                                                              ?.toString() ??
                                                          "0") ??
                                                  0;
                                              final bool isEditable =
                                                  readOnly != 1 &&
                                                      allowChange == 0;

                                              // Build "key - value" list
                                              List<String> combinedValues =
                                                  mapValues
                                                      .map((v) =>
                                                          "${(v['key'] ?? '').toString().trim()} - ${(v['value'] ?? '').toString()}")
                                                      .toList();

                                              // Reset if invalid
                                              if (currentValue != null &&
                                                  !combinedValues
                                                      .contains(currentValue)) {
                                                currentValue = null;
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: DropdownButtonFormField<
                                                    String?>(
                                                  isExpanded: true,
                                                  dropdownColor: isDarkMode
                                                      ? Colors.grey[850]
                                                      : Colors.white,
                                                  style: labelStyle,
                                                  decoration: InputDecoration(
                                                    fillColor: isEditable
                                                        ? (isDarkMode
                                                            ? Colors.black
                                                            : Colors.white)
                                                        : (isDarkMode
                                                            ? Colors.grey[800]
                                                            : Colors.grey[200]),
                                                    filled: true,
                                                    labelText: label,
                                                    labelStyle: labelStyle,
                                                    errorText:
                                                        resulterror[code],
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Appcolorblue),
                                                    ),
                                                  ),
                                                  value: currentValue,
                                                  items: [
                                                    if (!isRequired)
                                                      DropdownMenuItem<String?>(
                                                        value: null,
                                                        child: Text(
                                                          'Select $label',
                                                          style: labelStyle
                                                              .copyWith(
                                                                  color: Colors
                                                                      .grey),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ...mapValues.map<
                                                            DropdownMenuItem<
                                                                String?>>(
                                                        (valueMap) {
                                                      final String key =
                                                          (valueMap['key'] ??
                                                                  '')
                                                              .toString()
                                                              .trim();
                                                      final String valueText =
                                                          (valueMap['value'] ??
                                                                  '')
                                                              .toString();
                                                      final String keyValue =
                                                          "$key - $valueText"; // ✅ combined
                                                      return DropdownMenuItem<
                                                          String?>(
                                                        value: keyValue,
                                                        child: Text(
                                                          keyValue,
                                                          style: labelStyle,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ],
                                                  selectedItemBuilder:
                                                      (BuildContext context) {
                                                    List<Widget>
                                                        selectedWidgets = [];
                                                    if (!isRequired) {
                                                      selectedWidgets.add(Text(
                                                        'Select $label',
                                                        style:
                                                            labelStyle.copyWith(
                                                                color: Colors
                                                                    .grey),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ));
                                                    }
                                                    selectedWidgets.addAll(
                                                        mapValues.map<Widget>(
                                                            (valueMap) {
                                                      final String key =
                                                          (valueMap['key'] ??
                                                                  '')
                                                              .toString()
                                                              .trim();
                                                      final String valueText =
                                                          (valueMap['value'] ??
                                                                  '')
                                                              .toString();
                                                      return Text(
                                                        "$key - $valueText",
                                                        style: labelStyle,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      );
                                                    }).toList());
                                                    return selectedWidgets;
                                                  },
                                                  onChanged: isEditable
                                                      ? (value) async {
                                                          if (event != "") {
                                                            await controller
                                                                .GetUserData(
                                                                    code,
                                                                    rule,
                                                                    value ??
                                                                        "");
                                                            controller
                                                                    .admissionId =
                                                                value;
                                                          }
                                                          controller.dataMap[
                                                                  code] =
                                                              value ??
                                                                  ""; // ✅ "1 - a"
                                                          controller.setFieldValue(
                                                              label,
                                                              value ??
                                                                  ""); // ✅ "1 - a"
                                                          controller
                                                              .setInitialValue(
                                                                  code,
                                                                  value ??
                                                                      ""); // ✅ "1 - a"
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

                                            if (fieldType == 'combobox' &&
                                                result) {
                                              comboboxmapValues =
                                                  field['values'] ?? [];
                                              List<String> _options =
                                                  List<String>.from(
                                                      comboboxmapValues
                                                              .isNotEmpty
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
                                                builder:
                                                    (context, setInnerState) {
                                                  void _saveValue(
                                                      String value) {
                                                    controller.dataMap[
                                                        field['code']] = value;
                                                    controller.setFieldValue(
                                                        label, value);
                                                    controller.setInitialValue(
                                                        code, value);
                                                  }

                                                  void _onTextChanged(
                                                      String value) {
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

                                                  void _onItemSelected(
                                                      String value) {
                                                    _controllers[label]!.text =
                                                        value;
                                                    _saveValue(
                                                        value); // Save on dropdown selection
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    setInnerState(() {
                                                      _filteredOptions =
                                                          _options;
                                                    });
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 5.0,
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          _controllers[label],
                                                      enabled: readOnly != 1,
                                                      readOnly: readOnly == 1,
                                                      onChanged: readOnly != 1
                                                          ? _onTextChanged
                                                          : null,
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isDarkMode
                                                            ? Colors.black
                                                            : Colors.white,
                                                        labelText:
                                                            'Select a $label',
                                                        suffixIcon:
                                                            PopupMenuButton<
                                                                String>(
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
                                                                      labelStyle,
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
                                            if (fieldType == 'boolean' &&
                                                result) {
                                              String? savedValue =
                                                  initialValue.toString();
                                              if (savedValue == '1') {
                                                isSelected = [true, false];
                                              } else if (savedValue == '0') {
                                                isSelected = [false, true];
                                              } else {
                                                isSelected = [false, false];
                                              }

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 9),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Align(
                                                        alignment:
                                                            Alignment.topLeft,
                                                        child: Text(label,
                                                            style: labelStyle)),
                                                    const SizedBox(height: 10),
                                                    Align(
                                                      alignment:
                                                          Alignment.topLeft,
                                                      child: ToggleButtons(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        selectedColor:
                                                            Colors.white,
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
                                                            ? Colors.white
                                                            : Colors.black,
                                                        isSelected: isSelected,
                                                        onPressed: (index) {
                                                          setState(() {
                                                            for (int i = 0;
                                                                i <
                                                                    isSelected
                                                                        .length;
                                                                i++) {
                                                              isSelected[i] =
                                                                  i == index;
                                                            }

                                                            var selectedValue =
                                                                index == 0
                                                                    ? 1
                                                                    : 0;
                                                            String savedValue =
                                                                selectedValue
                                                                    .toString();

                                                            controller.dataMap[
                                                                    field[
                                                                        'code']] =
                                                                savedValue;
                                                            controller
                                                                .setFieldValue(
                                                                    label,
                                                                    savedValue);
                                                            controller
                                                                .setInitialValue(
                                                                    code,
                                                                    savedValue);
                                                          });
                                                        },
                                                        children: const [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16),
                                                            child: Text(
                                                              "Yes",
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16),
                                                            child: Text(
                                                              "No",
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
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
                                            if (fieldType == 'doc' && result) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Custom file input field that looks like a TextField
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 5.0),
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
                                                          text: controller.imagePaths[
                                                                      code] !=
                                                                  null
                                                              ? controller
                                                                  .imagePaths[
                                                                      code]!
                                                                  .split('/')
                                                                  .last
                                                              : ''),
                                                      // Display the file name or path
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isDarkMode
                                                            ? Colors.black
                                                            : Colors.white,
                                                        labelText: label,
                                                        hintText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .green),
                                                        ),
                                                        suffixIcon: IconButton(
                                                            icon: Icon(
                                                                Icons
                                                                    .attachment,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                            onPressed: () {
                                                              _pickAndUploadFile(
                                                                int.tryParse(controller
                                                                            .getInitialValue(code)
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
                                                          controller.imagePaths[
                                                                  code] =
                                                              value; // Optionally save the file path here
                                                        });
                                                        controller
                                                                .dataMap[code] =
                                                            value; // Directly updating dataMap
                                                        controller
                                                            .setInitialValue(
                                                                code, value);
                                                        controller
                                                            .setFieldValue(
                                                                label, value);
                                                      },
                                                    ),
                                                  ),
                                                  controller.imagePaths[code] !=
                                                          null
                                                      ? CachedNetworkImage(
                                                          imageUrl:
                                                              "https://cuickdev.com/API/DOCS/api/doc/th/${controller.uploadDocument[code]}?t=${DateTime.now().millisecondsSinceEpoch}",
                                                          width: 100,
                                                          height: 100,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        )
                                                      : Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      16.0),
                                                          child: Image.network(
                                                              width: 100,
                                                              height: 100,
                                                              controller.getInitialValue(
                                                                          code) ==
                                                                      null
                                                                  ? imageUrlHelper
                                                                      .applogourl
                                                                  : "https://cuickdev.com/API/DOCS/api/doc/th/${controller.getInitialValue(code).toString()}?t=0"), // Display the selected image (optional)
                                                        )
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0,
                                                        vertical: 5.0),
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
                                                              ImageSource
                                                                  .camera);
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
                                                      readOnly: true,
                                                      style: labelStyle,
                                                      controller: TextEditingController(
                                                          text: controller.imagePaths[
                                                                      code] !=
                                                                  null
                                                              ? controller
                                                                  .imagePaths[
                                                                      code]!
                                                                  .split('/')
                                                                  .last
                                                              : ''),
                                                      // Display the file name or path
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: isDarkMode
                                                            ? Colors.black
                                                            : Colors.white,
                                                        labelText: label,
                                                        labelStyle: labelStyle,
                                                        errorText:
                                                            resulterror[code],
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .green),
                                                        ),
                                                        suffixIcon: IconButton(
                                                            icon: Icon(
                                                              Icons.attachment,
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                            onPressed: () {
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
                                                            } // Trigger the file picker on tap

                                                            ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          controller.imagePaths[
                                                                  code] =
                                                              value; // Optionally save the file path here
                                                        });
                                                        controller
                                                                .dataMap[code] =
                                                            value; // Directly updating dataMap
                                                        controller
                                                            .setInitialValue(
                                                                code, '0');
                                                      },
                                                    ),
                                                  ),
                                                  controller.imagePaths[code] !=
                                                          null
                                                      ? Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical:
                                                                      16.0),
                                                          child: Image.file(
                                                            File(
                                                              controller
                                                                      .imagePaths[
                                                                  code]!,
                                                            ),
                                                            width: 100,
                                                            height: 100,
                                                          ), // Display the selected image (optional)
                                                        )
                                                      : Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical:
                                                                      16.0),
                                                          child: Image.network(
                                                              width: 100,
                                                              height: 100,
                                                              controller.getInitialValue(
                                                                          code) ==
                                                                      null
                                                                  ? imageUrlHelper
                                                                      .applogourl
                                                                  : "https://cuickdev.com/API/DOCS/api/doc/th/${controller.getInitialValue(code).toString()}?t=0"), // Display the selected image (optional)
                                                        )
                                                ],
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
                                              children: controller.buttons
                                                  .where((button) {
                                                switch (
                                                    button.name.toLowerCase()) {
                                                  case 'list':
                                                    return widget.isread == 1;
                                                  case 'delete':
                                                    return widget.isdelete ==
                                                            1 &&
                                                        !isNewClicked;
                                                  case 'update':
                                                    return widget.isupdate == 1;
                                                  case 'save':
                                                    return widget.iscreate ==
                                                            1 ||
                                                        widget.isupdate == 1 &&
                                                            widget.formID !=
                                                                ''; // Assuming you have issave for Save button
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
                                                    if (button.name
                                                            .toLowerCase() ==
                                                        'save') {
                                                      if (isSaving)
                                                        return; // 🛑 Prevent multiple submissions

                                                      setState(() {
                                                        isSaving = true;
                                                      });

                                                      if (_formKey.currentState
                                                              ?.validate() ??
                                                          false) {
                                                        Map<String, dynamic>?
                                                            response =
                                                            await SaveForm();
                                                        if (response != null &&
                                                            response[
                                                                'success']) {
                                                          showToast();
                                                        } else {
                                                          var inputError =
                                                              response?[
                                                                      'result'][
                                                                  'inputerror'];
                                                          if (!mounted)
                                                            return; // <-- very important here
                                                          setState(() {
                                                            resulterror.clear();

                                                            if (inputError !=
                                                                null) {
                                                              inputError
                                                                  .forEach((key,
                                                                      value) {
                                                                resulterror[
                                                                        key] =
                                                                    value;
                                                                CherryToast
                                                                    .error(
                                                                  backgroundColor:
                                                                      const Color(
                                                                          0xFFF8D0D9),
                                                                  animationDuration:
                                                                      Durations
                                                                          .short1,
                                                                  title: const Text(
                                                                      "Error Saving Form",
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.black)),
                                                                ).show(Get
                                                                    .overlayContext!);
                                                              });
                                                            } else {
                                                              // Optional: handle no inputError case
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
                                                      handleButtonClick(button
                                                          .name
                                                          .toLowerCase());
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
                                                        color: (button.name
                                                                        .toLowerCase() ==
                                                                    'save' &&
                                                                isSaving)
                                                            ? Colors
                                                                .grey.shade300
                                                            : null,
                                                        border: Border.all(
                                                          color: isDarkMode
                                                              ? const Color(
                                                                  0xFF4F76E2)
                                                              : const Color(
                                                                  0xFF1A237E),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          button.name
                                                              .toUpperCase(),
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

                                                  // Container(
                                                  //   height: 45,
                                                  //   width: 120,
                                                  //   decoration: BoxDecoration(
                                                  //     border: Border.all(
                                                  //       color: isDarkMode
                                                  //           ? const Color(0xFF4F76E2)
                                                  //           : const Color(0xFF1A237E),
                                                  //     ),
                                                  //     borderRadius:
                                                  //         BorderRadius.circular(5),
                                                  //   ),
                                                  //   child: Center(
                                                  //     child: Text(
                                                  //       button.name.toUpperCase(),
                                                  //       style: TextStyle(
                                                  //         color: isDarkMode
                                                  //             ? const Color(
                                                  //                 0xFF4F76E2)
                                                  //             : const Color(
                                                  //                 0xFF1A237E),
                                                  //         fontWeight: FontWeight.w500,
                                                  //         fontFamily: 'Lato',
                                                  //         fontSize: 15,
                                                  //       ),
                                                  //     ),
                                                  //   ),
                                                  // ),
                                                );

                                                /*GestureDetector(
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
                                                :const Color(0xFF1A237E),
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            button.name.toUpperCase(),
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ?const Color(0xFF4F76E2)
                                                  : const Color(0xFF1A237E),
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Lato',
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );*/
                                              }).toList(),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          childcontroller
                                                      .filteredData.isEmpty &&
                                                  childcontroller
                                                      .childlabellist.isEmpty
                                              ? SizedBox()
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[200],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              childcontroller
                                                                  .Childtitle
                                                                  .value,
                                                              style: const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            childcontroller
                                                                        .iscreate !=
                                                                    0
                                                                ? ElevatedButton
                                                                    .icon(
                                                                    onPressed:
                                                                        () {
                                                                      Get.to(ChilduiformScreen(
                                                                          title: childcontroller
                                                                              .Childtitle
                                                                              .value,
                                                                          editid:
                                                                              0));
                                                                    },
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .add,
                                                                        color: Colors
                                                                            .white),
                                                                    label: Text(
                                                                      "Add ${childcontroller.Childtitle.value}",
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                    style: ElevatedButton
                                                                        .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .indigo,
                                                                      foregroundColor:
                                                                          Colors
                                                                              .white,
                                                                    ),
                                                                  )
                                                                : SizedBox()
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 10),
                                                      childcontroller
                                                                  .filteredData
                                                                  .isEmpty &&
                                                              childcontroller
                                                                  .childlabellist
                                                                  .isEmpty
                                                          ? const SizedBox()
                                                          : childcontroller
                                                                      .isread !=
                                                                  0
                                                              ? SingleChildScrollView(
                                                                  scrollDirection:
                                                                      Axis.horizontal,
                                                                  physics:
                                                                      const BouncingScrollPhysics(),
                                                                  child:
                                                                      DataTable(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Get.isDarkMode
                                                                          ? Colors
                                                                              .black
                                                                          : const Color(
                                                                              0xFFF5F5F5),
                                                                    ),
                                                                    border:
                                                                        TableBorder
                                                                            .all(
                                                                      color: Get.isDarkMode
                                                                          ? Colors
                                                                              .white
                                                                          : const Color(
                                                                              0xFFE0E0E0),
                                                                    ),
                                                                    columnSpacing:
                                                                        20,
                                                                    dividerThickness:
                                                                        0.2,
                                                                    columns: [
                                                                      ...childcontroller
                                                                          .childlabellist
                                                                          .map(
                                                                              (field) {
                                                                        final displayLabel = field['refKey'] == 1 &&
                                                                                field['depAttribute'] != null
                                                                            ? _capitalize(field['label'])
                                                                            : _capitalize(field['label']);

                                                                        return DataColumn(
                                                                          label:
                                                                              Text(
                                                                            displayLabel,
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 15,
                                                                              color: Get.isDarkMode ? Colors.white : Colors.black,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                      if (childcontroller.isdelete !=
                                                                              0 ||
                                                                          childcontroller.isupdate !=
                                                                              0)
                                                                        DataColumn(
                                                                          label:
                                                                              Text(
                                                                            'Action',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 15,
                                                                              color: Get.isDarkMode ? Colors.white : Colors.black,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                    rows: List<
                                                                        DataRow>.generate(
                                                                      childcontroller
                                                                          .filteredData
                                                                          .length,
                                                                      (rowIndex) {
                                                                        final attribute =
                                                                            childcontroller.filteredData[rowIndex];

                                                                        final dynamicValues = childcontroller
                                                                            .childlabellist
                                                                            .map((label) {
                                                                          if (label['refKey'] == 1 &&
                                                                              label['depAttribute'] != null) {
                                                                            return attribute[label['depAttribute']];
                                                                          }
                                                                          return attribute[
                                                                              label['code']];
                                                                        }).toList();

                                                                        return DataRow(
                                                                          color:
                                                                              WidgetStateProperty.resolveWith<Color?>(
                                                                            (Set<WidgetState> states) => isDarkMode
                                                                                ? (rowIndex.isEven ? Colors.grey[900] : Colors.grey[800])
                                                                                : (rowIndex.isEven ? Colors.white : Colors.grey[200]),
                                                                          ),
                                                                          cells: [
                                                                            ...List.generate(
                                                                              dynamicValues.length,
                                                                              (columnIndex) {
                                                                                final label = childcontroller.childlabellist[columnIndex]['code'];
                                                                                final type = childcontroller.childlabellist[columnIndex]['type'];

                                                                                if (type == 'file') {
                                                                                  final imageId = dynamicValues[columnIndex] ?? 0;
                                                                                  final imageUrl = (imageId != null && imageId != 0 && imageId != "") ? "https://cuickdev.com/API/DOCS/api/doc/th/${imageId}?t=${DateTime.now().millisecondsSinceEpoch}" : imageUrlHelper.applogourl;
                                                                                  return DataCell(
                                                                                    imageUrl.isNotEmpty
                                                                                        ? GestureDetector(
                                                                                            onTap: () async {
                                                                                              final Uri testUrl = Uri.parse(imageUrl);
                                                                                              await launchUrl(testUrl);
                                                                                            },
                                                                                            child: CachedNetworkImage(
                                                                                              imageUrl: imageUrl,
                                                                                              width: 50,
                                                                                              height: 50,
                                                                                              fit: BoxFit.cover,
                                                                                              placeholder: (context, url) => const SizedBox(
                                                                                                width: 24, // Set your desired width
                                                                                                height: 24, // Set your desired height
                                                                                                child: CircularProgressIndicator(),
                                                                                              ),
                                                                                              errorWidget: (context, url, error) => const Icon(Icons.error), // Show an error icon if the image fails to load
                                                                                            ))
                                                                                        : Text('-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                                                                  );
                                                                                }
                                                                                if (type == 'doc') {
                                                                                  final imageId = dynamicValues[columnIndex] ?? 0;

                                                                                  final imageUrl = (imageId != null && imageId != 0 && imageId != "") ? "https://cuickdev.com/API/DOCS/api/doc/th/${imageId}?t=${DateTime.now().millisecondsSinceEpoch}" : imageUrlHelper.applogourl;
                                                                                  return DataCell(
                                                                                    imageUrl.isNotEmpty
                                                                                        ? GestureDetector(
                                                                                            onTap: () async {
                                                                                              var finalimageId = (imageId == null || imageId == 0) ? 0 : imageId;
                                                                                              final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/$finalimageId');
                                                                                              await launchUrl(testUrl);
                                                                                            },
                                                                                            child: CachedNetworkImage(
                                                                                              imageUrl: imageUrl,
                                                                                              width: 50,
                                                                                              height: 50,
                                                                                              fit: BoxFit.cover,
                                                                                              placeholder: (context, url) => const SizedBox(
                                                                                                width: 24, // Set your desired width
                                                                                                height: 24, // Set your desired height
                                                                                                child: CircularProgressIndicator(),
                                                                                              ), // Show a loading indicator while the image is loading
                                                                                              errorWidget: (context, url, error) => const Icon(Icons.error), // Show an error icon if the image fails to load
                                                                                            ))
                                                                                        : Text('-', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                                                                  );
                                                                                } else {
                                                                                  return DataCell(
                                                                                    Text(
                                                                                      dynamicValues[columnIndex]?.toString() ?? '-',
                                                                                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              },
                                                                            ),
                                                                            if (widget.isdelete != 0 ||
                                                                                widget.isupdate != 0)
                                                                              DataCell(
                                                                                Row(
                                                                                  children: [
                                                                                    if (widget.isupdate != 0)
                                                                                      IconButton(
                                                                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                                                                        onPressed: () {
                                                                                          int? itemId = attribute['id']; // Extract the item ID
                                                                                          if (itemId != null) {
                                                                                            Get.to(Editchildform(title: childcontroller.Childtitle.value, editid: itemId, formusecaseid: currentId));
                                                                                          } else {}
                                                                                        },
                                                                                      ),
                                                                                    if (widget.isdelete != 0)
                                                                                      IconButton(
                                                                                        icon: const Icon(Icons.delete, color: Colors.red),
                                                                                        onPressed: () {
                                                                                          int? itemId = attribute['id']; // Extract the item ID
                                                                                          if (itemId != null) {
                                                                                            showchileDeleteConfirmation(itemId, childcontroller.deleteListItem);
                                                                                          } else {}
                                                                                        },
                                                                                      ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                )
                                                              : const SizedBox()
                                                    ]),
                                          const SizedBox(height: 20),
                                          Obx(
                                              () =>
                                                  controller.commentEnabled
                                                              .value ==
                                                          1
                                                      ? Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey[200],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  const Text(
                                                                    "Comments",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      showAddCommentDialog();
                                                                    },
                                                                    child: Container(
                                                                        height: 40,
                                                                        width: 50,
                                                                        decoration: BoxDecoration(
                                                                            color: isDarkMode ? const Color(0xFF4F76E2) : Appcolorblue,
                                                                            border: Border.all(
                                                                              color: Appcolorblue,
                                                                            ),
                                                                            borderRadius: BorderRadius.circular(20)),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .add,
                                                                          size:
                                                                              40,
                                                                          color:
                                                                              Colors.white,
                                                                          // color: Color(0xFF2962FF),
                                                                        )),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 10),
                                                            controller
                                                                    .commentsList
                                                                    .isEmpty
                                                                ? const SizedBox()
                                                                : SingleChildScrollView(
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    physics:
                                                                        const BouncingScrollPhysics(),
                                                                    child:
                                                                        DataTable(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: isDarkMode
                                                                            ? Colors.black
                                                                            : const Color(0xFFF5F5F5),
                                                                      ),
                                                                      border: TableBorder.all(
                                                                          color: isDarkMode
                                                                              ? Colors.white
                                                                              : const Color(0xFFE0E0E0)),
                                                                      columnSpacing:
                                                                          20,
                                                                      dividerThickness:
                                                                          0.2,
                                                                      headingRowHeight:
                                                                          0, // Removes header space
                                                                      columns: const [
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                      ],

                                                                      rows: controller
                                                                          .commentsList
                                                                          .asMap()
                                                                          .entries
                                                                          .map(
                                                                              (entry) {
                                                                        int index =
                                                                            entry.key +
                                                                                1;
                                                                        var commentData =
                                                                            entry.value; // Extracting data dynamically

                                                                        return DataRow(
                                                                            cells: [
                                                                              DataCell(Text(
                                                                                index.toString(),
                                                                                style: TextStyle(
                                                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                                                ),
                                                                              )),
                                                                              // Serial number
                                                                              DataCell(
                                                                                Text(
                                                                                  commentData['comment'] ?? '-',
                                                                                  style: TextStyle(
                                                                                    color: isDarkMode ? Colors.white : Colors.black,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              // Dynamic comment
                                                                              DataCell(
                                                                                Row(
                                                                                  children: [
                                                                                    Tooltip(
                                                                                      message: commentData['userFirstname'] ?? '',
                                                                                      child: CircleAvatar(
                                                                                        backgroundColor: Colors.blue.shade50,
                                                                                        child: Text(
                                                                                          (commentData['userFirstname'] != null && commentData['userFirstname'].isNotEmpty)
                                                                                              ? commentData['userFirstname']!
                                                                                                  .split(' ')
                                                                                                  .where((e) => (e as String).isNotEmpty) // Explicit cast to String
                                                                                                  .map((e) => e[0])
                                                                                                  .join()
                                                                                                  .padRight(2, '-')
                                                                                                  .substring(0, 2)
                                                                                                  .toUpperCase()
                                                                                              : '-',
                                                                                          style: const TextStyle(
                                                                                            color: Colors.blue,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),

                                                                                    const SizedBox(width: 8),
                                                                                    Text(
                                                                                      formatDateview(commentData['modifiedDatetime'] ?? 0),
                                                                                      style: TextStyle(
                                                                                        color: isDarkMode ? Colors.white : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    // Display formatted date
                                                                                  ],
                                                                                ),
                                                                              ),

                                                                              DataCell(Row(
                                                                                children: [
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.info, color: Colors.blue),
                                                                                    onPressed: () {
                                                                                      showCommentInfoPopup(commentData);
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.edit, color: Colors.green),
                                                                                    onPressed: () {
                                                                                      String commentId = commentData["id"].toString();
                                                                                      fetchCommentById(commentId); //
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                                                    onPressed: () {
                                                                                      String commentId = commentData["id"].toString();
                                                                                      showDeleteConfirmation(commentId);
                                                                                    },
                                                                                  ),
                                                                                ],
                                                                              )),
                                                                            ]);
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                          ],
                                                        )
                                                      : const SizedBox
                                                          .shrink()),
                                          const SizedBox(height: 20),
                                          Obx(
                                              () =>
                                                  controller.attachmentEnabled
                                                              .value ==
                                                          1
                                                      ? Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            // Header
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(10),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .grey[200],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  const Text(
                                                                    "Attachments",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      showAddAttachmentDialog(
                                                                          context,
                                                                          isDarkMode);
                                                                    },
                                                                    child: Container(
                                                                        height: 40,
                                                                        width: 50,
                                                                        decoration: BoxDecoration(
                                                                            color: isDarkMode ? const Color(0xFF4F76E2) : Appcolorblue,
                                                                            border: Border.all(
                                                                              color: Appcolorblue,
                                                                            ),
                                                                            borderRadius: BorderRadius.circular(20)),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .add,
                                                                          size:
                                                                              40,
                                                                          color:
                                                                              Colors.white,
                                                                          // color: Color(0xFF2962FF),
                                                                        )),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),

                                                            const SizedBox(
                                                                height: 10),
                                                            controller
                                                                    .attachmentList
                                                                    .isEmpty
                                                                ? const SizedBox()
                                                                : SingleChildScrollView(
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    physics:
                                                                        const BouncingScrollPhysics(),
                                                                    child:
                                                                        DataTable(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: isDarkMode
                                                                            ? Colors.black
                                                                            : const Color(0xFFF5F5F5),
                                                                      ),
                                                                      border:
                                                                          TableBorder
                                                                              .all(
                                                                        color: isDarkMode
                                                                            ? Colors.white
                                                                            : const Color(0xFFE0E0E0),
                                                                      ),
                                                                      columnSpacing:
                                                                          20,
                                                                      dividerThickness:
                                                                          0.2,
                                                                      headingRowHeight:
                                                                          0, // Removes header space

                                                                      columns: const [
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                        DataColumn(
                                                                            label:
                                                                                SizedBox.shrink()), // No header
                                                                      ],

                                                                      // Rows
                                                                      rows: controller
                                                                          .attachmentList
                                                                          .asMap()
                                                                          .entries
                                                                          .map(
                                                                              (entry) {
                                                                        int index =
                                                                            entry.key +
                                                                                1;
                                                                        var attachmentData =
                                                                            entry.value; // Extracting data dynamically
                                                                        final imageUrl =
                                                                            attachmentData['attachmentUrl'];

                                                                        return DataRow(
                                                                            cells: [
                                                                              DataCell(Text(
                                                                                index.toString(),
                                                                                style: TextStyle(
                                                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                                                ),
                                                                              )),
                                                                              // Serial number
                                                                              DataCell(GestureDetector(
                                                                                onTap: () async {
                                                                                  final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/${attachmentData['attachment']}?t=${DateTime.now().millisecondsSinceEpoch}');
                                                                                  // final Uri testUrl = Uri.parse(imageUrl);

                                                                                  await launchUrl(testUrl);
                                                                                },
                                                                                child: Image.network(
                                                                                  imageUrl,
                                                                                  width: 50,
                                                                                  height: 50,
                                                                                  fit: BoxFit.cover,
                                                                                  errorBuilder: (context, error, stackTrace) {
                                                                                    return const Icon(Icons.broken_image, color: Colors.red); // Show error icon if image fails
                                                                                  },
                                                                                ),
                                                                              )),

                                                                              DataCell(
                                                                                Text(
                                                                                  attachmentData['description'] ?? '-',
                                                                                  style: TextStyle(
                                                                                    color: isDarkMode ? Colors.white : Colors.black,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              DataCell(
                                                                                Row(
                                                                                  children: [
                                                                                    Tooltip(
                                                                                      message: attachmentData['userFirstname'] ?? '',
                                                                                      child: CircleAvatar(
                                                                                        backgroundColor: Colors.blue.shade50,
                                                                                        child: Text(
                                                                                          (attachmentData['userFirstname'] != null && attachmentData['userFirstname'].isNotEmpty)
                                                                                              ? attachmentData['userFirstname']!
                                                                                                  .split(' ')
                                                                                                  .where((e) => (e as String).isNotEmpty) // Explicit cast to String
                                                                                                  .map((e) => e[0])
                                                                                                  .join()
                                                                                                  .padRight(2, '-')
                                                                                                  .substring(0, 2)
                                                                                                  .toUpperCase()
                                                                                              : '-',
                                                                                          style: const TextStyle(
                                                                                            color: Colors.blue,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),

                                                                                        /*      child: Text(

                                                                      (attachmentData['userFirstname'] !=
                                                                                  null &&
                                                                              attachmentData['userFirstname']
                                                                                  .isNotEmpty)
                                                                          ? attachmentData['userFirstname']!
                                                                              .split(
                                                                                  ' ')
                                                                              .map((e) =>
                                                                                  e[0])
                                                                              .take(2)
                                                                              .join()
                                                                              .toUpperCase()
                                                                          : '-',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),*/
                                                                                      ),
                                                                                    ),
                                                                                    const SizedBox(width: 8),
                                                                                    Text(
                                                                                      formatDateview(attachmentData['modifiedDatetime'] ?? 0),
                                                                                      style: TextStyle(
                                                                                        color: isDarkMode ? Colors.white : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    // Display formatted date
                                                                                  ],
                                                                                ),
                                                                              ),

                                                                              DataCell(Row(
                                                                                children: [
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.info, color: Colors.blue),
                                                                                    onPressed: () {
                                                                                      showCommentInfoPopup(attachmentData);
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.edit, color: Colors.green),
                                                                                    onPressed: () {
                                                                                      String attachmentId = attachmentData["id"].toString();
                                                                                      onEditPressed(attachmentId);
                                                                                    },
                                                                                  ),
                                                                                  IconButton(
                                                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                                                    onPressed: () {
                                                                                      String attachmentId = attachmentData["id"].toString();
                                                                                      showattachmentDeleteConfirmation(attachmentId);
                                                                                    },
                                                                                  ),
                                                                                ],
                                                                              )),
                                                                            ]);
                                                                      }).toList(),
                                                                    ),
                                                                  ),
                                                          ],
                                                        )
                                                      : const SizedBox
                                                          .shrink()),
                                          const SizedBox(height: 20),
                                        ],
                                      ),
                                    )),
                    ],
                  );
                }),
              ),
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
          ],
        ));
  }

  void showchileDeleteConfirmation(int itemId, Function onDelete) {
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
              onDelete(itemId); // Call delete function
              Get.back(); // Close the dialog after deleting
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Map<String, TextEditingController> _childcontrollers = {};
  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  String formatDateview(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void showImageDialog(String imageUrl) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    Get.back(); // Close Dialog
                  },
                ),
              ),

              // Image Viewer
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image,
                        color: Colors.red); // Show error icon if image fails
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showFile(String fileUrl) {
    // Check file extension (you can extend this for other file types)
    if (fileUrl.endsWith('.pdf')) {
      // Open PDF file using the open_file package
      OpenFile.open(fileUrl);
    } else {
      Get.snackbar("Error", "File type not supported for viewing!",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  final namecontroller = TextEditingController();
  final Emailcontroller = TextEditingController();

  void ShareBottomSheet() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final labelStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );

    // Define a GlobalKey for the form
    final _formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Share Form",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Gilroy',
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Wrap the TextFormFields in a Form widget
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name TextFormField
                  TextFormField(
                    controller: namecontroller,
                    style: labelStyle,
                    decoration: InputDecoration(
                      hintText: 'Enter Name',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        color:
                            isDarkMode ? Colors.white : const Color(0XFF9B9B9B),
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey[850]
                          : const Color(0xFFF5F5F5),
                      contentPadding:
                          const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null; // Return null if the input is valid
                    },
                  ),

                  const SizedBox(height: 10),
                  // Email TextFormField with validation
                  TextFormField(
                    controller: Emailcontroller,
                    style: labelStyle,
                    decoration: InputDecoration(
                      hintText: 'Enter Email',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        color:
                            isDarkMode ? Colors.white : const Color(0XFF9B9B9B),
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey[850]
                          : const Color(0xFFF5F5F5),
                      contentPadding:
                          const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required'; // Validate if the input is empty
                      }

                      // Regular expression for validating an email
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Enter a valid email'; // Validate if the email matches the pattern
                      }

                      return null; // If no validation errors, return null
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "We'll send data in PDF format to this Gmail.",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    color: isDarkMode ? Colors.white : Colors.black26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Share Button
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // If the form is valid, proceed with sending the email
                      if (namecontroller.text != "" &&
                          Emailcontroller.text != "") {
                        Sendmail();
                        Get.back();
                      } else {
                        CherryToast.error(
                          backgroundColor: const Color(0xFFF8D0D9),
                          animationDuration: Durations.short3,
                          animationCurve: Curves.easeInCubic,
                          title: const Text('Fill the Fields',
                              style: TextStyle(color: Colors.black)),
                        ).show(Get.overlayContext!);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(0.0),
                    height: 50.0,
                    width: 120.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Appcolorblue),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0XFF23408F).withOpacity(0.20),
                          blurRadius: 13,
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        LayoutBuilder(builder: (context, constraints) {
                          return Container(
                            height: constraints.maxHeight,
                            width: constraints.maxHeight,
                            decoration: BoxDecoration(
                              color: Appcolorblue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                          );
                        }),
                        const Expanded(
                          child: Text(
                            'Share',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Cancel Button
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(0.0),
                    height: 50.0,
                    width: 120.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0XFF23408F).withOpacity(0.20),
                          blurRadius: 13,
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        LayoutBuilder(builder: (context, constraints) {
                          return Container(
                            height: constraints.maxHeight,
                            width: constraints.maxHeight,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          );
                        }),
                        const Expanded(
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isDismissible: true,
    );
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
}