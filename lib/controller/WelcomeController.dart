import 'dart:async';
import 'dart:convert';
import 'package:cuickdevuser/model/application_model.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/model/loginmodel.dart';
import 'package:cuickdevuser/service/LocalStorageservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../service/httpservice.dart';
import 'login_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WelcomeController extends GetxController {
  var name = "".obs;
  var applicationurl = "".obs;
  var jsession = "".obs;
  var userstoryName = "".obs;
  var authkey = 0.obs;
  var userid = 0.obs;
  var imageId = 0.obs;
  var appId = 0.obs;
  var orgimage = 0.obs;
  var code = "".obs;
  var applicationname = "".obs;
  var userrolename = "".obs;
  var orgName = "".obs;
  var dashboardlistitem = ''.obs;
  var isOffline = false.obs;
  var isRefreshing = false.obs;
  var isInitialized = false.obs;
  
  List<Org> loadedOrgList = [];
  List<App> loadedAppList = [];
  
  TextEditingController rolename = TextEditingController();
  TextEditingController appname = TextEditingController();
  TextEditingController appurl = TextEditingController();
  
  HttpServices httpServices = HttpServices();
  
  RxList<dynamic> dashboardlist = RxList<dynamic>();
  RxList<dynamic> labellist = RxList<dynamic>();
  RxMap<String, List<dynamic>> prelaodlist = RxMap<String, List<dynamic>>();
  RxList<dynamic> DATAlist = RxList<dynamic>();
  final RxMap<String, String> _fieldValues = <String, String>{}.obs;
  RxList<Map<String, dynamic>> structuredMenu = <Map<String, dynamic>>[].obs;
  var fieldvalue = <Field>[].obs;
  RxMap<String, String> initialValues = <String, String>{}.obs;
  var dboardlist = <dynamic>[].obs;
  RxList<dynamic> fieldsList = RxList<dynamic>();
  
  final LoginController loginController = Get.put(LoginController());
  RxList<Menu> menus = <Menu>[].obs;
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  
  final List<String> allowedTypes = [
    'text', 'date', 'number', 'object', 'email', 'time', 'url', 'map', 'textarea'
  ];
  
  var list = <Map<String, dynamic>>[].obs;
  List<String> globalYUsecases = [];
  RxList<Map<String, dynamic>> structuredReports = <Map<String, dynamic>>[].obs;
  RxList<Menu> reports = <Menu>[].obs;
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;
  Map<String, dynamic> dataMap = {};
  RxMap<String, int> chartData = <String, int>{}.obs;
  var orgId = 0.obs;

  final TextEditingController searchController = TextEditingController();
  final RxList<dynamic> filteredMenu = RxList<dynamic>();
  final RxList<dynamic> searcfilteredMenu = RxList<dynamic>();
  final RxList<dynamic> searcedMenu = RxList<dynamic>();

  // Track connectivity state
  bool lastConnectivityState = true;
  Timer? _refreshDebounceTimer;
  Timer? _retryTimer;
  // Add these variables at the top of WelcomeController with your other Rx variables
  var cachedOrgImage = Rx<Uint8List?>(null);
  var isOrgImageCached = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
    Getinitaldata();
    checkSession();
    
    // Listen to connectivity changes with immediate refresh
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool wasOffline = isOffline.value;
      bool isNowOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      
      // Update offline status
      isOffline.value = isNowOffline;
      
      // If we just came online (was offline and now online)
      if (wasOffline && !isNowOffline) {
        print("🚀 Internet connection restored! Auto-refreshing data immediately...");
        // Cancel any pending retry
        _retryTimer?.cancel();
        // Immediate refresh without debounce for better user experience
        autoRefreshData();
      }
      
      // If we just went offline
      if (!wasOffline && isNowOffline) {
        print("📴 Internet connection lost. Working in offline mode...");
        // Get.snackbar(
        //   'Offline Mode',
        //   'You are now working offline. Showing cached data.',
        //   snackPosition: SnackPosition.TOP,
        //   backgroundColor: Colors.orange,
        //   colorText: Colors.white,
        //   duration: const Duration(seconds: 3),
        // );
      }
    });
  }

  @override
  void onClose() {
    _refreshDebounceTimer?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }

  // Auto refresh data when connection is restored
  Future<void> autoRefreshData() async {
    if (isRefreshing.value) {
      print("Already refreshing, skipping auto-refresh...");
      return;
    }
    
    isRefreshing.value = true;
    
    try {
      print("🔄 Starting auto-refresh process...");
      
      // Clear existing data to force fresh load
      dashboardlist.clear();
      list.clear();
      
      // Refresh all data in sequence with proper error handling
      await GetapplicationDetails();
      await buildMenuHierarchy();
      await getDashoard(); // This will fetch fresh data
      await getData();
      
      isInitialized.value = true;
      
      print("✅ Auto-refresh completed successfully! Dashboard items: ${dashboardlist.length}");
      
      // Get.snackbar(
      //   'Internet Restored',
      //   'Dashboard data has been refreshed successfully',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      //   icon: const Icon(Icons.wifi, color: Colors.white),
      // );
    } catch (e) {
      print("❌ Auto-refresh failed: $e");
      
      // Retry after 3 seconds
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 3), () {
        if (!isOffline.value && !isRefreshing.value) {
          print("🔄 Retrying auto-refresh...");
          autoRefreshData();
        }
      });
      
      Get.snackbar(
        'Refresh Failed',
        'Could not refresh data. Retrying automatically...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  // Manual refresh with loading indicator
  Future<void> manualRefresh() async {
    if (isRefreshing.value) {
      Get.snackbar(
        'Already Refreshing',
        'Please wait for current refresh to complete',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    isRefreshing.value = true;
    
    try {
      // Clear existing data
      dashboardlist.clear();
      list.clear();
      
      await Future.wait([
        GetapplicationDetails(),
        buildMenuHierarchy(),
        getDashoard(),
        getData(),
      ]);
      
      Get.snackbar(
        'Success',
        'Dashboard data refreshed successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Refresh Failed',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    isOffline.value = connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none);
    lastConnectivityState = !isOffline.value;
  }

  Future<bool> isDeviceOffline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none);
  }

  Future<void> checkSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('islogin') ?? false;

    if (!isLoggedIn) {
      Get.offAllNamed('/login');
    }
  }

  Future<void> Getinitaldata() async {
    try {
      // First load cached data
      await loadCachedData();
      
      // Then try to fetch fresh data if online
      if (!await isDeviceOffline()) {
        await Future.wait([
          GetapplicationDetails(),
          buildMenuHierarchy(),
          getDashoard(),
          getData(),
        ]);
        isInitialized.value = true;
      }
    } catch (e) {
      print("Initialization error: $e");
    }
  }

  // Add this method to cache the organization image
  Future<void> cacheOrgImage(int orgImageId) async {
    if (orgImageId == 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String imageUrl =
          "https://cuickdev.com/API/DOCS/api/doc/th/$orgImageId";

      // Download and cache the image
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        // Save to SharedPreferences as base64
        final String base64Image = base64Encode(bytes);
        await prefs.setString('org_image_$orgImageId', base64Image);
        await prefs.setInt('last_org_image_id', orgImageId);

        // Also save to local storage
        await LocalStorageService.saveOrgImage(orgImageId.toString(), bytes);

        cachedOrgImage.value = bytes;
        isOrgImageCached.value = true;
        print("✅ Organization image cached successfully for ID: $orgImageId");
      }
    } catch (e) {
      print("❌ Error caching organization image: $e");
    }
  }

// Add this method to load cached organization image
  Future<Uint8List?> loadCachedOrgImage(int orgImageId) async {
    if (orgImageId == 0) return null;

    try {
      // Try to load from LocalStorageService first
      final Uint8List? localBytes =
          await LocalStorageService.loadOrgImage(orgImageId.toString());
      if (localBytes != null) {
        cachedOrgImage.value = localBytes;
        isOrgImageCached.value = true;
        print("📦 Loaded org image from LocalStorageService");
        return localBytes;
      }

      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? base64Image = prefs.getString('org_image_$orgImageId');

      if (base64Image != null) {
        final Uint8List bytes = base64Decode(base64Image);
        cachedOrgImage.value = bytes;
        isOrgImageCached.value = true;
        print("📦 Loaded org image from SharedPreferences");
        return bytes;
      }

      // Try to load last cached org image
      final int lastOrgImageId = prefs.getInt('last_org_image_id') ?? 0;
      if (lastOrgImageId != 0) {
        final String? lastBase64Image =
            prefs.getString('org_image_$lastOrgImageId');
        if (lastBase64Image != null) {
          final Uint8List bytes = base64Decode(lastBase64Image);
          cachedOrgImage.value = bytes;
          isOrgImageCached.value = true;
          print("📦 Loaded last cached org image: $lastOrgImageId");
          return bytes;
        }
      }
    } catch (e) {
      print("❌ Error loading cached organization image: $e");
    }

    return null;
  }

// Add this method to clear org image cache (useful during logout)
  Future<void> clearOrgImageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int lastOrgImageId = prefs.getInt('last_org_image_id') ?? 0;

      if (lastOrgImageId != 0) {
        await prefs.remove('org_image_$lastOrgImageId');
      }
      await prefs.remove('last_org_image_id');

      cachedOrgImage.value = null;
      isOrgImageCached.value = false;

      // Also clear from LocalStorageService
      if (lastOrgImageId != 0) {
        await LocalStorageService.deleteOrgImage(lastOrgImageId.toString());
      }

      print("🗑️ Organization image cache cleared");
    } catch (e) {
      print("❌ Error clearing org image cache: $e");
    }
  }
  Future<void> GetOrgDetails() async {
  // Check if offline
  if (await isDeviceOffline()) {
    var cachedData = await LocalStorageService.loadOrgDetails();
    if (cachedData != null) {
      orgName.value = cachedData['name'] ?? "";
      orgimage.value = cachedData['logoId'] ?? 0;
      
      // Load cached org image
      if (orgimage.value != 0) {
        await loadCachedOrgImage(orgimage.value);
      }
    }
    return;
  }

  try {
    var res = await httpServices.GetORGDetails(orgid: orgId.value);
    if (res != null && res['success'] == true) {
      var data = res['result']['data'];
      orgName.value = data['name'] ?? "";
      orgimage.value = data['logoId'] ?? 0;
      
      // Save to cache
      await LocalStorageService.saveOrgDetails({
        'name': orgName.value,
        'logoId': orgimage.value,
      });
      
      // Cache the org image
      if (orgimage.value != 0) {
        await cacheOrgImage(orgimage.value);
      }
      
      update();
    }
  } catch (e) {
    print("Error fetching org details: $e");
    
    // On error, try to load cached org details and image
    var cachedData = await LocalStorageService.loadOrgDetails();
    if (cachedData != null) {
      orgName.value = cachedData['name'] ?? "";
      orgimage.value = cachedData['logoId'] ?? 0;
      
      // Load cached org image
      if (orgimage.value != 0) {
        await loadCachedOrgImage(orgimage.value);
      }
    }
  }
}

  Future<void> loadCachedData() async {
    try {
      // Load dashboard data from cache
      List<dynamic> cachedDashboard = await LocalStorageService.loadDashboardData();
      if (cachedDashboard.isNotEmpty) {
        dashboardlist.assignAll(cachedDashboard);
        print('📦 Loaded ${cachedDashboard.length} dashboard items from cache');
      }

      // Load menu data from cache
      List<dynamic> cachedMenu = await LocalStorageService.loadMenuData();
      if (cachedMenu.isNotEmpty) {
        searcfilteredMenu.assignAll(cachedMenu);
        structuredMenu.value = cachedMenu.cast<Map<String, dynamic>>();
        print('📦 Loaded ${cachedMenu.length} menu items from cache');
      }

      // Load application details from cache
      var cachedAppDetails = await LocalStorageService.loadApplicationDetails();
      if (cachedAppDetails != null) {
        imageId.value = cachedAppDetails['logo'] ?? 0;
        applicationname.value = cachedAppDetails['name'] ?? "";
      }

      // Load org details from cache
      var cachedOrgDetails = await LocalStorageService.loadOrgDetails();
      if (cachedOrgDetails != null) {
        orgName.value = cachedOrgDetails['name'] ?? "";
        orgimage.value = cachedOrgDetails['logoId'] ?? 0;
      }

      update();
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  // Add these variables at the top of WelcomeController
var cachedProfileImage = Rx<Uint8List?>(null);
var isProfileImageCached = false.obs;

// Add this method to cache the profile image
Future<void> cacheProfileImage(int imageId) async {
  if (imageId == 0) return;
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final String imageUrl = "https://cuickdev.com/API/DOCS/api/doc/th/$imageId";
    
    // Download and cache the image
    final http.Response response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final Uint8List bytes = response.bodyBytes;
      
      // Save to SharedPreferences as base64
      final String base64Image = base64Encode(bytes);
      await prefs.setString('profile_image_$imageId', base64Image);
      await prefs.setInt('last_profile_image_id', imageId);
      
      // Also save to local storage
      await LocalStorageService.saveProfileImage(imageId.toString(), bytes);
      
      cachedProfileImage.value = bytes;
      isProfileImageCached.value = true;
      print("✅ Profile image cached successfully for ID: $imageId");
    }
  } catch (e) {
    print("❌ Error caching profile image: $e");
  }
}

// Add this method to load cached profile image
Future<Uint8List?> loadCachedProfileImage(int imageId) async {
  if (imageId == 0) return null;
  
  try {
    // Try to load from LocalStorageService first
    final Uint8List? localBytes = await LocalStorageService.loadProfileImage(imageId.toString());
    if (localBytes != null) {
      cachedProfileImage.value = localBytes;
      isProfileImageCached.value = true;
      return localBytes;
    }
    
    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? base64Image = prefs.getString('profile_image_$imageId');
    
    if (base64Image != null) {
      final Uint8List bytes = base64Decode(base64Image);
      cachedProfileImage.value = bytes;
      isProfileImageCached.value = true;
      return bytes;
    }
    
    // Try to load last cached image
    final int lastImageId = prefs.getInt('last_profile_image_id') ?? 0;
    if (lastImageId != 0) {
      final String? lastBase64Image = prefs.getString('profile_image_$lastImageId');
      if (lastBase64Image != null) {
        final Uint8List bytes = base64Decode(lastBase64Image);
        cachedProfileImage.value = bytes;
        isProfileImageCached.value = true;
        return bytes;
      }
    }
  } catch (e) {
    print("❌ Error loading cached profile image: $e");
  }
  
  return null;
}

// Update GetapplicationDetails to cache profile image
Future<void> GetapplicationDetails() async {
  final pref = await SharedPreferences.getInstance();
  String? cdauth = pref.getString('cdauthkey');
  if (cdauth != null && cdauth.isNotEmpty) {
    List<String> parts = cdauth.split('.');
    if (parts.length > 1) {
      orgId.value = int.parse(parts[0]);
      appId.value = int.parse(parts[1]);
    }
  }

  // Check if offline
  if (await isDeviceOffline()) {
    // Load from cache
    var cachedData = await LocalStorageService.loadApplicationDetails();
    if (cachedData != null) {
      imageId.value = cachedData['logo'] ?? 0;
      applicationname.value = cachedData['name'] ?? "";
      
      // Load cached profile image
      await loadCachedProfileImage(imageId.value);
    }
    return;
  }

  try {
    var res = await httpServices.GetapplicationDetails(appid: appId.value.toString());
    if (res != null && res['success'] == true) {
      var data = res['result']['data'];
      imageId.value = data['logo'] ?? 0;
      applicationname.value = data['name'] ?? "";

      // Save to cache
      await LocalStorageService.saveApplicationDetails({
        'logo': imageId.value,
        'name': applicationname.value,
      });
      
      // Cache the profile image
      if (imageId.value != 0) {
        await cacheProfileImage(imageId.value);
      }
      
      await GetOrgDetails();

      pref.setString("appName", applicationname.value);
      pref.setInt("logo", imageId.value);
      pref.setInt("orgimage", orgimage.value);
      pref.setString("orgName", orgName.value);
    }
  } catch (e) {
    print("Error fetching application details: $e");
    
    // On error, try to load cached image
    int cachedImageId = pref.getInt('logo') ?? pref.getInt('last_profile_image_id') ?? 0;
    if (cachedImageId != 0) {
      imageId.value = cachedImageId;
      applicationname.value = pref.getString("appName") ?? "";
      await loadCachedProfileImage(cachedImageId);
    }
  }
  update();
}


  List<Map<String, dynamic>> extractData(List<Menu> jsonData) {
    List<Map<String, dynamic>> extractedData = [];

    for (var item in jsonData) {
      Map<String, dynamic> extractedItem = {
        "name": item.name ?? "",
        "linkto": item.linkto ?? "",
        "id": item.id ?? "",
        "code": item.code ?? "",
      };

      if (item.linkto == "form") {
        extractedItem["formId"] = item.formId?.toString() ?? "";
      } else if (item.linkto == "report") {
        extractedItem["reportsId"] = item.reportsId?.toString() ?? "";
      } else if (item.linkto == "url") {
        extractedItem["url"] = item.url ?? "";
      }

      extractedData.add(extractedItem);

      if (item.children.isNotEmpty) {
        extractedData.addAll(extractData(item.children));
      }
    }
    update();
    return extractedData;
  }

  void updateMenuList(List<Menu> jsonData) {
    searcfilteredMenu.clear();
    searcfilteredMenu.addAll(extractData(jsonData));
    // Save to cache
    LocalStorageService.saveMenuData(searcfilteredMenu.toList());
    update();
  }

  void filterMenu(String query) {
    if (query.isEmpty) {
      searcedMenu.assignAll(searcfilteredMenu);
    } else {
      searcedMenu.assignAll(
        searcfilteredMenu.where((menu) {
          final name = menu['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList(),
      );
    }
    searcedMenu.refresh();
  }

  Future<void> getDashoard() async {
    final pref = await SharedPreferences.getInstance();
    String? cdauth = pref.getString('cdauthkey');
    if (cdauth == null || cdauth.isEmpty) {
      print("No cdauthkey found");
      return;
    }
    
    List<String> parts = cdauth.toString().split('.');
    if (parts.length < 2) {
      print("Invalid cdauthkey format");
      return;
    }
    
    int appId = int.parse(parts[1]);

    // Check if offline
    if (await isDeviceOffline()) {
      List<dynamic> cachedData = await LocalStorageService.loadDashboardData();
      if (cachedData.isNotEmpty) {
        dashboardlist.assignAll(cachedData);
        print('📦 Loaded dashboard from cache in offline mode');
      }
      return;
    }

    await GetDashboarddata(appId);
  }

  Future<void> Getitemcode(String formid) async {
    if (formid.isEmpty) return;
    
    // Check if offline
    if (await isDeviceOffline()) {
      List<dynamic> cachedTableData = await LocalStorageService.loadTableData(formid);
      if (cachedTableData.isNotEmpty) {
        list.assignAll(cachedTableData.map((item) => item as Map<String, dynamic>).toList());
      }
      return;
    }

    try {
      var res = await httpServices.GetListusecase(id: formid);
      if (res != null && res['success'] == true) {
        var dataResponse = res['result']['data'];
        if (dataResponse != null) {
          code.value = dataResponse['code'] ?? '';
          applicationurl.value = dataResponse['appCode'] ?? '';
          if (code.value.isNotEmpty && applicationurl.value.isNotEmpty) {
            await GetdataList(applicationurl.value, code.value);
          }
        }
      }
    } catch (e) {
      print("Error in Getitemcode: $e");
    }
  }

  Future<void> GetDashboarddata(int appid) async {
    try {
      var res = await httpServices.Dashboarduiform(applicationId: appid);
      
      if (res != null && res['success'] == true) {
        var filteredList = res['result']['data'];
        if (filteredList != null && filteredList is List) {
          dashboardlist.assignAll(filteredList);
          
          // Save to cache immediately
          await LocalStorageService.saveDashboardData(filteredList);
          print("✅ Dashboard data fetched and cached: ${filteredList.length} items");
          
          // Load data for each dashboard item
          for (var dashboardItem in dashboardlist) {
            final userstoryId = dashboardItem['userstoryId']?.toString();
            if (userstoryId != null && userstoryId.isNotEmpty) {
              await Getitemcode(userstoryId);
              await Getattributefield(userstoryId);
            }
          }
        }
      } else {
        print('API response failed or no data');
        // Try to load from cache if API fails
        List<dynamic> cachedData = await LocalStorageService.loadDashboardData();
        if (cachedData.isNotEmpty) {
          dashboardlist.assignAll(cachedData);
          print('📦 Loaded dashboard from cache after API failure');
        }
      }
    } catch (e) {
      print("Error in GetDashboarddata: $e");
      // Load from cache on error
      List<dynamic> cachedData = await LocalStorageService.loadDashboardData();
      if (cachedData.isNotEmpty) {
        dashboardlist.assignAll(cachedData);
        print('📦 Loaded dashboard from cache after error');
      }
    }
  }

  Future<void> GetdataList(String url, String field) async {
    if (url.isEmpty || field.isEmpty) return;
    
    try {
      var res = await httpServices.GetList(
        url: url,
        field: field.toLowerCase(),
        currentPage: 0,
      );
      
      if (res != null && res['success'] == true) {
        var dataResponse = res['result']['data'];
        if (dataResponse != null && dataResponse is List) {
          list.assignAll(dataResponse.map((item) => item as Map<String, dynamic>).toList());
          
          // Save table data to cache
          if (code.value.isNotEmpty) {
            await LocalStorageService.saveTableData(code.value, dataResponse);
          }
        }
      } else {
        // Try to load from cache if API fails
        if (code.value.isNotEmpty) {
          List<dynamic> cachedData = await LocalStorageService.loadTableData(code.value);
          if (cachedData.isNotEmpty) {
            list.assignAll(cachedData.map((item) => item as Map<String, dynamic>).toList());
            print('📦 Loaded table data from cache for form: ${code.value}');
          }
        }
      }
    } catch (e) {
      print("Error in GetdataList: $e");
      // Load from cache on error
      if (code.value.isNotEmpty) {
        List<dynamic> cachedData = await LocalStorageService.loadTableData(code.value);
        if (cachedData.isNotEmpty) {
          list.assignAll(cachedData.map((item) => item as Map<String, dynamic>).toList());
        }
      }
    }
  }

  Future<void> Getpreloadfield(String name) async {
    String formname = code.value.isNotEmpty ? code.value : name;
    if (formname.isEmpty) return;
    
    // Check if offline
    if (await isDeviceOffline()) {
      return;
    }

    try {
      var res = await httpServices.Getpreloaddata(
          formname: formname, appurl: applicationurl.value);
      if (res != null && res['success'] == true) {
        var result = res['result'] ?? {};
        var useCases = globalYUsecases;
        prelaodlist.clear();
        for (var useCase in useCases) {
          if (result.containsKey(useCase)) {
            var data = result[useCase];
            if (data is List) {
              prelaodlist[useCase] = List.from(data);
            }
          }
        }
      }
    } catch (e) {
      print("Error in Getpreloadfield: $e");
    }
  }

  Future<void> buildMenuHierarchy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String applicationRoleId = prefs.getString("applicationRoleId") ?? '';
    
    if (applicationRoleId.isEmpty) {
      Logout();
      return;
    }

    // Check if offline
    if (await isDeviceOffline()) {
      List<dynamic> cachedMenu = await LocalStorageService.loadMenuData();
      if (cachedMenu.isNotEmpty) {
        searcfilteredMenu.assignAll(cachedMenu);
        structuredMenu.value = cachedMenu.cast<Map<String, dynamic>>();
        print('📦 Loaded menu from cache in offline mode');
      }
      return;
    }

    try {
      if (loginController.menus.isEmpty) {
        var res = await httpServices.Getapplications(roleId: applicationRoleId);
        if (res?.success == true && res?.result?.data != null) {
          var data = res!.result.data;
          if (data != null) {
            userrolename.value = data.rolename?.toString() ?? '';
            menus.assignAll(data.menus ?? []);
            updateMenuList(menus);
            
            List<Map<String, dynamic>> structuredData = [];
            for (var parentMenu in menus) {
              structuredData.add(_buildMenuMap(parentMenu));
            }
            structuredMenu.value = structuredData;
            filteredMenu.value = structuredData;
            
            // Save to cache
            await LocalStorageService.saveMenuData(structuredData);
          }
        }
      } else {
        menus.assignAll(loginController.menus);
        updateMenuList(menus);
        
        List<Map<String, dynamic>> structuredData = [];
        for (var parentMenu in menus) {
          structuredData.add(_buildMenuMap(parentMenu));
        }
        structuredMenu.value = structuredData;
        filteredMenu.value = structuredData;
        
        // Save to cache
        await LocalStorageService.saveMenuData(structuredData);
      }
    } catch (e) {
      print("Error in buildMenuHierarchy: $e");
      // Load from cache on error
      List<dynamic> cachedMenu = await LocalStorageService.loadMenuData();
      if (cachedMenu.isNotEmpty) {
        searcfilteredMenu.assignAll(cachedMenu);
        structuredMenu.value = cachedMenu.cast<Map<String, dynamic>>();
      }
    }
  }

  Future<void> Getattributefield(String formId) async {
    if (formId.isEmpty) return;
    
    labellist.clear();
    
    // Check if offline
    if (await isDeviceOffline()) {
      return;
    }

    try {
      var res = await httpServices.Getlistattribute(formId: formId);
      if (res != null && res['success'] == true) {
        var filteredList = res['result']['data'];
        if (filteredList != null && filteredList is List) {
          var sortedFilteredList = filteredList.where((label) {
            return fields.any((field) => field.id.toString() == label['id'].toString());
          }).toList();
          
          sortedFilteredList.sort((a, b) {
            int indexA = fields.indexWhere((field) => field.id.toString() == a['id'].toString());
            int indexB = fields.indexWhere((field) => field.id.toString() == b['id'].toString());
            return indexA.compareTo(indexB);
          });
          
          if (sortedFilteredList.isNotEmpty) {
            labellist.assignAll(sortedFilteredList);
          }
          
          filterlabellist.assignAll(
            labellist.where((e) => allowedTypes.contains(e['type'])).toList()
          );
          
          var uniqueUsecases = <String>{};
          for (var dashboardItem in labellist) {
            String yUsecase = dashboardItem['primaryUsecase'] ?? "";
            if (yUsecase.isNotEmpty) {
              uniqueUsecases.add(yUsecase);
            }
          }
          globalYUsecases = uniqueUsecases.toList();
          await Getpreloadfield(userstoryName.value.toLowerCase());
        }
      }
    } catch (e) {
      print("Error in Getattributefield: $e");
    }
  }

  Future<void> Logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jsessionid');
    await prefs.remove('islogin');
    await prefs.remove('authkey');
    await prefs.remove('userid');
    await prefs.remove('imageId');
    await prefs.remove('appId');
    await prefs.remove('loginId');
    await prefs.remove('defaultRoleId');
    await prefs.remove('applicationRoleId');
    await prefs.remove('appName');
    await prefs.remove('appId');
    await prefs.remove('logo');
    await prefs.remove('orgimage');
    
    // Clear all cached data on logout
    await LocalStorageService.clearAllCache();
    
    Get.offAllNamed('/login');
  }

  Future<void> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    name.value = prefs.getString("name") ?? "";
    jsession.value = prefs.getString("jsessionid") ?? "";
    authkey.value = prefs.getInt("authkey") ?? 0;
    userid.value = prefs.getInt("userid") ?? 0;
    appId.value = prefs.getInt("appId") ?? 0;
    orgimage.value = prefs.getInt("orgimage") ?? 0;
    orgName.value = prefs.getString("orgName") ?? "";
    loadedOrgList = await loadOrgListFromPrefs();
    loadedAppList = await loadAppListFromPrefs();
  }

  void navigateBack() {
    Get.back();
  }

  Map<String, dynamic> _buildMenuMap(Menu menu) {
    return {
      'title': menu.name ?? '',
      'formId': menu.formId ?? 0,
      'reportId': menu.reportsId ?? 0,
      'url': menu.url ?? '',
      'linkto': menu.linkto ?? '',
      'submenus': menu.children?.map((child) => _buildMenuMap(child)).toList() ?? [],
    };
  }

  Future<List<Org>> loadOrgListFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? orgListJson = prefs.getStringList('orgList');
    if (orgListJson == null) {
      return [];
    } else {
      return orgListJson.map((org) => Org.fromJson(jsonDecode(org))).toList();
    }
  }

  Future<List<App>> loadAppListFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? appListJson = prefs.getStringList('appList');
    if (appListJson == null) {
      return [];
    } else {
      return appListJson.map((app) => App.fromJson(jsonDecode(app))).toList();
    }
  }

  // Add this method to WelcomeController
  Future<String> getProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    int cachedImageId = prefs.getInt('imageId') ?? 0;
    int currentImageId = imageId.value;

    // If we have a cached image ID and we're offline, use it
    if (await isDeviceOffline()) {
      if (cachedImageId != 0) {
        return "https://cuickdev.com/API/DOCS/api/doc/th/$cachedImageId?t=cached";
      }
    }

    // If online, use current image ID and cache it
    if (!await isDeviceOffline() && currentImageId != 0) {
      await prefs.setInt('imageId', currentImageId);
      return "https://cuickdev.com/API/DOCS/api/doc/th/$currentImageId?t==${DateTime.now().millisecondsSinceEpoch}";
    }

    // Fallback to default
    return "https://cuickdev.com/API/DOCS/api/doc/th/0?t=cached";
  }
}