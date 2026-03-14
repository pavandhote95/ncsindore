import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/attendance_controller.dart';
import 'package:cuickdevuser/screen/Utility_Qr_Screen.dart';
import 'package:cuickdevuser/screen/ViewAttendanceScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../components/Appcolor.dart';
import 'package:provider/provider.dart';

class AttendanceScreen extends StatelessWidget {
  AttendanceScreen({super.key});
  final AttendanceController controller = Get.put(AttendanceController());
  @override
  Widget build(BuildContext context) {
        final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
          double size = MediaQuery.of(context).size.width * 0.28;

      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Access List",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 40),

            /// 🔵 Scan Button
       /// 🔵 Scan + View Attendance Buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// 🔍 Scan Button             
                  InkWell(
                    onTap: () {
                      Get.to(() => const UtilityQrScannerScreen());
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:isDarkMode?Colors.white: Colors.indigo,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/scan-icon.png',
                            height: size * 0.4,
                            width: size * 0.4,
                            color:isDarkMode?Colors.black: Colors.indigo,
                          ),
                          SizedBox(height: size * 0.08),
                          Text(
                            "Scan",
                            style: TextStyle(
                              color:isDarkMode?Colors.black: Colors.indigo,
                              fontWeight: FontWeight.w700,
                              fontSize: size * 0.16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// 📋 View Attendance Button
          /// 📋 View Attendance Button (Same Color as Scan)
                  InkWell(
                    onTap: () {
                      Get.to(() => AttendanceTableScreen());
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:isDarkMode?Colors.black: Colors.indigo, // SAME COLOR
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: size * 0.4,
                            color:isDarkMode?Colors.black: Colors.indigo, // SAME COLOR
                          ),
                          SizedBox(height: size * 0.08),
                          Text(
                            "Attendance",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:isDarkMode?Colors.black: Colors.indigo, // SAME COLOR
                              fontWeight: FontWeight.w700,
                              fontSize: size * 0.14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),
            /// Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Attendance",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Text(
                      "View all",
                      style: TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationThickness: 0.5,
                        color: Color.fromARGB(255, 134, 134, 134),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            /// 📋 Attendance List
            Expanded(
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                itemCount: controller.itemCount,
                itemBuilder: (context, index) {
                  bool isLate = index % 3 == 0;
                  bool isIn = index % 2 == 0;
              
                  return attendanceCard(
                    isDarkMode: isDarkMode,
                    day: "${13 - (index % 5)}",
                    month: "January 2026",
                    status: isLate ? "Late" : "On Time",
                    time: isIn ? "10:0${index % 6} AM" : "06:2${index % 6} PM",
                    type: isIn ? "IN" : "OUT",
                    isLate: isLate,
                  );
                },
              ),
            ),
          ],
        ),
      );
    
  }
  /// 🔹 Attendance Card
  Widget attendanceCard({
    required bool isDarkMode,
    required String day,
    required String month,
    required String status,
    required String time,
    required String type,
    required bool isLate,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          /// Date Box
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  month,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white70 : Colors.black,
                  ),
                ),
              ],
            ),  
          ),
          const SizedBox(width: 12),

          /// Arrow
Icon(
            isLate ? Icons.arrow_back : Icons.arrow_forward,
            color: isLate ? Colors.red : Colors.green,
          ),

          const SizedBox(width: 12),

          /// Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLate ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLate ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Time : $time",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          /// IN / OUT
          Text(
            type,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: type == "IN" ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}