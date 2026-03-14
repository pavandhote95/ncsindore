import 'package:cuickdevuser/screen/AttendaceScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../components/ThemeProvider.dart';
import '../components/Appcolor.dart';

class UtilityAppsScreen extends StatelessWidget {
  const UtilityAppsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

final List<Map<String, dynamic>> apps = [
      {
        "title": "Attendance",
        "subtitle": "Mark & Track Attendance",
        "icon": Icons.fact_check, 
      },
      {
        "title": "Sample App",
        "subtitle": "Customer Management",
        "icon": Icons.people,
      },
      {
        "title": "Sample App",
        "subtitle": "My Tasks",
        "icon": Icons.task_alt,
      },
      {
        "title": "Sample App",
        "subtitle": "View & Edit",
        "icon": Icons.person,
      },
      {
        "title": "Sample App",
        "subtitle": "Scan Codes",
        "icon": Icons.qr_code_scanner,
      },
      {
        "title": "Sample App",
        "subtitle": "Access Control",
        "icon": Icons.nfc,
      },                                                                                                                        
    ];

  return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Utility Apps",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: apps.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final app = apps[index];

            return appGridTile(
              context,
              title: app["title"],
              subtitle: app["subtitle"],
              icon: app["icon"],
              onTap: () {
                if (app["title"] == "Attendance") {
                  Get.to(() =>  AttendanceScreen());
                }
              },
            );
          },
        ),
      ),
    );

  }

  /// 🔹 Grid Card Widget
  Widget appGridTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isDarkMode ? Colors.white :const  Color(0xFF1A237E,)
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
