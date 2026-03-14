  import 'package:cherry_toast/cherry_toast.dart';
  import 'package:cuickdevuser/controller/attendanc_table_controller.dart';
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:provider/provider.dart';
  import '../components/Appcolor.dart';
  import '../components/ThemeProvider.dart';

  class AttendanceTableScreen extends StatelessWidget {
    AttendanceTableScreen({super.key});
    final AttendanceTableController controller =
        Get.put(AttendanceTableController());

    @override
    Widget build(BuildContext context) {
      final themeNotifier = Provider.of<ThemeNotifier>(context);
      bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

      DateTime now = DateTime.now(); // Current date for highlighting

      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Attendance List",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            // Filter Icon
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: () {
                _showFilterDialog(context);
              },
            ),
  IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                CherryToast.success(
                  title: const Text("Refreshed successfully!"),
                  toastDuration: const Duration(microseconds: 500),
                  disableToastAnimation: true, // ✨ no animation
                  autoDismiss: true,
                ).show(context);

                // TODO: Add your actual refresh logic here
              },
            ),

            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // January 2026
                _monthHeader("January 2026", controller.januaryData, isDarkMode),
                _attendanceTable(controller.januaryData, isDarkMode, 1, 2026, now),
          
                // November 2025
                _monthHeader("November 2025", controller.novemberData, isDarkMode),
                _attendanceTable(
                    controller.novemberData, isDarkMode, 11, 2025, now),
              ],
            ),
          ),
        ),
      );
    }

    /// 🔹 Month Header
    Widget _monthHeader(String title, List<Map<String, String>> data, bool dark) {
      int presentCount = data.where((e) => e['status'] == "P").length;

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AttendanceTableColors.headerText(dark))),
            Text("Working Days: $presentCount",
                style: TextStyle(
                    fontSize: 15,
                    color: AttendanceTableColors.subText(dark),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    /// 🔹 Attendance Table (5 cells per row)
    Widget _attendanceTable(List<Map<String, String>> data, bool dark, int month,
        int year, DateTime today) {
      int cols = 5;
      int rows = (data.length / cols).ceil();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
          },
          children: List.generate(rows, (row) {
            return TableRow(
              children: List.generate(cols, (col) {
                int index = row * cols + col;
                if (index >= data.length) return const SizedBox(); // empty cell
                return _dayCell(data[index], dark, month, year, today);
              }),
            );
          }),
        ),
      );
    }

    /// 🔹 Day Cell
    Widget _dayCell(Map<String, String> item, bool dark, int month, int year,
        DateTime today) {
      bool present = item['status'] == "P";

      int day = int.tryParse(item['day'] ?? '0') ?? 0;

      // Highlight only if this cell is today
      bool isToday =
          (day == today.day && month == today.month && year == today.year);

      return Container(
        height: 85,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isToday
              ? const Color.fromARGB(255, 255, 249, 193)
              : AttendanceTableColors.cellBg(dark),
          border: Border.all(color: AttendanceTableColors.border(dark)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           Text(
            "Day $day",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color:isToday?Colors.black: AttendanceTableColors.textColor(dark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['status']!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: present
                  ? AttendanceTableColors.present
                  : AttendanceTableColors.absent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "(${item['hrs']})",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color:isToday?Colors.black: AttendanceTableColors.textColor(dark),
            ),
          ),

          ],
        ),
      );
    }

    /// 🔹 Filter Dialog
  void _showFilterDialog(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    String selectedMonth = "January";
    String selectedYear = DateTime.now().year.toString();

    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    List<String> years =
        List.generate(10, (index) => (2023 + index).toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            title: Text(
              "Select Month and Year",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.indigo,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedMonth,
                  isExpanded: true,
                  dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  items: months
                      .map((month) => DropdownMenuItem(
                            value: month,
                            child: Text(month),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedYear,
                  isExpanded: true,
                  dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  items: years
                      .map((year) => DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Appcolorblue : Appcolorblue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
         CherryToast.success(
                  
                    description: Text(
                      "$selectedMonth, $selectedYear",
                      style: TextStyle(
                        color: isDarkMode ? Colors.black87 : Colors.black87,
                      ),
                    ),
                    toastDuration: const Duration(milliseconds: 800),
                    disableToastAnimation: true, // same as refresh
                    autoDismiss: true,
                  ).show(context);

                  Navigator.pop(context);

                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        });
      },
    );
  }

  
  }

  /// 🔹 Colors
  class AttendanceTableColors {
    static const Color present = Colors.green;
    static const Color absent = Colors.red;

    static Color cellBg(bool dark) => dark ? Colors.black : Colors.white;
    static Color border(bool dark) =>
        dark ? const Color.fromARGB(255, 78, 78, 78) : Colors.grey.shade300;
    static Color headerText(bool dark) => dark ? Colors.white : Colors.black;
    static Color subText(bool dark) => dark ? Colors.white : Colors.black;
    static Color textColor(bool dark) => dark ? Colors.white70 : Colors.black87;

  }
