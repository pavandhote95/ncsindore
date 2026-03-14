import 'dart:convert';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/apihelper.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/Menucontroller.dart';

class Pivotcontroller extends GetxController {
  final Menucontroller menuController = Get.put(Menucontroller());
  final HttpServices httpServices = HttpServices();
  final ApiBaseHelper helper = ApiBaseHelper();
  RxList<dynamic> labellist = RxList<dynamic>();
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  RxList<dynamic> searchfilterlabellist = RxList<dynamic>();
  RxList<dynamic> iwantlist = RxList<dynamic>();
  RxList<dynamic> groupbylist = RxList<dynamic>();
  RxList<dynamic> catergorylist = RxList<dynamic>();
  String USERstoryid = "";
  String menu = "";
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;

  var code = "".obs;
  var menuname = "".obs;
  var appCode = "".obs;
  var collectionName = "".obs;
  final RxString selectedChartType = ''.obs;
  var list = <Map<String, dynamic>>[].obs;
  var dataRows = <Map<String, dynamic>>[].obs;
  var pivotchart = ''.obs;

  var iscreate = 0.obs;
  var isread = 0.obs;
  var isupdate = 0.obs;
  var isdelete = 0.obs;
  var isuserFilter = 0.obs;

  var isPortrait = true.obs;

  final List<String> allowedTypes = [
    'text',
    'date',
    'object',
    'email',
    'time',
    'url',
    'map',
    'list',
  ];
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
  final List<String> groupbyallowedTypes = [
    'text',
    'date',
    'object',
    'email',
    'time',
    'url',
    'map',
    'list',
  ];
  final List<String> categoryallowedTypes = [
    'text',
    'date',
    'object',
    'email',
    'time',
    'url',
    'map',
    'list',
  ];

  String? selectedCondition;
  String? selectedField;
// Pivotcontroller.dart में conditions list update करें:

  final List<Map<String, String>> conditions = [
    {'value': 'EQ', 'label': '='},
    {'value': 'NEQ', 'label': '!='},
    {'value': 'GT', 'label': '>'},
    {'value': 'LT', 'label': '<'},
    {'value': 'GTE', 'label': '>='},
    {'value': 'LTE', 'label': '<='},
    {'value': 'BETWEEN', 'label': 'Between'},
    {'value': 'LIKE', 'label': 'like'},
    {'value': 'IS_NULL', 'label': 'Null'},
    {'value': 'IS_NOT_NULL', 'label': 'Not Null'},
    {'value': 'IS_EMPTY', 'label': 'Empty'},
    {'value': 'DAY', 'label': 'Day'},
    {'value': 'MONTH', 'label': 'Month'},
    {'value': 'DAY_MONTH', 'label': 'Day & Month'},
  ];
  // =========================================================
  // CONSTRUCTOR – Listen to userFilter changes
  // =========================================================
  Pivotcontroller() {
    ever(isuserFilter, (_) => _onUserFilterChanged());
  }

  // =========================================================
  // REAL-TIME REFRESH WHEN ADMIN CHANGES USER FILTER
  // =========================================================
  void _onUserFilterChanged() async {
    if (code.value.isEmpty || appCode.value.isEmpty) return;

    debugPrint(
        "userFilter changed → ${isuserFilter.value == 1 ? 'ON' : 'OFF'} → Refreshing instantly");

    list.clear();
    dataRows.clear();
    update();

    if (isuserFilter.value == 1) {
      await GetdataList(code.value, appCode.value);
    } else {
      await Getseachdata(code.value, appCode.value); // ALL DATA – NO FILTER
    }
  }

  void toggleOrientation() {
    if (isPortrait.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    isPortrait.value = !isPortrait.value;
  }

  // ----------- Form Fetch & Init --------------
  Future<void> GetForm_API(String id) async {
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res!.data;

      menu = data.userstoryName.toString().toLowerCase();
      buttons.assignAll(data.buttons ?? []);
      fields.assignAll(data.fields ?? []);
      USERstoryid = data.userstoryId.toString();

      await getuser_role_access(id);
      await Getattributefield(data.userstoryId.toString());
      await Getitemcode(data.userstoryId.toString());
    }
  }

  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(id: formid);
    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data'];
      menuname.value = dataResponse['name']?.toString() ?? '';
      code.value = dataResponse['code']?.toString() ?? '';
      appCode.value = dataResponse['appCode']?.toString() ?? '';
      collectionName.value = dataResponse['collectionName']?.toString() ?? '';
      update();
    }
  }
  

  // =========================================================
  // BUILD OWNER FILTER (only when needed)
  // =========================================================
  Future<Map<String, dynamic>?> _buildOwnerFilterIfNeeded() async {
    if (isuserFilter.value != 1) {
      return null; // userFilter OFF होने पर owner filter नहीं लगाएं
    }

    final prefs = await SharedPreferences.getInstance();
    final String? currentUserId = prefs.getString('userId') ??
        prefs.getString('user_id') ??
        prefs.getString('username') ??
        prefs.getString('userName') ??
        prefs.getString('loginId') ??
        prefs.getString('user');

    if (currentUserId == null || currentUserId.isEmpty) return null;

    final List<String> possibleOwnerFields = [
      'createdBy',
      'createdByUserId',
      'userId',
      'owner',
      'created_by',
      'ownerId',
      'createdById'
    ];

    String ownerField = 'createdBy';
    for (var f in possibleOwnerFields) {
      if (iwantlist.any((e) => e['code']?.toString() == f)) {
        ownerField = f;
        break;
      }
    }


    return {
      'field': ownerField,
      'label': ownerField,
      'value': currentUserId,
      'condition': 'EQ',
    };
  }

  // ---------------- Get Data List (owner filter applied) -----------------
Future<void> GetdataList(String field, String url) async {
    list.clear();
    dataRows.clear();
    update();

    final prefs = await SharedPreferences.getInstance();
    final String sessionId = prefs.getString('jsessionid') ?? '';
    if (sessionId.isEmpty) return;

    List<Map<String, dynamic>> searchList = [];

    // यहाँ सुधार: केवल userFilter ON होने पर ही owner filter add करें
    if (isuserFilter.value == 1) {
      final ownerFilter = await _buildOwnerFilterIfNeeded();
      if (ownerFilter != null) {
        searchList.add(ownerFilter);
        print('Owner filter applied: $ownerFilter');
      }
    } else {
      print('User filter is OFF - showing all data');
    }

    final reqBody = {"searchList": searchList};

    // यहाँ payload print करें
    print('Request Payload: $reqBody');
    print(
        'Payload JSON: ${jsonEncode(reqBody)}'); // JSON format में देखने के लिए

    try {
      final response = await helper.postApi(
        "api/v1/$url/$field/searchCriteria;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        final List<dynamic> dataResponse =
            (response['result']['data'] ?? []) as List<dynamic>;

        list.assignAll(dataResponse
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());

        final List<Map<String, dynamic>> tempRows = [];
        for (var item in list) {
          final Map<String, dynamic> newRow = {};
          for (var fieldDef in iwantlist) {
            final String fieldName = fieldDef['code']?.toString() ?? '';
            final String labelName = fieldDef['label']?.toString() ?? fieldName;
            newRow[labelName] = item.containsKey(fieldName) &&
                    item[fieldName] != null &&
                    item[fieldName].toString().trim().isNotEmpty
                ? item[fieldName]
                : '-';
          }
          tempRows.add(newRow);
        }
        dataRows.assignAll(tempRows);

        print(
            'Data loaded: ${dataRows.length} rows with userFilter: ${isuserFilter.value}');
        update();
      }
    } catch (e) {
      debugPrint('GetdataList error: $e');
    }
  }
  // ---------------- Get Search Data (NO filter when userFilter = 0) -----------------
  Future<Map<String, dynamic>?> Getseachdata(
      String url, String menutitle) async {
    final prefs = await SharedPreferences.getInstance();
    final String sessionId = prefs.getString('jsessionid') ?? '';
    if (sessionId.isEmpty)
      return {'success': false, 'message': 'Session missing'};

    List<Map<String, dynamic>> searchList = [];

    // ONLY add owner filter when userFilter is ON
    if (isuserFilter.value == 1) {
      final ownerFilter = await _buildOwnerFilterIfNeeded();
      if (ownerFilter != null) searchList.add(ownerFilter);
    }
    // When OFF → searchList = [] → ALL DATA

    final reqBody = {"searchList": searchList};

    try {
      final response = await helper.postApi(
        "api/v1/$menutitle/$url/searchCriteria;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        final List<dynamic> responseData =
            (response['result']['data'] ?? []) as List<dynamic>;

        final Map<String, String> codesToExtract = {
          for (var e in iwantlist) e['code'].toString(): e['label'].toString()
        };

        dataRows.assignAll(responseData.map((itemRaw) {
          final item = Map<String, dynamic>.from(itemRaw as Map);
          final sanitizedItem = <String, dynamic>{};
          codesToExtract.forEach((key, label) {
            sanitizedItem[label] = item.containsKey(key) &&
                    item[key] != null &&
                    item[key].toString().trim().isNotEmpty
                ? item[key]
                : '-';
          });
          return sanitizedItem;
        }).toList());

        update();
        return response;
      }
    } catch (e) {
      debugPrint("Getseachdata error: $e");
    }
    return null;
  }


  // ---------------- Report Search ----------------
Future<Map<String, dynamic>?> Getreportseachdata(
      List<Map<String, String>> addedFilters) async {
    dataRows.clear();
    update();

    final prefs = await SharedPreferences.getInstance();
    final String sessionId = prefs.getString('jsessionid') ?? '';
    if (sessionId.isEmpty)
      return {'success': false, 'message': 'Session missing'};

    List<Map<String, dynamic>> normalizedFilters = [];

    for (var f in addedFilters) {
      final fieldCode = f['field']?.toString() ?? '';
      final condition = f['condition']?.toString() ?? 'EQ';

      // BETWEEN condition के लिए special handling
      if (condition == 'BETWEEN') {
        final rangeFrom = f['rangeFrom']?.toString() ?? '';
        final rangeTo = f['rangeTo']?.toString() ?? '';

        if (rangeFrom.isNotEmpty && rangeTo.isNotEmpty) {
          // दो separate filters create करें: GTE और LTE
          normalizedFilters.add({
            'field': fieldCode,
            'label': fieldCode,
            'value': rangeFrom,
            'condition': 'GTE',
          });

          normalizedFilters.add({
            'field': fieldCode,
            'label': fieldCode,
            'value': rangeTo,
            'condition': 'LTE',
          });
        }
        continue;
      }

      final rawValue = f['value']?.toString() ?? '';
      final fieldDetails =
          iwantlist.firstWhereOrNull((e) => e['code'] == fieldCode);
      final fieldType =
          fieldDetails?['type']?.toString().toLowerCase() ?? 'text';

      // Handle special conditions
      dynamic value = rawValue;
      if (condition == 'IS_NULL' ||
          condition == 'IS_NOT_NULL' ||
          condition == 'IS_EMPTY') {
        value = null;
      } else if (condition == 'DAY' ||
          condition == 'MONTH' ||
          condition == 'DAY_MONTH') {
        value = rawValue;
      } else if (['number', 'long'].contains(fieldType))
        value = int.tryParse(rawValue) ?? rawValue;
      else if (['decimal', 'expression'].contains(fieldType))
        value = double.tryParse(rawValue) ?? rawValue;
      else if (fieldType == 'date') {
        if (rawValue.isNotEmpty) {
          try {
            DateTime.parse(rawValue);
            value = rawValue;
          } catch (e) {
            value = rawValue;
          }
        }
      }

      normalizedFilters.add({
        'field': fieldCode,
        'label': fieldDetails?['label'] ?? fieldCode,
        'value': value,
        'condition': condition,
      });
    }

    // userFilter के हिसाब से owner filter add/remove करें
    if (isuserFilter.value == 1) {
      final owner = await _buildOwnerFilterIfNeeded();
      if (owner != null) {
        final existingOwnerIndex =
            normalizedFilters.indexWhere((f) => f['field'] == owner['field']);

        if (existingOwnerIndex >= 0) {
          normalizedFilters[existingOwnerIndex] = owner;
        } else {
          normalizedFilters.add(owner);
        }
      }
    } else {
      normalizedFilters.removeWhere((f) =>
          f['field']!.toString().toLowerCase().contains('createdby') ||
          f['field']!.toString().toLowerCase().contains('userid') ||
          f['field']!.toString().toLowerCase().contains('owner'));
    }

    final reqBody = {"searchList": normalizedFilters};

    try {
      final response = await helper.postApi(
        "api/v1/${appCode.value}/${code.value}/searchCriteria;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        final data = (response['result']['data'] ?? []) as List<dynamic>;

        if (data.isEmpty) {
          return {
            'success': true,
            'emptyData': true,
            'message': 'No records found for the applied filters.',
            'data': []
          };
        } else {
          final map = {
            for (var e in iwantlist) e['code'].toString(): e['label'].toString()
          };
          dataRows.assignAll(data.map((itemRaw) {
            final item = Map<String, dynamic>.from(itemRaw as Map);
            final row = <String, dynamic>{};
            map.forEach((k, label) {
              row[label] =
                  (item[k] == null || item[k].toString().trim().isEmpty)
                      ? '-'
                      : item[k];
            });
            return row;
          }).toList());

          return {'success': true, 'emptyData': false, 'data': data};
        }
      } else {
        return {
          'success': false,
          'message': response?['message'] ?? 'Something went wrong'
        };
      }
    } catch (e) {
      debugPrint("Getreportseachdata error: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  
  Future<void> Getpivotchart(
    String charttype,
    String title,
    List<String> values,
    List<String> indexFields,
    List<String> columnFields,
    String agg,
    String fun,
    bool showTotal,
  ) async {
    pivotchart.value = "";
    if (dataRows.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('jsessionid') ?? '';
    if (sessionId.isEmpty) return;

    final body = {
      "chart_type": charttype.isEmpty ? "html" : charttype,
      "title": menuname.value,
      "columns": columnFields,
      "aggfunc": {agg: fun.toLowerCase()},
      "index": indexFields,
      "values": values,
      "margins": showTotal,
      "data": dataRows,
    };

    try {
      final res = await helper.StringpostApi(
          "ctl/pivot;jsessionid=$sessionId", jsonEncode(body));
      if (res.statusCode == 200) {
        pivotchart.value = res.body;
        update();
      }
    } catch (e) {
      debugPrint("Getpivotchart error: $e");
    }
  }

  // =========================================================
  // ROLE ACCESS – AUTO REFRESH ON CHANGE
  // =========================================================
  Future<void> getuser_role_access(String formID) async {
    final prefs = await SharedPreferences.getInstance();
    final applicationRoleId = prefs.getString("applicationRoleId") ?? '';

    final res = await httpServices.getUserAccess(
        formId: formID, applicationRoleId: applicationRoleId);

    if (res != null && res['success'] == true) {
      final userAccesslist = res['result']['data'] as List<dynamic>;
      if (userAccesslist.isNotEmpty) {
        final access = userAccesslist[0] as Map<String, dynamic>;

        final newUserFilter = access['userFilter'] ?? 0;

        // CRITICAL: Only update if changed → triggers ever()
        if (isuserFilter.value != newUserFilter) {
          isuserFilter.value = newUserFilter;
          debugPrint(
              "userFilter CHANGED to $newUserFilter → Auto-refreshing data");
        }

        iscreate.value = access['create'] ?? 0;
        isread.value = access['read'] ?? 0;
        isupdate.value = access['update'] ?? 0;
        isdelete.value = access['delete'] ?? 0;

        // INSTANT DATA REFRESH
        if (code.value.isNotEmpty && appCode.value.isNotEmpty) {
          list.clear();
          dataRows.clear();
          update();

          if (newUserFilter == 1) {
            await GetdataList(code.value, appCode.value);
          } else {
            await Getseachdata(code.value, appCode.value); // ALL DATA
          }
        }
      }
    }
  }

  // =========================================================
  // ATTRIBUTE FIELD
  // =========================================================
  Future<void> Getattributefield(String formId) async {
    labellist.clear();
    final res = await httpServices.Getlistattribute(formId: formId);

    if (res?['success'] == true) {
      List<Map<String, dynamic>> attributeList =
          List<Map<String, dynamic>>.from(res!['result']['data']);

      for (var attr in attributeList) {
        final field = fields.firstWhereOrNull((f) => f.code == attr['code']);
        if (field != null) attr['label'] = field.label;
      }

      final depAttrs = attributeList
          .where((a) => a['depAttribute'] != null)
          .map((a) => a['depAttribute'] as String)
          .toSet();

      final filtered = attributeList
          .where(
              (a) => depAttrs.contains(a['code']) || a['depAttribute'] == null)
          .toList();

      groupbylist.assignAll(filtered
          .where((e) => groupbyallowedTypes.contains(e['type']))
          .toList());
      catergorylist.assignAll(filtered
          .where((e) => categoryallowedTypes.contains(e['type']))
          .toList());
      iwantlist.assignAll(filtered
          .where((e) => iwantallowedTypes.contains(e['type']))
          .toList());

      update();
    }
  }

  @override
  void dispose() {
    debugPrint('Pivotcontroller disposed');
    super.dispose();
  }
}
