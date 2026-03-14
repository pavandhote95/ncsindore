import 'dart:convert';
import 'package:cuickdevuser/service/apihelper.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/form_response.dart';

class Reportcontroller extends GetxController {
  final ApiBaseHelper helper = ApiBaseHelper();
  HttpServices httpServices = HttpServices();

  var code = "".obs;
  var appCode = "".obs;
  var chart = "".obs;
  var pivotchart = ''.obs;

  RxList<dynamic> filterlabellist = RxList<dynamic>();
  RxList<dynamic> labellist = RxList<dynamic>();
  var dataRows = <Map<String, dynamic>>[].obs; //
  var chartType = "".obs;
  var title = "".obs;
  var values = <String>[].obs;
  var indexFields = <String>[].obs;
  var columnFields = <String>[].obs;
  var numericFields = <String>[].obs;
  var aggfunc = <String, String>{}.obs;
  final RxMap<String, String> _fieldValues = <String, String>{}.obs;
  RxMap<String, List<dynamic>> prelaodlist = RxMap<String, List<dynamic>>();
  var userstoryName = "".obs;
  @override
  void onInit() {
    super.onInit();
  }
  dynamic getFieldValue(String label) {
    return _fieldValues[label];
  }
  void setFieldValue(String label, dynamic value) {

    _fieldValues[label] = value;
    update();
  }
  List<dynamic> initialData = [];
  List<dynamic> initialrowData = [];

  Future<void> updateChartData(Map<String, dynamic> dataJson) async {
    chartType.value = dataJson["chart_type"];
    title.value = dataJson["title"];
    values.value = List<String>.from(dataJson["values"] ?? []);
    indexFields.value = List<String>.from(dataJson["index"] ?? []);
    columnFields.value = List<String>.from(dataJson["columns"] ?? []);
    numericFields.value = List<String>.from(dataJson["numericfields"] ?? []);
    aggfunc.value = Map<String, String>.from(dataJson["aggfunc"] ?? {});


    initialrowData = dataJson["data"];

    dataRows.assignAll(
        (dataJson["data"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
    );

    if(dataRows.isNotEmpty){
      await Getpivotchart(dataRows);
    }
    update();
  }
  void clearChartData() {
    chartType.value = '';  // Or null, depending on your preference
    title.value = '';
    values.value = [];
    indexFields.value = [];
    columnFields.value = [];
    numericFields.value = [];
    aggfunc.value = {};
    update();
  }

  Future<void> Getreportdatavalue(String id) async {
    var res = await httpServices.Getreportdata(id: id);
    clearChartData();
    if (res != null && res['success'] == true) {
      var dataResponse = res['result'];

      var dataJson = dataResponse['data']['dataJson'];
      if (dataJson is Map<String, dynamic>) {
        updateChartData(dataJson);
      } else {
        print("Unexpected data format: $dataJson");
      }

      // updateChartData(dataJson);
      chart.value = dataJson["chart_type"];
      await GetForm_API(dataResponse['data']['uiFormId'].toString());
    } else {
      debugPrint("Error fetching report data.");
    }
  }
  List<String> globalYUsecases = []; // For m
  Future<void> Getpreloadfield(String name) async {

    String formname = "";
    formname = code.value;
    var res = await httpServices.Getpreloaddata(
        formname: formname, appurl: appCode.value);
    if (res != null && res['success'] == true) {
      var result = res['result'] ?? {}; // Ensure result is a Map
      var useCases = globalYUsecases; // A List<String> containing keys like "fbnc.state", "fbnc.country"
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
    } else {

    }
  }
  RxList<Field> fields = <Field>[].obs;
  Future<void> GetForm_API(String id) async {
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;
      fields.assignAll(data!.fields);
      userstoryName.value = data!.userstoryName.toString();
      await Getattributefield(data.userstoryId.toString());
      await filteredlist(data.userstoryId.toString());
      await Getitemcode(data.userstoryId.toString());
      update();
    } else {
      debugPrint("Error in Get_Form_Data.");
    }
  }
  RxList<dynamic> filterlist = RxList<dynamic>();
  final List<String> iwantallowedTypes = [
    'text',
    'textarea',
    'long',
    'date',
    'number',
    'object',
    'email',
    'time',
    'url',
    'map',
    'textarea',
    'list',
    'decimal',
    'expression',
  ];
  final List<String> allowedTypes = [
    'text',
    'date',
    'number',
    'object',
    'email',
    'time',
    'url',
    'map',
    'textarea'
        'phone'
  ];
  final List<String> groupbyallowedTypes = [
    'text',
    'date',
    'object',
    'textarea',
    'number',
    'email',
    'time',
    'url',
    'map',
    'list',
  ];


  String? selectedCondition;
  String? selectedField;

  final List<Map<String, String>> conditions = [
    {'value': 'EQ', 'label': '='},
    {'value': 'NEQ', 'label': '!='},
    {'value': 'GT', 'label': '>'},
    {'value': 'LT', 'label': '<'},
    {'value': 'GTE', 'label': '>='},
    {'value': 'LTE', 'label': '<='},
    {'value': 'LIKE', 'label': 'like'},
  ];
  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(id: formid);

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data'];
      code.value = dataResponse['code'];
      appCode.value = dataResponse['appCode'];
      update();
    } else {
      debugPrint("Error in Getitemcode.");
    }
  }

  Future<void> Getattributefield(String formId) async {
    labellist.clear();
    filterlabellist.clear();
    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data'];

      labellist.assignAll(filteredList);
      filterlabellist.assignAll(labellist.where((e) => e['refKey'] != 1).toList());
      var uniqueUsecases = <String>{};

      for (var dashboardItem in labellist) {
        String yUsecase = dashboardItem['primaryUsecase'] ?? ""; // Check if primaryUsecase exists, else default to empty string

        if (yUsecase.isNotEmpty) {
          uniqueUsecases
              .add(yUsecase); // Add to the Set (duplicates are ignored)
        } else {}
      }

      globalYUsecases = uniqueUsecases.toList(); // For multiple values
      Getpreloadfield(userstoryName.value.toLowerCase());
      update();
    }
  }
  Future<void> filteredlist(String formId) async {

    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      List<Map<String, dynamic>> attributeList = List<Map<String, dynamic>>.from(res!['result']['data']);

      // 1. Add label from fields
      attributeList.forEach((attribute) {
        var matchingField = fields.firstWhereOrNull((field) => field.code == attribute['code']);
        if (matchingField != null) {
          attribute['label'] = matchingField.label;
        }
      });



      //  2. Collect all depAttribute values
      Set<String> depAttrValues = attributeList
          .where((attr) => attr['depAttribute'] != null)
          .map((attr) => attr['depAttribute'] as String)
          .toSet();



      // 3. Keep attributes whose code is in depAttrValues OR no depAttribute at all
      List<Map<String, dynamic>> filteredAttributes = attributeList
          .where((attr) => depAttrValues.contains(attr['code']) || attr['depAttribute'] == null)
          .toList();



      filterlist.assignAll(
        filteredAttributes.where((e) => iwantallowedTypes.contains(e['type'])).toList(),
      );

      } else {}

      update();


  }
  Future<Map<String, dynamic>?> Getreportseachdata(
    List<Map<String, String>> addedFilters) async {
  dataRows.clear();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String sessionId = prefs.getString('jsessionid') ?? '';

  if (sessionId.isEmpty) {
    return {'success': false, 'message': 'Session ID is missing'};
  }

  List<Map<String, dynamic>> normalizedFilters = addedFilters.map((filter) {
  return {
    'field': filter['field']?.toString() ?? '',             // always string
    'value': int.tryParse(filter['value']?.toString() ?? '') ??
             filter['value']?.toString() ?? '',            // int if possible, else string
    'condition': filter['condition']?.toString() ?? 'EQ',   // always string
  };
}).toList();

Map<String, dynamic> reqBody = {
  "searchList": normalizedFilters,
};


  debugPrint("Request Body: ${jsonEncode(reqBody)}"); // ✅ log JSON
  try {
    final response = await helper.postApi(
      "api/v1/${appCode.value}/${code.value}/searchCriteria;jsessionid=$sessionId",
      reqBody, // ✅ pass Map, not json string
    );

    if (response != null && response['success'] == true) {
      var responseData = response['result']['data'] as List<dynamic>;
      initialData = responseData.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();

      final allowedKeysMap = {
        for (var attr in filterlabellist)
          if (attr['code'] != null && attr['label'] != null)
            attr['code']: attr['label']
      };

      dataRows.assignAll(initialData.map((item) {
        final sanitizedItem = <String, dynamic>{};
        for (var key in item.keys) {
          if (allowedKeysMap.containsKey(key)) {
            sanitizedItem[allowedKeysMap[key]] = item[key];
          }
        }

        Map<String, dynamic> filteredSanitizedItem = {
          for (var key in initialrowData.first.keys)
            if (sanitizedItem.containsKey(key)) key: sanitizedItem[key],
        };

        return filteredSanitizedItem;
      }).toList());

      update();

      if (dataRows.isNotEmpty) {
        await Getpivotchart(dataRows);
      } else {
        debugPrint("dataRows is empty, pivotchart API won't be called.");
      }

      return response;
    } else {
      if (response?['message'] == "Record not found") {
        Get.defaultDialog(
          title: "Error",
          middleText: "Record not found",
          textConfirm: "OK",
          onConfirm: () {
            Get.back();
          },
        );
      } else {
        debugPrint("Error: ${response?['message'] ?? 'Unknown error'}");
      }
      return response;
    }
  } catch (e) {
    debugPrint("Error in Getreportseachdata: $e");
    return {'success': false, 'message': 'Error occurred in search data'};
  }
}

  Future<Map<String, dynamic>?> Getseachdata(String url, String menutitle, Map<String, dynamic> bodydata ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      return {'success': false, 'message': 'Session ID is missing'};
    }
    // Map<String, String> reqBody = {};


    Map<String, dynamic> reqBody = bodydata.isNotEmpty ? bodydata : {};


    dataRows.clear();
    try {
      final response = await helper.postApi(
        "api/v1/${appCode.value}/${code.value}/searchCriteria;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        var responseData = response['result']['data'] as List<dynamic>;

        if (filterlabellist.isEmpty) {
          debugPrint("filterlabellist is empty, no valid mapping will be created.");
        }

        final allowedKeysMap = {
          for (var attr in filterlabellist)
            if (attr['code'] != null && attr['label'] != null)
              attr['code']:attr['label']

        };

        dataRows.assignAll(responseData.map((item) {
          final sanitizedItem = <String, dynamic>{};
          allowedKeysMap.forEach((key, label) {
            if (item.containsKey(key)) {
              sanitizedItem[label] = item[key];
            }
          });
          return sanitizedItem;
        }).toList());
        update();

        if (dataRows.isNotEmpty  && dataRows != []) {
          await Getpivotchart(dataRows);
        } else {
          debugPrint("dataRows is empty, pivotchart API won't be called.");
        }

        return response;
      } else {
        debugPrint("Error: ${response?['message'] ?? 'Unknown error'}");
        return response;
      }
    } catch (e) {
      debugPrint("Error in Getseachdata: $e");
      return {'success': false, 'message': 'Error occurred in search data'};
    }
  }
  Future<Map<String, dynamic>?> Getseachreportdata(String fieldCode, dynamic  fieldValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      return {'success': false, 'message': 'Session ID is missing'};
    }

    Map<String, dynamic> reqBody = {
      fieldCode: int.tryParse(fieldValue.toString()) ?? fieldValue,
      "pageSize": "50"
    };
    dataRows.clear();
    try {
      final response = await helper.postApi(
        "api/v1/${appCode.value}/${code.value}/search/0;jsessionid=$sessionId",
        reqBody,
      );
      if (response != null && response['success'] == true) {
        var responseData = response['result']['data'] as List<dynamic>;
        if (filterlabellist.isEmpty) {
          debugPrint("filterlabellist is empty, no valid mapping will be created.");
        }

        final allowedKeysMap = {
          for (var attr in filterlabellist)
            if (attr['code'] != null && attr['label'] != null)
              attr['code']:attr['label']

        };

        dataRows.assignAll(responseData.map((item) {
          final sanitizedItem = <String, dynamic>{};
          allowedKeysMap.forEach((key, label) {
            if (item.containsKey(key)) {
              sanitizedItem[label] = item[key];
            }
          });
          return sanitizedItem;
        }).toList());
        update();


        if (dataRows.isNotEmpty  && dataRows != []) {
          await Getpivotchart(dataRows);
        } else {
          debugPrint("dataRows is empty, pivotchart API won't be called.");
        }

        return response;
      } else {
        debugPrint("Error: ${response?['message'] ?? 'Unknown error'}");
        return response;
      }
    } catch (e) {
      debugPrint("Error in Getseachdata: $e");
      return {'success': false, 'message': 'Error occurred in search data'};
    }
  }




  Future<void> Getpivotchart(List<Map<String, dynamic>> dataRowsdata) async {
    if (dataRowsdata.isEmpty) {
      debugPrint("Skipping Getpivotchart because dataRowsdata is empty.");
      return;
    }
    pivotchart.value = "";

    Map<String, dynamic> reqBody = {
      "margins": true,
      "chart_type": chartType.value,
      "title": title.value,
      "values": values,
      "numericfields": numericFields,
      "index": indexFields,
      "columns": columnFields,
      "aggfunc": aggfunc,
      "data": dataRowsdata,
    };



    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    String jsonString = jsonEncode(reqBody);
    try {
      final response = await helper.StringpostApi(
          "ctl/pivot;jsessionid=$sessionId", jsonString);

      if (response.statusCode == 200) {

        pivotchart.value = response.body;

        update();
      } else {

      }
    } catch (e) {
      debugPrint("Error during pivotchart API call: $e");
    }
  }
}
