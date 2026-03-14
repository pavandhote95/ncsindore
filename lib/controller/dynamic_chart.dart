import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/Menucontroller.dart';


class Dynamic_chart extends GetxController {

  HttpServices httpServices = HttpServices();
  RxList<dynamic> labellist = RxList<dynamic>();
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  String appname = "";
  String menu = "";
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;
  var list = <Map<String, dynamic>>[].obs;
  var applicationurl = "".obs;
  var code = "".obs;
  var appCode = "".obs;
  var collectionName = "".obs;
  var iscreate = 0.obs;
  var isread = 0.obs;
  var isupdate = 0.obs;
  var isdelete = 0.obs;
  var isuserFilter = 0.obs;
  RxMap<String, double> chartData = <String, double>{}.obs; // RxMap initialization

  final List<String> allowedTypes = [
    'date',
    'time',
    'list',
  ];

  Future<void> GetdataList(String field, String url, String selectedfeield) async {

    var res = await httpServices.GetList(
      field: field.toLowerCase(), url: url, currentPage: 0, isuserFilter: isuserFilter.value,);

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data'] as List; // Cast to List<dynamic>

      list.assignAll(
          dataResponse.map((item) => item as Map<String, dynamic>).toList());

      calculateChartData(selectedfeield);
    } else {

    }
  }

  void calculateChartData(String selectedField) {

    chartData.clear();

    for (var item in list) {
      String key = item[selectedField]?.toString() ?? 'Unknown'; // Handle null
      if (chartData.containsKey(key)) {
        chartData[key] = chartData[key]! + 1;
      } else {
        chartData[key] = 1;
      }
    }

  }
  Future<void> Getattributefield(String formId) async {

    var res = await httpServices.Getlistattribute(formId: formId);

    if (res!['success'] == true) {

      var filteredList = res['result']['data'];

      // Update labels in attributelist using fields list
      filteredList.forEach((attribute) {
        // Find the field that matches the code in attribute
        var matchingFields = fields.where(
              (field) => field.code == attribute['code'],
        ).toList(); // Convert the iterable to a list

        // Check if a matching field is found
        if (matchingFields.isNotEmpty) {
          var field = matchingFields.first; // Get the first matching field
          attribute['label'] = field.label; // Update the label in attributelist
        }
      });


      List<dynamic> depAttributeValues = filteredList
          .where((e) => e.containsKey('depAttribute') && e['depAttribute'] != null)
          .map((e) => e['depAttribute'].toString())
          .toList();



      if (filteredList.isNotEmpty) {
        filterlabellist.assignAll(
          filteredList.where((e) {
            bool isAllowedType = allowedTypes.contains(e['type']);


            bool hasMatchingCode = depAttributeValues.contains(e['code']);

            return hasMatchingCode || isAllowedType;
          }).toList(),
        );


      }

      update();
    }
  }
  Future<void> GetForm_API(String id) async {
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;
      appname = res!.data.applicationName.toLowerCase();
      menu = res.data.userstoryName.toLowerCase();
      buttons.assignAll(data!.buttons);
      fields.assignAll(data.fields);
      await Getitemcode(data.userstoryId.toString());
      await Getattributefield(data.userstoryId.toString());
    } else {
    }
  }
  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(
      id: formid,
    );
    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data']; // Cast to List<dynamic>

      code.value = dataResponse['code'];
      appCode.value = dataResponse['appCode'];
      collectionName.value = dataResponse['collectionName'];

      update();
    } else {}
  }
  Future<void> GetChart_API(String type, String appname, String field) async {
    chartData.clear();
    var res = await httpServices.Getchartdata(
        type: 'data',  appname: collectionName.value, menu: field);
    if (res?['success'] == true) {
      var result = res?['result'];
      var data = result['data'];

      chartData.value = (data as Map<String, dynamic>).map<String, double>((key, value) {
        double parsedValue;
        if (value is int) {
          parsedValue = value.toDouble();
        } else if (value is double) {
          parsedValue = value;
        } else if (value is String) {
          parsedValue = double.tryParse(value) ?? 0.0; // Convert string to double safely
        } else {
          parsedValue = 0.0; // Default value for unexpected types
        }
        return MapEntry(key, parsedValue);
      }
      );


    } else {
    }
  }

  Future<void> getuser_role_access(String formID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String applicationRoleId =prefs.getString("applicationRoleId") ?? '';

    var res = await httpServices.getUserAccess(
      formId: formID,
      applicationRoleId: applicationRoleId,
    );

    if (res != null && res['success'] == true) {
      var userAccesslist = res['result']['data'];

      if (userAccesslist.isNotEmpty) {
        var firstAccess = userAccesslist[0]; // Get first index

        iscreate.value = firstAccess['create'] ?? 0;
        isread.value = firstAccess['read'] ?? 0;
        isupdate.value = firstAccess['update'] ?? 0;
        isdelete.value = firstAccess['delete'] ?? 0;
        isuserFilter.value = firstAccess['userFilter'] ?? 0; // If available

      } else {
      }
    } else {
    }
  }
}
