import 'package:cuickdevuser/controller/login_controller.dart';
import 'package:cuickdevuser/screen/login_screen.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboding/LandingPageView.dart';
class QrScreen extends StatefulWidget {
  QrScreen({Key? key}) : super(key: key);

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // final LoginController loginController =
  // Get.put(LoginController(), permanent: true);
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }
  Future<void> _onQRViewCreated(QRViewController controller) async {
    this.controller = controller;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool scanned = false;

    controller.scannedDataStream.listen((scanData) async {
      if (scanned || scanData.code == null) return;
      scanned = true;
      result = scanData;
      debugPrint('QR Scan Result: ${result!.code}');
      // Save auth key for this session
      await prefs.setString('cdauthkey', result!.code!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully Scanned QR Code')),
      );
      // Clear previous cached landing pages (optional, safer)
      final keys = prefs.getKeys().where((k) => k.startsWith('landingPageUrl_')).toList();
      for (var key in keys) await prefs.remove(key);

      // Navigate to LandingPageView with empty URL → it will fetch new landing page per app
      Get.off(() => LandingPageView(url: ""));

      controller.dispose();
    });
  }


  /*Future<void> _onQRViewCreated(QRViewController controller) async {
    this.controller = controller;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool scanned = false;
    controller.scannedDataStream.listen((scanData) async {
      if (!scanned) {
        setState(() {
          result = scanData;
          scanned = true;
        });
        debugPrint('result...............................${result!.code.toString()}');
        if (result != null) {
          setState(()  {
           prefs.setString('cdauthkey', result!.code.toString());
          });


          String? cdauth = prefs.getString('cdauthkey');
          debugPrint('cdauth====QR=======QR========>>>>>>>>>>>.$cdauth');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully Scanned QR Code')),
          );
         await loginController.GetapplicationDetails();

          debugPrint('loginController.landingPage.${loginController.landingPage}?t=0');
           String url = "https://cuickdev.com/API/DOCS/api/doc/${loginController.landingPage}";


          if (loginController.landingPage != 0) {
            setState(() {

            });

            debugPrint('url...............................${url}');
            Get.off(() =>  LandingPageView(url: url),);

          } else {
            // If landingPage doesn't have value, show dialog or fallback
            Get.off(() => const LoginScreen());
          }
         //  Get.off(() => const LoginScreen());

          controller.dispose();
        }
      } else {

        prefs.remove('cdauthkey');
        setState(() {
          result = null;
        });
        debugPrint('Clearing previous auth value.');
      }
    });
  }*/

  @override
  void dispose() {
    controller?.dispose();

    super.dispose();
  }
  disposeclear() async {
    result = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('cdauthkey');
    prefs.clear();
  }
  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    debugPrint('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    debugPrint('${ctrl.hasPermissions}');

    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Permission')),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;
    return WillPopScope(
        onWillPop: () async {

          disposeclear();
          return true;

        },
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  flex: 6,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    cameraFacing: CameraFacing.back,
                    overlay: QrScannerOverlayShape(
                        borderColor: Colors.indigo,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: scanArea),
                    onPermissionSet: (ctrl, p) =>
                        _onPermissionSet(context, ctrl, p),
                  )),
            ],
          ),
        ));
  }
}
