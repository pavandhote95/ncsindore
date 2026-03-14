import 'dart:convert';
import 'dart:io';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:expressions/expressions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'Childcontroller.dart';


class EditformController extends GetxController {

  // Add these properties to EditformController
  var workingDays = ''.obs;
  var perDaySalary = ''.obs;
  var netSalary = ''.obs;

// Add these methods to EditformController

  void calculateAllFields() {
    print('🧮 ===== MANUAL CALCULATION START =====');

    try {
      // 1. Get values - try ALL possible field names
      String? days = getFieldValue('Days') ?? dataMap['days']?.toString();

      String? sundays = getFieldValue('Sundays In Month') ??
          dataMap['sundaysInMonth']?.toString();

      // Try both Saturday field names
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

      print(
          '📊 Values - Days: $days, Sundays: $sundays, Saturdays: $saturdays, Salary: $salary, Leave: $leave');

      // 2. Calculate Working Days
      if (days != null && days.isNotEmpty) {
        int daysInt = int.tryParse(days) ?? 0;
        int sundaysInt = int.tryParse(sundays ?? '0') ?? 0;
        int saturdaysInt = int.tryParse(saturdays ?? '0') ?? 0;

        int workingDaysValue = daysInt - sundaysInt - saturdaysInt;
        if (workingDaysValue < 0) workingDaysValue = 0;

        String workingDaysStr = workingDaysValue.toString();

        // Update Working Days
        setFieldValue('Working Days In Month', workingDaysStr);
        dataMap['workingDaysInMonth'] = workingDaysStr;
        this.workingDays.value = workingDaysStr;

        print('✅ Working Days: $workingDaysStr');

        // 3. Calculate Per Day Salary
        if (salary != null && salary.isNotEmpty && workingDaysValue > 0) {
          double salaryDouble = double.tryParse(salary) ?? 0;
          double perDaySalaryValue = salaryDouble / workingDaysValue;
          String perDaySalaryStr = perDaySalaryValue.toStringAsFixed(3);

          setFieldValue('Per Day Salary', perDaySalaryStr);
          dataMap['perDaySalary'] = perDaySalaryStr;
          this.perDaySalary.value = perDaySalaryStr;

          print('✅ Per Day Salary: $perDaySalaryStr');

          // 4. Calculate Net Salary
          double leaveDouble = double.tryParse(leave ?? '0') ?? 0;

          if (leaveDouble > 0) {
            double netSalaryValue =
                salaryDouble - (leaveDouble * perDaySalaryValue);
            if (netSalaryValue < 0) netSalaryValue = 0;

            String netSalaryStr = netSalaryValue.toStringAsFixed(3);

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
      if (field['type'] != 'expression') {
        String? value = getFieldValue(field['label']);
        if (value != null && value.isNotEmpty && value != "null") {
          print('✅ Found input value in: ${field['label']} = $value');
          return true;
        }
      }
    }
    return false;
  }

// Add this to EditformController
void updateAllExpressionFields() {
  print('🟢 ===== UPDATE ALL EXPRESSION FIELDS =====');
  
  // DEBUG: Print all available keys
  print('📋 Available keys in dataMap: ${dataMap.keys.join(', ')}');
  
  // First, collect all current values
  Map<String, dynamic> currentValues = Map.from(dataMap);
  
  // Add values from field values
  for (var field in labellist) {
    String label = field['label'] ?? '';
    String code = field['code'] ?? '';
    String fieldType = field['type'] ?? '';
    
    if (fieldType == 'expression') continue;
    
    String? fieldValue = getFieldValue(label);
    if (fieldValue != null && fieldValue.isNotEmpty) {
      currentValues[code] = fieldValue;
      print('  📥 Value for $code ($label): $fieldValue');
    }
  }
  
  // DEBUG: Print all values being used for calculation
  print('📊 Values for calculation:');
  currentValues.forEach((key, value) {
    print('  - $key: $value');
  });
  
  // Process expression fields
  for (var field in labellist) {
    if (field['type'] == 'expression') {
      String label = field['label'] ?? '';
      String code = field['code'] ?? '';
      String expression = field['expression'] ?? field['rule'] ?? '';
      
      if (expression.isNotEmpty) {
        print('🔍 Calculating: $label = $expression');
        
        String calculatedValue = _calculateExpression(expression, currentValues);
        
        // Update both storage locations
        setFieldValue(label, calculatedValue);
        dataMap[code] = calculatedValue;
        
        print('✅ Result: $calculatedValue');
      }
    }
  }
  
  update();
}
String calculateExpression(String expression, Map<String, dynamic> values) {
  try {
    // Replace @fieldName with actual values
    String parsedExpression = expression;
    final RegExp fieldPattern = RegExp(r'@(\w+)');
    
    parsedExpression = parsedExpression.replaceAllMapped(fieldPattern, (match) {
      String fieldName = match.group(1) ?? '';
      dynamic value = values[fieldName];
      
      if (value == null || value.toString().isEmpty) {
        return '0';
      }
      
      // Clean the value - remove any non-numeric characters except decimal
      String numStr = value.toString().replaceAll(RegExp(r'[^\d.-]'), '');
      return numStr.isEmpty ? '0' : numStr;
    });
    
    // Handle basic arithmetic
    // This is a simplified version - you might want a proper expression evaluator
    if (parsedExpression.contains('*')) {
      var parts = parsedExpression.split('*');
      if (parts.length == 2) {
        double left = double.tryParse(parts[0].trim()) ?? 0;
        double right = double.tryParse(parts[1].trim()) ?? 0;
        return (left * right).toStringAsFixed(2);
      }
    }
    
    if (parsedExpression.contains('/')) {
      var parts = parsedExpression.split('/');
      if (parts.length == 2) {
        double left = double.tryParse(parts[0].trim()) ?? 0;
        double right = double.tryParse(parts[1].trim()) ?? 0;
        if (right != 0) {
          return (left / right).toStringAsFixed(2);
        }
      }
    }
    
    if (parsedExpression.contains('+')) {
      var parts = parsedExpression.split('+');
      if (parts.length == 2) {
        double left = double.tryParse(parts[0].trim()) ?? 0;
        double right = double.tryParse(parts[1].trim()) ?? 0;
        return (left + right).toStringAsFixed(2);
      }
    }
    
    if (parsedExpression.contains('-')) {
      var parts = parsedExpression.split('-');
      if (parts.length == 2) {
        double left = double.tryParse(parts[0].trim()) ?? 0;
        double right = double.tryParse(parts[1].trim()) ?? 0;
        return (left - right).toStringAsFixed(2);
      }
    }
    
    return parsedExpression;
  } catch (e) {
    print('❌ Error calculating expression: $e');
    return '0';
  }
}
 
  var appurl = "".obs;
  var pagetitle = "".obs;
  var saveformcode = "".obs;
  var isLoading = false.obs;
  Map<String, dynamic>? previousResponse;
  var collectionName = "".obs;
  String? admissionId;
  var imagePaths = <String, String?>{}.obs;
  var docPaths = <String, String?>{}.obs;
  final RxBool showTextField = false.obs;
  updateappurl(
    var menutitle,
    var appurldata,
  ) {
    appurl.value = appurldata;
    pagetitle.value = menutitle;
  }

  dynamic getInitialValues(String fieldCode, String label) {
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

  RxList<GroupLabels> grouplabellist = <GroupLabels>[].obs;
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  HttpServices httpServices = HttpServices();
  var userstoryName = "".obs;
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;
  RxList<ChildForm> ChildFormlist = <ChildForm>[].obs;
  var code = "".obs;
  // var childcode = "".obs;
  var emailEnabled = 0.obs;
  var exportEnabled = 0.obs;
  var commentEnabled = 0.obs;
  var attachmentEnabled = 0.obs;
  var foreignId = 0.obs;
  var userStoryId = "".obs;
  var childformId = "".obs;
  var saveform_id = 0.obs; // Making it observable
  var uploadimage = <String, String?>{}.obs;
  var uploadDocument = <String, String?>{}.obs;
  var appCode = "".obs;
  var applicationurl = "".obs;
  var dataMap = <String, dynamic>{}.obs;
  var commentsList = <Map<String, dynamic>>[].obs;
  var attachmentList = <Map<String, dynamic>>[].obs;
  Map<String, dynamic> parentChildUsecase = {};
  RxList<dynamic> labellist = RxList<dynamic>();
  RxMap<String, List<dynamic>> prelaodlist = RxMap<String, List<dynamic>>();
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  List<String> globalYUsecases = [];
  RxList<dynamic> preloadparentUsecases = RxList<dynamic>();
  RxMap<String, String> initialValues = <String, String>{}.obs;
  final RxMap<String, String> _fieldValues = <String, String>{}.obs;
  var usecase;
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

  void setInitialValue(String code, String value) {
    dataMap[code] = value;
    update();
  }

  String? getFieldValue(String label) {
    return _fieldValues[label];
  }

  void setFieldValue(String label, String value) {
    _fieldValues[label] = value;
    update();
  }

  void clearInitialValue(String code) {
    initialValues.remove(code);
    dataMap.remove(code);
    update();
  }

  // Get form data API
  Future<void> GetForm_API(String id) async {
    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;
      saveformcode.value = data!.code.toString();
      userstoryName.value = data!.userstoryName.toString();
      buttons.assignAll(data.buttons);
      fields.assignAll(data.fields);

      ChildFormlist.assignAll(data.childFormList);
      grouplabellist.assignAll(data.groupLabels);
      userStoryId.value = data.userstoryId.toString();
      foreignId.value = int.parse(data.id);
      await Getitemcode(data.userstoryId.toString());
      await Getattributefield(data.userstoryId.toString());
      update();
    } else {}

  }

  var isuserFilter = 0.obs;
  Future<Map<String, dynamic>?> Savecomboitem(String formID, var value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
    }

    try {
      final response = await httpServices.tagitemsave(
          label: "Combobox",
          type: "combobox",
          userstoryId: userStoryId.value.toString(), // Ensure it's an int
          id: formID, // Ensure it's an int
          values: value);

      if (response != null && response['success'] == true) {
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return {'message': 'Error occurred while saving the form'};
    }
  }


String _calculateExpression(String expression, Map<String, dynamic> values) {
  try {
    print('📐 Calculating expression: $expression');
    print('📊 Available values: $values');
    
    // Create a mapping of possible field name variations
    Map<String, String> fieldNameMapping = {};
    
    // Build mapping from actual field codes to what might be in expressions
    for (var field in labellist) {
      String code = field['code'] ?? '';
      String label = field['label'] ?? '';
      
      // Store both the code and label as possible keys
      if (code.isNotEmpty) {
        fieldNameMapping[code.toLowerCase()] = code;
        fieldNameMapping[code.replaceAll(' ', '').toLowerCase()] = code;
      }
      if (label.isNotEmpty) {
        fieldNameMapping[label.toLowerCase()] = code;
        fieldNameMapping[label.replaceAll(' ', '').toLowerCase()] = code;
      }
    }
    
    // Replace @fieldName with actual values
    String parsedExpression = expression;
    final RegExp fieldPattern = RegExp(r'@([\w\s]+?)(?=[+\-*/()]|$)');
    
    parsedExpression = parsedExpression.replaceAllMapped(fieldPattern, (match) {
      String fieldExpr = match.group(1)?.trim() ?? '';
      print('  - Looking for field: @$fieldExpr');
      
      // Clean the field name for matching
      String cleanFieldExpr = fieldExpr.toLowerCase().replaceAll(' ', '');
      
      // Find the actual field code
      String? actualCode;
      
      // Try direct match in values
      if (values.containsKey(fieldExpr)) {
        actualCode = fieldExpr;
      } else if (values.containsKey(fieldExpr.toLowerCase())) {
        actualCode = fieldExpr.toLowerCase();
      } else {
        // Try using the mapping
        actualCode = fieldNameMapping[cleanFieldExpr];
      }
      
      if (actualCode != null && values.containsKey(actualCode)) {
        dynamic value = values[actualCode];
        print('  - Found with code: $actualCode = $value');
        
        if (value == null || value.toString().isEmpty) {
          return '0';
        }
        
        String valueStr = value.toString();
        double? numValue = double.tryParse(valueStr);
        if (numValue != null) {
          return numValue.toString();
        }
        return '0';
      }
      
      // Special case for "Maximum Marks Per Subject"
      if (fieldExpr.toLowerCase().contains('maximum') && 
          fieldExpr.toLowerCase().contains('marks')) {
        // Try to find maximumMarksPerSubject
        dynamic value = values['maximumMarksPerSubject'];
        if (value != null) {
          print('  - Found maximumMarksPerSubject = $value');
          return value.toString();
        }
      }
      
      print('  - @$fieldExpr = null (using 0)');
      return '0';
    });
    
    print('📝 Parsed expression: $parsedExpression');
    
    // Clean the expression - remove any remaining text
    parsedExpression = parsedExpression.replaceAll(RegExp(r'[^\d\+\-\*\/\(\)\.]'), '');
    
    // Evaluate the mathematical expression
    return _evaluateMathExpression(parsedExpression);
  } catch (e) {
    print('❌ Error calculating expression: $e');
    return '0';
  }
}

String _evaluateMathExpression(String expression) {
  try {
    if (expression.isEmpty) return '0';
    
    // Remove any non-math characters
    expression = expression.replaceAll(RegExp(r'[^\d\+\-\*\/\(\)\.]'), '');
    if (expression.isEmpty) return '0';
    
    print('🔢 Evaluating: $expression');
    
    // Handle parentheses first
    while (expression.contains('(')) {
      RegExp parenExp = RegExp(r'\(([^\(\)]+)\)');
      Match? match = parenExp.firstMatch(expression);
      
      if (match != null) {
        String innerExpr = match.group(1)!;
        String innerResult = _evaluateSimpleExpression(innerExpr);
        expression = expression.replaceFirst('($innerExpr)', innerResult);
      } else {
        break;
      }
    }
    
    // Evaluate the remaining expression
    return _evaluateSimpleExpression(expression);
  } catch (e) {
    print('Error evaluating expression: $e');
    return '0';
  }
}

String _evaluateSimpleExpression(String expr) {
  try {
    if (expr.isEmpty) return '0';
    
    // Handle multiplication and division first
    if (expr.contains('*') || expr.contains('/')) {
      // Split into numbers and operators
      List<String> tokens = [];
      String current = '';
      
      for (int i = 0; i < expr.length; i++) {
        String char = expr[i];
        if (char == '+' || char == '-' || char == '*' || char == '/') {
          if (current.isNotEmpty) {
            tokens.add(current);
            current = '';
          }
          tokens.add(char);
        } else {
          current += char;
        }
      }
      if (current.isNotEmpty) {
        tokens.add(current);
      }
      
      // Convert to numbers list
      List<double> numbers = [];
      List<String> operators = [];
      
      for (int i = 0; i < tokens.length; i++) {
        if (i % 2 == 0) {
          numbers.add(double.tryParse(tokens[i]) ?? 0);
        } else {
          operators.add(tokens[i]);
        }
      }
      
      // Process * and / first
      for (int i = 0; i < operators.length; i++) {
        if (operators[i] == '*' || operators[i] == '/') {
          double left = numbers[i];
          double right = numbers[i + 1];
          double result = operators[i] == '*' ? left * right : (right != 0 ? left / right : 0);
          
          numbers[i] = result;
          numbers.removeAt(i + 1);
          operators.removeAt(i);
          i--;
        }
      }
      
      // Process + and -
      double result = numbers[0];
      for (int i = 0; i < operators.length; i++) {
        if (operators[i] == '+') {
          result += numbers[i + 1];
        } else if (operators[i] == '-') {
          result -= numbers[i + 1];
        }
      }
      
      return result.toStringAsFixed(2);
    }
    
    // Handle simple addition/subtraction
    if (expr.contains('+') || expr.contains('-')) {
      List<String> parts = expr.split(RegExp(r'([\+-])'));
      List<String> operators = expr.split(RegExp(r'[^\+-]+')).where((op) => op.isNotEmpty).toList();
      
      double result = double.tryParse(parts[0]) ?? 0;
      for (int i = 0; i < operators.length; i++) {
        double next = double.tryParse(parts[i + 1]) ?? 0;
        if (operators[i] == '+') {
          result += next;
        } else {
          result -= next;
        }
      }
      return result.toStringAsFixed(2);
    }
    
    // Single number
    return (double.tryParse(expr) ?? 0).toStringAsFixed(2);
  } catch (e) {
    return '0';
  }
}

  String formatTimeForDisplay(String timeValue, int timeFormat) {
    try {
      if (timeValue.isEmpty) return '';

      if (timeFormat == 24) {
        // Already in HH:mm format, return as is
        return timeValue;
      } else {
        // Convert HH:mm to hh:mm a
        if (timeValue.length >= 5) {
          try {
            DateTime dt = DateFormat('HH:mm').parse(timeValue);
            return DateFormat('hh:mm a').format(dt);
          } catch (e) {
            // If parsing fails, try direct conversion
            return timeValue;
          }
        }
        return timeValue;
      }
    } catch (e) {
      print('Error formatting time: $e');
      return timeValue;
    }
  }

// Convert UI time (always AM/PM) to database format based on timeFormat setting
  String formatTimeForApi(String displayTime, int timeFormat) {
    try {
      if (displayTime.isEmpty) return '';

      // Parse from AM/PM format (UI always uses AM/PM)
      final dt = DateFormat('h:mm a').parse(displayTime);

      // Convert based on timeFormat setting
      if (timeFormat == 24) {
        return DateFormat('HH:mm').format(dt); // 24-hour format
      } else {
        return DateFormat('h:mm a').format(dt); // Keep AM/PM format
      }
    } catch (e) {
      print('Error formatting time for API: $e, displayTime: $displayTime');
      return displayTime;
    }
  }

  String formatIDateForApi(String userInput) {
    try {
      String input = userInput.trim();
      DateTime dt;

      if (input.contains('T')) {
        // Already in ISO format
        dt = DateTime.parse(input);
      } else if (input.contains('-')) {
        // Check if it's dd-MM-yyyy or yyyy-MM-dd
        List<String> parts = input.split('-');
        if (parts[0].length == 2) {
          // dd-MM-yyyy format
          dt = DateFormat('dd-MM-yyyy').parse(input);
        } else {
          // yyyy-MM-dd format
          dt = DateFormat('yyyy-MM-dd').parse(input);
        }
      } else if (input.contains('/')) {
        dt = DateFormat('dd/MM/yyyy').parse(input);
      } else {
        throw Exception('Invalid date format');
      }

      // Convert to UTC ISO format
      return DateTime.utc(dt.year, dt.month, dt.day).toIso8601String();
    } catch (e) {
      print('Error formatting idate: $e');
      return userInput;
    }
  }

// IDATE को display format में बदलें (dd-MM-yyyy)
  String formatIDateForDisplay(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';

    try {
      String input = value.toString().trim();
      DateTime dt;

      if (input.contains('T')) {
        // ISO format
        dt = DateTime.parse(input).toLocal();
      } else if (input.contains('-')) {
        // Already in date format
        List<String> parts = input.split('-');
        if (parts[0].length == 2) {
          // dd-MM-yyyy
          dt = DateFormat('dd-MM-yyyy').parse(input);
        } else {
          // yyyy-MM-dd
          dt = DateFormat('yyyy-MM-dd').parse(input);
        }
      } else {
        dt = DateTime.parse(input);
      }

      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      print('Error formatting idate for display: $e');
      return value.toString();
    }
  }

// ITIME फील्ड के लिए - ISO format में save करें (1970-01-01THH:mm:ss.sssZ)
  String formatITimeForApi(String userInput) {
    try {
      String input = userInput.trim();

      if (input.contains('T')) {
        // Already in ISO format
        return input;
      }

      // Parse AM/PM or 24-hour format
      TimeOfDay timeOfDay;

      if (input.toUpperCase().contains('AM') ||
          input.toUpperCase().contains('PM')) {
        // AM/PM format
        bool isPM = input.toUpperCase().contains('PM');
        String timePart = input.replaceAll(RegExp(r'[APMapm]'), '').trim();

        List<String> parts = timePart.split(':');
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;

        // Convert to 24-hour
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;

        timeOfDay = TimeOfDay(hour: hour, minute: minute);
      } else {
        // 24-hour format
        List<String> parts = input.split(':');
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        timeOfDay = TimeOfDay(hour: hour, minute: minute);
      }

      // Create DateTime with reference date 1970-01-01
      DateTime dt = DateTime(1970, 1, 1, timeOfDay.hour, timeOfDay.minute);

      // Convert to UTC ISO format
      return dt.toUtc().toIso8601String();
    } catch (e) {
      print('Error formatting itime: $e');
      return userInput;
    }
  }
// EditformController में formatITimeForDisplay method को update करें:

// ITIME को display format में बदलें (h:mm a)
  String formatITimeForDisplay(dynamic value, int timeFormat) {
    if (value == null || value.toString().trim().isEmpty) return '';

    try {
      String input = value.toString().trim();
      DateTime dt;

      if (input.contains('T')) {
        // ISO format (e.g., "1970-01-01T14:30:00.000Z")
        dt = DateTime.parse(input).toLocal();
      } else if (input.contains(':')) {
        // Already in time format (HH:mm or h:mm a)
        if (input.toUpperCase().contains('AM') ||
            input.toUpperCase().contains('PM')) {
          // Already in AM/PM format, parse it
          bool isPM = input.toUpperCase().contains('PM');
          String timePart = input.replaceAll(RegExp(r'[APMapm]'), '').trim();

          List<String> parts = timePart.split(':');
          int hour = int.tryParse(parts[0]) ?? 0;
          int minute = int.tryParse(parts[1]) ?? 0;

          // Adjust for AM/PM
          if (isPM && hour < 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;

          // Create DateTime for today with this time
          DateTime now = DateTime.now();
          dt = DateTime(now.year, now.month, now.day, hour, minute);
        } else {
          // 24-hour format (HH:mm)
          List<String> parts = input.split(':');
          int hour = int.tryParse(parts[0]) ?? 0;
          int minute = int.tryParse(parts[1]) ?? 0;

          DateTime now = DateTime.now();
          dt = DateTime(now.year, now.month, now.day, hour, minute);
        }
      } else {
        return input; // Return as is if can't parse
      }

      // Format based on timeFormat
      if (timeFormat == 24) {
        return DateFormat('hh:mm a').format(dt);
      } else {
        // Change to 'h:mm a' for single digit hour (5:12 AM)
        return DateFormat('hh:mm a').format(dt);
      }
    } catch (e) {
      print('Error formatting itime for display: $e, value: $value');
      return value.toString();
    }
  }

  String formatDateTimeForApi(String userInput) {
    try {
      String input = userInput.trim();
      DateTime dt;

      if (input.contains('T')) {
        // Already in ISO format
        dt = DateTime.parse(input);
      } else if (input.contains(' ') && input.contains('-')) {
        // yyyy-MM-dd HH:mm format
        dt = DateFormat('yyyy-MM-dd HH:mm').parse(input);
      } else if (input.contains(' ') && input.contains('/')) {
        // dd/MM/yyyy HH:mm format
        dt = DateFormat('dd/MM/yyyy HH:mm').parse(input);
      } else {
        throw Exception('Invalid datetime format');
      }

      // Convert to UTC ISO format
      return dt.toUtc().toIso8601String();
    } catch (e) {
      print('Error formatting datetime: $e');
      return userInput;
    }
  }

// DATETIME को display format में बदलें
  String formatDateTimeForDisplay(dynamic value, int timeFormat) {
    if (value == null || value.toString().trim().isEmpty) return '';

    try {
      String input = value.toString().trim();
      DateTime dt;

      if (input.contains('T')) {
        // ISO format (e.g., "2023-01-01T14:30:00.000Z")
        dt = DateTime.parse(input).toLocal();
      } else {
        // Try parsing other formats
        dt = DateTime.parse(input).toLocal();
      }

      // Format based on timeFormat
      if (timeFormat == 24) {
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      } else {
        // Change 'h:mm a' to 'hh:mm a' for 2-digit hour with AM/PM
        return DateFormat('yyyy-MM-dd hh:mm a').format(dt);
      }
    } catch (e) {
      print('Error formatting datetime for display: $e, value: $value');
      return value.toString();
    }
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

        isuserFilter.value = firstAccess['userFilter'] ?? 0; // If available
      } else {}
    } else {}
  }

  // Inside EditformController
  void clearForm() {
    // 1. Reset the primary identifier to signify a NEW record
    saveform_id.value = 0;

    // 2. Clear all data stores related to the previous record
    dataMap.clear();
    _fieldValues.clear(); // CRITICAL: This holds your field values by label
    previousResponse = null;

    // 3. Clear file/attachment/comments states
    imagePaths.clear();
    docPaths.clear();
    uploadimage.clear();
    uploadDocument.clear();
    commentsList.clear();
    attachmentList.clear();

    // 4. Clear location controllers and UI flags
    latController.clear();
    longController.clear();
    showTextField.value = false;

    // 5. Re-apply default values AND ENSURE NO OLD VALUES REMAIN
    // This loop is the most common point of failure.
    for (var item in labellist) {
      String fieldCode = item['code'] ?? '';
      String fieldLabel = item['label'] ?? '';
      String? defaultValue = item['defaultValue'];

      // Always clear the existing values first, then apply default
      setFieldValue(fieldLabel, ""); // Clear value by label
      dataMap[fieldCode] = ""; // Clear value by code

      if (defaultValue != null && defaultValue.isNotEmpty) {
        setFieldValue(fieldLabel, defaultValue);
        dataMap[fieldCode] = defaultValue;
      }
    }

    // 6. Trigger a GetX UI update for Obx/GetBuilder widgets
    update();
  }

  // Get use-case data API
  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(
      id: formid,
    );

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data']; // Cast to List<dynamic>
      usecase = dataResponse;
      code.value = dataResponse['code'];
      appCode.value = dataResponse['appCode'];
      collectionName.value = dataResponse['collectionName'];
      if (dataResponse.containsKey('emailEnabled')) {
        emailEnabled.value =
            dataResponse['emailEnabled'] as int; // Ensure it's an int
      } else {
        emailEnabled.value = 0; // Default value when null or missing
      }

      if (dataResponse.containsKey('exportEnabled')) {
        exportEnabled.value =
            dataResponse['exportEnabled'] as int; // Ensure it's an int
      } else {
        exportEnabled.value = 0; // Default value when null or missing
      }

      if (dataResponse.containsKey('commentEnabled')) {
        commentEnabled.value =
            dataResponse['commentEnabled'] as int; // Ensure it's an int
      } else {
        commentEnabled.value = 0; // Default value when null or missing
      }

      if (dataResponse.containsKey('attachmentEnabled')) {
        attachmentEnabled.value =
            dataResponse['attachmentEnabled'] as int; // Ensure it's an int
      } else {
        attachmentEnabled.value = 0; // Default value when null or missing
      }

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

      await GetdataList(appCode.value, appurl.value);
      update();
    } else {}
  }

  // Get form data API
  Future<void> GetdataList(String formname, String id) async {
    var res = await httpServices.GetFormdata(
      formname: formname,
      appurl: code.value,
      formId: id.toString(),
    );
    if (res?['success'] == true) {
      var dataResponse = res?['result'];

      if (dataResponse != null && dataResponse['data'] is Map) {
        dataMap.assignAll(dataResponse['data']);

        update();
      } else {
        dataMap.clear();
        update();
      }
    } else {}
  }

  void clearFieldValue(String fieldCode) {
    if (dataMap.containsKey(fieldCode)) {
      dataMap[fieldCode] = ""; // Reset to null or a default value
    }
    update(); //
  }

  // Get Attribute data API============
  Future<void> Getattributefield(String formId) async {
    labellist.clear();
    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data']; // Update labellist

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

      // Add the `show` field to the sortedFilteredList
      // Add the `show` field to the sortedFilteredList
      for (var item in sortedFilteredList) {
        var matchingField = fields.firstWhere(
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
        labellist.assignAll(sortedFilteredList);
      } else {}
      var uniqueUsecases = <String>{};
      for (var dashboardItem in labellist) {
        String yUsecase = dashboardItem['primaryUsecase'] ?? "";
        if (yUsecase.isNotEmpty) {
          uniqueUsecases.add(yUsecase);
        } else {}
      }
      globalYUsecases = uniqueUsecases.toList(); // For multiple values
      await Getpreloadfield(code.value);
    }
  }

  // Get Group Field============
  List getGroupsField(String label) {
    return labellist.where((field) => field['group'] == label).toList();
  }

  List getItemsWithoutGroup() {
    return labellist
        .where((field) => field['group'] == "" || field['group'] == null)
        .toList();
  }

  //  EvaluateCondition Method for the show when functionality to check expression------------------------
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

  //-------------------------------------------//
  // Get-Prelaod--list-API
  Future<void> Getpreloadfield(String name) async {
    var res = await httpServices.Getpreloaddata(
        formname: name, appurl: appCode.value);
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
            update();
          } else {}
        } else {}
      }
    } else {}
  }
  // Get-ParentFilter-data

  void onChange(Map<String, dynamic> e, dynamic val) {
    final primaryUsecase = e['primaryUsecase'];
    final depAttribute = e['depAttribute'];

    final List<dynamic>? l = prelaodlist[primaryUsecase];
    if (l == null) return;

    for (var item in l) {
      // print("item['id']: ${item['id']}");
      // print("val: ${val}");

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
    print('data========data====>>>${data}');
    print('val=====val=======>>>${val}');

    final code = data['id']; // e.g., "componentNameId"
    final codeVALUE = data['code']; // e.g., "componentNameId"
    print('val=====>${val}===code====>>>${code}');

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

        debugPrint('result::::::::::::::::::::$result');
        debugPrint('useCases::::::::::::::::::::$useCases');

        for (var useCase in useCases) {
          if (result.containsKey(useCase)) {
            var data = result[useCase];

            if (data is List) {
              debugPrint('Incoming data: $data');

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

  //----------Get-ParentFilter-data API-----------///
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

  // Get Comment list Data API
  Future<void> getComments(String formID, String id) async {
    commentsList.clear();
    var res = await httpServices.GetComments(
        formId: formID, recordId: id, userstoryId: userStoryId.value);

    if (res != null && res['success'] == true) {
      List<dynamic> rawData = res['result']['data'] ?? [];
      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(rawData); //  Explicit cast

      if (data.isNotEmpty) {
        commentsList.assignAll(data); //  Now correctly assigns list of maps
      } else {}
      update();
    } else {}
  }

  // Get Attachment list Data API
  Future<void> getattachment(String formID, String id) async {
    if (attachmentList.length == 1) {
      attachmentList.clear();
    }

    var res = await httpServices.GetAttachment(
        formId: formID, recordId: id, userstoryId: userStoryId.value);

    if (res != null && res['success'] == true) {
      List<dynamic> rawData = res['result']['data'] ?? [];
      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(rawData);

      if (data.isNotEmpty) {
        for (var item in data) {
          String attachmentId = item['attachment'].toString();
          item['attachmentUrl'] =
              "https://cuickdev.com/API/DOCS/api/doc/th/$attachmentId?t=${DateTime.now().millisecondsSinceEpoch}";
        }

        attachmentList.assignAll(data); // Assign updated data with URLs

        update();
      } else {
        debugPrint("No attachmentList found.");
      }

      update();
    } else {}
  }

  // Save Comment list Data API
  Future<bool> saveComments(
      int id, String comment, String formID, String recordId) async {
    int? usecaseId = commentsList.isNotEmpty
        ? commentsList.first["usecaseId"]
        : 0; // Default to 0 if not found

    var res = await httpServices.SaveComments(
        appcode: appCode.value,
        code: code.value,
        comment: comment,
        formId: formID,
        recordId: recordId,
        userstoryId: userStoryId.value,
        usecaseId: usecaseId ?? 0,
        id: id);

    if (res != null && res['success'] == true) {
      return true;
    } else {
      return false;
    }
  }

  // Save Upload Attachment list Data API
  Future<bool> uploadAttachment(
      File file, String formId, String recordId, String description) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';

    int? applicationId = prefs.getInt("appId");
    int? usecaseId = attachmentList.isNotEmpty
        ? attachmentList.first["usecaseId"]
        : 0; // Default to 0 if not found

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          "https://api.ncsindore.com/api/v1/${appCode.value}/${code.value}/addAttechment;jsessionid=$jsessionid"),
    );

    // Add the file to the request
    String fileType = file.path
        .split('.')
        .last
        .toLowerCase(); // Extract the file extension (e.g., jpg, pdf)

    // Check file type and add file to the request
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    request.fields.addAll({
      "applicationId": applicationId.toString(),
      "userstoryId": userStoryId.value,
      "usecaseId": usecaseId.toString(),
      "formId": formId,
      "recordId": recordId,
      "description": description,
    });
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse["success"] == true;
    } catch (e) {
      print("Error uploading attachment: $e");
      return false;
    }
  }

  // Save update Attachment list Data API
  Future<bool> updateImage(
      String attachmentId,
      File?
          imageFile, // Make this nullable to handle the case where no new file is selected
      String formId,
      String recordId,
      String descontroller) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';

    int? usecaseId = attachmentList.isNotEmpty
        ? attachmentList.first["usecaseId"]
        : 0; // Default to 0 if not found

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          "https://api.ncsindore.com/api/v1/${appCode.value}/${code.value}/addAttechment;jsessionid=$jsessionid"),
    );

    // If a new file is selected, add it to the request
    if (imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath("file", imageFile.path));
    }

    // Always include the fields for attachment
    request.fields.addAll({
      "id": attachmentId,
      "applicationId": prefs.getInt("appId").toString(),
      "userstoryId": userStoryId.value,
      "usecaseId": usecaseId.toString(),
      "formId": formId,
      "recordId": recordId,
      "description": descontroller,
    });

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var jsonResponse = jsonDecode(response.body);

      return jsonResponse["success"] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    // Clean up text controllers
    latController.dispose();
    longController.dispose();

    // Clear observable maps/lists if needed
    imagePaths.clear();
    docPaths.clear();
    uploadimage.clear();
    uploadDocument.clear();
    _fieldValues.clear();

    // Any other necessary disposals
    commentsList.clear();
    attachmentList.clear();
    dataMap.clear();
    previousResponse = null;

    super.onClose();
  }
}
