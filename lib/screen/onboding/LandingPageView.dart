import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../controller/login_controller.dart';
import '../login_screen.dart';

class LandingPageView extends StatefulWidget {
  final String url;
  const LandingPageView({Key? key, required this.url}) : super(key: key);
  @override
  State<LandingPageView> createState() => _LandingPageViewState();
}

class _LandingPageViewState extends State<LandingPageView> {
  WebViewController? _controller;
  final LoginController loginController =
  Get.put(LoginController(), permanent: true);

  String url = "";
  bool isLoading = true; // loader only for first load
  bool isInitialized = false;

  static const String landingPageUrlKey = 'landingPageUrl';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    if (isInitialized) return;
    isInitialized = true;

    final prefs = await SharedPreferences.getInstance();

    // Get a unique identifier for the current app
    final String appId = loginController.appId?.toString() ?? 'default';
    final String cacheKey = 'landingPageUrl_$appId';

    // Try to read cached URL for this app
    String? cachedUrl = prefs.getString(cacheKey);

    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      url = cachedUrl;
      _setupController();
    } else {
      await loginController.GetapplicationDetails();

      if (loginController.landingPage != 0) {
        url = "https://cuickdev.com/API/DOCS/api/doc/${loginController.landingPage}";
        await prefs.setString(cacheKey, url);
        _setupController();
      } else {
        Get.off(() => const LoginScreen());
      }
    }

  }


  void _setupController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {

          },
          onPageFinished: (String url) {

            if (isLoading) {
              setState(() => isLoading = false);
            }
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
            if (isLoading) {
              setState(() => isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.contains('/login/')) {
              String code = request.url.split('/login/').last;
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('cdauthkey');
              await prefs.setString('cdauthkey', code);
              Get.off(() => const LoginScreen());
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() {}); // rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
