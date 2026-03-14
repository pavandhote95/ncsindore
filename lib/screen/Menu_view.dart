import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/tableview_controller.dart';
import 'package:cuickdevuser/controller/Uiform_controller.dart';
import 'package:cuickdevuser/screen/Menucontroller.dart';
import 'package:cuickdevuser/screen/Pivotchartscreen.dart';
import 'package:cuickdevuser/screen/dynamic_chart_screen.dart';
import 'package:cuickdevuser/screen/table_view_screen.dart';
import 'package:cuickdevuser/screen/ui_form_screen.dart';
import 'package:cuickdevuser/screen/welcome.dart';
import 'Edit_form.dart';

class MenuViewscreen extends StatefulWidget {
  final String appurl;
  final String menutitle;
  final String formID;
  final int initialTabIndex;

  const MenuViewscreen({
    super.key,
    required this.appurl,
    required this.menutitle,
    required this.formID,
    required this.initialTabIndex,
  });

  @override
  State<MenuViewscreen> createState() => _MenuViewscreenState();
}

class _MenuViewscreenState extends State<MenuViewscreen> {
  final Menucontroller controller = Get.put(Menucontroller());
  final TableviewController tableviewController = Get.put(TableviewController());
  final Uiformcontroller uicontroller = Get.put(Uiformcontroller(), permanent: true);

  @override
  void initState() {
    super.initState();
    controller.getuser_role_access(widget.formID);
  }

  // Reset UiFormScreen data safely
  void resetUiForm() {
    // uicontroller.imagePaths.clear();
    // uicontroller.docPaths.clear();
    // uicontroller.showTextField.value = false;
    // uicontroller.clearForm();
    uicontroller.saveform_id.value = 0;
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Obx(() => Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Appcolorblue,
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: isDarkMode ? Colors.grey[800] : Appcolorblue,
            title: Text(widget.menutitle,
                style: const TextStyle(color: Colors.white, fontSize: 20)),
          ),
          body: WillPopScope(
            onWillPop: () async {
              if (controller.currentIndex.value == 0) {
                Get.offAll(() => Welcomescreen());
              } else {
                controller.changeTab(0);
              }
              return false;
            },
            child: IndexedStack(
              index: controller.currentIndex.value,
              children: [
                TableViewScreen(
                  appurl: widget.appurl,
                  menutitle: widget.menutitle,
                  formID: widget.formID,
                  iscreate: controller.iscreate.value,
                  isread: controller.isread.value,
                  isdelete: controller.isdelete.value,
                  isupdate: controller.isupdate.value,
                  isuserFilter: controller.isuserFilter.value,
                ),
                UiFormScreen(
                  appurl: widget.appurl,
                  menutitle: widget.menutitle,
                  formID: widget.formID,
                  iscreate: controller.iscreate.value,
                  isread: controller.isread.value,
                  isdelete: controller.isdelete.value,
                  isupdate: controller.isupdate.value,
                ),
                DynamicChartScreen(
                  appurl: widget.appurl,
                  menutitle: widget.menutitle,
                  formID: widget.formID,
                ),
                Pivotchartscreen(
                  appurl: widget.appurl,
                  menutitle: widget.menutitle,
                  formID: widget.formID,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: (index) async {
              if (index == 1) {
                await tableviewController.getfetchrule();

                if (tableviewController.updatedFormID.value.isNotEmpty) {
                  Get.to(() => EditFormScreen(
                        id: int.parse(tableviewController.updatedFormID.value),
                        appurl: widget.appurl,
                        formID: widget.formID,
                        menutitle: widget.menutitle,
                        userstoryName: tableviewController.updateduserstoryname.value,
                        iscreate: controller.iscreate.value,
                        isread: controller.isread.value,
                        isdelete: controller.isdelete.value,
                        isupdate: controller.isupdate.value,
                      ));
                  return;
                } else {
                  resetUiForm();
                  controller.changeTabmenu(index);
                }
              } else {
                controller.changeTabmenu(index);
              }
            },
            items: [
              BottomNavigationBarItem(
                backgroundColor: isDarkMode ? Colors.grey[800] : Appcolorblue,
                icon: const Icon(Icons.list_sharp),
                label: 'List',
              ),
              BottomNavigationBarItem(
                backgroundColor: isDarkMode ? Colors.grey[800] : Appcolorblue,
                icon: const Icon(Icons.text_snippet_outlined),
                label: 'Form',
              ),
              BottomNavigationBarItem(
                backgroundColor: isDarkMode ? Colors.grey[800] : Appcolorblue,
                icon: const Icon(Icons.bar_chart),
                label: 'Quick',
              ),
              BottomNavigationBarItem(
                backgroundColor: isDarkMode ? Colors.grey[800] : Appcolorblue,
                icon: const Icon(Icons.pivot_table_chart),
                label: 'Pivot',
              ),
            ],
            backgroundColor: isDarkMode ? Colors.grey[800] : Appcolorblue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
          ),
        ));
  }
}
