import 'dart:convert';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/controller/tableview_controller.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/material.dart%20';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/apihelper.dart';
import 'editform_controller.dart';

class Childcontroller extends GetxController {
  var iscreate = 0.obs;
  var isread = 0.obs;
  var isupdate = 0.obs;
  var isdelete = 0.obs;
  var isuserFilter = 0.obs;
  var pagetitle = "".obs;
  var Childtitle = "".obs;
  var childappCode = "".obs;
  RxString updatedName = "".obs;
  var applicationurl = "".obs;
  var UseraccessID = "".obs;
  var filteredData = [].obs;
  var childcode = "".obs;
  var foreignId = "".obs;
  var uploadimage = <String, String?>{}.obs;
  var uploadDocument = <String, String?>{}.obs;
  var imagePaths = <String, String?>{}.obs;
  RxList<GroupLabels> groupchildlabellist = <GroupLabels>[].obs;
  RxList<dynamic> preloadparentUsecases = RxList<dynamic>();
  String? parentKey;
  var saveform_id = 0.obs; // Making it observable
  List<String> globalYUsecases = [];
  Map<String, dynamic> parentChildUsecase = {};
  RxList<dynamic> childlabellist = RxList<dynamic>();
  RxList<Button> childbuttons = <Button>[].obs;
  RxList<Field> childfields = <Field>[].obs;
  HttpServices httpServices = HttpServices();
  RxMap<String, List<dynamic>> prelaodlist = RxMap<String, List<dynamic>>();
  RxMap<String, String> initialValues = <String, String>{}.obs;
  final RxMap<String, String> _fieldValues = <String, String>{}.obs;
  final EditformController controller = Get.put(EditformController());
  var dataMap = <String, dynamic>{}.obs;
  var dataMapdata = <String, dynamic>{}.obs;
  var collectionName = "".obs;
  String? admissionId;
  Map<String, dynamic>? previousResponse;
  final ApiBaseHelper helper = ApiBaseHelper();

  Future<void> GetForm_API(String id) async {
    childfields.clear();
    childbuttons.clear();
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;

      saveformcode.value = data!.code.toString();
      saveformcode.value = data.code.toString();
      Childtitle.value = data.title;
      childfields.assignAll(data.fields);
      childbuttons.assignAll(data.buttons);
      childformid = data.id.toString();
      await getuser_role_access(data.id.toString());
      await Getchilditemcode(data.userstoryId.toString());

      update();
    } else {}
  }

  List getGroupsField(String label) {
    return childlabellist.where((field) => field['group'] == label).toList();
  }

  List getItemsWithoutGroup() {
    return childlabellist
        .where((field) => field['group'] == "" || field['group'] == null)
        .toList();
  }

  void setInitialValue(String code, dynamic value) {
    dataMap[code] = value;
    update();
  }

  dynamic getFieldValue(String label) {
    return _fieldValues[label];
  }

  void setFieldValue(String label, dynamic value) {
    _fieldValues[label] = value;
    update();
  }

  void clearInitialValue(String code) {
    initialValues.remove(code);
    dataMap.remove(code);
    update();
  }

  Future<void> getuser_role_access(String formID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String applicationRoleId = prefs.getString("applicationRoleId") ?? '';

    var res = await httpServices.getUserAccess(
      formId: formID,
      applicationRoleId: applicationRoleId,
    );

    if (res != null && res['success'] == true) {
      var userAccesslist = res['result']['data'];

      if (userAccesslist.isNotEmpty) {
        var firstAccess = userAccesslist[0]; // Get first index
        UseraccessID.value = firstAccess['createdBy'].toString();
        iscreate.value = firstAccess['create'] ?? 0;
        isread.value = firstAccess['read'] ?? 0;
        isupdate.value = firstAccess['update'] ?? 0;
        isdelete.value = firstAccess['delete'] ?? 0;
        isuserFilter.value = firstAccess['userFilter'] ?? 0; // If available
      } else {}
    } else {}
  }

  String? childformid;

  var saveformcode = "".obs;
  var saveuserstoryid = 0.obs;
  var recordidcode = 0.obs;

  Future<void> getchildlist(int recordid) async {
    if (controller.ChildFormlist.isNotEmpty) {




      for (var selectedForm in controller.ChildFormlist) {
        Map<String, dynamic> usecase = {
          "collectionName": selectedForm.code,
          "parentUsecases": {} // Populate if necessary
        };
        recordidcode.value = recordid;
        saveformcode.value = selectedForm!.code.toString();
        Childtitle.value = selectedForm.title;
        saveuserstoryid.value =selectedForm.userstoryId;
        childfields.assignAll(selectedForm.fields);
        childbuttons.assignAll(selectedForm.buttons);
        childformid = selectedForm.id.toString();
        await   GetForm_API(childformid!);
        await getuser_role_access(selectedForm.id.toString());
        await Getchilditemcode(selectedForm.userstoryId.toString());
        await getUiFormDatas(usecase, selectedForm.userstoryId.toString(), recordidcode.value);
      }
    }
  }

  void setInitialValues(String fieldCode, dynamic label) {
    if (!dataMap.containsKey(fieldCode)) {
      return; // Exit if the key doesn't exist
    }

    var value = dataMap[fieldCode];

    // Ensure value is stored correctly
    if (value is int || value is double) {
      setFieldValue(label, value.toString());
      setInitialValue(label, value.toString());
    } else {
      setFieldValue(label, value);
      setInitialValue(label, value);
    }
  }

  dynamic getInitialValues(String fieldCode, String label) {
    // print('Fetching initial value for field code: $fieldCode');
    if (dataMap.containsKey(fieldCode)) {
      var value = dataMap[fieldCode];
      setFieldValue(label, value.toString());
      setInitialValue(label, value.toString());
      if (value is int) {
        setFieldValue(label, value.toString());
        setInitialValue(label, value.toString());
        return value.toString();
      }
      return value;
    }
    return null;
  }
  Map<String, dynamic> searchParams ={};
  Future<void> getUiFormDatas(
      Map<String, dynamic> usecase, String usecaseId, int recordid) async {
    updatedName.value = usecase['collectionName'].replaceAll('.', '/');
    searchParams = {

    };

    if (usecase.containsKey('parentUsecases') && parentChildUsecase != null) {
      if (parentChildUsecase.containsKey(controller.collectionName.value)) {
        parentKey = parentChildUsecase[controller.collectionName.value]['id'];

        if (parentKey != null) {
          // searchParams[parentKey!] = controller.foreignId.value;
          searchParams[parentKey!] = recordid;
        }
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';
    try {
      final response = await helper.postApi(
          "api/v1/${childappCode.value}/${childcode.value}/search;jsessionid=$jsessionid",
          searchParams);

      var data = response['result']['data'];

      filteredData.assignAll(data);

      await Getchildattributefield(usecaseId);
    } catch (e) {
      print("Error: $e");
    }
  }

  Getlistdata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';
    try {
      final response = await helper.postApi(
          "api/v1/${childappCode.value}/${childcode.value}/search;jsessionid=$jsessionid",
          searchParams);

      var data = response['result']['data'];

      filteredData.assignAll(data);
update();
      await Getchildattributefield(saveuserstoryid.value.toString());
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> deleteListItem(int itemId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';
    String aPPmAINuRL = "https://api.ncsindore.com/api/v1";

    String url =
        "$aPPmAINuRL/${updatedName.value}/delete/$itemId;jsessionid=$jsessionid";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        CherryToast.success(
          backgroundColor: Color(0xFFDDF4DE),
          animationDuration: Durations.short1,
          title: const Text("Item deleted successfully",
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
        filteredData.removeWhere((item) => item['id'] == itemId);
        filteredData.refresh(); // Refresh UI using GetX
      } else {
        CherryToast.error(
          backgroundColor: Color(0xFFF8D0D9),
          animationDuration: Durations.short3,
          animationCurve: Curves.easeInCubic,
          title: const Text('Failed to delete item.',
              style: TextStyle(color: Colors.black)),
        ).show(Get.overlayContext!);
      }
    } catch (e) {
      print("Error deleting item: $e");
    }
  }

  Future<void> Getchildattributefield(String formId) async {
    childlabellist.clear();

    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data']; // Update labellist

      var sortedFilteredList = filteredList.where((label) {
        return childfields
            .any((field) => field.id.toString() == label['id'].toString());
      }).toList();

      sortedFilteredList.sort((a, b) {
        int indexA = childfields
            .indexWhere((field) => field.id.toString() == a['id'].toString());
        int indexB = childfields
            .indexWhere((field) => field.id.toString() == b['id'].toString());
        return indexA.compareTo(indexB);
      });

      // Add the `show` field to the sortedFilteredList
      for (var item in sortedFilteredList) {
        var matchingField = childfields.firstWhere(
          (field) => field.id.toString() == item['id'].toString(),
        );

        if (matchingField != "") {
          item['show'] =
              matchingField.show ?? ''; // Add the `show` field from `fields`
          item['group'] =
              matchingField.group ?? ''; // Add the `show` field from `fields`
          item['event'] = matchingField.event ?? '';
          item['rule'] = matchingField.rule ?? '';
          item['label'] = matchingField.label ?? '';
          item['parentFilter'] = matchingField.parentFilter ?? '';
        }
      }

      if (sortedFilteredList.isNotEmpty) {
        childlabellist.assignAll(sortedFilteredList);

      } else {}

      var uniqueUsecases = <String>{};
      for (var dashboardItem in childlabellist) {
        String yUsecase = dashboardItem['primaryUsecase'] ?? "";

        if (yUsecase.isNotEmpty) {
          uniqueUsecases.add(yUsecase);
        } else {}
      }

      for (var labellist in childlabellist) {
        if (labellist['code'] == parentKey) {
          setFieldValue(labellist['label']!, recordidcode.value.toString());
          break;
        }
      }
      globalYUsecases = uniqueUsecases.toList(); // For multiple values
      Getpreloadfield(childcode.value);
    }
  }

  Future<void> Getchilditemcode(String formid) async {
    var res = await httpServices.GetListusecase(
      id: formid,
    );

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data']; // Cast to List<dynamic>
      parentChildUsecase = dataResponse['parentUsecases'];
      childcode.value = dataResponse['code'];
      childappCode.value = dataResponse['appCode'];
      if (dataResponse['parentUsecases'] is Map<String, dynamic>) {
        // Convert the map to a list of entries
        preloadparentUsecases.assignAll(
          dataResponse['parentUsecases'].entries.map((entry) {
            return {'key': entry.key, 'value': entry.value};
          }).toList(),
        );
      } else if (dataResponse['parentUsecases'] is List) {
        preloadparentUsecases.assignAll(dataResponse['parentUsecases']);
      } else {}

      GetdataList(childappCode.value, childcode.value);
      update();
    } else {}
  }

  Future<void> GetdataList(String formname, String id) async {
    dataMap.clear();
    var res = await httpServices.GetFormdata(
      formname: childappCode.value,
      appurl: childcode.value,
      formId: id.toString(),
    );
    if (res?['success'] == true) {
      var dataResponse = res?['result'];

      print('dataResponse=====GetdataList=====GetdataList==>>${dataResponse}');
      if (dataResponse != null && dataResponse['data'] is Map) {
        dataMap.assignAll(dataResponse['data']);

        update();
      } else {
        dataMap.clear();
        update();
      }
    } else {}
  }

  Future<void> Getpreloadfield(String name) async {
    var res = await httpServices.Getpreloaddata(
        formname: name, appurl: controller.appCode.value);
    if (res != null && res['success'] == true) {
      var result = res['result'] ?? {};

      var useCases = globalYUsecases;
      prelaodlist.clear();
      for (var useCase in useCases) {
        if (result.containsKey(useCase)) {
          var data = result[useCase];
          if (data is List) {
            prelaodlist[useCase] =
                List.from(data); // Assign data to the specific use case
          } else {}
        } else {}
      }
    } else {}
  }

  bool evaluateCondition(Map<String, String> reqBody, String condition) {
    try {
      if (condition.isEmpty) {
        return true; // If no condition, always show the field
      }

      // Regex to match potential placeholders not inside quotes
      final placeholderRegex = RegExp(r'(?<!")\b\w+\b(?!")');

      // Replace only placeholders in the condition that exist in reqBody
      String parsedCondition = condition;
      parsedCondition =
          parsedCondition.replaceAllMapped(placeholderRegex, (match) {
        String key = match.group(0)!;
        return reqBody.containsKey(key) ? '"${reqBody[key]}"' : key;
      });

      // Evaluate the parsed condition
      final bool result = _evaluateExpression(parsedCondition);

      return result;
    } catch (e) {
      print("Error evaluating condition: $condition, Error: $e");
      return false;
    }
  }

  bool _evaluateExpression(String expression) {
    try {
      // Check for equality (==)
      if (expression.contains('==')) {
        final parts = expression.split('==').map((e) => e.trim()).toList();
        // Convert numeric strings to numbers for comparison if possible
        final left = _parseToComparable(parts[0]);
        final right = _parseToComparable(parts[1]);
        return left == right;
      }
      // Check for inequality (!=)
      if (expression.contains('!=')) {
        final parts = expression.split('!=').map((e) => e.trim()).toList();
        final left = _parseToComparable(parts[0]);
        final right = _parseToComparable(parts[1]);
        return left != right;
      }
      // Comparison operators (>=, <=, >, <)
      if (expression.contains('>=')) {
        final parts = expression.split('>=').map((e) => e.trim()).toList();
        return (double.tryParse(parts[0]) ?? 0) >=
            (double.tryParse(parts[1]) ?? 0);
      }
      if (expression.contains('<=')) {
        final parts = expression.split('<=').map((e) => e.trim()).toList();
        return (double.tryParse(parts[0]) ?? 0) <=
            (double.tryParse(parts[1]) ?? 0);
      }
      if (expression.contains('>')) {
        final parts = expression.split('>').map((e) => e.trim()).toList();
        return (double.tryParse(parts[0]) ?? 0) >
            (double.tryParse(parts[1]) ?? 0);
      }
      if (expression.contains('<')) {
        final parts = expression.split('<').map((e) => e.trim()).toList();
        return (double.tryParse(parts[0]) ?? 0) <
            (double.tryParse(parts[1]) ?? 0);
      }
      // Default to false for invalid expressions
      return false;
    } catch (e) {
      print("Error evaluating expression: $expression, Error: $e");
      return false;
    }
  }

  dynamic _parseToComparable(String value) {
    value = value.replaceAll('"', '').trim(); // Remove quotes
    return double.tryParse(value) ??
        value; // Convert to number if possible, else keep as string
  }

  Future<Map<String, dynamic>?> validateAndSubmitDate(
      String rule, String dischargeDate) async {
    try {
      Map<String, dynamic> reqBody = {
        "admissionId": admissionId,
        "collectionName": collectionName.value,
      };

      if (previousResponse != null) {
        // Add only the keys from previousResponse that are not admissionId or collectionName
        previousResponse!.forEach((key, value) {
          if (key != "admissionId" && key != "collectionName") {
            reqBody[key] = value;
          }
        });
      }
      reqBody['dischargeDate'] = dischargeDate; // Add/overwrite dischargeDate

      // Make API call for validation
      var res = await httpServices.Getexecutedata(
        rule: rule, // Use the current rule
        reqBody: reqBody, // Pass the constructed payload
      );

      return res;
    } catch (e, stackTrace) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetUserData(
      String code, String rule, String admissionId) async {
    try {
      // Prepare payload based on previous response
      Map<String, dynamic> reqBody = {
        code: admissionId,
        "collectionName": collectionName.value,
      };

      if (previousResponse != null) {
        // Add only the keys from previousResponse that are not admissionId or collectionName
        previousResponse!.forEach((key, value) {
          if (key != code && key != "collectionName") {
            reqBody[key] = value;
          }
        });
      }

      // Fetch data from API
      var res = await httpServices.Getexecutedata(
        rule: rule,
        reqBody: reqBody, // Pass the prepared payload here
      );

      // Log API response

      // Validate and update the dataMap
      if (res != null && res['success'] == true && res['result'] != null) {
        var resultData = res['result'];

        resultData.forEach((key, value) {
          if (dataMap.containsKey(key)) {
            dataMap[key] = value;
          }
        });

        previousResponse = dataMap;
        update();
      } else {
        debugPrint(
          'Failed to fetch data. Success: ${res?['success']}, Result: ${res?['result']}',
        );
      }

//       if (res != null && res['success'] == true && res['result'] != null) {
//         var resultData = res['result'];
// print('DataMap=====Before========>>${dataMap}');
//         // Check if resultData is a valid Map
//         dataMap.assignAll(resultData);
//         print('DataMap=======After======>>${dataMap}');
//         previousResponse = dataMap;
//         update();
//       } else {
//         debugPrint(
//           'Failed to fetch data. Success: ${res?['success']}, Result: ${res?['result']}',
//         );
//       }

      return res;
    } catch (e, stackTrace) {}
    return null;
  }

  // Get-ParentFilter-data
  void addParentFilter() {
    // Check if form or form.data or form.data.fields is null
    final datafields = childfields
        .where((field) =>
            field.parentFilter != null && field.parentFilter.isNotEmpty)
        .toList();

    // Get the code from the first field
    final code = datafields.isNotEmpty ? datafields[0].code : null;
    if (code == null) return;
    // Variables to hold the matching use case and key
    dynamic matchingUsecase;
    String? matchingKey;

    if (preloadparentUsecases.isNotEmpty) {
      for (final parentUsecase in preloadparentUsecases) {
        // Ensure the element is a map
        if (preloadparentUsecases.isNotEmpty) {
          for (final parentUsecase in preloadparentUsecases) {
            // Ensure the element is a Map<String, dynamic>
            if (parentUsecase is Map<String, dynamic>) {
              // Iterate over the key-value pairs of the map
              for (final entry in preloadparentUsecases) {
                final key = entry['key']; // Access the 'key'
                final value =
                    entry['value']; // Access the 'value' (the nested map)
                if (value is Map<String, dynamic>) {
                  final nestedValue = value;
                  if (nestedValue['id'] == code) {
                    matchingKey = key;
                    processParentFilterAndCallApi(
                        datafields[0].parentFilter, matchingKey!);
                  }
                }
              }
            } else {
              debugPrint(
                  'Invalid parentUsecase type: ${parentUsecase.runtimeType}');
            }
          }
        } else {
          debugPrint('Preload parentUsecases list is empty.');
        }
      }
    } else {
      debugPrint('Preload parentUsecases list is empty.');
    }
  }

  // Get-ParentFilter-data API
  Future<void> processParentFilterAndCallApi(
      String parentFilter, String matchingKey) async {
    List<String> parts = matchingKey.split(".");

    String hrStatus = parts[1]; // The value at index 1
    if (parentFilter.isEmpty) return;

    Map<String, String> filterParams = {};

    List<String> pairs = parentFilter.split('&');

    for (String pair in pairs) {
      List<String> keyValue = pair.split('=').map((e) => e.trim()).toList();

      if (keyValue.length == 2) {
        filterParams[keyValue[0].replaceFirst('@', '')] = keyValue[1];
      }
    }

    if (prelaodlist.isEmpty) {
      getdata(hrStatus, parentFilter);
    }
  }

  Future<void> getdata(String hrStatus, String filterParams) async {
    prelaodlist.clear();
    try {
      var response = await httpServices.getParentFilterData(
          appCode: childappCode.value, hrStatus: hrStatus, val: filterParams);

      if (response?['success'] == true) {
        var useCases = globalYUsecases;
        var result = response?['result'];

        for (var useCase in useCases) {
          if (result.containsKey(useCase)) {
            var data = result[useCase];
            if (data is List) {
              prelaodlist[useCase] =
                  List.from(data); // Assign data to the specific use case

              print('=length==========>${prelaodlist.length}');
            } else {}
          } else {}
        }
        update();
      }
    } catch (e) {
      debugPrint('Error calling API: $e');
    }
  }
}
