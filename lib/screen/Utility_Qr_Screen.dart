import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_id/android_id.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';
import '../service/httpservice.dart';

class UtilityQrScannerScreen extends StatefulWidget {
  const UtilityQrScannerScreen({super.key});
  @override
  State<UtilityQrScannerScreen> createState() => _UtilityQrScannerScreenState();
}
class _UtilityQrScannerScreenState extends State<UtilityQrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;
  HttpServices httpServices = HttpServices();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.indigo,
          borderRadius: 12,
          borderLength: 30,
          borderWidth: 8,
          cutOutSize: 260,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;

    controller!.scannedDataStream.listen((scanData) async {
      if (scanned) return;
      scanned = true;

      final String? qrValue = scanData.code;
      if (qrValue == null || qrValue.isEmpty) {
        _showErrorToast(context, "Invalid QR Code");
        scanned = false;
        return;
      }

      try {
        // 📍 LOCATION
        Position position = await _getCurrentLocation();

        // 📶 WIFI
        List<String> wifiList = await _scanWifi();

        // 🚀 API CALL
        await _sendAccessData(
          qrValue,
          position.latitude,
          position.longitude,
          wifiList,
        );
      } catch (e) {
        _showErrorToast(context, e.toString());
        scanned = false;
      }
    });
  }

  // 📍 LOCATION
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 📶 WIFI
  Future<List<String>> _scanWifi() async {
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      return [];
    }

    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();

    return results.map((wifi) => wifi.ssid).toList();
  }

  // 📱 DEVICE ID
  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      const androidIdPlugin = AndroidId();
      final String? androidId = await androidIdPlugin.getId();
      return androidId ?? "android_unknown";
    }
    return "unknown_device";
  }

  // 🚀 API CALL
  Future<void> _sendAccessData(
    String qrValue,
    double lat,
    double lon,
    List<String> wifiList,
  ) async {
    try {
      print("========== ACCESS API START ==========");

      final prefs = await SharedPreferences.getInstance();

      int? prefUserId = prefs.getInt('userid');
      String? prefUserName = prefs.getString('name');
      String? prefSessionId = prefs.getString('jsessionid');
      String? userRole = prefs.getString("userrolename");
      String? appCode = prefs.getString("appCode");

      print("📦 SharedPreferences Data:");
      print("userid      => $prefUserId");
      print("name        => $prefUserName");
      print("jsessionid  => $prefSessionId");
      print("role        => $userRole");
      print("appCode     => $appCode");

      String userId = prefUserId?.toString() ?? "0";
      String userName = prefUserName ?? "";
      String sessionId = prefSessionId ?? "";
      String accessType = userRole ?? "USER";
      String finalAppCode = appCode ?? "pnac-application";
      String deviceId = await getDeviceId();

Map<String, dynamic> payload = {
        "accessType": accessType,
        "gateName": qrValue,
        "id": 0,
        "latLonPosition": "$lat,$lon",
        "mobileId": deviceId,
        "userName": userName,
        "userid": userId,
        "wifiList": wifiList.join(","),
        "dateAndTime": DateTime.now().toUtc().toIso8601String(),
      };


      print("📤 API PAYLOAD:");
      payload.forEach((key, value) {
        print("$key => $value");
      });

      final url = 'api/v1/$finalAppCode/access-list/'
          '$finalAppCode.access-list.access-list/'
          'saveForm;jsessionid=$sessionId';

      print("🌐 API URL:");
      print(url);

      final response = await httpServices.helper.postApi(url, payload);

      print("📥 API RESPONSE:");
      print(response);

      if (response != null && response['success'] == true) {
        _showSuccessDialog(
          context,
          response['message'] ?? "Access Granted",
        );
      } else {
        _showErrorToast(
          context,
          response?['message'] ?? "Access Denied",
        );
        scanned = false;
      }

      print("========== ACCESS API END ==========");
    } catch (e, stack) {
      print("🔥 API EXCEPTION:");
      print(e);
      print(stack);
      _showErrorToast(context, "API Error");
      scanned = false;
    }
  }
  // ✅ SUCCESS DIALOG
  void _showSuccessDialog(BuildContext context, String message) {
    Get.defaultDialog(
      title: '',
      radius: 30,
      barrierDismissible: false,
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/donetask.png',
              height: 90,
              width: 90,
              color: Colors.green,
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(200, 45),
              ),
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ❌ ERROR TOAST
  void _showErrorToast(BuildContext context, String message) {
    MotionToast(
      icon: Icons.error_outline,
      primaryColor: Colors.redAccent.withOpacity(0.3),
      secondaryColor: Colors.white,
      enableAnimation: true,
      animationType: AnimationType.slideInFromTop,
      toastAlignment: Alignment.topCenter,
      title: const Text(
        "Failed!",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
