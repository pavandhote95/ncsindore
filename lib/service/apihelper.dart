  import 'dart:convert';
  import 'dart:io';
  import 'package:cherry_toast/cherry_toast.dart';
  import 'package:cuickdevuser/screen/onboding/onboding_screen.dart';
  import 'package:cuickdevuser/service/httpservice.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart%20';
  import 'package:get/get.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';
  

  class ApiBaseHelper {
    String aPPmAINuRL = "https://api.ncsindore.com/";
    // String aPPmAINuRL = "https://api.cuickdev.com/";
  // api_base_helper.dart में

static bool isFromSaveButton = false;

    Future<void> _authFailure() async {
      try { 
        // Clear session data
        await saveSkey("", "");


        // Welcome screen पर redirect करेंcls
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != '/welcome') {
            Get.offAllNamed('/onboarding');
          }
        });
      } catch (e) {
        print('Error in auth failure: $e');
        // Fallback to welcome screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/onboarding');
        });
      }
    }
    loginautomatically() async {
      HttpServices httpServices = new HttpServices();
      final prefs = await SharedPreferences.getInstance();
      String saved_email = prefs.getString("saved_email") ?? "";
      String saved_password = prefs.getString("saved_password") ?? "";
      print('loginautomatically============>>${saved_email}>>>${saved_password}');
      try {
        var res = await httpServices.userAuthentication(
          mailid: saved_email,
          password: saved_password,
        );

        if (res['success'] == true) {
          prefs.setBool("islogin", true);
          prefs.setString("jsessionid", res['result']['jsessionid'] ?? "");
          prefs.setString("name", res['result']['data']['name'] ?? "");
          prefs.setInt(
              "authkey",
              int.tryParse(res['result']['data']['authKey']?.toString() ?? "0") ??
                  0);
          prefs.setInt(
              "userid",
              int.tryParse(res['result']['data']['userId']?.toString() ?? "0") ??
                  0);
          prefs.setInt(
              "imageId",
              int.tryParse(res['result']['data']['imageId']?.toString() ?? "0") ??
                  0);
          prefs.setInt(
              "appId",
              int.tryParse(res['result']['data']['appId']?.toString() ?? "0") ??
                  0);
          prefs.setString("loginId", res['result']['data']['loginId'] ?? "");
          prefs.setInt(
              "defaultRoleId", res['result']['data']['defaultRoleId'] ?? 0);
        } else {
          CherryToast.error(
            backgroundColor: const Color(0xFFF8D0D9),
            animationDuration: Durations.short1,
            title:
                Text(res['message'], style: const TextStyle(color: Colors.red)),
          ).show(Get.overlayContext!);
        }
      } catch (e) {
        // Handle errors
      }
    }

  Future<void> saveSkey(String jsessionid, String skey) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('cdauthkey');
      await prefs.remove('jsessionid');
      await prefs.remove('islogin');
      await prefs.remove('authkey');
      await prefs.remove('userid');
      await prefs.remove('imageId');
      await prefs.remove('appId');
      await prefs.remove('loginId');
      await prefs.remove('defaultRoleId');
      await prefs.remove('applicationRoleId');
      await prefs.remove('userrolename');
      await prefs.remove('name');
    }
    Future<http.Response> StringpostApi(String url, String body) async {
      final response = await http.post(Uri.parse(aPPmAINuRL + url),
          body: body, headers: {'Content-Type': 'application/json'});
      return response;
    }

Future<dynamic> postApi(String url, Map<String, dynamic> reqBody) async {
    final pref = await SharedPreferences.getInstance();
    String? cdauth = pref.getString('cdauthkey')?.trim();

    if (cdauth == null || cdauth.isEmpty) {
      // अगर cdauthkey नहीं है तो onboarding पर भेजें
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != '/onboarding') {
          Get.offAllNamed('/onboarding');
        }
      });
      throw Exception('Invalid or missing cdauthkey');
    }

    try {
      final response = await http.post(
        Uri.parse(aPPmAINuRL + url),
        body: jsonEncode(reqBody),
        headers: {
          "cdauthkey": cdauth,
          HttpHeaders.contentTypeHeader: 'application/json;charset=UTF-8',
        },
      );

      return _returnResponse(response);
    } on SocketException catch (_) {
      print('No Internet connectionnsssss');

      // User को inform करें और home screen पर रहने दें
      if (!ApiBaseHelper.isFromSaveButton) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CherryToast.error(
            backgroundColor: const Color(0xFFF8D0D9),
            animationDuration: Durations.short1,
            title: const Text(
              "No internet connection",
              style: TextStyle(color: Colors.black),
            ),
          ).show(Get.overlayContext!);
        });
      }

      throw Exception('No Internet connectionss');
    } catch (e) {
      print('Error occurred during API call: $e');
      rethrow;
    }
  }

  Future<dynamic> get(String url, Map<String, String>? data) async {
    final pref = await SharedPreferences.getInstance();
    final String? cdauth = pref.getString('cdauthkey');

    if (cdauth == null || cdauth.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/onboarding');
      });
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(aPPmAINuRL + url).replace(queryParameters: data),
        headers: {
          "cdauthkey": cdauth,
          HttpHeaders.contentTypeHeader: 'application/json;charset=UTF-8',
        },
      );

      return _returnResponse(response);
    } on SocketException catch (_) {
      print('No Internet connection');

      // Only show snackbar, don't navigate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Get.snackbar(
        //   'Connection Lost',
        //   'Please check your internet connection',
        //   backgroundColor: Colors.orange,
        //   colorText: Colors.white,
        // );
      });

      return null; // Return null instead of throwing exception
    } catch (e) {
      print('Error in GET request: $e');
      return null;
    }
  }

  dynamic _returnResponse(http.Response response) async {
    switch (response.statusCode) {
      case 200:
        try {
          var responseJson = jsonDecode(response.body);
          return responseJson;
        } catch (e) {
          print('JSON decode error: $e');
          return null;
        }
      case 401:
        await _authFailure();
        return null;
      case 403:
        print('Access forbidden');
        return null;
      default:
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
    }
  }
   
   
   
    Future<dynamic> exportpostApi(
        String url, Map<String, dynamic> reqBody) async {
      final pref = await SharedPreferences.getInstance();
      String? cdauth = pref.getString('cdauthkey');

      final response = await http
          .post(Uri.parse(aPPmAINuRL + url), body: jsonEncode(reqBody), headers: {
        "cdauthkey": cdauth!,
        HttpHeaders.contentTypeHeader: 'application/json',
      });

      try {
        return response.body;
      } catch (e) {
        e.toString();
      }
    }
    Future<Uint8List?> pdfexportpostApi(
        String url, Map<String, dynamic> body) async {
      try {
        final response = await http.post(
          Uri.parse("https://api.ncsindore.com/$url"),
          headers: {
            'Accept': 'application/pdf',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          debugPrint("API ERROR [${response.statusCode}]: ${response.body}");
          return null;
        }
      } catch (e) {
        debugPrint("Exception in exportpostApi: $e");
        return null;
      }
    }

   
   
   
    Future<dynamic> put(String url, Map<String, String> data) async {
      var responseJson;
      if (kDebugMode) {
        print(data);
      }
      try {
        final response = await http.put(
          Uri.parse(aPPmAINuRL + url).replace(queryParameters: data),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
          },
        );

        return responseJson = _returnResponse(response);
      } on SocketException {
        throw Exception('Check Your Network Connection');
      }
    }


    Future<dynamic> getGoogleMap(String url) async {
      var responseJson;
      final response = await http.get(Uri.parse(url));

      responseJson = _returnResponse(response);
      return responseJson;
    }
  }
