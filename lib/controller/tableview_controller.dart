import 'dart:io';
import 'dart:typed_data';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/apihelper.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/Menucontroller.dart';

class TableviewController extends GetxController {
  var dataState = DataState.loading.obs;
  final RxMap<String, dynamic> _fieldValues = <String, dynamic>{}.obs;
  // Use a map to store active filters
  final RxMap<String, dynamic> activeFilters = <String, dynamic>{}.obs;
  HttpServices httpServices = HttpServices();
  RxBool isSearch = false.obs;
  var userstoryName = "".obs;
  var appurl = "".obs;
  var totalPages = 1.obs;
  var tagenable = 0.obs;
  var saveformcode = "".obs;
  var recordCount = 0.obs;
  var usecaseid = 0.obs;
  RxList<String> selectedTags = <String>[].obs;
  RxList<String> allTags = <String>[].obs;

  final ApiBaseHelper helper = ApiBaseHelper();
  var list = <Map<String, dynamic>>[].obs;
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;
  RxList<dynamic> labellist = RxList<dynamic>();
  RxList<dynamic> datalabellist = RxList<dynamic>();
  RxMap<String, List<dynamic>> prelaodlist = RxMap<String, List<dynamic>>();
  List<String> globalYUsecases = [];
  RxList<bool> selectedRows = RxList<bool>();

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
        'list'
  ];
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  RxList<dynamic> taglist = RxList<dynamic>();
  var CurrentPage = 0.obs;
  Map<String, dynamic> usecaseList = {};
  final Menucontroller menuController = Get.put(Menucontroller());
  var code = "".obs;
  var appCode = "".obs;
  var exportEnabled = 0.obs;
  var updatedFormID = "".obs;
  var updateduserstoryname = "".obs;
  var userstortyid = 0.obs;
  int _pageSize = 10;
  var tagItem;
  final RxMap<String, dynamic> searchfilteredFields = <String, dynamic>{}.obs;

  void setFieldValue(String label, dynamic value) {
    _fieldValues[label] = value;
    update();
  }

  dynamic getFieldValue(String label) {
    return _fieldValues[label];
  }

  Future<void> Getpreloadfield(String name) async {
    String formname = "";
    if (code.value != null) {
      formname = code.value;
    } else {
      formname = name;
    }

    var res = await httpServices.Getpreloaddata(
        formname: formname, appurl: appCode.value);
    if (res != null && res['success'] == true) {
      var result = res['result'] ?? {};
      var useCases = globalYUsecases;
      prelaodlist.clear();

      for (var useCase in useCases) {
        if (result.containsKey(useCase)) {
          var data = result[useCase];
          if (data is List) {
            prelaodlist[useCase] = List.from(data);
          } else {}
        } else {}
      }
    } else {}
  }

  Future<void> GetForm_API(String id) async {
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;

      appurl.value = id;
      saveformcode.value = data!.code.toString();
      userstoryName.value = data!.userstoryName.toString();
      userstortyid.value = int.parse(data.userstoryId.toString());

      buttons.assignAll(data.buttons);
      fields.assignAll(data.fields);
      await loadData(data.userstoryId.toString());
      update();
    } else {
      debugPrint("Error_in_Get_Form_Data...");
    }
  }

  Future<void> loadData(String userstoryId) async {
    try {
      await Getitemcode(userstoryId);
      await Getattributefield(userstoryId);
      await filteredlist(userstoryId);
    } catch (e) {
      debugPrint("Error in API calls: $e");
    }
  }

  Future<void> getfetchrule() async {
    var res = await httpServices.FetchruleAPI(
        formId: appurl.value, formname: appCode.value, appurl: code.value);
    if (res != null && res['success'] == true) {
      final result = res['result'];
      final data = result?['data'];
      updatedFormID.value = data?['updatedFormID'];
      updateduserstoryname.value = data?['appCode'];
    } else {
      debugPrint("FetchruleAPI returned null or failed.");
    }
  }
Future<void> onSearch() async {
    isSearch.value = true;
    CurrentPage.value = 0;
    searchfilteredFields.clear();

    for (var field in filterlabellist) {
      var fieldValue = getFieldValue(field['label']);
      var fieldType = field['type'];

      // Check if the field has a non-empty value
      if ((fieldValue is String && fieldValue.isNotEmpty) ||
          (fieldValue is int && fieldValue != 0) ||
          (fieldValue is double && fieldValue != 0.0)) {
        dynamic formattedValue = fieldValue;

        // ✅ 1. IDATE FIELD FORMATTING (API expects ISO format: 2026-01-29T18:30:00.000Z)
 if (fieldType == 'idate') {
          if (fieldValue is String && fieldValue.isNotEmpty) {
            try {
              String value = fieldValue.trim();
              DateTime dt;

              if (value.contains('T')) {
                // ✅ Already correct ISO → JUST parse
                dt = DateTime.parse(value);
              } else if (value.contains('-')) {
                // yyyy-MM-dd OR dd-MM-yyyy
                List<String> parts = value.split('-');
                if (parts[0].length == 2) {
                  dt = DateFormat('dd-MM-yyyy').parse(value);
                } else {
                  dt = DateFormat('yyyy-MM-dd').parse(value);
                }
              } else if (value.contains('/')) {
                dt = DateFormat('dd/MM/yyyy').parse(value);
              } else {
                continue;
              }

              // ✅ FORCE UTC MIDNIGHT (NO SHIFT)
              formattedValue = DateTime.utc(
                dt.year,
                dt.month,
                dt.day,
              ).toIso8601String();

              debugPrint('🔍 iDate converted: $value → $formattedValue');
            } catch (e) {
              debugPrint('❌ IDate format error: $e , value: $fieldValue');
              continue;
            }
          }
        }

        // ✅ 2. ITIME FIELD FORMATTING (API expects ISO format: 1970-01-01T11:55:00.000Z)
else if (fieldType == 'itime') {
          if (fieldValue is String && fieldValue.isNotEmpty) {
            try {
              String timeStr = fieldValue.trim();
              DateTime dt;

              if (timeStr.contains('T')) {
                // Already ISO UTC
                dt = DateTime.parse(timeStr);
              } else if (timeStr.toUpperCase().contains('AM') ||
                  timeStr.toUpperCase().contains('PM')) {
                bool isPM = timeStr.toUpperCase().contains('PM');
                String timePart =
                    timeStr.replaceAll(RegExp(r'[APMapm]'), '').trim();

                List<String> parts = timePart.split(':');
                if (parts.length < 2) continue;

                int hour = int.tryParse(parts[0]) ?? 0;
                int minute = int.tryParse(parts[1]) ?? 0;

                if (isPM && hour < 12) hour += 12;
                if (!isPM && hour == 12) hour = 0;

                // ✅ IST → UTC
                DateTime istTime = DateTime(1970, 1, 1, hour, minute);
                dt = istTime.subtract(const Duration(hours: 5, minutes: 30));
              } else if (timeStr.contains(':')) {
                List<String> parts = timeStr.split(':');
                if (parts.length < 2) continue;

                int hour = int.tryParse(parts[0]) ?? 0;
                int minute = int.tryParse(parts[1]) ?? 0;

                // ✅ IST → UTC
                DateTime istTime = DateTime(1970, 1, 1, hour, minute);
                dt = istTime.subtract(const Duration(hours: 5, minutes: 30));
              } else {
                continue;
              }

              // ✅ Final payload format
    
    formattedValue = dt.toIso8601String() + 'Z';


              debugPrint('🔍 iTime converted: $timeStr → $formattedValue');
            } catch (e) {
              debugPrint('❌ ITime format error: $e , value: $fieldValue');
              continue;
            }
          }
        }


        // ✅ 3. TIME FIELD FORMATTING (API expects HH:mm format: 16:25)
        else if (fieldType == 'time') {
          if (fieldValue is String && fieldValue.isNotEmpty) {
            try {
              String timeStr = fieldValue.trim();

              if (timeStr.contains('AM') ||
                  timeStr.contains('PM') ||
                  timeStr.contains('am') ||
                  timeStr.contains('pm')) {
                // AM/PM format, convert to HH:mm
                bool isPM = timeStr.toUpperCase().contains('PM');
                String timePart = timeStr
                    .replaceAll(RegExp(r'[APMapm]'), '')
                    .replaceAll('M', '')
                    .trim();
                List<String> parts = timePart.split(':');
                if (parts.length >= 2) {
                  int hour = int.tryParse(parts[0]) ?? 0;
                  int minute = int.tryParse(parts[1]) ?? 0;

                  // Convert to 24-hour format
                  if (isPM && hour < 12) hour += 12;
                  if (!isPM && hour == 12) hour = 0;

                  formattedValue =
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                }
              } else if (timeStr.contains('T')) {
                // ISO format, extract time part
                DateTime dt = DateTime.parse(timeStr);
                formattedValue = DateFormat('HH:mm').format(dt);
              } else if (timeStr.contains(':')) {
                // Already in HH:mm format, ensure correct format
                List<String> parts = timeStr.split(':');
                if (parts.length >= 2) {
                  int hour = int.tryParse(parts[0]) ?? 0;
                  int minute = int.tryParse(parts[1]) ?? 0;
                  formattedValue =
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                }
              }
              debugPrint('🔍 Time converted: $fieldValue → $formattedValue');
            } catch (e) {
              debugPrint('❌ Time format error: $e , value: $fieldValue');
              continue;
            }
          }
        }
        // ✅ 4. DATETIME/DATEANDTIME FIELD FORMATTING (API expects ISO format: 2026-01-30T12:55:00.000Z)
        else if (fieldType == 'datetime' || fieldType == 'dateandtime') {
          if (fieldValue is String && fieldValue.isNotEmpty) {
            try {
              String dateTimeStr = fieldValue.trim();
              DateTime dt;

              if (dateTimeStr.contains('T')) {
                // Already in ISO format
                dt = DateTime.parse(dateTimeStr).toUtc();
              } else if (dateTimeStr.contains(' ') &&
                  dateTimeStr.contains('-')) {
                // yyyy-MM-dd HH:mm format
                dt = DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr).toUtc();
              } else if (dateTimeStr.contains(' ') &&
                  dateTimeStr.contains('/')) {
                // dd/MM/yyyy HH:mm format
                dt = DateFormat('dd/MM/yyyy HH:mm').parse(dateTimeStr).toUtc();
              } else if (dateTimeStr.contains(' ') &&
                  (dateTimeStr.contains('AM') || dateTimeStr.contains('PM'))) {
                // Date with AM/PM time
                List<String> parts = dateTimeStr.split(' ');
                if (parts.length >= 3) {
                  String datePart = parts[0];
                  String timePart = parts[1];
                  String period = parts[2];

                  // Parse date
                  DateTime date;
                  if (datePart.contains('-')) {
                    List<String> dateParts = datePart.split('-');
                    if (dateParts[0].length == 2) {
                      date = DateFormat('dd-MM-yyyy').parse(datePart);
                    } else {
                      date = DateFormat('yyyy-MM-dd').parse(datePart);
                    }
                  } else if (datePart.contains('/')) {
                    date = DateFormat('dd/MM/yyyy').parse(datePart);
                  } else {
                    continue;
                  }

                  // Parse time
                  List<String> timeParts = timePart.split(':');
                  if (timeParts.length >= 2) {
                    int hour = int.tryParse(timeParts[0]) ?? 0;
                    int minute = int.tryParse(timeParts[1]) ?? 0;

                    // Adjust for AM/PM
                    bool isPM = period.toUpperCase().contains('PM');
                    if (isPM && hour < 12) hour += 12;
                    if (!isPM && hour == 12) hour = 0;

                    dt = DateTime(date.year, date.month, date.day, hour, minute)
                        .toUtc();
                  } else {
                    continue;
                  }
                } else {
                  continue;
                }
              } else {
                dt = DateTime.parse(dateTimeStr).toUtc();
              }

              // ✅ Convert to ISO format with timezone (UTC)
              // Format: 2026-01-30T12:55:00.000Z
              formattedValue = dt.toIso8601String();
        
              debugPrint('🔍 DateTime converted: $dateTimeStr → $formattedValue');
            } catch (e) {
              debugPrint('❌ DateTime format error: $e , value: $fieldValue');
              continue;
            }
          }
        }
        // ✅ 5. DATE FIELD FORMATTING (API expects yyyy-MM-dd format: 2026-01-23)
        else if (fieldType == 'date') {
          if (fieldValue is String && fieldValue.isNotEmpty) {
            try {
              DateTime dt;
              String value = fieldValue.trim();

              if (value.contains('T')) {
                // ISO format, extract date part
                dt = DateTime.parse(value);
              } else if (value.contains('-')) {
                // Already in yyyy-MM-dd format
                dt = DateFormat('yyyy-MM-dd').parse(value);
              } else if (value.contains('/')) {
                // dd/MM/yyyy format
                dt = DateFormat('dd/MM/yyyy').parse(value);
              } else {
                dt = DateTime.parse(value);
              }

              // ✅ Convert to yyyy-MM-dd format
              formattedValue = DateFormat('yyyy-MM-dd').format(dt);
              debugPrint('🔍 Date converted: $value → $formattedValue');
            } catch (e) {
              debugPrint('❌ Date format error: $e , value: $fieldValue');
              continue;
            }
          }
        }
        // ✅ 6. DECIMAL FIELD
        else if (field['type'] == 'decimal' && fieldValue is String) {
          final parsed = double.tryParse(fieldValue);
          if (parsed != null) {
            formattedValue = parsed;
          } else {
            continue;
          }
        }
        // ✅ 7. REFERENCE KEY FIELD
        else if (field['refKey'] == 1 &&
            RegExp(r'^\d+$').hasMatch(fieldValue.toString())) {
          formattedValue = int.parse(fieldValue.toString());
        }

        // ✅ Add to search filters
        if (formattedValue != null) {
          searchfilteredFields[field['code']] = formattedValue;
          debugPrint(
              '🔍 Added filter: ${field['code']} = $formattedValue (Type: $fieldType)');
        }
      }
    }

    // Debug debugPrint final payload
    debugPrint('🎯 Final Search Payload: $searchfilteredFields');

    await getdataList();
  }
  
Future<void> getdataList() async {
    dataState.value = DataState.loading;
    update();

    debugPrint('=== getdataList() START ===');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint('ERROR: Session ID is empty!');
      dataState.value = DataState.empty;
      update();
      return;
    }

    Map<String, dynamic> reqBody = {
      "pageSize": "10",
    };

    if (appCode.value.isEmpty || code.value.isEmpty) {
      debugPrint('ERROR: appCode or code is empty!');
      dataState.value = DataState.empty;
      update();
      return;
    }

    final String url =
        "api/v1/${appCode.value}/${code.value}/search/$CurrentPage;jsessionid=$sessionId";

    if (menuController.isuserFilter.value == 1) {
      String loginId = prefs.getString('loginId') ?? '';
      reqBody["createdBy"] = loginId;
    }

    if (isSearch.value) {
      reqBody.addAll(searchfilteredFields);
    }

    try {
      final response = await helper.postApi(url, reqBody);

      if (response == null) {
        dataState.value = DataState.empty;
        update();
        return;
      }

      if (response['success'] == true) {
        var result = response['result'];
        var dataResponse = result['data'];

        if (dataResponse is List) {
          CurrentPage.value = result['pageNo'] ?? 0;
          totalPages.value = result['pageCount'] ?? 1;
          recordCount.value = result['recordCount'] ?? 0;

          // Process each item to format date/time fields
          List<Map<String, dynamic>> formattedList = [];
          for (var item in dataResponse) {
            Map<String, dynamic> formattedItem = Map.from(item);

            // Format date/time fields for display
            formattedItem.forEach((key, value) {
              // Check field type from labellist
              var fieldInfo = labellist.firstWhere(
                (field) => field['code'] == key,
                orElse: () => {},
              );

              if (fieldInfo.isNotEmpty) {
                String fieldType = fieldInfo['type'] ?? '';

                // FIX: Properly handle timeFormat (could be String or int)
                dynamic timeFormatValue = fieldInfo['timeFormat'];
                int timeFormat = 24; // Default

                if (timeFormatValue != null) {
                  if (timeFormatValue is int) {
                    timeFormat = timeFormatValue;
                  } else if (timeFormatValue is String) {
                    timeFormat = int.tryParse(timeFormatValue) ?? 24;
                  }
                }

                // 🎯 DATE & TIME FORMATTING
                if (fieldType == 'datetime' || fieldType == 'dateandtime') {
                  if (value != null && value.toString().isNotEmpty) {
                    try {
                      // Check if it's ISO format with 'T'
                      String dateTimeStr = value.toString();
                      DateTime dt;

                      if (dateTimeStr.contains('T')) {
                        // ISO format: "2024-01-22T09:30:00.000Z"
                        dt = DateTime.parse(dateTimeStr).toLocal();
                      } else if (dateTimeStr.contains(' ')) {
                        // Already in display format: "2024-01-22 09:30"
                        dt = DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeStr);
                      } else {
                        // Unknown format, try parsing
                        dt = DateTime.parse(dateTimeStr).toLocal();
                      }

                      // Display format based on timeFormat
                      if (timeFormat == 24) {
                        formattedItem[key] =
                            DateFormat('yyyy-MM-dd HH:mm').format(dt);
                      } else {
                        formattedItem[key] =
                            DateFormat('yyyy-MM-dd hh:mm a').format(dt);
                      }
                    } catch (e) {
                      debugPrint(
                          'Error formatting datetime $key: $e, value: $value');
                      // Keep original value
                    }
                  }
                } else if (fieldType == 'idate') {
                  if (value != null && value.toString().isNotEmpty) {
                    try {
                      String dateStr = value.toString();
                      DateTime dt;

                      if (dateStr.contains('T')) {
                        // ISO format with time: "2024-01-22T00:00:00.000Z"
                        dt = DateTime.parse(dateStr).toLocal();
                      } else if (dateStr.contains('-')) {
                        // Already in date format: "2024-01-22"
                        dt = DateFormat('yyyy-MM-dd').parse(dateStr);
                      } else {
                        dt = DateTime.parse(dateStr).toLocal();
                      }

                      // ✅ Display in dd-MM-yyyy format
                      formattedItem[key] = DateFormat('dd-MM-yyyy').format(dt);
                    } catch (e) {
                      debugPrint('Error formatting idate $key: $e, value: $value');
                    }
                  }
                } else if (fieldType == 'itime') {
                  if (value != null && value.toString().isNotEmpty) {
                    try {
                      String timeStr = value.toString();

                      if (timeStr.contains('T')) {
                        // ISO format: "1970-01-01T14:30:00.000Z"
                        DateTime dt = DateTime.parse(timeStr).toLocal();

                        // Check timeFormat for display
                        if (timeFormat == 24) {
                          formattedItem[key] = DateFormat('h:mm a').format(dt);
                        } else {
                          // ✅ Display in h:mm a format (2:30 PM)
                          formattedItem[key] = DateFormat('h:mm a').format(dt);
                        }
                      } else if (timeStr.contains('AM') ||
                          timeStr.contains('PM')) {
                        // Already in AM/PM format
                        formattedItem[key] = timeStr;
                      } else if (timeStr.contains(':')) {
                        // Already in HH:mm format
                        List<String> parts = timeStr.split(':');
                        if (parts.length >= 2) {
                          int hour = int.tryParse(parts[0]) ?? 0;
                          int minute = int.tryParse(parts[1]) ?? 0;

                          if (timeFormat == 24) {
                            formattedItem[key] =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                          } else {
                            // Convert to AM/PM
                            String period = 'AM';
                            int displayHour = hour;

                            if (hour >= 12) {
                              period = 'PM';
                              if (hour > 12) {
                                displayHour = hour - 12;
                              }
                            }

                            if (hour == 0) {
                              displayHour = 12; // Midnight is 12:00 AM
                            }

                            // ✅ Single digit hour without leading zero
                            formattedItem[key] =
                                '$displayHour:${minute.toString().padLeft(2, '0')} $period';
                          }
                        }
                      }
                    } catch (e) {
                      debugPrint('Error formatting itime $key: $e, value: $value');
                    }
                  }
                } else if (fieldType == 'time') {
                  if (value != null && value.toString().isNotEmpty) {
                    try {
                      String timeValue = value.toString();

                      // Check if already in AM/PM format
                      if (timeValue.contains('AM') ||
                          timeValue.contains('PM')) {
                        formattedItem[key] = timeValue;
                      } else if (timeValue.contains('T')) {
                        // ISO format
                        DateTime dt = DateTime.parse(timeValue).toLocal();

                        if (timeFormat == 24) {
                          formattedItem[key] = DateFormat('HH:mm').format(dt);
                        } else {
                          formattedItem[key] = DateFormat('h:mm a').format(dt);
                        }
                      } else if (timeValue.contains(':')) {
                        List<String> parts = timeValue.split(':');
                        if (parts.length >= 2) {
                          int hour = int.tryParse(parts[0]) ?? 0;
                          int minute = int.tryParse(parts[1]) ?? 0;

                          // Check timeFormat for display
                          if (timeFormat == 24) {
                            formattedItem[key] =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                          } else {
                            // ✅ Display in AM/PM with single digit hour
                            String period = 'AM';
                            int displayHour = hour;

                            if (hour >= 12) {
                              period = 'PM';
                              if (hour > 12) {
                                displayHour = hour - 12;
                              }
                            }

                            if (hour == 0) {
                              displayHour = 12; // Midnight is 12:00 AM
                            }

                            // ✅ Single digit hour (2:52 PM instead of 02:52 PM)
                            formattedItem[key] =
                                '$displayHour:${minute.toString().padLeft(2, '0')} $period';
                          }
                        }
                      }
                    } catch (e) {
                      debugPrint('Error formatting time $key: $e, value: $value');
                    }
                  }
                } else if (fieldType == 'date') {
                  if (value != null && value.toString().isNotEmpty) {
                    try {
                      String dateStr = value.toString();
                      DateTime dt;

                      if (dateStr.contains('T')) {
                        // ISO format: "2024-01-22T00:00:00.000Z"
                        dt = DateTime.parse(dateStr).toLocal();
                      } else {
                        // Already in date format
                        dt = DateFormat('yyyy-MM-dd').parse(dateStr);
                      }

                      // ✅ Display in dd-MM-yyyy format
                      formattedItem[key] = DateFormat('yyyy-MM-dd').format(dt);
                    } catch (e) {
                      debugPrint('Error formatting date $key: $e, value: $value');
                    }
                  }
                }
              }
            });

            formattedList.add(formattedItem);
          }

          list.assignAll(formattedList);
          dataState.value =
              list.isNotEmpty ? DataState.loaded : DataState.empty;

          // ✅ DEBUG: debugPrint formatted values
          if (list.isNotEmpty) {
            debugPrint('=== FORMATTED DATA SAMPLE ===');
            var sample = list.first;
            sample.forEach((key, value) {
              var fieldInfo = labellist.firstWhere(
                (field) => field['code'] == key,
                orElse: () => {},
              );
              if (fieldInfo.isNotEmpty) {
                String fieldType = fieldInfo['type'] ?? '';
                if (fieldType == 'idate' ||
                    fieldType == 'date' ||
                    fieldType == 'itime' ||
                    fieldType == 'time' ||
                    fieldType == 'datetime' ||
                    fieldType == 'dateandtime') {
                  debugPrint('$key ($fieldType): $value');
                }
              }
            });
          }
        } else {
          dataState.value = DataState.empty;
        }
      } else {
        dataState.value = DataState.empty;
      }
    } catch (e, stackTrace) {
      debugPrint('EXCEPTION in getdataList: $e');
      debugPrint('Stack trace: $stackTrace');

      dataState.value = DataState.empty;

      CherryToast.error(
        backgroundColor: Colors.red,
        animationDuration: Durations.short1,
        title: const Text("Error loading data. Please try again.",
            style: TextStyle(color: Colors.white)),
      ).show(Get.overlayContext!);
    } finally {
      update();
    }
  }
 
  Future<void> filteredlist(String formId) async {
    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data'];

      var sortedFilteredList = filteredList.where((label) {
        return fields
            .any((field) => field.id.toString() == label['id'].toString());
      }).toList();

      sortedFilteredList.sort((a, b) {
        int indexA = fields
            .indexWhere((field) => field.id.toString() == a['id'].toString());
        int indexB = fields
            .indexWhere((field) => field.id.toString() == b['id'].toString());
        return indexA.compareTo(indexB);
      });

      for (var item in sortedFilteredList) {
        var matchingField = fields.firstWhere(
              (field) => field.id.toString() == item['id'].toString(),
        );

        if (matchingField != "") {
          item['show'] =
              matchingField.show ?? '';
          item['group'] =
              matchingField.group ?? '';
          item['event'] = matchingField.event ?? '';
          item['rule'] = matchingField.rule ?? '';
          item['label'] = matchingField.label ?? '';
          item['parentFilter'] = matchingField.parentFilter ?? '';
        }
      }

      if (sortedFilteredList.isNotEmpty) {
        filterlabellist.assignAll(sortedFilteredList
            .where((e) =>
        !(e['type'] == 'doc' ||
            e['type'] == 'file')
        )
            .toList());
      } else {}

      update();
    }
  }

  Future<void> Gettagattibute(String formId) async {
    debugPrint('formId=========>${formId}');

    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data'];
      taglist.assignAll(filteredList);
    }
  }

  Future<void> Getattributefield(String formId) async {
    labellist.clear();
    tagItem = "";
    tagItem = null;

    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data'];
      bool hasTag = filteredList.any((item) => item['type'] == 'tag');
      var sortedFilteredList = filteredList.where((label) {
        return fields.any((field) => field.id.toString() == label['id'].toString());
      }).toList();

      sortedFilteredList.sort((a, b) {
        int indexA = fields.indexWhere((field) => field.id.toString() == a['id'].toString());
        int indexB = fields.indexWhere((field) => field.id.toString() == b['id'].toString());
        return indexA.compareTo(indexB);
      });

      for (var item in sortedFilteredList) {
        var matchingField = fields.firstWhere(
              (field) => field.id.toString() == item['id'].toString(),
        );

        if (matchingField != "") {
          item['show'] = matchingField.show ?? '';
          item['group'] = matchingField.group ?? '';
          item['event'] = matchingField.event ?? '';
          item['rule'] = matchingField.rule ?? '';
          item['label'] = matchingField.label ?? '';
          item['parentFilter'] = matchingField.parentFilter ?? '';
        }
      }

      if (sortedFilteredList.isNotEmpty) {
        labellist.assignAll(sortedFilteredList);
        bool hasTag = labellist.any((item) => item['type'] == 'tag');
        selectedRows.value = List.generate(labellist.length, (index) => false);
      } else {
        selectedRows.value = [];
      }
      var uniqueUsecases = <String>{};
      for (var dashboardItem in labellist) {
        String yUsecase = dashboardItem['primaryUsecase'] ?? "";

        if (yUsecase.isNotEmpty) {
          uniqueUsecases.add(yUsecase);
        } else {}
      }
      globalYUsecases = uniqueUsecases.toList();
      if (globalYUsecases.isNotEmpty) {
        await Getpreloadfield(code.value);
      }
    }
  }

  Future<bool> deleteAlllistitem(String url, String field, String id,
      int _currentPage, int _pageSize) async {
    var res = await httpServices.DeleteListItem(
      appurl: appCode.value,
      field: code.value,
      id: id,
    );

    if (res != null && res['success'] == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> deletelistitem(String url, String field, String id,
      int _currentPage, int _pageSize) async {
    var res = await httpServices.DeleteListItem(
      appurl: appCode.value,
      field: code.value,
      id: id,
    );

    if (res != null && res['success'] == true) {
      CherryToast.success(
        backgroundColor: Color(0xFFBCF3BF),
        animationDuration: Durations.short1,
        title: const Text("Deleted successfully!!",
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);

      await getdataList();
    } else {
      CherryToast.error(
        backgroundColor: Colors.red,
        animationDuration: Durations.short1,
        title: const Text("Failed to delete item!",
            style: TextStyle(color: Colors.white)),
      ).show(Get.overlayContext!);
    }
  }

  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(
      id: formid,
    );

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data'];
      code.value = dataResponse['code'];
      usecaseid.value = dataResponse['id'];
      appCode.value = dataResponse['appCode'];
      if (dataResponse.containsKey('exportEnabled')) {
        exportEnabled.value =
        dataResponse['exportEnabled'] as int;
      } else {
        exportEnabled.value = 0;
      }
      isSearch.value = false;
      await getdataList();
      update();
    } else {}
  }

  Future<Map<String, dynamic>?> ExportdataList(String field, String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    String loginId = '';

    Map<String, dynamic> reqBody = {
      "pageSize": "50",
    };
    if (menuController.isuserFilter.value == 1) {
      String loginId = prefs.getString('loginId') ?? '';
      reqBody["createdBy"] = loginId;
    }

    searchfilteredFields.forEach((key, value) {
      debugPrint("Filtered field -> $key: $value");
      dynamic formattedValue = value;
      if (value is String && RegExp(r'^\d+$').hasMatch(value)) {
        formattedValue = int.parse(value);
      }
      reqBody[key] = formattedValue;
    });

    var response;
    debugPrint("ExportdataList::::::::::::reqBody----->>> $reqBody");
    try {
      response = await helper.exportpostApi(
          "api/v1/${appCode.value}/${code.value}/export;jsessionid=$sessionId",
          reqBody);
      debugPrint("ExportdataList::::::::::::response----->>> $response");
      String cleanedCsvData = response.replaceAll('"', '');
      saveAndLaunchFile(cleanedCsvData, 'Export.csv');
    } catch (e) {
      debugPrint("Error in ExportdataList: $e");
    }
    return null;
  }

  Future<void> saveAndLaunchFile(String bytes, String fileName) async {
    String directory = '/storage/emulated/0/Download/';
    final path = Platform.isAndroid
        ? directory
        : (await getApplicationDocumentsDirectory()).path;
    int counter = 1;
    String finalFileName = fileName;

    while (await File('$path/$finalFileName').exists()) {
      finalFileName = fileName.replaceFirst('.csv', '($counter).csv');
      counter++;
    }

    final file = File('$path/$finalFileName');
    await file.writeAsString(bytes, flush: true);

    OpenFile.open('$path/$finalFileName');
  }

  Future<void> ExportpdfFunction(String field, String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    String loginId = '';

    Map<String, dynamic> reqBody = {
      "pageSize": 50,
    };

    if (menuController.isuserFilter.value == 1) {
      String loginId = prefs.getString('loginId') ?? '';
      reqBody["createdBy"] = loginId;
    }

    searchfilteredFields.forEach((key, value) {
      debugPrint("Filtered field -> $key: $value");
      dynamic formattedValue = value;
      if (value is String && RegExp(r'^\d+$').hasMatch(value)) {
        formattedValue = int.parse(value);
      }
      reqBody[key] = formattedValue;
    });

    try {
      final response = await helper.pdfexportpostApi(
          "api/v1/${appCode.value}/${code.value}/pdf;jsessionid=$sessionId",
          reqBody);
      debugPrint("URL::::::::::::URL----->>> ${'api/v1/${appCode.value}/${code.value}/pdf'}");
      debugPrint("ExportpdfFunction::::::::::::reqBody----->>> $reqBody");
      debugPrint("ExportpdfFunction::::::::::::response----->>> $response");
      if (response == null) {
        debugPrint("ExportpdfFunction: PDF response is null");
        return;
      }

      saveAndLaunchpdfFile(response, 'exported_document.pdf');
    } catch (e) {
      debugPrint("Error in ExportpdfFunction: $e");
    }
  }

  Future<void> saveAndLaunchpdfFile(Uint8List pdfData, String filename) async {
    String directory = '/storage/emulated/0/Download/';
    final path = Platform.isAndroid
        ? directory
        : (await getApplicationDocumentsDirectory()).path;
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void onNextPage() {
    if (CurrentPage.value < totalPages.value - 1) {
      CurrentPage.value++;
      getdataList();
    }
  }

  void onPreviousPage() {
    if (CurrentPage.value > 0) {
      CurrentPage.value--;
      getdataList();
    }
  }
}

enum DataState { loading, loaded, empty }