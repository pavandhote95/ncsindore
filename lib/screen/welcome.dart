import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';
import 'package:cuickdevuser/controller/login_controller.dart';
import 'package:cuickdevuser/controller/report_controller.dart';
import 'package:cuickdevuser/main.dart';
import 'package:cuickdevuser/screen/Menu_view.dart';
import 'package:cuickdevuser/screen/MyDataTableWidget.dart';
import 'package:cuickdevuser/screen/MyTodoList.dart';
import 'package:cuickdevuser/screen/MybarchartWidget.dart';
import 'package:cuickdevuser/screen/Mylinechartwidget.dart';
import 'package:cuickdevuser/screen/MypiechartWiget.dart';
import 'package:cuickdevuser/screen/profile_screen.dart';
import 'package:cuickdevuser/screen/report_screen.dart';
import 'package:cuickdevuser/screen/support_system_screen.dart';
import 'package:cuickdevuser/service/LocalStorageservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/ProfileController.dart';
import '../model/application_model.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Welcomescreen extends StatefulWidget {
  const Welcomescreen({super.key});

  @override
  State<Welcomescreen> createState() => _WelcomescreenState();
}

class _WelcomescreenState extends State<Welcomescreen>
    with TickerProviderStateMixin {
  final WelcomeController controller = Get.put(WelcomeController());
  bool isLoadingpage = false;
  late TabController _tabController;
  late FocusNode _focusNode;
  bool _isFocused = false;
  String userrolename = "";
  String username = "";
  String orgname = "";

  final _iconTabs = [
    Tab(icon: Image.asset('assets/Backgrounds/tablechart.png')),
    Tab(icon: Image.asset('assets/Backgrounds/pie-chart.png')),
    Tab(icon: Image.asset('assets/Backgrounds/bar-graph.png')),
    Tab(icon: Image.asset('assets/Backgrounds/line-chart.png')),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });

    getrolename();

    // Listen to connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isOffline =
          results.isEmpty || results.contains(ConnectivityResult.none);

      if (!isOffline) {
        // We're online, refresh data if needed
        if (controller.dashboardlist.isEmpty) {
          controller.getDashoard();
        }
        if (username.isEmpty) {
          getrolename();
        }
        if (controller.orgName.isEmpty) {
          controller.GetapplicationDetails();
        }
        if (controller.searcfilteredMenu.isEmpty ||
            controller.structuredMenu.isEmpty) {
          loadData();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _tabController.dispose();
   
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  getrolename() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userrolename = prefs.getString("userrolename") ?? '';
      username = prefs.getString("name") ?? '';
      orgname = prefs.getString('orgname') ?? "";
    });
  }

  Future<void> loadData() async {
    setState(() {
      isLoadingpage = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    getrolename();

    try {
      await Future.wait([
        controller.GetapplicationDetails(),
        controller.getDashoard(),
        controller.getData(),
        controller.buildMenuHierarchy(),
      ]);
    } catch (e) {
      print("Error loading data: $e");
    }

    if (!mounted) return;

    setState(() {
      isLoadingpage = false;
    });
  }

  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndPrintFullContent() async {
    await Future.delayed(Duration(milliseconds: 300));

    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(child: pw.Image(pdfImage)),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: isDarkMode ? Colors.black : Colors.grey.shade100,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: isDarkMode ? Colors.black : Appcolorblue,
        title: Obx(() => Text(
              controller.isOffline.value ? 'Dashboard' : 'Dashboard',
              style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.white,
                  fontSize: 20),
            )),
        actions: [
         
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () {
              if (themeProvider.themeMode == ThemeMode.light) {
                themeProvider.setTheme(ThemeMode.dark);
              } else {
                themeProvider.setTheme(ThemeMode.light);
              }
            },
          ),
          GestureDetector(
            onTap: () {
              loadData();
            },
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.refresh),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Searchbottomsheet(context, controller, isDarkMode);
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
      drawer: Obx(() {
        return Drawer(
          elevation: 0.5,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black : Colors.grey.shade100,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8.0, top: 5),
                                child: Row(
                                  children: [
                                  // Replace the CircleAvatar in drawer with this:
                                    Obx(() {
                                      if (controller.cachedProfileImage.value !=
                                          null) {
                                        // Show cached image
                                        return CircleAvatar(
                                          radius: 38,
                                          backgroundImage: MemoryImage(
                                              controller
                                                  .cachedProfileImage.value!),
                                        );
                                      } else if (controller.imageId.value !=
                                          0) {
                                        // Try to load from network, but show cached version when offline
                                        return CircleAvatar(
                                          radius: 38,
                                          backgroundImage: NetworkImage(
                                            "https://cuickdev.com/API/DOCS/api/doc/th/${controller.imageId.value}?t==${DateTime.now().millisecondsSinceEpoch}",
                                          ),
                                          onBackgroundImageError: (_, __) {
                                            // If network fails, load cached image
                                            controller.loadCachedProfileImage(
                                                controller.imageId.value);
                                          },
                                        );
                                      } else {
                                        // Show default image
                                        return CircleAvatar(
                                          radius: 38,
                                          backgroundImage: const NetworkImage(
                                            "https://cuickdev.com/API/DOCS/api/doc/th/0",
                                          ),
                                          child: controller.isOffline.value
                                              ? Icon(Icons.person,
                                                  size: 38, color: Colors.grey)
                                              : null,
                                        );
                                      }
                                    }),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 185,
                                      child: Text(
                                        controller.applicationname.value
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 8),
                                  Text(
                                    "User: $username",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    " Role: $userrolename",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 5),
                      child: ListTile(
                        leading: Icon(Icons.home),
                        hoverColor: Colors.indigo,
                        iconColor: isDarkMode ? Colors.white : Colors.black87,
                        shape: Border.all(
                            color: Colors.grey,
                            style: BorderStyle.solid,
                            width: 0.5),
                        title: Text(
                          'Dashboard',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    buildMenu(controller.structuredMenu),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 5),
                      child: ListTile(
                        leading: Icon(Icons.person),
                        iconColor: isDarkMode ? Colors.white : Colors.black87,
                        shape: Border.all(color: Colors.grey, width: 0.5),
                        title: Text(
                          'Profile',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 5),
                      child: ListTile(
                        leading: Icon(Icons.task),
                        iconColor: isDarkMode ? Colors.white : Colors.black87,
                        shape: Border.all(color: Colors.grey, width: 0.5),
                        title: Text(
                          'Task',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          Get.to(const MyTodoList());
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 5),
                      child: ListTile(
                        leading: Icon(Icons.logout),
                        iconColor: isDarkMode ? Colors.white : Colors.black87,
                        shape: Border.all(color: Colors.grey, width: 0.5),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () async {
                              SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                               LocalStorageService.clearAllCache();
                          // await prefs.clear();
                          // await prefs.remove('cdauthkey');
                          await prefs.remove('jsessionid');
                          await prefs.remove('islogin');
                          await prefs.remove('authkey');
                          await prefs.remove('userid');
                          await prefs.remove('imageId');
                          await prefs.remove('appId');
                          await prefs.remove('loginId');
                          await prefs.remove('defaultRoleId');
                          await prefs.remove('applicationRoleId');
                          // Navigate to login screen
                  controller.Logout();

                          themeProvider.setTheme(ThemeMode.light);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Obx(() {
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: 8.0, top: 5, left: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(
                                    controller.orgimage.value != 0
                                        ? "https://cuickdev.com/API/DOCS/api/doc/th/${controller.orgimage.value}?t="
                                        : "https://cuickdev.com/API/DOCS/api/doc/th/0?t=",
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  controller.orgName.value.toString(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    
    
      body: WillPopScope(
        onWillPop: () async => false,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Obx(() {
            if (controller.isOffline.value &&
                controller.dashboardlist.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    
                    ],
                  ),
                ),
              );
            }

            if (isLoadingpage && controller.dashboardlist.isEmpty) {
              return Align(
                alignment: Alignment.center,
                child: LoadingAnimationWidget.threeArchedCircle(
                  size: 50,
                  color: Appcolorblue,
                ),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.dashboardlist.length,
              itemBuilder: (context, dashboardIndex) {
                final dashboardItem = controller.dashboardlist[dashboardIndex];
                RxList<Map<String, dynamic>> viewdatlist = controller.list;
                final fields = dashboardItem['fields'] ?? [];

                return DashboardItem(
                  itemlength: controller.dashboardlist.length,
                  dashboardItem: dashboardItem,
                  userstoryId: dashboardItem['userstoryId'].toString(),
                  fields: fields,
                  viewdatlist: viewdatlist,
                  iconTabs: _iconTabs,
                  applicationurl: controller.applicationurl.value,
                  dashboardIndex: dashboardIndex,
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget buildMenu(List<dynamic> menus) {
    final themeProvider = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: menus.map((menu) {
          List<dynamic> submenus = menu['submenus'] ?? [];
          String? linkto = menu['linkto'];
          String title = menu['title'] ?? 'No Title';

          IconData getMenuIcon() {
            if (linkto == "seperator") return Icons.send;
            if (linkto == "form") return Icons.list_alt;
            if (linkto == "report") return Icons.assessment;
            if (linkto == "url") return Icons.link;
            return Icons.menu;
          }

          if (submenus.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ExpansionTile(
                  title: GestureDetector(
                    onTap: () {
                      if (linkto == "seperator") return;
                      Navigator.pop(context);

                      if (linkto == "form") {
                        Get.to(MenuViewscreen(
                          appurl: controller.applicationurl.value,
                          menutitle: title,
                          formID: menu['formId']?.toString() ?? '',
                          initialTabIndex: 0,
                        ));
                      } else if (linkto == "report") {
                        Get.to(ReportpageScreen(
                          reportid: menu['reportId'].toString(),
                          reporttitle: title,
                          subReports: [],
                        ));
                      } else if (linkto == "url") {
                        launchUrl(Uri.parse(menu['url'] ?? ''));
                      }
                    },
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  collapsedIconColor:
                      isDarkMode ? Colors.white : Colors.black87,
                  leading: Icon(getMenuIcon()),
                  iconColor: isDarkMode ? Colors.white : Colors.black87,
                  children:
                      submenus.map((submenu) => buildMenu([submenu])).toList(),
                ),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () {
                if (linkto == "seperator") return;
                Navigator.pop(context);

                if (linkto == "form") {
                  Get.to(MenuViewscreen(
                    appurl: controller.applicationurl.value,
                    menutitle: title,
                    formID: menu['formId']?.toString() ?? '',
                    initialTabIndex: 0,
                  ));
                } else if (linkto == "report") {
                  Get.to(ReportpageScreen(
                    reportid: menu['reportId'].toString(),
                    reporttitle: title,
                    subReports: [],
                  ));
                } else if (linkto == "url") {
                  launchUrl(Uri.parse(menu['url'] ?? ''));
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    leading: Icon(getMenuIcon()),
                    iconColor: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }
}

void Searchbottomsheet(
    BuildContext context, WelcomeController controller, bool isdark) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        height: 650,
        decoration: BoxDecoration(
          color: isdark ? Colors.grey[850] : Colors.white,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 350,
                  height: 50,
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: (value) {
                      controller.searchController.text = value;
                      controller.filterMenu(value);
                    },
                    onSubmitted: (value) {
                      controller.searchController.text = value;
                      controller.filterMenu(value);
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: isdark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      fillColor: isdark ? Colors.black : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 15,
                        color: isdark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isdark ? Colors.white : Colors.black,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isdark ? Colors.white : Appcolorblue,
                        ),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.searchController.clear();
                          controller.filterMenu("");
                          Get.back();
                        },
                        child: Icon(
                          Icons.close,
                          color: isdark ? Colors.white : Colors.black,
                        ),
                      ),
                      hintText: 'Search the Menus',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isdark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            controller.searchController.text.isEmpty
                ? Expanded(
                    child: Obx(() {
                      return ListView.builder(
                        itemCount: controller.searcfilteredMenu.length,
                        itemBuilder: (context, index) {
                          if (controller.searcfilteredMenu.isNotEmpty) {
                            return GestureDetector(
                              onTap: () {
                                String? linkType = controller
                                    .searcfilteredMenu[index]['linkto'];
                                String menuTitle = controller
                                        .searcfilteredMenu[index]['name'] ??
                                    'No Title';
                                String formID = controller
                                        .searcfilteredMenu[index]['formId']
                                        ?.toString() ??
                                    '';
                                String reportid = controller
                                        .searcfilteredMenu[index]['reportsId']
                                        ?.toString() ??
                                    '';

                                if (linkType == "form") {
                                  Get.to(MenuViewscreen(
                                    appurl: controller.applicationurl.value,
                                    menutitle: menuTitle,
                                    formID: formID,
                                    initialTabIndex: 0,
                                  ));
                                } else if (linkType == "report") {
                                  Get.to(ReportpageScreen(
                                    reportid: reportid,
                                    reporttitle: menuTitle,
                                  ));
                                } else if (linkType == "url") {
                                  String? url = controller
                                      .searcfilteredMenu[index]['url'];
                                  if (url != null && url.isNotEmpty) {
                                    launchUrl(Uri.parse(url));
                                  }
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListTile(
                                  title: Text(
                                    " ${index + 1}. ${controller.searcfilteredMenu[index]['name'] ?? 'No Name'}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isdark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      );
                    }),
                  )
                : Expanded(
                    child: Obx(() {
                      return ListView.builder(
                        itemCount: controller.searcedMenu.length,
                        itemBuilder: (context, index) {
                          if (controller.searcedMenu.isNotEmpty) {
                            return GestureDetector(
                              onTap: () {
                                String? linkType =
                                    controller.searcedMenu[index]['linkto'];
                                String menuTitle = controller.searcedMenu[index]
                                        ['name'] ??
                                    'No Title';
                                String formID = controller.searcedMenu[index]
                                            ['formId']
                                        ?.toString() ??
                                    '';
                                String reportid = controller.searcedMenu[index]
                                            ['reportsId']
                                        ?.toString() ??
                                    '';

                                if (linkType == "form") {
                                  Get.to(MenuViewscreen(
                                    appurl: controller.applicationurl.value,
                                    menutitle: menuTitle,
                                    formID: formID,
                                    initialTabIndex: 0,
                                  ));
                                } else if (linkType == "report") {
                                  Get.to(ReportpageScreen(
                                    reportid: reportid,
                                    reporttitle: menuTitle,
                                  ));
                                } else if (linkType == "url") {
                                  String? url =
                                      controller.searcedMenu[index]['url'];
                                  if (url != null && url.isNotEmpty) {
                                    launchUrl(Uri.parse(url));
                                  }
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ListTile(
                                  title: Text(
                                    " ${index + 1}. ${controller.searcedMenu[index]['name'] ?? 'No Name'}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isdark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      );
                    }),
                  ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  ).whenComplete(
    () {
      if (controller.searchController.text != "" &&
          controller.searchController.text.isNotEmpty) {
        controller.searchController.clear();
        controller.filterMenu('');
      }
    },
  );
}

class DashboardItem extends StatefulWidget {
  final Map<String, dynamic> dashboardItem;
  final List fields;
  final RxList<Map<String, dynamic>> viewdatlist;
  final List<Widget> iconTabs;
  final int dashboardIndex;
  final String applicationurl;
  final String userstoryId;
  final int itemlength;

  const DashboardItem({
    Key? key,
    required this.dashboardItem,
    required this.fields,
    required this.viewdatlist,
    required this.iconTabs,
    required this.dashboardIndex,
    required this.applicationurl,
    required this.userstoryId,
    required this.itemlength,
  }) : super(key: key);

  @override
  State<DashboardItem> createState() => _DashboardItemState();
}

class _DashboardItemState extends State<DashboardItem>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _selectedColor = const Color(0xffdee2e6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black54.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.dashboardItem['title'] ??
                  'Dashboard ${widget.dashboardIndex + 1}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Container(
            height: 55,
            padding: const EdgeInsets.only(top: 16.0, right: 10.0, left: 10.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : _selectedColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              physics: const NeverScrollableScrollPhysics(),
              indicator: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      topRight: Radius.circular(4.0)),
                  color: Colors.white),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white,
              tabs: widget.iconTabs,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: widget.itemlength > 1 ? 300 : 550,
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                MyDataTableWidget(
                  itemlength: widget.itemlength,
                  userstoryId: widget.dashboardItem['userstoryId'].toString(),
                  fields: widget.fields,
                  list: widget.viewdatlist,
                  url: widget.applicationurl,
                  title: widget.dashboardItem['title'],
                ),
                MypiechartWiget(
                  itemlength: widget.itemlength,
                  title: widget.dashboardItem['title'],
                  fields: widget.fields,
                  url: widget.applicationurl,
                  formid: widget.dashboardItem['userstoryId'].toString(),
                ),
                MybarchartWidget(
                  itemlength: widget.itemlength,
                  title: widget.dashboardItem['title'],
                  fields: widget.fields,
                  url: widget.applicationurl,
                  formid: widget.dashboardItem['userstoryId'].toString(),
                ),
                Mylinechartwidget(
                  itemlength: widget.itemlength,
                  title: widget.dashboardItem['title'],
                  fields: widget.fields,
                  url: widget.applicationurl,
                  formid: widget.dashboardItem['userstoryId'].toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
