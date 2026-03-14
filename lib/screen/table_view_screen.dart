import 'package:cached_network_image/cached_network_image.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/Uiform_controller.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';
import 'package:cuickdevuser/controller/chart_controller.dart';
import 'package:cuickdevuser/controller/dynamic_chart.dart';
import 'package:cuickdevuser/controller/login_controller.dart';
import 'package:cuickdevuser/controller/tableview_controller.dart';
import 'package:cuickdevuser/screen/Edit_form.dart';
import 'package:cuickdevuser/screen/Menucontroller.dart';
import 'package:cuickdevuser/screen/tabletag.dart';
import 'package:cuickdevuser/screen/utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/DBHelper.dart';
import '../service/apihelper.dart';
import 'package:cuickdevuser/widgets/custom_scrollable_text_with_indicator.dart'; // Adjust path as needed


class TableViewScreen extends StatefulWidget {
  final String appurl;
  final String menutitle;
  final String formID;
  final int iscreate;
  final int isread;
  final int isdelete;
  final int isupdate;
  final int isuserFilter;

  const TableViewScreen({
    super.key,
    required this.appurl,
    required this.menutitle,
    required this.formID,
    required this.iscreate,
    required this.isread,
    required this.isdelete,
    required this.isupdate,
    required this.isuserFilter,                                                                                                                                                 
  });

  @override
  State<TableViewScreen> createState() => _TableViewScreenState();
}

class _TableViewScreenState extends State<TableViewScreen> {

    final Connectivity _connectivity = Connectivity();
  RxBool isOffline = false.obs;
  String formatNumber(dynamic value) {
    if (value == null) return '-';

    final doubleValue = double.tryParse(value.toString());
    if (doubleValue == null) return value.toString();

    return doubleValue % 1 == 0
        ? doubleValue.toInt().toString() // 10.0 → 10
        : doubleValue.toString(); // 10.5 → 10.5
  }

  // 📌 HELPER FUNCTION TO FORMAT DECIMAL VALUES
  String _formatDecimalForDisplay(String? value) {
    if (value == null || value.isEmpty) return '';

    try {
      // Parse as double
      double numValue = double.parse(value);

      // Check if it's a whole number
      if (numValue % 1 == 0) {
        return numValue.toInt().toString(); // Return without .0
      } else {
        // For decimal numbers, remove trailing zeros
        String formatted = numValue.toString();
        if (formatted.contains('.')) {
          formatted =
              formatted.replaceAll(RegExp(r'0+$'), ''); // Remove trailing zeros
          formatted =
              formatted.replaceAll(RegExp(r'\.$'), ''); // Remove trailing dot
        }
        return formatted;
      }
    } catch (e) {
      // If parsing fails, return original value
      return value;
    }
  }
  void resetDateFields() {
  for (var field in viewcontroller.filterlabellist) {
    String label = field['label'];
    String fieldType = field['type'];

    if (fieldType == 'idate' ||
        fieldType == 'date' ||
        fieldType == 'itime' ||
        fieldType == 'time' ||
        fieldType == 'datetime' ||
        fieldType == 'dateandtime') {
      _controllers[label]?.clear();
      viewcontroller.setFieldValue(label, null);
    }
  }
}

  // 1. Only for 'idate' type
String _formatIDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    try {
      String input = value.toString().trim();
      DateTime dt;

      // ✅ Case 1: Timestamp (milliseconds)
      int? millis = int.tryParse(input);
      if (millis != null && millis > 0) {
        dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
        return DateFormat('yyyy-MM-dd').format(dt);
      }

      // ✅ Case 2: ISO DateTime (2024-01-22T00:00:00.000Z)
      if (input.contains('T')) {
        dt = DateTime.parse(input).toLocal();
        return DateFormat('yyyy-MM-dd').format(dt);
      }

      // ✅ Case 3: dd-MM-yyyy
      if (input.contains('-') && input.split('-').first.length == 2) {
        dt = DateFormat('dd-MM-yyyy').parse(input);
        return DateFormat('yyyy-MM-dd').format(dt);
      }

      // ✅ Case 4: yyyy-MM-dd
      if (input.contains('-')) {
        dt = DateFormat('yyyy-MM-dd').parse(input);
        return DateFormat('yyyy-MM-dd').format(dt);
      }

      // Fallback
      dt = DateTime.parse(input);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      print('IDATE reverse format error: $e, value: $value');
      return value.toString();
    }
  }
  // Format display value based on field type
  dynamic _formatDisplayValue(String fieldType, dynamic value,
      {int? timeFormat}) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    try {
          if (fieldType == 'Decimal') {
      String strValue = value.toString().trim();
      // Try to parse as double
      double? numValue = double.tryParse(strValue);
      if (numValue != null) {
        // Check if it's a whole number
        if (numValue % 1 == 0) {
          return numValue.toInt().toString(); // Return without .0
        } else {
          // For decimal numbers, remove trailing zeros
          String formatted = numValue.toString();
          if (formatted.contains('.')) {
            formatted = formatted.replaceAll(RegExp(r'0+$'), '');
            formatted = formatted.replaceAll(RegExp(r'\.$'), '');
          }
          return formatted;
        }
      }
      return strValue;
    }
      if (fieldType == 'idate') {
        return _formatIDate(value);
      } else if (fieldType == 'itime') {
        return _formatITime(value, timeFormat: timeFormat ?? 12);
      } else if (fieldType == 'datetime' || fieldType == 'dateandtime') {
        return _formatDateTime(value);
      } else if (fieldType == 'date') {
        return _formatDate(value);
      } else if (fieldType == 'time') {
        return _formatTime(value, timeFormat: timeFormat ?? 12);
      }
      return value?.toString() ?? '-';
    } catch (e) {
      print('Format error for type $fieldType: $e, value: $value');
      return value?.toString() ?? '-';
    }
  }


// Add this for date formatting
  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    try {
      String input = value.toString().trim();
      DateTime dt;

      if (input.contains('T')) {
        dt = DateTime.parse(input).toLocal();
      } else if (input.contains('-')) {
        dt = DateFormat('yyyy-MM-dd').parse(input);
      } else {
        dt = DateTime.parse(input);
      }
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      print('DATE format error: $e, value: $value');
      return value.toString();
    }
  }

// Add this for time formatting
  String _formatTime(dynamic value, {int timeFormat = 12}) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    try {
      String input = value.toString().trim();

      if (input.contains('T')) {
        DateTime dt = DateTime.parse(input).toLocal();
        if (timeFormat == 24) {
          return DateFormat('HH:mm').format(dt);
        } else {
          return DateFormat('h:mm a').format(dt);
        }
      }

      if (input.toUpperCase().contains('AM') ||
          input.toUpperCase().contains('PM')) {
        return input;
      }

      if (input.contains(':')) {
        List<String> parts = input.split(':');
        if (parts.length >= 2) {
          int hour = int.tryParse(parts[0]) ?? 0;
          int minute = int.tryParse(parts[1]) ?? 0;

          if (timeFormat == 24) {
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          } else {
            String period = hour >= 12 ? 'PM' : 'AM';
            int displayHour = hour % 12;
            if (displayHour == 0) displayHour = 12;

            return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
          }
        }
      }

      return input;
    } catch (e) {
      print('TIME format error: $e, value: $value');
      return value.toString();
    }
  }

String _formatITime(dynamic value, {int timeFormat = 12}) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    try {
      String input = value.toString().trim();

      // ✅ Case 1: ISO DateTime (1970-01-01T14:30:00.000Z)
      if (input.contains('T')) {
        DateTime dt = DateTime.parse(input).toLocal();
        return timeFormat == 24
            ? DateFormat('HH:mm').format(dt)
            : DateFormat('h:mm a').format(dt);
      }

      // ✅ Case 2: Already AM/PM
      if (input.toUpperCase().contains('AM') ||
          input.toUpperCase().contains('PM')) {
        return input;
      }

      // ✅ Case 3: HH:mm
      if (input.contains(':')) {
        List<String> parts = input.split(':');
        if (parts.length >= 2) {
          int hour = int.tryParse(parts[0]) ?? 0;
          int minute = int.tryParse(parts[1]) ?? 0;

          if (timeFormat == 24) {
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          } else {
            String period = hour >= 12 ? 'PM' : 'AM';
            int displayHour = hour % 12;
            if (displayHour == 0) displayHour = 12;

            return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
          }
        }
      }

      return input;
    } catch (e) {
      print('ITIME format error: $e, value: $value');
      return value.toString();
    }

  }
String _formatDateTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    try {
      String input = value.toString().trim();
      DateTime dt;

      // ✅ Case 1: Timestamp (milliseconds)
      int? millis = int.tryParse(input);
      if (millis != null && millis > 0) {
        dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      }

      // ✅ Case 2: ISO DateTime (2024-01-22T14:30:00.000Z)
      if (input.contains('T')) {
        dt = DateTime.parse(input).toLocal();
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      }

      // ✅ Case 3: yyyy-MM-dd HH:mm
      if (input.contains('-') && input.contains(':')) {
        dt = DateFormat('yyyy-MM-dd HH:mm').parse(input);
        return DateFormat('yyyy-MM-dd HH:mm').format(dt);
      }

      // Fallback
      dt = DateTime.parse(input);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      print('DATETIME format error: $e, value: $value');
      return value.toString();
    }
  }
void _showFullDetailsDialog(Map<String, dynamic> attribute) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),

          // 🔹 TITLE PADDING (TOP SPACE REDUCED)
          titlePadding: const EdgeInsets.fromLTRB(12, 8, 8, 0),

          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_outlined,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  widget.menutitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),

              // ❌ CLOSE ICON (NO EXTRA SPACE)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),

          // 🔹 CONTENT PADDING REDUCED
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),

          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(100),
                    1: FlexColumnWidth(),
                  },
                  border: TableBorder.all(
                    color: isDarkMode ? Colors.grey : Colors.black12,
                    width: 0.8,
                  ),
                  children: [
                    /// 🔹 TABLE HEADER
                    TableRow(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Field",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Value",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// 🔹 DATA ROWS
                    ...viewcontroller.labellist.map<TableRow>((labelItem) {
                      final displayLabel = _capitalize(labelItem['label']);
                      final type = labelItem['type'];
                      dynamic value;

                      if (labelItem['refKey'] == 1 &&
                          labelItem['depAttribute'] != null) {
                        value = attribute[labelItem['depAttribute']];
                      } else {
                        value = attribute[labelItem['code']];
                      }

                      Widget valueWidget;
  /// DATETIME (complete date and time)
  if (type == 'dateandtime') {
    String formattedDateTime = '-';

    if (value != null && value.toString().isNotEmpty) {
      try {
        // Parse UTC datetime string to DateTime
        DateTime utcDateTime = DateTime.parse(value.toString());
        // Convert to local timezone
        DateTime localDateTime = utcDateTime.toLocal();

        // Format datetime with date and time (YYYY-MM-DD HH:MM:SS)
        formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(localDateTime);
      } catch (e) {
        print('Error parsing datetime: $e');
        formattedDateTime = value.toString();
      }
    }

    valueWidget = Text(
      formattedDateTime,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  /// DATE
  else if (type == 'date' || type == 'idate') {
    String formattedDate = '-';

    if (value != null && value.toString().isNotEmpty) {
      try {
        // Parse UTC date string to DateTime
        DateTime utcDate = DateTime.parse(value.toString());
        // Convert to local timezone
        DateTime localDate = utcDate.toLocal();

        // Format based on type - YYYY-MM-DD format
        if (type == 'date') {
          // Date only - 2026-01-28
          formattedDate = DateFormat('yyyy-MM-dd').format(localDate);
        } else if (type == 'idate') {
          // Date with time - 2026-01-28 14:30
          formattedDate = DateFormat('yyyy-MM-dd').format(localDate);
        }
      } catch (e) {
        print('Error parsing date: $e');
        formattedDate = value.toString();
      }
    }

    valueWidget = Text(
      formattedDate,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  /// TIME
  else if (type == 'time' || type == 'itime') {
    String formattedTime = '-';

    if (value != null && value.toString().isNotEmpty) {
      try {
        // Parse UTC time string to DateTime
        DateTime utcTime = DateTime.parse(value.toString());
        // Convert to local timezone
        DateTime localTime = utcTime.toLocal();

        // Format based on type
        if (type == 'time') {
          // Time only (24-hour format) - 14:30:45
          formattedTime = DateFormat('HH:mm:ss').format(localTime);
        } else if (type == 'itime') {
          // Time with AM/PM format - 02:30 PM
          formattedTime = DateFormat('hh:mm a').format(localTime);
        }
      } catch (e) {
        print('Error parsing time: $e');
        formattedTime = value.toString();
      }
    }

    valueWidget = Text(
      formattedTime,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

                      /// TIME
                      else if (type == 'time' || type == 'itime') {
                        String formattedTime = '-';

                        if (value != null && value.toString().isNotEmpty) {
                          try {
                            // Parse UTC time string to DateTime
                            DateTime utcTime = DateTime.parse(value.toString());
                            // Convert to local timezone
                            DateTime localTime = utcTime.toLocal();

                            // Format based on type
                            if (type == 'time') {
                              // Time only (24-hour format)
                              formattedTime =
                                  DateFormat('HH:mm').format(localTime);
                            } else if (type == 'itime') {
                              // Time with AM/PM format
                              formattedTime =
                                  DateFormat('hh:mm a').format(localTime);
                            }
                          } catch (e) {
                            print('Error parsing time: $e');
                            formattedTime = value.toString();
                          }
                        }

                        valueWidget = Text(
                          formattedTime,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        );
                      }

                      /// LOCATION
                      else if (type == 'location') {
                        String textToShow = '-';
                        final loc = value;

                        if (loc is Map &&
                            loc.containsKey('lat') &&
                            loc.containsKey('lng')) {
                          textToShow = '${loc['lat']}, ${loc['lng']}';
                        }

                        valueWidget = GestureDetector(
                          onTap: () async {
                            if (textToShow != '-') {
                              final uri = Uri.parse(
                                'https://www.google.com/maps?q=$textToShow',
                              );
                              await launchUrl(uri);
                            }
                          },
                          child: Text(
                            textToShow,
                            style: const TextStyle(
                              color: Color(0xFF2962FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      /// BOOLEAN
                      else if (type == 'boolean') {
                        valueWidget = Text(
                          value == 1 || value == "1" ? "True" : "False",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        );
                      }

                      /// FILE / DOC
                      else if (type == 'file' || type == 'doc') {
                        final imageId = value ?? 0;
                        final imageUrl = (imageId != 0)
                            ? "https://cuickdev.com/API/DOCS/api/doc/th/$imageId?t=${DateTime.now().millisecondsSinceEpoch}"
                            : imageUrlHelper.applogourl;

                        valueWidget = GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(
                              'https://cuickdev.com/API/DOCS/api/doc/$imageId',
                            );
                            await launchUrl(uri);
                          },
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 90,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }

                      /// TEXTAREA
                      else if (type == 'textarea') {
                        valueWidget = SizedBox(
                          height: 80,
                          child: SingleChildScrollView(
                            child: Text(
                              value?.toString() ?? '-',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }

                      /// DEFAULT
                      else {
                        valueWidget = Text(
                          value?.toString() ?? '-',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        );
                      }

                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              displayLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: valueWidget,
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),

          // 🔹 ACTION BUTTON SPACE REDUCED
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),

          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                side: BorderSide(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                "Close",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  final ImageUrlHelper imageUrlHelper = ImageUrlHelper();
  Widget borderedIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color, width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

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
  final Uiformcontroller uicontroller =
      Get.put(Uiformcontroller(), permanent: true);
  final WelcomeController controller = Get.put(WelcomeController());
  final TableviewController viewcontroller = Get.put(TableviewController());
  final Map<String, String> fieldValues = {};
  final ChartController chartcontroller = Get.put(ChartController());
  final Dynamic_chart DYchartcontroller = Get.put(Dynamic_chart());
  final LoginController loginController = Get.put(LoginController());
  bool showDataNotFound = false;
  final Menucontroller menucontroller = Get.find();
  final Map<String, TextEditingController> _controllers = {};
  bool isCardView = false;
  String fieldvalue = "";
  String saveform_id = "";
  bool search = false;
  final int _pageSize = 10;
  List<int> selectedItemIds = []; // List to store selected item IDs

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadFormData();
      _checkConnectivity(); // ✅ Connectivity check
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus); 
  }
Future<void> _checkConnectivity() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  // ✅ Updated method signature to accept List<ConnectivityResult>
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // Check if any connectivity type is available
    if (result.contains(ConnectivityResult.none)) {
      isOffline.value = true;
    } else {
      isOffline.value = false;
    }
  }

  // ✅ Update connection status


  void loadFormData() async {
    await viewcontroller.GetForm_API(widget.formID);

    // Assuming viewcontroller.labellist or formData holds the API result
    if (viewcontroller.labellist.isEmpty && mounted) {
      // Wait 3 seconds before showing the fallback
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          showDataNotFound = true;
        });
      }
    }
  }

  String? dropdownValue;

  void _changePage(int newPage) async {
    if (newPage >= 0 && newPage < viewcontroller.totalPages.value) {
      viewcontroller.CurrentPage.value = newPage;
      await viewcontroller.getdataList();
    }
  }

  // List<bool> selectedRows = [];
  bool isAllSelected = false; // To manage the "select all" checkbox state
  void _deleteSelectedItems() async {
    bool allDeleted = true;

    for (int itemId in selectedItemIds) {
      var res = await viewcontroller.deleteAlllistitem(
        widget.appurl,
        widget.menutitle,
        itemId.toString(),
        viewcontroller.CurrentPage.value,
        _pageSize,
      );

      // If any deletion fails, set flag to false
      if (res == false) {
        allDeleted = false;
      }
    }

    // Clear selection and refresh UI
    setState(() {
      selectedItemIds.clear();
      viewcontroller.selectedRows.value = List.generate(
        viewcontroller.labellist.length,
        (index) => false,
      );
    });

    // Show final popup after all deletions
    if (allDeleted) {
      CherryToast.success(
        backgroundColor: Color(0xFFBCF3BF),
        animationDuration: Durations.short1,
        title: const Text("All items deleted successfully!",
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);

      await viewcontroller.getdataList();
    } else {
      CherryToast.warning(
        backgroundColor: Colors.orangeAccent,
        animationDuration: Durations.short1,
        title: const Text("Some items couldn't be deleted.",
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    showDataNotFound = false;
  }

  Future<void> showOfflineForms(BuildContext context) async {
    List<Map<String, dynamic>> forms = await DBHelper().getAllForms();

    if (forms.isEmpty) {
      debugPrint('No offline forms found.');

      // Show dialog with empty message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Offline Forms"),
            content: const Text("No offline forms found."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          );
        },
      );
    } else {
      // Show dialog with list of forms
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            title: const Text("Offline Forms"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: forms.length,
                itemBuilder: (context, index) {
                  final form = forms[index];
                  return Card(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      title: Text(form['title'] ?? 'No Title'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Saved at: ${DateFormat('MMMM d, y h:mm:ss a').format(form['timestamp'] is String ? DateTime.parse(form['timestamp']) : form['timestamp'])}'),
                          Text('Code: ${form['code']}'),
                          Text('AppCode: ${form['appCode']}'),
                          Text('data: ${form['data']}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Handle tap on a form → maybe open detail screen or send data
                        debugPrint('Tapped on form: ${form['title']}');
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
              TextButton(
                onPressed: () async {
                  await DBHelper().resetDatabase();
                },
                child: const Text("Clear data"),
              ),
            ],
          );
        },
      );
    }
  }

  late int indexlocation = 0;
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final labelStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
      fontSize: 15,
      fontWeight: FontWeight.w400,
    );

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Obx(() {
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (widget.iscreate != 0)
                        GestureDetector(
                          onTap: () async {
                            // showDataNotFound = false;
                            setState(() {});
                            await viewcontroller.getfetchrule().then(
                              (value) {
                                if (viewcontroller.updatedFormID != null &&
                                    viewcontroller.updatedFormID.isNotEmpty) {
                                  // ✅ Navigate to EditFormScreen
                                  Get.to(
                                    EditFormScreen(
                                      id: int.parse(viewcontroller.updatedFormID
                                          .value), // ← make sure attribute is defined in this scope
                                      appurl: widget.appurl,
                                      formID: widget.formID,
                                      menutitle: widget.menutitle,
                                      userstoryName: viewcontroller
                                          .updateduserstoryname.value,
                                      iscreate: widget.iscreate,
                                      isread: widget.isread,
                                      isdelete: widget.isdelete,
                                      isupdate: widget.isupdate,
                                    ),
                                  );
                                } else {
                                  // uicontroller.imagePaths.clear();
                                  // uicontroller.docPaths.clear();
                                  // uicontroller.showTextField.value = false;
                                  // uicontroller.clearForm();
                                  // _controllers.clear();
                                  uicontroller.saveform_id.value = 0;
                                  // setState(() {});
                                  // 🔄 Change tab if no updatedFormID
                                  menucontroller.changeTab(1);
                                }
                              },
                            );
                            // menucontroller.changeTab(1); // Switc
                          },
                          child: Container(
                              height: 40,
                              width: 50,
                              decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF4F76E2)
                                      : Appcolorblue,
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
                      const SizedBox(
                        width: 5,
                      ),
                      if (widget.isdelete != 0)
                        GestureDetector(
                          onTap: () {
                            if (selectedItemIds.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please select at least one item to delete.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              _deleteSelectedItems();
                            }
                          },
                          child: Container(
                            height: 40,
                            width: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF4F76E2)
                                  : Appcolorblue,
                              border: Border.all(
                                color: Appcolorblue,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_sweep_rounded,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isCardView = !isCardView;
                          });
                        },
                        child: Tooltip(
                          message: isCardView
                              ? "Switch to Table View"
                              : "Switch to Card View",
                          child: Container(
                            height: 40,
                            width: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF4F76E2)
                                  : Appcolorblue,
                              border: Border.all(
                                color: Appcolorblue,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isCardView
                                  ? Icons.list_sharp
                                  : Icons.grid_view_sharp,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          viewcontroller.update();
                          viewcontroller.GetForm_API(widget.formID);
                          viewcontroller.CurrentPage.value = 0;
                        },
                        child: Container(
                            height: 40,
                            width: 50,
                            decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF4F76E2)
                                    : Appcolorblue,
                                // color: Appcolorblue,
                                // color:const Color(0xFF2962FF),
                                border: Border.all(
                                  color: Appcolorblue,
                                ),
                                borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Image.asset(
                                'assets/icons/refresh.png',
                                color: Colors.white,
                              ),
                            )),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                  showModalBottomSheet(
                            context: context,
                            backgroundColor:
                                isDarkMode ? Colors.grey[800] : Colors.white,
                            isScrollControlled: true,
                            isDismissible: false,
                            builder: (BuildContext context) {
                              return StatefulBuilder(

                                builder: (context, setState) {
                                  return SafeArea(
                                    child: Padding(
                                      padding: MediaQuery.of(context).viewInsets,
                                      child: Container(
                                        constraints: const BoxConstraints.expand(
                                            height: 600), // Height increased
                                        color: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.white,
                                        height: MediaQuery.of(context).size.height *
                                            0.65,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(height: 15),
                                              viewcontroller
                                                      .filterlabellist.isNotEmpty
                                                  ? Expanded(
                                                      child: GridView.builder(
                                                        gridDelegate:
                                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 1,
                                                          childAspectRatio: 6,
                                                          mainAxisSpacing: 16.0,
                                                          crossAxisSpacing: 8.0,
                                                        ),
                                                        itemCount: viewcontroller
                                                            .filterlabellist.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          var field = viewcontroller
                                                                  .filterlabellist[
                                                              index];
                                                          String label =
                                                              field['label'];
                                                          String fieldType =
                                                              field['type'];
                                                          bool isRequired =
                                                              field['required'] ==
                                                                  1;
                                                          bool isRefKey =
                                                              field['refKey'] == 1;
                                                          bool primaryUsecase =
                                                              field['primaryUsecase'] !=
                                                                  "";
                                                          bool showDropdown =
                                                              primaryUsecase ==
                                                                      true &&
                                                                  isRefKey == true;
                                                          String yUsecase = field[
                                                                  'primaryUsecase'] ??
                                                              "";

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
                                                              .text = viewcontroller
                                                                  .getFieldValue(
                                                                      label)
                                                                  ?.toString() ??
                                                              "";

                                                          // 1️⃣ IDATE FIELD
                                                          if (fieldType ==
                                                              'idate') {
                                                            return TextFormField(
                                                              style: labelStyle,
                                                              readOnly: true,
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              decoration:
                                                                  InputDecoration(
                                                                fillColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                labelStyle:
                                                                    labelStyle,
                                                                labelText: label,
                                                                suffixIcon: Icon(
                                                                  Icons
                                                                      .calendar_today,
                                                                  color: isDarkMode
                                                                      ? Colors.white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Appcolorblue),
                                                                ),
                                                              ),
                                                              onTap: () async {
                                                                DateTime?
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
                                                                if (selectedDate !=
                                                                    null) {
                                                                  // Format as dd-MM-yyyy for display
                                                                  String
                                                                      formattedDate =
                                                                      DateFormat(
                                                                              'dd-MM-yyyy')
                                                                          .format(
                                                                              selectedDate);
                                                                  setState(() {
                                                                    _controllers[
                                                                                label]
                                                                            ?.text =
                                                                        formattedDate;
                                                                    viewcontroller
                                                                        .setFieldValue(
                                                                            label,
                                                                            formattedDate);
                                                                  });
                                                                }
                                                              },
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
                                                            );
                                                          }

                                                          // 2️⃣ ITIME FIELD
                                                          else if (fieldType ==
                                                              'itime') {
                                                            return TextFormField(
                                                              style: labelStyle,
                                                              readOnly: true,
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              decoration:
                                                                  InputDecoration(
                                                                fillColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                labelStyle:
                                                                    labelStyle,
                                                                labelText: label,
                                                                suffixIcon: Icon(
                                                                  Icons.access_time,
                                                                  color: isDarkMode
                                                                      ? Colors.white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Appcolorblue),
                                                                ),
                                                              ),
                                                              onTap: () async {
                                                                TimeOfDay?
                                                                    selectedTime =
                                                                    await showTimePicker(
                                                                  context: context,
                                                                  initialTime:
                                                                      TimeOfDay
                                                                          .now(),
                                                                );
                                                                if (selectedTime !=
                                                                    null) {
                                                                  // Format time in AM/PM format
                                                                  String
                                                                      formattedTime =
                                                                      DateFormat(
                                                                              'h:mm a')
                                                                          .format(
                                                                    DateTime(
                                                                      DateTime.now()
                                                                          .year,
                                                                      DateTime.now()
                                                                          .month,
                                                                      DateTime.now()
                                                                          .day,
                                                                      selectedTime
                                                                          .hour,
                                                                      selectedTime
                                                                          .minute,
                                                                    ),
                                                                  );
                                                                  setState(() {
                                                                    _controllers[
                                                                                label]
                                                                            ?.text =
                                                                        formattedTime;
                                                                    viewcontroller
                                                                        .setFieldValue(
                                                                            label,
                                                                            formattedTime);
                                                                  });
                                                                }
                                                              },
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
                                                            );
                                                          }

                                                          // 3️⃣ DATETIME/DATEANDTIME FIELD
                                                          else if (fieldType ==
                                                                  'datetime' ||
                                                              fieldType ==
                                                                  'dateandtime') {
                                                            return TextFormField(
                                                              style: labelStyle,
                                                              readOnly: true,
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              decoration:
                                                                  InputDecoration(
                                                                fillColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                labelStyle:
                                                                    labelStyle,
                                                                labelText: label,
                                                                suffixIcon: Icon(
                                                                  Icons.date_range,
                                                                  color: isDarkMode
                                                                      ? Colors.white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Appcolorblue),
                                                                ),
                                                              ),
                                                              onTap: () async {
                                                                DateTime?
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
                                                                if (selectedDate !=
                                                                    null) {
                                                                  TimeOfDay?
                                                                      selectedTime =
                                                                      await showTimePicker(
                                                                    context:
                                                                        context,
                                                                    initialTime:
                                                                        TimeOfDay
                                                                            .now(),
                                                                  );
                                                                  if (selectedTime !=
                                                                      null) {
                                                                    // Combine date and time
                                                                    final combinedDateTime =
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

                                                                    // Format as yyyy-MM-dd HH:mm
                                                                    String
                                                                        formattedDateTime =
                                                                        DateFormat(
                                                                                'yyyy-MM-dd HH:mm')
                                                                            .format(
                                                                                combinedDateTime);

                                                                    setState(() {
                                                                      _controllers[
                                                                                  label]
                                                                              ?.text =
                                                                          formattedDateTime;
                                                                      viewcontroller
                                                                          .setFieldValue(
                                                                              label,
                                                                              formattedDateTime);
                                                                    });
                                                                  }
                                                                }
                                                              },
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
                                                            );
                                                          }

                                                          // 4️⃣ DATE FIELD (existing)
                                                          else if (fieldType ==
                                                              'date') {
                                                            return TextFormField(
                                                              style: labelStyle,
                                                              readOnly: true,
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              decoration:
                                                                  InputDecoration(
                                                                fillColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                labelText: label,
                                                                labelStyle:
                                                                    labelStyle,
                                                                suffixIcon: Icon(
                                                                  Icons
                                                                      .calendar_today,
                                                                  color: isDarkMode
                                                                      ? Colors.white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Appcolorblue),
                                                                ),
                                                              ),
                                                              onTap: () async {
                                                                DateTime?
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
                                                                if (selectedDate !=
                                                                    null) {
                                                                  String
                                                                      formattedDate =
                                                                      DateFormat(
                                                                              'yyyy-MM-dd')
                                                                          .format(
                                                                              selectedDate);
                                                                  setState(() {
                                                                    _controllers[
                                                                                label]
                                                                            ?.text =
                                                                        formattedDate;
                                                                    viewcontroller
                                                                        .setFieldValue(
                                                                            label,
                                                                            formattedDate);
                                                                  });
                                                                }
                                                              },
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
                                                            );
                                                          }

                                                          // 5️⃣ TIME FIELD (existing)
                                                          else if (fieldType ==
                                                              'time') {
                                                            return TextFormField(
                                                              readOnly: true,
                                                              style: labelStyle,
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              decoration:
                                                                  InputDecoration(
                                                                fillColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white,
                                                                labelStyle:
                                                                    labelStyle,
                                                                labelText: label,
                                                                suffixIcon: Icon(
                                                                  Icons.access_time,
                                                                  color: isDarkMode
                                                                      ? Colors.white
                                                                      : Colors
                                                                          .black,
                                                                ),
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Appcolorblue),
                                                                ),
                                                              ),
                                                              onTap: () async {
                                                                TimeOfDay?
                                                                    selectedTime =
                                                                    await showTimePicker(
                                                                  context: context,
                                                                  initialTime:
                                                                      TimeOfDay
                                                                          .now(),
                                                                );
                                                                if (selectedTime !=
                                                                    null) {
                                                                  final now =
                                                                      DateTime
                                                                          .now();
                                                                  final dateTime =
                                                                      DateTime(
                                                                    now.year,
                                                                    now.month,
                                                                    now.day,
                                                                    selectedTime
                                                                        .hour,
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
                                                                                label]!
                                                                            .text =
                                                                        formattedTime;
                                                                    viewcontroller
                                                                        .setFieldValue(
                                                                            label,
                                                                            formattedTime);
                                                                  });
                                                                }
                                                              },
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
                                                            );
                                                          }

                                                          // 6️⃣ TEXT FIELD (existing)
                                                          else if (fieldType ==
                                                              'text') {
                                                            return TextFormField(
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              style: labelStyle,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText: label,
                                                                labelStyle:
                                                                    labelStyle,
                                                                fillColor:
                                                                    isDarkMode
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
                                                              ),
                                                              keyboardType:
                                                                  TextInputType
                                                                      .text,
                                                              onChanged: (value) =>
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          value),
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
                                                            );
                                                          }

                                                          // LOCATION FIELD
                                                          else if (fieldType ==
                                                              'location') {
                                                            return TextFormField(
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              style: labelStyle,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText: label,
                                                                labelStyle:
                                                                    labelStyle,
                                                                fillColor:
                                                                    isDarkMode
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
                                                              ),
                                                              keyboardType:
                                                                  TextInputType
                                                                      .text,
                                                              onChanged: (value) =>
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          value),
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
                                                            );
                                                          }

                                                          // OBJECT FIELD
                                                          else if (fieldType ==
                                                              'object') {
                                                            return TextFormField(
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              style: labelStyle,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText: label,
                                                                labelStyle:
                                                                    labelStyle,
                                                                fillColor:
                                                                    isDarkMode
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
                                                              ),
                                                              keyboardType:
                                                                  TextInputType
                                                                      .text,
                                                              onChanged: (value) =>
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          value),
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
                                                            );
                                                          }

                                                          // URL FIELD
                                                          else if (fieldType ==
                                                              'url') {
                                                            return TextFormField(
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              style: labelStyle,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText: label,
                                                                labelStyle:
                                                                    labelStyle,
                                                                fillColor:
                                                                    isDarkMode
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
                                                              ),
                                                              keyboardType:
                                                                  TextInputType.url,
                                                              onChanged: (value) =>
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          value),
                                                              validator: isRequired
                                                                  ? (value) {
                                                                      if (value ==
                                                                              null ||
                                                                          value
                                                                              .isEmpty) {
                                                                        return 'Please enter a valid URL';
                                                                      }
                                                                      return null;
                                                                    }
                                                                  : null,
                                                            );
                                                          }

                                                          // NUMBER/DECIMAL FIELDS
                                        else if (fieldType ==
                                                                'number' ||
                                                            fieldType ==
                                                                'long' ||
                                                            fieldType ==
                                                                'phone' ||
                                                            fieldType ==
                                                                'expression' ||
                                                            fieldType ==
                                                                'decimal') {
                                                          // 📌 CONTROLLER INITIALIZATION WITH FORMATTING
                                                          _controllers
                                                              .putIfAbsent(
                                                                  label, () {
                                                            // Get existing value and format it
                                                            String?
                                                                existingValue =
                                                                viewcontroller
                                                                    .getFieldValue(
                                                                        label)
                                                                    ?.toString();
                                                            String
                                                                formattedValue =
                                                                _formatDecimalForDisplay(
                                                                    existingValue);
                                                            return TextEditingController(
                                                                text:
                                                                    formattedValue);
                                                          });

                                                          return TextFormField(
                                                            style: labelStyle,
                                                            controller:
                                                                _controllers[
                                                                    label],
                                                            decoration:
                                                                InputDecoration(
                                                              labelText: label,
                                                              labelStyle:
                                                                  labelStyle,
                                                              fillColor:
                                                                  isDarkMode
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
                                                            ),
                                                            keyboardType:
                                                                const TextInputType
                                                                    .numberWithOptions(
                                                                    decimal:
                                                                        true),
                                                            onChanged: (value) {
                                                              if (value
                                                                  .isEmpty) {
                                                                viewcontroller
                                                                    .setFieldValue(
                                                                        label,
                                                                        null);
                                                                return;
                                                              }

                                                              if (fieldType ==
                                                                  'decimal') {
                                                                final parsed =
                                                                    double.tryParse(
                                                                        value);
                                                                if (parsed !=
                                                                    null) {
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          parsed);

                                                                  // 📌 FORMAT THE VALUE IN REAL-TIME
                                                                  String
                                                                      formattedValue =
                                                                      _formatDecimalForDisplay(
                                                                          value);
                                                                  if (formattedValue !=
                                                                      value) {
                                                                    _controllers[label]
                                                                            ?.text =
                                                                        formattedValue;
                                                                    _controllers[label]
                                                                            ?.selection =
                                                                        TextSelection
                                                                            .fromPosition(
                                                                      TextPosition(
                                                                          offset:
                                                                              formattedValue.length),
                                                                    );
                                                                  }
                                                                }
                                                              } else {
                                                                final parsed =
                                                                    int.tryParse(
                                                                        value);
                                                                if (parsed !=
                                                                    null) {
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          parsed);
                                                                }
                                                              }
                                                            },
                                                            validator: (value) {
                                                              if (isRequired &&
                                                                  (value ==
                                                                          null ||
                                                                      value
                                                                          .isEmpty)) {
                                                                return 'Please enter $label';
                                                              }

                                                              if (fieldType ==
                                                                      'decimal' &&
                                                                  value !=
                                                                      null &&
                                                                  value
                                                                      .isNotEmpty) {
                                                                if (double.tryParse(
                                                                        value) ==
                                                                    null) {
                                                                  return 'Please enter a valid number';
                                                                }
                                                              }

                                                              if ((fieldType ==
                                                                          'number' ||
                                                                      fieldType ==
                                                                          'long' ||
                                                                      fieldType ==
                                                                          'phone' ||
                                                                      fieldType ==
                                                                          'expression') &&
                                                                  value !=
                                                                      null &&
                                                                  value
                                                                      .isNotEmpty) {
                                                                if (int.tryParse(
                                                                        value) ==
                                                                    null) {
                                                                  return 'Please enter a valid number';
                                                                }
                                                              }

                                                              return null;
                                                            },
                                                          );
                                                        }
                                                          // EMAIL FIELD
                                                          else if (fieldType ==
                                                              'email') {
                                                            return TextFormField(
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              style: labelStyle,
                                                              decoration:
                                                                  InputDecoration(
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
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Appcolorblue),
                                                                ),
                                                              ),
                                                              keyboardType:
                                                                  TextInputType
                                                                      .emailAddress,
                                                              onChanged:
                                                                  (value) async {
                                                                setState(() {
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          value);
                                                                });
                                                              },
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
                                                            );
                                                          }

                                                          // PASSWORD FIELD
                                                          else if (fieldType ==
                                                              'password') {
                                                            return TextFormField(
                                                              controller:
                                                                  _controllers[
                                                                      label],
                                                              style: labelStyle,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelText: label,
                                                                labelStyle:
                                                                    labelStyle,
                                                                fillColor:
                                                                    isDarkMode
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
                                                              ),
                                                              obscureText: true,
                                                              onChanged: (value) =>
                                                                  viewcontroller
                                                                      .setFieldValue(
                                                                          label,
                                                                          value),
                                                              validator: isRequired
                                                                  ? (value) {
                                                                      if (value ==
                                                                              null ||
                                                                          value
                                                                              .isEmpty) {
                                                                        return 'Please enter a password';
                                                                      }
                                                                      return null;
                                                                    }
                                                                  : null,
                                                            );
                                                          }

                                                          // TEXTAREA FIELD
                                                          else if (fieldType ==
                                                              'textarea') {
                                                            return Container(
                                                              height: 120,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: isDarkMode
                                                                    ? Colors.black
                                                                    : Colors.white,
                                                                border: Border.all(
                                                                    color:
                                                                        Appcolorblue),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4.0),
                                                              ),
                                                              child: Scrollbar(
                                                                thumbVisibility:
                                                                    true,
                                                                child:
                                                                    SingleChildScrollView(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(4.0),
                                                                  child:
                                                                      TextFormField(
                                                                    controller:
                                                                        _controllers[
                                                                            label],
                                                                    style: labelStyle
                                                                        .copyWith(
                                                                      color: isDarkMode
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                    ),
                                                                    decoration:
                                                                        InputDecoration(
                                                                      labelText:
                                                                          label,
                                                                      labelStyle:
                                                                          labelStyle,
                                                                      border:
                                                                          InputBorder
                                                                              .none,
                                                                      filled: true,
                                                                      fillColor: Colors
                                                                          .transparent,
                                                                    ),
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .multiline,
                                                                    maxLines: null,
                                                                    onChanged: (value) =>
                                                                        viewcontroller
                                                                            .setFieldValue(
                                                                                label,
                                                                                value),
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
                                                                ),
                                                              ),
                                                            );
                                                          }


                                                          // DROPDOWN FIELDS (MAP, LIST, COMBOBOX)
                                                // DROPDOWN FIELDS (MAP, LIST, COMBOBOX, BOOLEAN, SHOWDROPDOWN) with Obx

// MAP FIELD
else if (fieldType == 'map') {
  return Obx(() {
    List<dynamic> mapValues = field['values'] ?? [];
    String? currentValue = viewcontroller.getFieldValue(label);

    if (currentValue != null &&
        !mapValues.any((item) => item['key'].toString() == currentValue)) {
      currentValue = null;
    }

    return DropdownButtonFormField<String>(
      style: labelStyle,
      isExpanded: true,
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
      decoration: InputDecoration(
        fillColor: isDarkMode ? Colors.black : Colors.white,
        labelText: label,
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Appcolorblue),
        ),
      ),
      value: currentValue,
      items: [
        if (!isRequired)
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              'Select $label',
              style: labelStyle.copyWith(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ...mapValues.map<DropdownMenuItem<String>>((item) {
          final key = item['key'].toString();
          final valueText = item['value'].toString();
          return DropdownMenuItem<String>(
            value: key,
            child: Text(
              '$key - $valueText',
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          viewcontroller.setFieldValue(label, value ?? '');
        });
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            }
          : null,
    );
  });
}

// LIST FIELD
else if (fieldType == 'list') {
  return Obx(() {
    const placeholderValue = '';
    final placeholderText = '--Please select--$label';

    return DropdownButtonFormField<String>(
      isExpanded: true,
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
      style: labelStyle,
      decoration: InputDecoration(
        fillColor: isDarkMode ? Colors.black : Colors.white,
        labelText: label ?? "",
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Appcolorblue),
        ),
      ),
      value: field['values'].contains(viewcontroller.getFieldValue(label))
          ? viewcontroller.getFieldValue(label)
          : placeholderValue,
      items: [
        DropdownMenuItem<String>(
          value: placeholderValue,
          child: Text(
            placeholderText,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        ...field['values'].toSet().map<DropdownMenuItem<String>>((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        if (value != placeholderValue) {
          viewcontroller.setFieldValue(label, value!);
        }
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty || value == placeholderValue) {
                return 'Please select $label';
              }
              return null;
            }
          : null,
    );
  });
}

// COMBOBOX FIELD
else if (fieldType == 'combobox') {
  return Obx(() {
    List<dynamic> mapValues = field['values'] ?? [];

    return DropdownButtonFormField<String>(
      isExpanded: true,
      style: labelStyle,
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
      decoration: InputDecoration(
        fillColor: isDarkMode ? Colors.black : Colors.white,
        labelText: label,
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Appcolorblue),
        ),
      ),
      hint: Text(
        "Select $label",
        style: labelStyle,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      value: viewcontroller.getFieldValue(label)?.isEmpty ?? true
          ? null
          : viewcontroller.getFieldValue(label),
      items: mapValues.map<DropdownMenuItem<String>>((item) {
        String displayValue = item.toString();
        return DropdownMenuItem<String>(
          value: displayValue,
          child: Text(
            displayValue,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (value) async {
        viewcontroller.setFieldValue(label, value!);
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            }
          : null,
    );
  });
}

// BOOLEAN FIELD
else if (fieldType == 'boolean') {
  return Obx(() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        style: labelStyle,
        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
        decoration: InputDecoration(
          fillColor: isDarkMode ? Colors.black : Colors.white,
          labelText: label,
          labelStyle: labelStyle,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Appcolorblue),
          ),
        ),
        value: viewcontroller.getFieldValue(label)?.toString() ?? '',
        items: [
          DropdownMenuItem<String>(
            value: '',
            child: Text(
              'Select $label',
              style: labelStyle.copyWith(color: Colors.grey),
            ),
          ),
          DropdownMenuItem<String>(
            value: '1',
            child: Text('True', style: labelStyle),
          ),
          DropdownMenuItem<String>(
            value: '0',
            child: Text('False', style: labelStyle),
          ),
        ],
        onChanged: (value) {
          viewcontroller.setFieldValue(label, value);
        },
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

// PRIMARY USECASE DROPDOWN
else if (showDropdown) {
  return Obx(() {
    final dropdownItems = viewcontroller.prelaodlist[yUsecase] ?? [];
    final uniqueItems = {
      for (var item in dropdownItems) item['id'].toString(): item
    }.values.toList();

    final currentValue = viewcontroller.getFieldValue(label);
    final dropdownValues = uniqueItems.map((item) => item['id'].toString()).toSet();
    final dropdownValue = dropdownValues.contains(currentValue) ? currentValue : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
      style: labelStyle,
      decoration: InputDecoration(
        fillColor: isDarkMode ? Colors.black : Colors.white,
        labelText: label,
        labelStyle: labelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Appcolorblue),
        ),
        hintText: 'Select $label',
        hintStyle: labelStyle,
      ),
      value: dropdownValue,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Select an $label',
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        ...uniqueItems.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['id'].toString(),
            child: Text(
              item['_val'],
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        viewcontroller.setFieldValue(label, value!);
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            }
          : null,
    );
  });
}


                                                        },
                                                      ),
                                                    )
                                                  : const Center(
                                                      child: Text(
                                                        'No search field available',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),

                                              // ✅ THREE BUTTONS ROW - SEARCH, RESET, CLOSE
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  // 🔍 SEARCH BUTTON
                                                  GestureDetector(
                                                    onTap: () {
                                                      viewcontroller.onSearch();
                                                      resetDateFields();
                                                      Get.back();
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(0.0),
                                                      height: 40.0,
                                                      width: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20),
                                                        border: Border.all(
                                                            color: Appcolorblue),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0XFF23408F)
                                                                .withOpacity(0.20),
                                                            blurRadius: 13,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: <Widget>[
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraints) {
                                                            return Container(
                                                              height: constraints
                                                                  .maxHeight,
                                                              width: constraints
                                                                  .maxHeight,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Appcolorblue,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              ),
                                                              child: const Icon(
                                                                Icons.search,
                                                                color: Colors.white,
                                                              ),
                                                            );
                                                          }),
                                                          const Expanded(
                                                            child: Text(
                                                              'Search',
                                                              textAlign:
                                                                  TextAlign.center,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),



                                                  GestureDetector(
                                                    onTap: () {
                                                      Get.back();
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(0.0),
                                                      height: 40.0,
                                                      width: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20),
                                                        border: Border.all(
                                                            color: Colors.red),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0XFF23408F)
                                                                .withOpacity(0.20),
                                                            blurRadius: 13,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: <Widget>[
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraints) {
                                                            return Container(
                                                              height: constraints
                                                                  .maxHeight,
                                                              width: constraints
                                                                  .maxHeight,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors.red,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              ),
                                                              child: const Icon(
                                                                Icons.close,
                                                                color: Colors.white,
                                                              ),
                                                            );
                                                          }),
                                                          const Expanded(
                                                            child: Text(
                                                              'Close',
                                                              textAlign:
                                                                  TextAlign.center,
                                                              style: TextStyle(
                                                                color: Colors.red,
                                                                fontWeight:
                                                                    FontWeight.bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                             GestureDetector(
                                                  // In your reset button's onTap:
                                                  // In the reset button's onTap:
                                                  onTap: () {
                                                    setState(() {
                                                      // 1. Clear all text controllers
                                                      _controllers.forEach(
                                                          (key, controller) {
                                                        controller.clear();
                                                      });

                                                      // 2. Clear ALL field values in the controller
                                                      final fields = List.from(
                                                          viewcontroller
                                                              .filterlabellist);
                                                      for (var field
                                                          in fields) {
                                                        if (field['system'] !=
                                                            1) {
                                                          String label =
                                                              field['label'];
                                                          // Set to null for all field types
                                                          viewcontroller
                                                              .setFieldValue(
                                                                  label, null);
                                                        }
                                                      }

                                                      // 3. Force rebuild of the bottom sheet
                                                      // No need to call setState again as we're already in setState
                                                    });

                                                    // 4. Debug print to verify all fields are null
                                                    print(
                                                        '=== AFTER RESET ===');
                                                    for (var field
                                                        in viewcontroller
                                                            .filterlabellist) {
                                                      String label =
                                                          field['label'];
                                                      var value = viewcontroller
                                                          .getFieldValue(label);
                                                      print(
                                                          '$label: $value (Type: ${field['type']})');
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            0.0),
                                                    height: 40.0,
                                                    width: 100.0,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color: Colors.orange),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                                  0XFF23408F)
                                                              .withOpacity(
                                                                  0.20),
                                                          blurRadius: 13,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      children: <Widget>[
                                                        LayoutBuilder(builder:
                                                            (context,
                                                                constraints) {
                                                          return Container(
                                                            height: constraints
                                                                .maxHeight,
                                                            width: constraints
                                                                .maxHeight,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.orange,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: const Icon(
                                                              Icons.refresh,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          );
                                                        }),
                                                        const Expanded(
                                                          child: Text(
                                                            'Reset',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.orange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                ],
                                              ),


                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              );
                            },
                          );


                        },
                        child: Container(
                            height: 40,
                            width: 50,
                            decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF4F76E2)
                                    : Appcolorblue,
                                border: Border.all(
                                  color: Appcolorblue,
                                ),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Icon(
                              Icons.search,
                              size: 40,
                              color: Colors.white,
                              // color: Color(0xFF2962FF),
                            )),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      viewcontroller.exportEnabled.value == 1
                          ? GestureDetector(
                              onTap: () async {
                                debugPrint("====exportEnabled============>>");
                                await viewcontroller.ExportdataList(
                                    viewcontroller.userstoryName.value
                                        .toLowerCase(),
                                    widget.appurl);
                                // createAndDownloadExcel();
                              },
                              child: Container(
                                  height: 40,
                                  width: 50,
                                  decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF4F76E2)
                                          : Appcolorblue,
                                      border: Border.all(
                                        color: Appcolorblue,
                                      ),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Image.asset(
                                      'assets/icons/excel.png',
                                      color: Colors.white,
                                      // color: const Color(0xFF2962FF),
                                    ),
                                  )),
                            )
                          : const SizedBox(),
                      const SizedBox(
                        width: 5,
                      ),
                      viewcontroller.exportEnabled.value == 1
                          ? GestureDetector(
                              onTap: () async {
                                debugPrint("====exportEnabled============>>");
                                await viewcontroller.ExportpdfFunction(
                                    viewcontroller.userstoryName.value
                                        .toLowerCase(),
                                    widget.appurl);
                                // createPDF();
                              },
                              child: Container(
                                  height: 40,
                                  width: 50,
                                  decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF4F76E2)
                                          : Appcolorblue,
                                      border: Border.all(
                                        color: Appcolorblue,
                                      ),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Image.asset(
                                      'assets/icons/pdf.png',
                                      color: Colors.white,
                                    ),
                                  )),
                            )
                          : const SizedBox(),
                      GestureDetector(
                        onTap: () {
                          showOfflineForms(context); // Pass context
                        },
                        child: Container(
                            height: 40,
                            width: 50,
                            decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF4F76E2)
                                    : Appcolorblue,
                                border: Border.all(
                                  color: Appcolorblue,
                                ),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Icon(
                              Icons.backup,
                              size: 30,
                              color: Colors.white,
                              // color: Color(0xFF2962FF),
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Obx(() {
                  switch (viewcontroller.dataState.value) {
                    case DataState.loading:
                      return Center(
                        child: LoadingAnimationWidget.threeArchedCircle(
                          size: 50,
                          color: isDarkMode
                              ? const Color(0xFF4F76E2)
                              : Appcolorblue,
                        ),
                      );
                    case DataState.empty:
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          "Data Not Found",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? const Color(0xFF4F76E2)
                                : Colors.black,
                          ),
                        ),
                      );
                    case DataState.loaded:
                      return isCardView
                          ? viewcontroller.list.isNotEmpty &&
                                  viewcontroller.labellist.isNotEmpty &&
                                  widget.isread != 0
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: List.generate(
                                      viewcontroller.list.length,
                                      (rowIndex) {
                                        final attribute =
                                            viewcontroller.list[rowIndex];
                                        // Generate values as done in the DataTable code
                                        final dynamicValues = viewcontroller
                                            .labellist
                                            .map((label) {
                                          if (label['refKey'] == 1 &&
                                              label['depAttribute'] != null) {
                                            return attribute[
                                                label['depAttribute']];
                                          }
                                          return attribute[label['code']];
                                        }).toList();

                                        return dynamicValues.length > 10
                                            ? Card(
                                                color: isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.white,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6),
                                                elevation: 4,
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              20,
                                                      height: 300,
                                                      child: Scrollbar(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            // Sticky Header
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  "SNo. ${((viewcontroller.CurrentPage.value * _pageSize) + rowIndex + 1)}",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                  ),
                                                                ),
                                                                const Spacer(),
                                                                if (widget.isdelete !=
                                                                        0 ||
                                                                    widget.isupdate !=
                                                                        0)
                                                                  Row(
                                                                    children: [
                                                                      // ✏️ EDIT
                                                                      if (widget.isupdate !=
                                                                          0)
                                                                        borderedIcon(
                                                                          icon:
                                                                              Icons.edit,
                                                                          color:
                                                                              Colors.blueAccent,
                                                                          onTap:
                                                                              () {
                                                                            Get.to(
                                                                              EditFormScreen(
                                                                                id: attribute['id'],
                                                                                appurl: widget.appurl,
                                                                                formID: widget.formID,
                                                                                menutitle: widget.menutitle,
                                                                                userstoryName: attribute['userstoryName'].toString(),
                                                                                iscreate: widget.iscreate,
                                                                                isread: widget.isread,
                                                                                isdelete: widget.isdelete,
                                                                                isupdate: widget.isupdate,
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),

                                                                      const SizedBox(
                                                                          width:
                                                                              8),
                                                                      if (widget.isupdate !=
                                                                          0)
                                                                        // 👁 VIEW
                                                                       borderedIcon(
                                                                          icon:
                                                                              Icons.visibility,
                                                                          color:
                                                                              Colors.blueAccent,
                                                                          onTap:
                                                                              () {
                                                                _showFullDetailsDialog(attribute);
                                                                          },
                                                                        ),

                                                                      const SizedBox(
                                                                          width:
                                                                              8),

                                                                      // 🗑 DELETE
                                                                      if (widget.isdelete !=
                                                                          0)
                                                                        borderedIcon(
                                                                          icon:
                                                                              Icons.delete,
                                                                          color:
                                                                              Colors.red,
                                                                          onTap:
                                                                              () {
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                                                                                  content: SizedBox(
                                                                                    height: 130,
                                                                                    child: Column(
                                                                                      children: [
                                                                                        const SizedBox(height: 15),
                                                                                        Text(
                                                                                          "Are you sure you want to delete this item?",
                                                                                          style: TextStyle(
                                                                                            fontSize: 15,
                                                                                            fontFamily: "lato",
                                                                                            fontWeight: FontWeight.w500,
                                                                                            color: isDarkMode ? Colors.white : Colors.black,
                                                                                          ),
                                                                                        ),
                                                                                        const SizedBox(height: 15),
                                                                                        Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                                          children: [
                                                                                            ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop();
                                                                                              },
                                                                                              child: const Text("Cancel"),
                                                                                            ),
                                                                                            ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Get.back();
                                                                                                viewcontroller.deletelistitem(
                                                                                                  widget.appurl,
                                                                                                  widget.menutitle,
                                                                                                  attribute['id'].toString(),
                                                                                                  viewcontroller.CurrentPage.value,
                                                                                                  _pageSize,
                                                                                                );
                                                                                                setState(() {});
                                                                                              },
                                                                                              child: const Text("Delete"),
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                          },
                                                                        ),
                                                                    ],
                                                                  )
                                                              ],
                                                            ),

                                                            const SizedBox(
                                                                height: 8),

                                                            // Scrollable Content
                     Expanded(
                                                              child:
                                                                  SingleChildScrollView(
                                                                scrollDirection:
                                                                    Axis.vertical,
                                                                child:
                                                                    Container(
                                                                  width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          3),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: List
                                                                        .generate(
                                                                      dynamicValues
                                                                          .length,
                                                                      (columnIndex) {
                                                                        final labelItem =
                                                                            viewcontroller.labellist[columnIndex];
                                                                        final displayLabel =
                                                                            _capitalize(labelItem['label']);
                                                                        final value =
                                                                            dynamicValues[columnIndex];
                                                                        final type =
                                                                            labelItem['type'];

                                                                        // Function to format date/time based on type
                                                                        String formatDateTime(
                                                                            dynamic
                                                                                val,
                                                                            String
                                                                                fieldType) {
                                                                          if (val == null ||
                                                                              val.toString().trim().isEmpty) {
                                                                            return '-';
                                                                          }

                                                                          final strVal = val
                                                                              .toString()
                                                                              .trim();

                                                                          try {
                                                                            DateTime?
                                                                                parsedDate;

                                                                            // Check for Unix timestamp
                                                                            if (RegExp(r'^\d{10}$').hasMatch(strVal)) {
                                                                              final seconds = int.tryParse(strVal);
                                                                              if (seconds != null) {
                                                                                parsedDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                                                                              }
                                                                            } else if (RegExp(r'^\d{13}$').hasMatch(strVal)) {
                                                                              final milliseconds = int.tryParse(strVal);
                                                                              if (milliseconds != null) {
                                                                                parsedDate = DateTime.fromMillisecondsSinceEpoch(milliseconds);
                                                                              }
                                                                            } else {
                                                                              parsedDate = DateTime.tryParse(strVal);
                                                                            }

                                                                            if (parsedDate !=
                                                                                null) {
                                                                              final localDate = parsedDate.toLocal();

                                                                              // Different formats based on type
                                                                              switch (fieldType) {
                                                                                case 'date':
                                                                                case 'idate':
                                                                                  // Format: YYYY-MM-DD
                                                                                  final year = localDate.year.toString();
                                                                                  final month = localDate.month.toString().padLeft(2, '0');
                                                                                  final day = localDate.day.toString().padLeft(2, '0');
                                                                                  return '$year-$month-$day';

                                                                                case 'time':
                                                                                  // Format: HH:mm (24-hour)
                                                                                  final hour = localDate.hour.toString().padLeft(2, '0');
                                                                                  final minute = localDate.minute.toString().padLeft(2, '0');
                                                                                  return '$hour:$minute';

                                                                                case 'itime':
                                                                                  // Format: hh:mm a (12-hour with AM/PM)
                                                                                  final hour12 = localDate.hour % 12;
                                                                                  final displayHour = hour12 == 0 ? '12' : hour12.toString().padLeft(2, '0');
                                                                                  final minute = localDate.minute.toString().padLeft(2, '0');
                                                                                  final ampm = localDate.hour < 12 ? 'AM' : 'PM';
                                                                                  return '$displayHour:$minute $ampm';

                                                                                case 'dateandtime':
                                                                                case 'timestamp':
                                                                                  // Format: YYYY-MM-DD HH:mm
                                                                                  final year = localDate.year.toString();
                                                                                  final month = localDate.month.toString().padLeft(2, '0');
                                                                                  final day = localDate.day.toString().padLeft(2, '0');
                                                                                  final hour = localDate.hour.toString().padLeft(2, '0');
                                                                                  final minute = localDate.minute.toString().padLeft(2, '0');
                                                                                  return '$year-$month-$day $hour:$minute';

                                                                                default:
                                                                                  // For other types, return original value
                                                                                  return strVal;
                                                                              }
                                                                            }
                                                                          } catch (e) {
                                                                            print('Error parsing date: $e');
                                                                          }

                                                                          // If not a date or parsing failed, return original value
                                                                          return strVal;
                                                                        }

                                                                        // Check if this is a date/time field
                                                                        final dateTimeTypes =
                                                                            [
                                                                          'date',
                                                                          'idate',
                                                                          'time',
                                                                          'itime',
                                                                          'dateandtime',
                                                                          'timestamp'
                                                                        ];
                                                                        final isDateTimeField =
                                                                            dateTimeTypes.contains(type);

                                                                        // Get formatted value - ALL cases में formatDateTime use करें
                                                                        final displayValue = isDateTimeField
                                                                            ? formatDateTime(value,
                                                                                type)
                                                                            : (value?.toString() ??
                                                                                '-');

                                                                        // अब सभी special types को handle करें
                                                                        if (type ==
                                                                            'location') {
                                                                          final loc =
                                                                              value;
                                                                          String
                                                                              textToShow =
                                                                              '-';

                                                                          if (loc is Map &&
                                                                              loc.containsKey(
                                                                                  'lat') &&
                                                                              loc.containsKey(
                                                                                  'lng')) {
                                                                            final lat =
                                                                                loc['lat'];
                                                                            final lng =
                                                                                loc['lng'];
                                                                            textToShow =
                                                                                '$lat, $lng';
                                                                          } else if (loc is String &&
                                                                              loc.contains('lat') &&
                                                                              loc.contains('lng')) {
                                                                            try {
                                                                              final cleaned = loc.replaceAll(RegExp(r'[{}]'), '');
                                                                              final parts = cleaned.split(',');
                                                                              final lat = parts[0].split(':')[1].trim();
                                                                              final lng = parts[1].split(':')[1].trim();
                                                                              textToShow = '$lat, $lng';
                                                                            } catch (_) {
                                                                              textToShow = '-';
                                                                            }
                                                                          }

                                                                          return Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 4.0),
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  "$displayLabel: ",
                                                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                                                                ),
                                                                                Expanded(
                                                                                    child: GestureDetector(
                                                                                  onTap: () async {
                                                                                    if (textToShow != '-') {
                                                                                      final uri = Uri.parse('https://www.google.com/maps?q=$textToShow');
                                                                                      await launchUrl(uri);
                                                                                    }
                                                                                  },
                                                                                  child: Text(
                                                                                    textToShow,
                                                                                    style: const TextStyle(fontSize: 13, color: Color(0xFF2962FF), fontWeight: FontWeight.w500),
                                                                                  ),
                                                                                )),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }

                                                                        if (type ==
                                                                            'file') {
                                                                          final imageId =
                                                                              value ?? 0;

                                                                          final imageUrl = (imageId != 0)
                                                                              ? "https://cuickdev.com/API/DOCS/api/doc/th/$imageId?t=${DateTime.now().millisecondsSinceEpoch}"
                                                                              : imageUrlHelper.applogourl;

                                                                          return Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Wrap(
                                                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                                                  spacing: 8,
                                                                                  runSpacing: 4,
                                                                                  children: [
                                                                                    Text(
                                                                                      "$displayLabel: ",
                                                                                      style: TextStyle(
                                                                                        fontSize: 13,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: isDarkMode ? Colors.white : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    GestureDetector(
                                                                                      onTap: () async {
                                                                                        final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/$imageId');
                                                                                        await launchUrl(testUrl);
                                                                                      },
                                                                                      child: CachedNetworkImage(
                                                                                        imageUrl: imageUrl,
                                                                                        width: 50,
                                                                                        height: 50,
                                                                                        fit: BoxFit.cover,
                                                                                        placeholder: (context, url) => const SizedBox(),
                                                                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        }

                                                                        if (type ==
                                                                            'boolean') {
                                                                          return Row(
                                                                            children: [
                                                                              Text(
                                                                                "$displayLabel: ",
                                                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                                                              ),
                                                                              Expanded(
                                                                                child: Text(
                                                                                  dynamicValues[columnIndex] == "" || dynamicValues[columnIndex] == null
                                                                                      ? ""
                                                                                      : dynamicValues[columnIndex] == 1 || dynamicValues[columnIndex] == "1"
                                                                                          ? 'True'
                                                                                          : 'False',
                                                                                  style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        }
                                                                        if (type ==
                                                                            'textarea') {
                                                                          final textValue =
                                                                              dynamicValues[columnIndex]?.toString() ?? "";

                                                                          return GestureDetector(
                                                                            onTap:
                                                                                () {
                                                                              if (textValue.isNotEmpty && textValue != '-') {
                                                                                showDialog(
                                                                                  context: context,
                                                                                  builder: (context) => AlertDialog(
                                                                                    title: const Text('Full Textarea'),
                                                                                    content: SingleChildScrollView(
                                                                                      child: Text(textValue),
                                                                                    ),
                                                                                    actions: [
                                                                                      TextButton(
                                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                                        child: const Text('Close'),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                );
                                                                              }
                                                                            },
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Text(
                                                                                  "$displayLabel: ",
                                                                                  style: TextStyle(
                                                                                    fontSize: 13,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: isDarkMode ? Colors.white : Colors.black,
                                                                                  ),
                                                                                ),
                                                                                textValue.isNotEmpty
                                                                                    ? Expanded(
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                                                          child: Container(
                                                                                            width: 250,
                                                                                            height: 60,
                                                                                            decoration: BoxDecoration(
                                                                                              borderRadius: BorderRadius.circular(5),
                                                                                              color: Colors.white,
                                                                                              border: Border.all(color: const Color(0xFFE0E0E0)),
                                                                                            ),
                                                                                            child: CustomScrollableTextWithIndicator(
                                                                                              textValue: textValue,
                                                                                              isDarkMode: isDarkMode,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                    : const SizedBox(),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }

                                                                        if (type ==
                                                                            'email') {
                                                                          return GestureDetector(
                                                                            onTap:
                                                                                () async {
                                                                              final Uri emailLaunchUri = Uri(
                                                                                scheme: 'mailto',
                                                                                path: dynamicValues[columnIndex],
                                                                                query: Uri.encodeQueryComponent('subject=Your Subject&body=Your message here'),
                                                                              );
                                                                              launchUrl(emailLaunchUri);
                                                                            },
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Text(
                                                                                  "$displayLabel: ",
                                                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                                                                ),
                                                                                Expanded(
                                                                                    child: Text(
                                                                                  displayValue, // यहाँ displayValue use करें
                                                                                  style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
                                                                                )),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }

                                                                        if (type ==
                                                                            'url') {
                                                                          return GestureDetector(
                                                                            onTap:
                                                                                () async {
                                                                              final Uri testUrl = Uri.parse(dynamicValues[columnIndex]);
                                                                              await launchUrl(testUrl);
                                                                            },
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  "$displayLabel: ",
                                                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                                                                ),
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    displayValue, // यहाँ displayValue use करें
                                                                                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }

                                                                        if (type ==
                                                                            'doc') {
                                                                          final imageId =
                                                                              value ?? 0;

                                                                          final imageUrl = (imageId != 0)
                                                                              ? "https://cuickdev.com/API/DOCS/api/doc/th/$imageId?t=${DateTime.now().millisecondsSinceEpoch}"
                                                                              : imageUrlHelper.applogourl;

                                                                          return Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Wrap(
                                                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                                                  spacing: 8,
                                                                                  runSpacing: 4,
                                                                                  children: [
                                                                                    Text(
                                                                                      "$displayLabel: ",
                                                                                      style: TextStyle(
                                                                                        fontSize: 13,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: isDarkMode ? Colors.white : Colors.black,
                                                                                      ),
                                                                                    ),
                                                                                    GestureDetector(
                                                                                      onTap: () async {
                                                                                        final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/$imageId');
                                                                                        await launchUrl(testUrl);
                                                                                      },
                                                                                      child: CachedNetworkImage(
                                                                                        imageUrl: imageUrl,
                                                                                        width: 50,
                                                                                        height: 50,
                                                                                        fit: BoxFit.cover,
                                                                                        placeholder: (context, url) => const SizedBox(),
                                                                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          );
                                                                        }

                                                                        // DATE/TIME TYPES के लिए अलग handling - यह नया code add करें
                                                                        if (isDateTimeField) {
                                                                          return Padding(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 4.0),
                                                                            child:
                                                                                Row(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  "$displayLabel: ",
                                                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                                                                ),
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    displayValue, // यह formatted value show होगी
                                                                                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }

                                                                        // Default case for other types
                                                                        return Padding(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              vertical: 4.0),
                                                                          child:
                                                                              Row(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                "$displayLabel: ",
                                                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                                                              ),
                                                                              Expanded(
                                                                                child: Text(
                                                                                  displayValue,
                                                                                  style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      },
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    )),
                                              )
                                            : Card(
                                                color: isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.white,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                elevation: 4,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "SNo. ${((viewcontroller.CurrentPage.value * _pageSize) + rowIndex + 1).toString()}",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          // Pushes icons to the right
                                                          if (widget.isdelete !=
                                                                  0 ||
                                                              widget.isupdate !=
                                                                  0)
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceAround,
                                                              children: [
                                                                // 👁 VIEW

                                                                // ✏️ EDIT
                                                                if (widget
                                                                        .isupdate !=
                                                                    0)
                                                                  borderedIcon(
                                                                    icon: Icons
                                                                        .edit,
                                                                    color: Colors
                                                                        .blueAccent,
                                                                    onTap: () {
                                                                      Get.to(
                                                                        EditFormScreen(
                                                                          id: attribute[
                                                                              'id'],
                                                                          appurl:
                                                                              widget.appurl,
                                                                          formID:
                                                                              widget.formID,
                                                                          menutitle:
                                                                              widget.menutitle,
                                                                          userstoryName:
                                                                              attribute['userstoryName'].toString(),
                                                                          iscreate:
                                                                              widget.iscreate,
                                                                          isread:
                                                                              widget.isread,
                                                                          isdelete:
                                                                              widget.isdelete,
                                                                          isupdate:
                                                                              widget.isupdate,
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                const SizedBox(
                                                                    width: 8),
                                                             // 👁 VIEW
                                                                if (widget
                                                                        .isupdate !=
                                                                    0)
                                                                  borderedIcon(
                                                                    icon: Icons
                                                                        .visibility,
                                                                    color: Colors
                                                                        .blueAccent,
                                                                    onTap: () {
                                                             _showFullDetailsDialog(
                                                                          attribute);
                                                                    },
                                                                  ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                // 🗑 DELETE
                                                                if (widget
                                                                        .isdelete !=
                                                                    0)
                                                                  borderedIcon(
                                                                    icon: Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red,
                                                                    onTap: () {
                                                                      showDialog(
                                                                        context:
                                                                            context,
                                                                        builder:
                                                                            (BuildContext
                                                                                context) {
                                                                          return AlertDialog(
                                                                            backgroundColor: isDarkMode
                                                                                ? Colors.black
                                                                                : Colors.white,
                                                                            content:
                                                                                SizedBox(
                                                                              height: 130,
                                                                              child: Column(
                                                                                children: [
                                                                                  const SizedBox(height: 15),
                                                                                  Text(
                                                                                    "Are you sure you want to delete this item?",
                                                                                    style: TextStyle(
                                                                                      fontSize: 15,
                                                                                      fontFamily: "lato",
                                                                                      fontWeight: FontWeight.w500,
                                                                                      color: isDarkMode ? Colors.white : Colors.black,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15),
                                                                                  Row(
                                                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                                    children: [
                                                                                      ElevatedButton(
                                                                                        onPressed: () {
                                                                                          Navigator.of(context).pop();
                                                                                        },
                                                                                        child: const Text("Cancel"),
                                                                                      ),
                                                                                      ElevatedButton(
                                                                                        onPressed: () {
                                                                                          Get.back();
                                                                                          viewcontroller.deletelistitem(
                                                                                            widget.appurl,
                                                                                            widget.menutitle,
                                                                                            attribute['id'].toString(),
                                                                                            viewcontroller.CurrentPage.value,
                                                                                            _pageSize,
                                                                                          );
                                                                                          setState(() {});
                                                                                        },
                                                                                        child: const Text("Delete"),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        },
                                                                      );
                                                                    },
                                                                  ),
                                                              ],
                                                            )
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                         ...List.generate(dynamicValues.length, (columnIndex) {
  final labelItem = viewcontroller.labellist[columnIndex];
  final displayLabel = _capitalize(labelItem['label']);
  final type = labelItem['type'];
  final value = dynamicValues[columnIndex];

  // Get timeFormat if available
  dynamic timeFormatValue = labelItem['timeFormat'];
  int timeFormat = 24; // default
  if (timeFormatValue != null) {
    if (timeFormatValue is int) {
      timeFormat = timeFormatValue;
    } else if (timeFormatValue is String) {
      timeFormat = int.tryParse(timeFormatValue) ?? 24;
    }
  }

  // Format the value for display
  final displayValue = _formatDisplayValue(type, value, timeFormat: timeFormat);

  if (type == 'location') {
    final loc = value;
    String textToShow = '-';

    if (loc is Map &&
        loc.containsKey('lat') &&
        loc.containsKey('lng')) {
      final lat = loc['lat'];
      final lng = loc['lng'];
      textToShow = '$lat, $lng';
    } else if (loc is String &&
        loc.contains('lat') &&
        loc.contains('lng')) {
      try {
        final cleaned = loc.replaceAll(RegExp(r'[{}]'), '');
        final parts = cleaned.split(',');
        final lat = parts[0].split(':')[1].trim();
        final lng = parts[1].split(':')[1].trim();
        textToShow = '$lat, $lng';
      } catch (_) {
        textToShow = '-';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$displayLabel: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (textToShow != '-') {
                  final uri = Uri.parse('https://www.google.com/maps?q=$textToShow');
                  await launchUrl(uri);
                }
              },
              child: Text(
                textToShow,
                style: const TextStyle(
                  color: Color(0xFF2962FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  if (type == 'boolean') {
    return Row(
      children: [
        Text(
          "$displayLabel: ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            value == "" || value == null
                ? ""
                : value == 1 || value == "1"
                    ? 'True'
                    : 'False',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  if (type == 'file') {
    final imageId = value ?? 0;
    final imageUrl = (imageId != 0 && imageId.toString().isNotEmpty)
        ? "https://cuickdev.com/API/DOCS/api/doc/th/$imageId?t=${DateTime.now().millisecondsSinceEpoch}"
        : imageUrlHelper.applogourl;

    return Row(
      children: [
        Expanded(
          child: Text(
            "$displayLabel: ",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/$imageId');
            await launchUrl(testUrl);
          },
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ],
    );
  }

  if (type == 'textarea') {
    final textValue = value?.toString() ?? "";

    return GestureDetector(
      onTap: () {
        if (textValue.isNotEmpty && textValue != '-') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Full Textarea'),
              content: SingleChildScrollView(
                child: Text(textValue),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      },
      child: Row(
        children: [
          Text(
            "$displayLabel: ",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          textValue.isNotEmpty
              ? Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Container(
                      width: 250,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: CustomScrollableTextWithIndicator(
                        textValue: textValue,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  if (type == 'email') {
    return GestureDetector(
      onTap: () async {
        final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: value,
          query: Uri.encodeQueryComponent('subject=Your Subject&body=Your message here'),
        );
        launchUrl(emailLaunchUri);
      },
      child: Row(
        children: [
          Text(
            "$displayLabel: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              displayValue.toString(), // Use formatted value
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  if (type == 'url') {
    return GestureDetector(
      onTap: () async {
        final Uri testUrl = Uri.parse(value);
        await launchUrl(testUrl);
      },
      child: Text(
        displayValue.toString(), // Use formatted value
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  if (type == 'doc') {
    final imageId = value ?? 0;
    final imageUrl = (imageId != 0)
        ? "https://cuickdev.com/API/DOCS/api/doc/th/$imageId?t=${DateTime.now().millisecondsSinceEpoch}"
        : imageUrlHelper.applogourl;

    return Row(
      children: [
        Expanded(
          child: Text(
            "$displayLabel: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final Uri testUrl = Uri.parse('https://cuickdev.com/API/DOCS/api/doc/$imageId');
            await launchUrl(testUrl);
          },
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 24,
              height: 24,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ],
    );
  }

  // Default: show formatted text value
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$displayLabel: ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            displayValue.toString(), // Use formatted value
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    ));
                                      }),
                                                    ]
                                         )));

                                      },
                                    ),
                                  ),
                                )
                              : const SizedBox()
                          : viewcontroller.list.isNotEmpty &&
                                  viewcontroller.labellist.isNotEmpty &&
                                  widget.isread != 0
                              ? LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.black
                                                : const Color(
                                                    0xFFF5F5F5), // Dark mode background
                                          ),
                                          border: TableBorder.all(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : const Color(0xFFE0E0E0)),
                                          dataRowMinHeight: 1,
                                          columnSpacing: 20,
                                          dividerThickness: 0.2,
                                          columns: [
                                            if (widget.isdelete != 0)
                                              DataColumn(
                                                label: Checkbox(
                                                  activeColor: Colors.white,
                                                  fillColor:
                                                      WidgetStatePropertyAll(
                                                    isDarkMode
                                                        ? const Color(
                                                            0xFF2962FF)
                                                        : Appcolorblue,
                                                  ),
                                                  value: isAllSelected,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isAllSelected =
                                                          value ?? false;

                                                      final currentPageIds =
                                                          viewcontroller.list
                                                              .map((item) =>
                                                                  item['id']
                                                                      as int)
                                                              .toList();

                                                      if (isAllSelected) {
                                                        // Add current page items if not already selected
                                                        for (var id
                                                            in currentPageIds) {
                                                          if (!selectedItemIds
                                                              .contains(id)) {
                                                            selectedItemIds
                                                                .add(id);
                                                          }
                                                        }
                                                      } else {
                                                        // Remove current page items from selection
                                                        selectedItemIds
                                                            .removeWhere((id) =>
                                                                currentPageIds
                                                                    .contains(
                                                                        id));
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            if (widget.isupdate != 0)
                                              DataColumn(
                                                label: Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            DataColumn(
                                              label: Text(
                                                'SNo.',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            ...List.generate(
                                              viewcontroller.labellist.length,
                                              (index) {
                                                final item = viewcontroller
                                                    .labellist[index];

                                                final displayLabel = item[
                                                                'refKey'] ==
                                                            1 &&
                                                        item['depAttribute'] !=
                                                            null
                                                    ? _capitalize(item['label'])
                                                    : _capitalize(
                                                        item['label']);

                                                return DataColumn(
                                                  label: Text(
                                                    displayLabel,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            // DataColumn(
                                            //   label: Text(
                                            //     'Tags',
                                            //     style: TextStyle(
                                            //       fontSize: 15,
                                            //       color: isDarkMode
                                            //           ? Colors.white
                                            //           : Colors.black,
                                            //       fontWeight: FontWeight.bold,
                                            //     ),
                                            //   ),
                                            // ),

                                   if (widget.isdelete !=
                                                0) // सिर्फ delete permission check
                                              DataColumn(
                                                label: Text(
                                                  'Action',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                    rows: List<DataRow>.generate(
                                            viewcontroller.list.length,
                                            (rowIndex) {
                                              final attribute =
                                                  viewcontroller.list[rowIndex];
                                              final dynamicValues =
                                                  viewcontroller.labellist
                                                      .map((label) {
                                                if (label['refKey'] == 1 &&
                                                    label['depAttribute'] !=
                                                        null) {
                                                  return attribute[
                                                      label['depAttribute']];
                                                }
                                                return attribute[label['code']];
                                              }).toList();

                                              // Cells की list बनाएं
                                              final cells = <DataCell>[];

                                              // 1. Delete checkbox (अगर permission है)
                                              if (widget.isdelete != 0) {
                                                cells.add(
                                                  DataCell(
                                                    Checkbox(
                                                      value: selectedItemIds
                                                          .contains(
                                                              attribute['id']),
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          final id =
                                                              attribute['id']
                                                                  as int;
                                                          if (value == true) {
                                                            selectedItemIds
                                                                .add(id);
                                                          } else {
                                                            selectedItemIds
                                                                .remove(id);
                                                          }
                                                          final currentPageIds =
                                                              viewcontroller
                                                                  .list
                                                                  .map((item) =>
                                                                      item[
                                                                          'id'])
                                                                  .toList();
                                                          isAllSelected = currentPageIds
                                                              .every((id) =>
                                                                  selectedItemIds
                                                                      .contains(
                                                                          id));
                                                        });
                                                      },
                                                      activeColor: Colors.white,
                                                      fillColor:
                                                          WidgetStatePropertyAll(
                                                        isDarkMode
                                                            ? const Color(
                                                                0xFF2962FF)
                                                            : Appcolorblue,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              // 2. Edit button (अगर permission है)
                                              if (widget.isupdate != 0) {
                                                cells.add(
                                                  DataCell(
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors
                                                              .blueAccent),
                                                      onPressed: () {
                                                        Get.to(EditFormScreen(
                                                          id: attribute['id'],
                                                          appurl: widget.appurl,
                                                          formID: widget.formID,
                                                          menutitle:
                                                              widget.menutitle,
                                                          userstoryName: attribute[
                                                                  'userstoryName']
                                                              .toString(),
                                                          iscreate:
                                                              widget.iscreate,
                                                          isread: widget.isread,
                                                          isdelete:
                                                              widget.isdelete,
                                                          isupdate:
                                                              widget.isupdate,
                                                        ));
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }

                                              // 3. SNo.
                                              cells.add(
                                                DataCell(
                                                  Text(
                                                    ((viewcontroller.CurrentPage
                                                                    .value *
                                                                _pageSize) +
                                                            rowIndex +
                                                            1)
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              );

                                              // 4. Dynamic columns based on labellist
                                              for (int columnIndex = 0;
                                                  columnIndex <
                                                      dynamicValues.length;
                                                  columnIndex++) {
                                                final type = viewcontroller
                                                        .labellist[columnIndex]
                                                    ['type'];
                                                final value =
                                                    dynamicValues[columnIndex];

                                                // Format the value based on type
                                                String displayValue = '-';

                                                if (type == 'idate') {
                                                  displayValue =
                                                      _formatIDate(value);
                                                } else if (type == 'itime') {
                                                  displayValue =
                                                      _formatITime(value);
                                                } else if (type ==
                                                    'dateandtime') {
                                                  displayValue =
                                                      _formatDateTime(value);
                                                } else if (type == 'date') {
                                                  displayValue =
                                                      _formatDate(value);
                                                } else if (type == 'time') {
                                                  displayValue =
                                                      _formatTime(value);
                                                } else if (type == 'decimal' || type == 'number' || type == 'long') {
                                                  displayValue = formatNumber(value);
                                                } else {
                                                  displayValue = value?.toString() ?? '-';
                                                }
                                                // Special handling for different types
                                                if (type == 'file' ||
                                                    type == 'doc') {
                                                  final imageId = value ?? 0;
                                                  final imageUrl = (imageId !=
                                                          0)
                                                      ? "https://cuickdev.com/API/DOCS/api/doc/th/$imageId?t=${DateTime.now().millisecondsSinceEpoch}"
                                                      : imageUrlHelper
                                                          .applogourl;

                                                  cells.add(
                                                    DataCell(
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final Uri testUrl =
                                                              Uri.parse(
                                                                  'https://cuickdev.com/API/DOCS/api/doc/$imageId');
                                                          await launchUrl(
                                                              testUrl);
                                                        },
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: imageUrl,
                                                          width: 50,
                                                          height: 50,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context,
                                                                  url) =>
                                                              const SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons.error),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                } else if (type == 'textarea') {
                                                  final textValue =
                                                      value?.toString() ?? "";
                                                  cells.add(
                                                    DataCell(
                                                      GestureDetector(
                                                        onTap: () {
                                                          if (textValue
                                                                  .isNotEmpty &&
                                                              textValue !=
                                                                  '-') {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) =>
                                                                      AlertDialog(
                                                                title: const Text(
                                                                    'Full Textarea'),
                                                                content: SingleChildScrollView(
                                                                    child: Text(
                                                                        textValue)),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(),
                                                                    child: const Text(
                                                                        'Close'),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Container(
                                                          width: 250,
                                                          height: 60,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                            color: Colors.white,
                                                            border: Border.all(
                                                                color: const Color(
                                                                    0xFFE0E0E0)),
                                                          ),
                                                          child:
                                                              CustomScrollableTextWithIndicator(
                                                            textValue:
                                                                textValue,
                                                            isDarkMode:
                                                                isDarkMode,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                } else if (type == 'location') {
                                                  final loc = value;
                                                  String textToShow = '-';

                                                  if (loc is Map &&
                                                      loc.containsKey('lat') &&
                                                      loc.containsKey('lng')) {
                                                    textToShow =
                                                        '${loc['lat']}, ${loc['lng']}';
                                                  }

                                                  cells.add(
                                                    DataCell(
                                                      GestureDetector(
                                                        onTap: () async {
                                                          if (textToShow !=
                                                              '-') {
                                                            final uri = Uri.parse(
                                                                'https://www.google.com/maps?q=$textToShow');
                                                            await launchUrl(
                                                                uri);
                                                          }
                                                        },
                                                        child: Text(
                                                          textToShow,
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF2962FF),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  cells.add(
                                                    DataCell(
                                                      Text(
                                                        displayValue,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }

                                              // 5. Action buttons (अगर permission है)
                 // Check what actions are available
              // 5. Action buttons - सिर्फ तभी show करें जब delete permission हो
                                              if (widget.isdelete != 0) {
                                                // सिर्फ delete permission check करें
                                                cells.add(
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // 🗑️ Delete icon - सिर्फ delete permission होने पर
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.delete,
                                                              color:
                                                                  Colors.red),
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  backgroundColor: isDarkMode
                                                                      ? Colors
                                                                          .black
                                                                      : Colors
                                                                          .white,
                                                                  content:
                                                                      SizedBox(
                                                                    height: 130,
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        const SizedBox(
                                                                            height:
                                                                                15),
                                                                        Text(
                                                                          "Are you sure you want to delete this item?",
                                                                          style:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontFamily:
                                                                                "lato",
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color: isDarkMode
                                                                                ? Colors.white
                                                                                : Colors.black,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            height:
                                                                                15),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceAround,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              style: ButtonStyle(
                                                                                backgroundColor: WidgetStateProperty.all<Color>(
                                                                                  isDarkMode ? Colors.grey[800]! : const Color(0xFFB0B0B4),
                                                                                ),
                                                                              ),
                                                                              onPressed: () => Navigator.of(context).pop(),
                                                                              child: const Text("Cancel"),
                                                                            ),
                                                                            ElevatedButton(
                                                                              style: ButtonStyle(
                                                                                backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFFFF043B)),
                                                                              ),
                                                                              onPressed: () {
                                                                                Get.back();
                                                                                FocusScope.of(context).unfocus();
                                                                                viewcontroller.deletelistitem(
                                                                                  widget.appurl,
                                                                                  widget.menutitle,
                                                                                  attribute['id'].toString(),
                                                                                  viewcontroller.CurrentPage.value,
                                                                                  _pageSize,
                                                                                );
                                                                              },
                                                                              child: const Text("Delete"),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }

                                              return DataRow(
                                                color: WidgetStateProperty
                                                    .resolveWith<Color?>(
                                                  (Set<WidgetState> states) =>
                                                      isDarkMode
                                                          ? (rowIndex.isEven
                                                              ? Colors.grey[900]
                                                              : Colors
                                                                  .grey[800])
                                                          : (rowIndex.isEven
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey[200]),
                                                ),
                                                cells:
                                                    cells, // यहाँ सभी cells एक साथ pass करें
                                              );
                                            },
                                          ),
                                       
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox(); // Show your ListView or GridView
                  }
                }),
                const SizedBox(),
                if (viewcontroller.totalPages.value > 1 && widget.isread != 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.first_page,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: viewcontroller.CurrentPage.value > 0
                              ? () => _changePage(0)
                              : null, // First page should be 0
                        ),

                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: viewcontroller.CurrentPage.value > 0
                              ? () => _changePage(
                                  viewcontroller.CurrentPage.value - 1)
                              : null, // Previous page
                        ),

                        Text(
                          "Page ${viewcontroller.CurrentPage.value + 1} of ${viewcontroller.totalPages.value}",
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black),
                        ),
                        // Displaying 1-based page numbers

                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: viewcontroller.CurrentPage.value <
                                  viewcontroller.totalPages.value - 1
                              ? () => _changePage(
                                  viewcontroller.CurrentPage.value + 1)
                              : null, // Next page
                        ),

                        IconButton(
                          icon: Icon(
                            Icons.last_page,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: viewcontroller.CurrentPage.value <
                                  viewcontroller.totalPages.value - 1
                              ? () => _changePage(
                                  viewcontroller.totalPages.value - 1)
                              : null, // Last page
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  final ApiBaseHelper helper = ApiBaseHelper();

  Future<Map<String, dynamic>?> SaveTag(int id, String tag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
    }

    Map<String, dynamic> reqBody = {
      'id': id,
      'tag': tag
    }; // Add the 'id' field first

    try {
      final response = await helper.postApi(
        "api/v1/${viewcontroller.appCode.value}/${viewcontroller.code.value}/${viewcontroller.saveformcode.value.toString()}/saveForm;jsessionid=$sessionId",
        reqBody,
      );

      if (response != null && response['success'] == true) {
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return {'message': 'Error occurred while saving the form'};
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}

class CustomRow {
  final String name;
  final String value;

  CustomRow({required this.name, required this.value});
}
