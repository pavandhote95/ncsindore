import 'package:cuickdevuser/controller/tableview_controller.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/apihelper.dart';

class Uiformcontroller extends GetxController {
  var workingDays = ''.obs;
  var days = ''.obs;
  var sundays = ''.obs;
  var saturdays = ''.obs;
  // Uiformcontroller class में ये add करें
var perDaySalary = ''.obs;
var netSalary = ''.obs;
var leaveWithoutPay = ''.obs;
  final Map<String, String> fieldNameMapping = {
    'Non Working Saturday In Month': 'Saturday In Month',
    'nonWorkingSaturdayInMonth': 'Saturday In Month',
    'NonWorkingSaturdayInMonth': 'Saturday In Month',
    'saturdayInMonth': 'Saturday In Month',
    'Saturday': 'Saturday In Month',
    'Saturdays': 'Saturday In Month',
  }
  ;


  void updateExpressionFields() {
    for (var field in labellist) {
      if (field['type'] == 'expression') {
        String expression = field['expression'] ?? field['rule'] ?? '';
        if (expression.isNotEmpty) {
          calculateAndSetExpression(field, expression);
        }
      }
    }
  }

  Future<void> calculateAndSetExpression(
      Map<String, dynamic> field, String expression) async {
    try {
      String fieldLabel = field['label'];
      String fieldCode = field['code'];

      print('🟡 CALCULATING for: $fieldLabel');
      print('🟡 Expression: "$expression"');

      String calculatedValue = await calculateExpression(expression);

      print('🟡 Calculated result: "$calculatedValue"');

      setFieldValue(fieldLabel, calculatedValue);
      dataMap[fieldCode] = calculatedValue;

      print('🟡 Value set: $fieldLabel = $calculatedValue');

      update();
    } catch (e) {
      print('🟡 Error: $e');
    }
  }

  String formatNumber(double number) {
    // Check if it's a whole number
    if (number % 1 == 0) {
      return number.toInt().toString();
    } else {
      // Format with 3 decimal places but trim trailing zeros
      return number
          .toStringAsFixed(3)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

void calculateAllFields() {
  print('🧮 ===== MANUAL CALCULATION START =====');
  
  try {
    // 1. Get values - try ALL possible field names
    String? days = getFieldValue('Days') ?? dataMap['days']?.toString();
    
    String? sundays = getFieldValue('Sundays In Month') ?? 
                      dataMap['sundaysInMonth']?.toString();
    
    // 🔥 Try both Saturday field names
    String? saturdays = getFieldValue('Saturday In Month') ?? 
                        getFieldValue('Non Working Saturday In Month') ??
                        dataMap['saturdayInMonth']?.toString() ??
                        dataMap['nonWorkingSaturdayInMonth']?.toString();
    
    // Try both Salary field names
    String? salary = getFieldValue('Salary') ?? 
                     getFieldValue('Salay') ??
                     dataMap['salary']?.toString() ??
                     dataMap['salay']?.toString();
    
    // Get Leave
    String? leave = getFieldValue('Leave Without Pay') ?? 
                    dataMap['leaveWithoutPay']?.toString() ??
                    dataMap['leave']?.toString() ??
                    '0';
    
    print('📊 Values - Days: $days, Sundays: $sundays, Saturdays: $saturdays, Salary: $salary, Leave: $leave');
    
    // 2. Calculate Working Days
    if (days != null && days.isNotEmpty) {
      int daysInt = int.tryParse(days) ?? 0;
      int sundaysInt = int.tryParse(sundays ?? '0') ?? 0;
      int saturdaysInt = int.tryParse(saturdays ?? '0') ?? 0;
      
      int workingDays = daysInt - sundaysInt - saturdaysInt;
      if (workingDays < 0) workingDays = 0;
      
      String workingDaysStr = workingDays.toString();
      
      // Update Working Days
      setFieldValue('Working Days In Month', workingDaysStr);
      dataMap['workingDaysInMonth'] = workingDaysStr;
      this.workingDays.value = workingDaysStr;
      
      print('✅ Working Days: $workingDaysStr');
      
      // 3. Calculate Per Day Salary
      if (salary != null && salary.isNotEmpty && workingDays > 0) {
        double salaryDouble = double.tryParse(salary) ?? 0;
        double perDaySalary = salaryDouble / workingDays;
        String perDaySalaryStr = perDaySalary.toStringAsFixed(3);
        
        setFieldValue('Per Day Salary', perDaySalaryStr);
        dataMap['perDaySalary'] = perDaySalaryStr;
        this.perDaySalary.value = perDaySalaryStr;
        
        print('✅ Per Day Salary: $perDaySalaryStr');
        
        // 4. Calculate Net Salary
        double leaveDouble = double.tryParse(leave ?? '0') ?? 0;
        
        if (leaveDouble > 0) {
          double netSalary = salaryDouble - (leaveDouble * perDaySalary);
          if (netSalary < 0) netSalary = 0;
          
          String netSalaryStr = netSalary.toStringAsFixed(3);
          
          setFieldValue('Net Salary', netSalaryStr);
          dataMap['netSalary'] = netSalaryStr;
          this.netSalary.value = netSalaryStr;
          
          print('✅ Net Salary: $netSalaryStr');
        } else {
          setFieldValue('Net Salary', salary);
          dataMap['netSalary'] = salary;
          this.netSalary.value = salary ?? '0';
        }
      }
    }
    
    update();
    print('🧮 ===== MANUAL CALCULATION END =====');
  } catch (e) {
    print('❌ Manual calculation error: $e');
  }
}
// Check if any input field has value
  bool hasAnyInputValue() {
    for (var field in labellist) {
      // Sirf input fields check karo (expression field ko ignore karo)
      if (field['type'] != 'expression') {
        String? value = getFieldValue(field['label']);
        if (value != null && value.isNotEmpty && value != "null") {
          print('✅ Found input value in: ${field['label']} = $value');
          return true;
        }
      }
    }
    print('❌ No input values found');
    return false;
  }
// Update these methods in your Uiformcontroller class

Future<String> calculateExpression(String expression) async {
    print('🧮 Original Expression: "$expression"');

    // 🔥 Fix field names
    String fixedExpression = fixExpressionFields(expression);
    print('🧮 Fixed Expression: "$fixedExpression"');

    try {
      if (fixedExpression.isEmpty) return '';

      String calculatedExpression = fixedExpression;

      // First handle quoted fields (like @'Second Text')
      final quotedFieldPattern = RegExp(r"@'([^']+)'");
      final quotedMatches = quotedFieldPattern.allMatches(calculatedExpression);

      for (final match in quotedMatches) {
        final fieldName = match.group(1);
        if (fieldName != null) {
          print('🔍 Looking for quoted field: "$fieldName"');

          // Try to get value by exact label first
          String? fieldValue = getFieldValue(fieldName);

          if (fieldValue == null ||
              fieldValue.isEmpty ||
              fieldValue == "null") {
            // Try by code if not found by label
            fieldValue = getFieldValueByCode(fieldName);
          }

          // 🔥 FIX: Agar value null ya empty hai toh 0 use karo
          String numericValue = '0';
          if (fieldValue != null &&
              fieldValue.isNotEmpty &&
              fieldValue != "null") {
            // Remove non-numeric characters but keep decimal point and minus sign
            numericValue = fieldValue.replaceAll(RegExp(r'[^\d.-]'), '');
            if (numericValue.isEmpty) numericValue = '0';
          }

          calculatedExpression =
              calculatedExpression.replaceAll("@'$fieldName'", numericValue);
          print('🔍 Using value: $numericValue for: $fieldName');
        }
      }

      // Then handle regular fields (without quotes)
      final fieldPattern = RegExp(r'@(\w+)');
      final regularMatches = fieldPattern.allMatches(calculatedExpression);

      for (final match in regularMatches) {
        final fieldName = match.group(1);
        if (fieldName != null) {
          // Skip if already processed in quoted pattern
          if (calculatedExpression.contains("@'$fieldName'")) continue;

          print('🔍 Looking for regular field: "$fieldName"');

          // Special handling for common fields
          String? fieldValue;

          // Try common mappings
          if (fieldName == 'Text' || fieldName == 'text') {
            fieldValue = getFieldValue('Text') ?? getFieldValue('text') ?? '0';
          } else if (fieldName == 'Second' || fieldName == 'second') {
            fieldValue =
                getFieldValue('Second Text') ?? getFieldValue('second') ?? '0';
          } else {
            fieldValue =
                getFieldValue(fieldName) ?? getFieldValueByCode(fieldName);
          }

          // 🔥 FIX: Agar value null ya empty hai toh 0 use karo
          String numericValue = '0';
          if (fieldValue != null &&
              fieldValue.isNotEmpty &&
              fieldValue != "null") {
            numericValue = fieldValue.replaceAll(RegExp(r'[^\d.-]'), '');
            if (numericValue.isEmpty) numericValue = '0';
          }

          calculatedExpression =
              calculatedExpression.replaceAll('@$fieldName', numericValue);
          print('🔍 Using value: $numericValue for: $fieldName');
        }
      }

      // Clean up any remaining @ symbols
      calculatedExpression = calculatedExpression
          .replaceAll('@', '')
          .replaceAll(RegExp(r'[^\d\s\+\-\*\/\(\)\.]'), '')
          .replaceAll(RegExp(r'\s+'), '');

      print('🧮 Final expression: "$calculatedExpression"');

      if (calculatedExpression.isEmpty) return '';

      double? result = _evaluateMathExpression(calculatedExpression);

      if (result != null) {
        String formattedResult;
        if (result == result.roundToDouble()) {
          formattedResult = result.round().toString();
        } else {
          formattedResult = result.toStringAsFixed(3);
        }
        return formattedResult;
      }

      return '';
    } catch (e) {
      print('🧮 Error: $e');
      return '';
    }
  }
// Add this helper method to get value by code
  String? getFieldValueByCode(String code) {
    print('🔍 Looking for field by code: "$code"');

    for (var field in labellist) {
      String fieldCode = field['code']?.toString() ?? '';
      String fieldLabel = field['label']?.toString() ?? '';

      if (fieldCode == code) {
        String? value = getFieldValue(fieldLabel);
        if (value != null && value.isNotEmpty && value != "null") {
          print('🔍 Found by code: $fieldLabel = $value');
          return value;
        }
      }
    }
    return null;
  }

// Update fixExpressionFields method
  String fixExpressionFields(String expression) {
    print('🔧 Fixing expression: $expression');

    String fixed = expression;

    // Handle field names with spaces - convert to quoted format
    // This regex finds @ followed by words with spaces until next operator or end
    final unquotedPattern = RegExp(r'@([a-zA-Z\s]+?)(?=[+\-*/()]|$)');

    fixed = fixed.replaceAllMapped(unquotedPattern, (match) {
      String fieldName = match.group(1)?.trim() ?? '';

      // If it's already quoted, return as is
      if (fieldName.startsWith("'") && fieldName.endsWith("'")) {
        return "@$fieldName";
      }

      // Check if this is a multi-word field name
      if (fieldName.contains(' ')) {
        return "@'$fieldName'";
      }

      return "@$fieldName";
    });

    // Special case fixes
    fixed = fixed
        .replaceAll('@Text', '@Text')
        .replaceAll(
            '@Second', '@\'Second Text\'') // Map 'Second' to 'Second Text'
        .replaceAll('@text', '@Text')
        .replaceAll('@second', '@\'Second Text\'');

    print('🔧 Fixed expression: $fixed');
    return fixed;
  }

// Update updateAllExpressionFields to ensure proper calculation order
void updateAllExpressionFields() {
  print('🟢===== UPDATE ALL EXPRESSION FIELDS =====');
  
  // Check if any input field has value
  bool hasInput = hasAnyInputValue();
  if (!hasInput) {
    print('❌ No input values found - clearing expressions');
    
    // Clear all expression fields
    for (var field in labellist) {
      if (field['type'] == 'expression') {
        String label = field['label'] ?? '';
        String code = field['code'] ?? '';
        
        setFieldValue(label, '');
        dataMap[code] = '';
        
        // Update observables if needed
        if (label == 'Working Days In Month') {
          workingDays.value = '';
        } else if (label == 'Per Day Salary') {
          perDaySalary.value = '';
        } else if (label == 'Net Salary') {
          netSalary.value = '';
        }
      }
    }
    
    update();
    return;
  }

  // First, identify all expression fields and their dependencies
  List<Map<String, dynamic>> expressionFields = [];

  for (var field in labellist) {
    if (field['type'] == 'expression') {
      expressionFields.add(field);
    }
  }

  // Calculate in order - simple fields first, complex later
  // For now, just calculate all
  for (var field in expressionFields) {
    String expression = field['expression'] ?? field['rule'] ?? '';
    String label = field['label'] ?? '';

    print('🧮 Field Label: $label');
    print('🧮 Expression: $expression');

    if (expression.isNotEmpty) {
      if (!_isProcessingExpression(label)) {
        _markExpressionProcessing(label, true);

        calculateExpression(expression).then((result) {
          print('🧮 Calculated result for $label: "$result"');

          if (result.isNotEmpty) {
            // Skip setting if it's an expression field
            if (!_isExpressionField(label)) {
              setFieldValue(label, result);
            }
            dataMap[field['code']] = result;

            // Update the observable if needed
            if (label == 'Working Days In Month') {
              workingDays.value = result;
            } else if (label == 'Per Day Salary') {
              perDaySalary.value = result;
            } else if (label == 'Net Salary') {
              netSalary.value = result;
            } else if (label == 'Leave Without Pay') {
              leaveWithoutPay.value = result;
            }
          }

          _markExpressionProcessing(label, false);
          update();
        });
      }
    }
  }

  print('🟢 Total expression fields triggered: ${expressionFields.length}');
}
// Helper to check if field is expression
  bool _isExpressionField(String label) {
    for (var field in labellist) {
      if (field['label'] == label && field['type'] == 'expression') {
        return true;
      }
    }
    return false;
  }
 
  String removeTrailingZeros(String value) {
    if (value.isEmpty) return '';
    if (!value.contains('.')) return value;

    value = value.replaceAll(RegExp(r'0+$'), '');
    if (value.endsWith('.')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
// Helper function to remove trailing zeros

  var appurl = "".obs;
  var pagetitle = "".obs;
  var code = "".obs;
  var appCode = "".obs;
  var collectionName = "".obs;
  var applicationurl = "".obs;
  var saveformcode = "".obs;
  var saveform_id = 0.obs; // Making it observable
  var userstoryName = "".obs;
  var imagePaths = <String, String?>{}.obs;
  var docPaths = <String, String?>{}.obs;
  var resulterror = <String, String?>{}.obs;
  var uploadimage = <String, String?>{}.obs;
  var uploadDocument = <String, String?>{}.obs;
  var isLoading = false.obs;
  HttpServices httpServices = HttpServices();
  String? admissionId;
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;
  RxList<GroupLabels> grouplabellist = <GroupLabels>[].obs;
  Map<String, dynamic> dataMap = {};
  RxList<dynamic> labellist = RxList<dynamic>();
  RxList<dynamic> uniquefilteredList = RxList<dynamic>();
  RxList<dynamic> preloadparentUsecases = RxList<dynamic>();
  RxList<dynamic> uniquelist = RxList<dynamic>();
  RxMap<String, List<dynamic>> prelaodlist = RxMap<String, List<dynamic>>();
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  List<String> globalYUsecases = [];
  Map<String, dynamic>? previousResponse;
  RxMap<String, String> initialValues = <String, String>{}.obs;
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
  ];
  final RxMap<String, String> _fieldValues = <String, String>{}.obs;
  final TableviewController viewcontroller = Get.put(TableviewController());
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  updateappurl(
    var menutitle,
    var appurldata,
  ) {
    appurl.value = appurldata;
    pagetitle.value = menutitle;
  }

  final RxBool showTextField = false.obs;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Map<String, bool> fieldRequiredMap = {};
  Map<String, String> fieldCodeMap = {};
  bool validateLocationField(
      {required bool requiredField, required String fieldCode}) {
    final lat = latController.text.trim();
    final lng = longController.text.trim();

    if (requiredField && (lat.isEmpty || lng.isEmpty)) {
      resulterror[fieldCode] = 'Please set the location';
      return false;
    } else {
      resulterror.remove(fieldCode);
      return true;
    }
  }

  @override
  void onClose() {
    // Dispose all TextEditingControllers
    latController.dispose();
    longController.dispose();
    imagePaths.clear();
    docPaths.clear();
    uploadimage.clear();
    uploadDocument.clear();
    _fieldValues.clear();
    dataMap.clear();
    previousResponse = null;

    super.onClose();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    saveform_id.value = 0;
  }

 void clearForm() {
    saveform_id.value = 0;
    resulterror.clear();
    dataMap.clear();
    previousResponse = null;

    imagePaths.clear();
    docPaths.clear();
    uploadimage.clear();
    uploadDocument.clear();
    latController.clear();
    longController.clear();
    showTextField.value = false;

    _fieldValues.clear();
    initialValues.clear();

    // ✅ CLEAR EXPRESSION OBSERVABLES
    workingDays.value = '';
    perDaySalary.value = '';
    netSalary.value = '';
    leaveWithoutPay.value = '';

    // Re-apply default values immediately
    for (var item in labellist) {
      String fieldCode = item['code'] ?? '';
      String fieldLabel = item['label'] ?? '';
      String? defaultValue = item['defaultValue'];
      String fieldType = item['type'] ?? '';

      // ✅ SKIP EXPRESSION FIELDS - they should be empty on fresh form
      if (fieldType == 'expression') {
        setFieldValue(fieldLabel, '');
        dataMap[fieldCode] = '';
        continue;
      }

      // Only set defaultValue if it exists and field is not expression
      if (defaultValue != null && defaultValue.isNotEmpty) {
        setFieldValue(fieldLabel, defaultValue);
        dataMap[fieldCode] = defaultValue;
      }
    }

    if (viewcontroller.appurl.isNotEmpty) {
      viewcontroller.GetForm_API(viewcontroller.appurl.value);
    }

    viewcontroller.CurrentPage.value = 0;
    Get.find<TableviewController>().update();
    update();
  }
  void clearInitialValue(String code) {
    initialValues.remove(code);
    dataMap.remove(code);
    update();
  }

  var isuserFilter = 0.obs;

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

        isuserFilter.value = firstAccess['userFilter'] ?? 0; // If available
      } else {}
    } else {}
  }

  Future<Map<String, dynamic>?> Savecomboitem(String formID, var value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
    }
    print('Savecomboitem====formID==========>${formID}');
    print('Savecomboitem====value==========>${value}');

    try {
      final response = await httpServices.tagitemsave(
          label: "Combobox",
          type: "combobox",
          userstoryId: viewcontroller.userstortyid.value
              .toString(), // Ensure it's an int
          id: formID, // Ensure it's an int
          values: value);

      if (response != null && response['success'] == true) {
        print('SaveTag====Combobox==========>${response}');

        return response;
      } else {
        return response;
      }
    } catch (e) {
      return {'message': 'Error occurred while saving the form'};
    }
  }

  dynamic getInitialValues(String fieldCode, String label) {
    // print('Fetching initial value for field code: $fieldCode');
    if (dataMap.containsKey(fieldCode)) {
      var value = dataMap[fieldCode];
      setFieldValue(label, value.toString());
      if (value is int) {
        setFieldValue(label, value.toString());
        return value.toString();
      }
      return value;
    }
    return null;
  }

  void setInitialValue(String code, String value) {
    initialValues[code] = value;
    update();
  }

  String? getFieldValue(String label) {
    // First try exact match
    if (_fieldValues.containsKey(label)) {
      return _fieldValues[label];
    }
    
    // Try mapped field name
    if (fieldNameMapping.containsKey(label)) {
      String mappedLabel = fieldNameMapping[label]!;
      if (_fieldValues.containsKey(mappedLabel)) {
        print('🔄 Mapped "$label" to "$mappedLabel" = ${_fieldValues[mappedLabel]}');
        return _fieldValues[mappedLabel];
      }
    }
    
    return null;
  }
  
  // final controllers = <String, TextEditingController>{}.obs;

void setFieldValue(String label, dynamic value) {
  String valueStr = value?.toString() ?? '';
  
  // Don't set expression fields manually
  for (var field in labellist) {
    if (field['label'] == label && field['type'] == 'expression') {
      print('⚠️ Skipping expression field: $label');
      return;
    }
  }
  
  _fieldValues[label] = valueStr;
  
  // Special handling for Salary
  if (label == 'Salary' || label == 'Salay') {
    _fieldValues['Salary'] = valueStr;
    _fieldValues['Salay'] = valueStr;
    dataMap['salary'] = valueStr;
    dataMap['salay'] = valueStr;
  }
  
  print('📝 Set $label = $valueStr');
  update();
}
  Future<void> GetForm_API(String id) async {
    buttons.clear();
    grouplabellist.clear();
    fields.clear();
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;
      saveformcode.value = data!.code.toString();
      userstoryName.value = data.userstoryName.toString();
      buttons.assignAll(data.buttons);
      fields.assignAll(data.fields);
      grouplabellist.assignAll(data.groupLabels);
      await Getitemcode(data.userstoryId.toString());
      await Getattributefield(data.userstoryId.toString());

      update();
    } else {}
  }

  var usecase;
  final ApiBaseHelper helper = ApiBaseHelper();
  Future Getseachdata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      return {'success': false, 'message': 'Session ID is missing'};
    }

    Map<String, dynamic> reqBody = {};

    //  Loop through fields and add valid values to payload
    for (var field in filterlabellist) {
      var fieldValue = getFieldValue(field['label']);

      if ((fieldValue is String && fieldValue.isNotEmpty) ||
          (fieldValue is int && fieldValue != 0)) {
        dynamic formattedValue = fieldValue;

        if (field['refKey'] == 1 &&
            RegExp(r'^\d+$').hasMatch(fieldValue.toString())) {
          formattedValue = int.parse(fieldValue.toString());
        }

        reqBody[field['code']] = formattedValue;
      }
    }

    try {
      final response = await helper.postApi(
        "api/v1/${appCode.value}/${code.value}/search;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        var dataResponse = response['result']['data'] as List;

        print("dataResponse............................... ${dataResponse}");

        if (response != null && response['success'] == true) {
          var dataResponse = response['result']['data'] as List;

          if (dataResponse.isNotEmpty) {
            final record = dataResponse[0] as Map<String, dynamic>;
            dataMap.assignAll(record);
            for (var group in grouplabellist) {
              var allFields = getGroupsField(group.label);
              for (var field in allFields) {
                String label = field['label'];
                String code = field['code'];

                if (record.containsKey(code)) {
                  String value = record[code]?.toString() ?? "";

                  // Save in controller
                  setFieldValue(label, value);
                  setInitialValue(code, value);
                  dataMap[code] = value;

                  update();
                }
              }
            }
          }

          update(); // Notifies UI to rebuild
          return response;
        }

        update(); // Trigger GetX UI update
        return response;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error occurred while saving the form'
      };
    }
  }

  dynamic getInitialValue(String fieldCode) {
    // print('Fetching initial value for field code: $fieldCode');
    if (dataMap.containsKey(fieldCode)) {
      var value = dataMap[fieldCode];

      if (value is int) {
        setFieldValue(fieldCode, value.toString());
        return value.toString();
      }
      return value;
    }
    return null;
  }

  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(
      id: formid,
    );

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data']; // Cast to List<dynamic>
      usecase = dataResponse;
      if (dataResponse['parentUsecases'] is Map<String, dynamic>) {
        // Convert the map to a list of entries
        preloadparentUsecases.assignAll(
          dataResponse['parentUsecases'].entries.map((entry) {
            return {'key': entry.key, 'value': entry.value};
          }).toList(),
        );
      } else if (dataResponse['parentUsecases'] is List) {
        // If already a list, directly assign
        preloadparentUsecases.assignAll(dataResponse['parentUsecases']);
      } else {}

      code.value = dataResponse['code'];
      appCode.value = dataResponse['appCode'];
      collectionName.value = dataResponse['collectionName'];
      // uniquelist.addAll(dataResponse['unique'][0] ?? []);

      update();
    } else {}
  }

  void onChange(Map<String, dynamic> e, dynamic val) {
    final primaryUsecase = e['primaryUsecase'];
    final depAttribute = e['depAttribute'];

    final List<dynamic>? l = prelaodlist[primaryUsecase];
    if (l == null) return;

    for (var item in l) {
      if (item['id'] == val) {
        fields[depAttribute] = item['name'];
        break;
      }
    }
    // Check for dependency filter
    if (usecase != null &&
        usecase['parentUsecaseDependency'] != null &&
        usecase['parentUsecaseDependency'][primaryUsecase] != null) {
      primaryUsecaseDependencyFilter(
        usecase['parentUsecaseDependency'][primaryUsecase],
        val,
      );
    }
  }

  void primaryUsecaseDependencyFilter(
      Map<String, dynamic> data, dynamic val) async {
    final code = data['id']; // e.g., "componentNameId"
    final codeVALUE = data['code']; // e.g., "componentNameId"

    // Combine as required
    String formattedVal = "$code=$val";
    final paracode = data['code'];
    if (paracode == null) return;

    final parts = paracode.toString().split('.');
    if (parts.length < 2) return;

    final appCode = parts[0];
    final codes = parts[1];
    getdata(
      appCode,
      codes,
      formattedVal,
    );
  }

  Future<void> getdata(String appcode, String code, String filterParams) async {
    try {
      var response = await httpServices.getParentFilterData(
        appCode: appcode,
        hrStatus: code,
        val: filterParams,
      );

      if (response?['success'] == true) {
        var useCases = globalYUsecases;
        var result = response?['result'];

        for (var useCase in useCases) {
          if (result.containsKey(useCase)) {
            var data = result[useCase];

            if (data is List) {
              // Replace old list with new incoming data
              prelaodlist[useCase] = List.from(data);

              debugPrint(
                  'prelaodlist[$useCase] updated with ${data.length} items');
            }
          }
        }

        update();
      }
    } catch (e) {
      debugPrint('Error calling API: $e');
    }
  }

Future<void> Getattributefield(String formId) async {
  labellist.clear();
  var res = await httpServices.Getlistattribute(formId: formId);
  
  print('📥 Getlistattribute RESPONSE: $res');
  
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

    // 🔥 IMPORTANT: Add fields from backend response
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
        
        // 🔥 Store both code and label for reference
        print('📝 Field loaded - Code: ${item['code']}, Label: ${item['label']}');
      }

      // Apply default value if exists
      String fieldCode = item['code'] ?? '';
      String fieldLabel = item['label'] ?? '';
      String? defaultValue = item['defaultValue'];

      if (defaultValue != null && defaultValue.isNotEmpty && !dataMap.containsKey(fieldCode)) {
        setFieldValue(fieldLabel, defaultValue);
        dataMap[fieldCode] = defaultValue;
      }
    }

    if (sortedFilteredList.isNotEmpty) {
      labellist.assignAll(sortedFilteredList);
    }

    var uniqueUsecases = <String>{};
    for (var dashboardItem in labellist) {
      String yUsecase = dashboardItem['primaryUsecase'] ?? "";
      if (yUsecase.isNotEmpty) {
        uniqueUsecases.add(yUsecase);
      }
    }
    
    globalYUsecases = uniqueUsecases.toList();

    if (globalYUsecases.isNotEmpty) {
      await Getpreloadfield(code.value, appurl.value);
    }
    
    update();
  }
}
  List getGroupsField(String label) {
    var result = labellist
        .where((field) => field.containsKey('group') && field['group'] == label)
        .toList();
    return result;
  }

  List getItemsWithoutGroup() {
    return labellist
        .where((field) => field['group'] == "" || field['group'] == null)
        .toList();
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
      // update();
      return false;
    } catch (e) {
      return false;
    }
  }

  dynamic _parseToComparable(String value) {
    value = value.replaceAll('"', '').trim(); // Remove quotes
    // update();
    return double.tryParse(value) ??
        value; // Convert to number if possible, else keep as string
  }

  Future<void> Getpreloadfield(String name, String appurl) async {
    var res = await httpServices.Getpreloaddata(
        formname: name, appurl: appCode.value);
    if (res != null && res['success'] == true) {
      var result = res['result'] ?? {}; // Ensure result is a Map

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
  // Add these methods to your Uiformcontroller class

// Helper method to get field value by code or label
String? getFieldValueByCodeOrLabel(String fieldIdentifier) {
  print('🔍 Looking for field: "$fieldIdentifier"');
  
  // Clean the identifier
  String cleanIdentifier = fieldIdentifier.trim();
  
  // 🔥 IMPORTANT: Exact match priority
  
  // 1. First try exact label match (highest priority)
  for (var field in labellist) {
    String fieldLabel = field['label']?.toString() ?? '';
    if (fieldLabel == cleanIdentifier) {
      String? value = getFieldValue(fieldLabel);
      if (value != null && value.isNotEmpty && value != "null") {
        print('🔍 Exact label match: $fieldLabel = $value');
        return value;
      }
    }
  }
  
  // 2. Then try exact code match
  for (var field in labellist) {
    String fieldCode = field['code']?.toString() ?? '';
    if (fieldCode == cleanIdentifier) {
      String? value = getFieldValue(field['label']);
      if (value != null && value.isNotEmpty && value != "null") {
        print('🔍 Exact code match: $fieldCode = $value');
        return value;
      }
    }
  }
  
  // 3. Try case-insensitive match
  for (var field in labellist) {
    String fieldLabel = field['label']?.toString() ?? '';
    if (fieldLabel.toLowerCase() == cleanIdentifier.toLowerCase()) {
      String? value = getFieldValue(fieldLabel);
      if (value != null && value.isNotEmpty && value != "null") {
        print('🔍 Case-insensitive label match: $fieldLabel = $value');
        return value;
      }
    }
  }
  
  // 4. Try mapping for common variations
  Map<String, String> exactMapping = {
    'Salary': 'Salay',      // अगर Salary ढूंढ रहे हैं तो Salay check करें
    'Salay': 'Salary',      // अगर Salay ढूंढ रहे हैं तो Salary check करें
    'salary': 'Salay',
    'salay': 'Salary',
  };
  
  if (exactMapping.containsKey(cleanIdentifier)) {
    String mappedField = exactMapping[cleanIdentifier]!;
    for (var field in labellist) {
      String fieldLabel = field['label']?.toString() ?? '';
      if (fieldLabel == mappedField) {
        String? value = getFieldValue(fieldLabel);
        if (value != null && value.isNotEmpty && value != "null") {
          print('🔍 Mapped field match: $mappedField = $value');
          return value;
        }
      }
    }
  }
  
  // 5. ONLY as last resort - partial match (but exclude expression fields)
  for (var field in labellist) {
    String fieldLabel = field['label']?.toString() ?? '';
    String fieldType = field['type']?.toString() ?? '';
    
    // Skip expression fields for partial match
    if (fieldType == 'expression') continue;
    
    if (fieldLabel.toLowerCase().contains(cleanIdentifier.toLowerCase())) {
      String? value = getFieldValue(fieldLabel);
      if (value != null && value.isNotEmpty && value != "null") {
        print('🔍 Partial match (non-expression): $fieldLabel = $value');
        return value;
      }
    }
  }
  
  print('🔍 No valid value found for: $fieldIdentifier');
  return null;
}

  
  void onFieldValueChanged(String fieldCode, String newValue) {
    // Update the field value in dataMap
    dataMap[fieldCode] = newValue;

    // Find which expressions depend on this field
    List<String> dependentExpressions = [];

    for (var field in labellist) {
      if (field['type'] == 'expression') {
        String expression = field['expression'] ?? field['rule'] ?? '';
        if (expression.contains('@$fieldCode')) {
          dependentExpressions.add(field['code']);
        }
      }
    }

    // Recalculate dependent expressions
    if (dependentExpressions.isNotEmpty) {
      print(
          '🔄 Field $fieldCode changed, recalculating: $dependentExpressions');
      updateAllExpressionFields();
    }
  }


  final Set<String> _processingExpressions = {};

  bool _isProcessingExpression(String label) {
    return _processingExpressions.contains(label);
  }

  void _markExpressionProcessing(String label, bool isProcessing) {
    if (isProcessing) {
      _processingExpressions.add(label);
    } else {
      _processingExpressions.remove(label);
    }
  }

// Update the calculateExpression method to be more robust

// Enhanced math expression evaluator
  double? _evaluateMathExpression(String expression) {
    try {
      print('🧮 Evaluating: "$expression"');

      // Remove spaces
      expression = expression.replaceAll(' ', '');

      // Handle empty expression
      if (expression.isEmpty) return 0.0;

      // Use dart:math's expression evaluation
      // This is a simple implementation - for complex expressions consider using a package

      // First handle parentheses recursively
      while (expression.contains('(')) {
        final RegExp parenRegExp = RegExp(r'\(([^\(\)]+)\)');
        final match = parenRegExp.firstMatch(expression);

        if (match != null) {
          String innerExpr = match.group(1)!;
          double? innerResult = _evaluateSimpleExpression(innerExpr);

          if (innerResult == null) return null;

          expression =
              expression.replaceFirst(match.group(0)!, innerResult.toString());
        } else {
          break;
        }
      }

      // Evaluate the final expression
      return _evaluateSimpleExpression(expression);
    } catch (e) {
      print('🧮 Math evaluation error: $e');
      return null;
    }
  }

// Evaluate simple expressions without parentheses
  double? _evaluateSimpleExpression(String expr) {
    try {
      // Handle multiplication and division first
      final RegExp multDivRegExp =
          RegExp(r'(\-?\d+\.?\d*)([*/])(\-?\d+\.?\d*)');

      while (expr.contains('*') || expr.contains('/')) {
        final match = multDivRegExp.firstMatch(expr);
        if (match != null) {
          double left = double.parse(match.group(1)!);
          double right = double.parse(match.group(3)!);
          String op = match.group(2)!;

          double result = op == '*' ? left * right : left / right;
          expr = expr.replaceFirst(match.group(0)!, result.toString());
        } else {
          break;
        }
      }

      // Handle addition and subtraction
      final RegExp addSubRegExp =
          RegExp(r'(\-?\d+\.?\d*)([+\-])(\-?\d+\.?\d*)');

      while (expr.contains('+') ||
          (expr.contains('-') && expr.lastIndexOf('-') > 0)) {
        final match = addSubRegExp.firstMatch(expr);
        if (match != null) {
          double left = double.parse(match.group(1)!);
          double right = double.parse(match.group(3)!);
          String op = match.group(2)!;

          double result = op == '+' ? left + right : left - right;
          expr = expr.replaceFirst(match.group(0)!, result.toString());
        } else {
          break;
        }
      }

      return double.tryParse(expr);
    } catch (e) {
      print('🧮 Simple evaluation error: $e');
      return null;
    }
  }

// Uiformcontroller mein expression calculation properly implement karein

  double _parseExpression(String expr) {
    // Simple parser implementation
    // Agar complex calculations hain toh 'dart_expression' package use karein

    expr = expr.replaceAll(' ', '');

    // Parentheses handle karein
    while (expr.contains('(')) {
      final RegExp parenExp = RegExp(r'\(([^()]+)\)');
      final match = parenExp.firstMatch(expr);
      if (match != null) {
        final innerResult = _parseExpression(match.group(1)!);
        expr = expr.replaceFirst(match.group(0)!, innerResult.toString());
      } else {
        break;
      }
    }

    // Multiplication/Division
    final RegExp multDivExp = RegExp(r'(\d+\.?\d*)([*/])(\d+\.?\d*)');
    while (expr.contains('*') || expr.contains('/')) {
      final match = multDivExp.firstMatch(expr);
      if (match != null) {
        final left = double.parse(match.group(1)!);
        final right = double.parse(match.group(3)!);
        final op = match.group(2)!;

        double result = op == '*' ? left * right : left / right;
        expr = expr.replaceFirst(match.group(0)!, result.toString());
      } else {
        break;
      }
    }

    // Addition/Subtraction
    final RegExp addSubExp = RegExp(r'(\d+\.?\d*)([+\-])(\d+\.?\d*)');
    while (
        expr.contains('+') || (expr.contains('-') && !expr.startsWith('-'))) {
      final match = addSubExp.firstMatch(expr);
      if (match != null) {
        final left = double.parse(match.group(1)!);
        final right = double.parse(match.group(3)!);
        final op = match.group(2)!;

        double result = op == '+' ? left + right : left - right;
        expr = expr.replaceFirst(match.group(0)!, result.toString());
      } else {
        break;
      }
    }

    return double.tryParse(expr) ?? 0.0;
  }

// Safe evaluation method
  double? _safeEval(String expression) {
    try {
      // Using dart:math's expression evaluation
      // For complex expressions, consider using a proper library
      final List<String> tokens = expression
          .split(RegExp(r'(?<=[\d)])(?=[+\-*/])|(?<=[+\-*/])(?=[\d(])'));

      // Simple implementation - for production use a proper expression parser
      // This is a basic example - you might want to use a package like 'expressions' or 'math_expressions'

      // Using a safer approach - evaluate step by step
      // For now, we'll use a simple approach
      return _parseExpression(expression);
    } catch (e) {
      return null;
    }
  }

// Method to trigger expression recalculation
  void recalculateExpressions() {
    for (var field in labellist) {
      if (field['type'] == 'expression') {
        String expression = field['expression'] ?? '';
        if (expression.isNotEmpty) {
          calculateExpression(expression).then((result) {
            if (result.isNotEmpty) {
              setFieldValue(field['label'], result);
              dataMap[field['code']] = result;
            }
          });
        }
      }
    }
  }
Future<Map<String, dynamic>?> GetUserData(
    String code, String rule, String value) async {
  try {
    print('📤 ===== GET USER DATA START =====');
    print('📤 code: $code');
    print('📤 rule: $rule');
    print('📤 value: $value');
    print('📤 collectionName: ${collectionName.value}');
    
    Map<String, dynamic> reqBody = {
      code: value.toString(),
      "collectionName": collectionName.value,
      "id": 0
    };

    // Add all current values from dataMap
    dataMap.forEach((key, val) {
      if (key != code && key != "collectionName" && key != "id") {
        reqBody[key] = val?.toString() ?? '';
      }
    });

    print('📤 Final Request Body:');
    reqBody.forEach((key, val) {
      print('📤   $key: $val');
    });

    // Make API call
    print('📤 Calling API with rule: $rule');
    var res = await httpServices.Getexecutedata(
      rule: rule,
      reqBody: reqBody,
    );

    print('📥 GetUserData Response: $res');

    if (res != null) {
      print('📥 Response success: ${res['success']}');
      print('📥 Response result: ${res['result']}');
      
      if (res['success'] == true && res['result'] != null) {
        var resultData = res['result'];
        print('📥 Result data type: ${resultData.runtimeType}');
        print('📥 Result data: $resultData');
        
        if (resultData is Map) {
          // Update dataMap with new values
          resultData.forEach((key, val) {
            dataMap[key] = val;
            print('✅ Updated dataMap[$key] = $val');
          });
          
          previousResponse = Map.from(dataMap);

          // Update all field values in UI
          for (var item in labellist) {
            String fieldCode = item['code'];
            String fieldLabel = item['label'];

            if (dataMap.containsKey(fieldCode)) {
              var val = dataMap[fieldCode];
              setFieldValue(fieldLabel, val?.toString() ?? '');
              print('✅ UI Updated: $fieldLabel = $val');
            }
          }

          update();
          print('✅ GetUserData completed successfully');
          return res;
        } else {
          print('❌ resultData is not a Map: ${resultData.runtimeType}');
        }
      } else {
        print('❌ Response success false or result null');
      }
    } else {
      print('❌ Response is null');
    }

    print('📤 ===== GET USER DATA END =====');
    return res;
  } catch (e, stackTrace) {
    print('❌ GetUserData Error: $e');
    print('❌ StackTrace: $stackTrace');
    return null;
  }
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
}