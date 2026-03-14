import 'dart:convert';
import 'dart:core';
import 'package:cuickdevuser/model/application_model.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/Menucontroller.dart';

import 'apihelper.dart';

class HttpServices {  
  final ApiBaseHelper helper = ApiBaseHelper();
  Future<Map<String, dynamic>?> signUpUser(Map<String, dynamic> payload) async {
    try {
      final response =
          await helper.postApi('ctl/auth/signupUserApp;jsessionid=0', payload);

      if (response != null && response is Map<String, dynamic>) {
        if (response.containsKey("success") && response['success'] == true) {
          return response;
        } else if (response.containsKey("message")) {
          debugPrint('API Error: ${response["message"]}');
          return response;
        } else {
          debugPrint('Unexpected response format: ${response.toString()}');
          return null;
        }
      } else {
        debugPrint('Received null or invalid response from the API');
        return null;
      }
    } catch (e) {
      debugPrint('Error occurred during sign-up API: ${e.toString()}');
      return null;
    }
  }

userAuthentication({
    required String mailid,
    required String password,
  }) async {
    Map<String, dynamic> reqBody = {
      'loginId': mailid,
      "password": password,
    };

    try {
      final response =
          await helper.postApi('ctl/auth/signin;jsessionid=0', reqBody);

      if (response != null && response is Map<String, dynamic>) {
        debugPrint("LOGIN FULL RESPONSE => $response");

        if (response['success'] == true) {
          final data = response['data'];

          if (data != null && data is Map<String, dynamic>) {
            final accessToken = data['token'] ?? data['accessToken'];
            final refreshToken = data['refreshToken'];

            debugPrint("ACCESS TOKEN => $accessToken");
            debugPrint("REFRESH TOKEN => $refreshToken");
            debugPrint("JSESSIONID => ${data['jsessionid']}");
          }

          return response;
        } else {
          debugPrint("LOGIN FAILED => ${response['message']}");
          return response;
        }
      } else {
        debugPrint("Invalid login response");
        return null;
      }
    } catch (e) {
      debugPrint('Login Error: ${e.toString()}');
      return null;
    }
  }

  Future<dynamic> fetchApplicationRole(String appId, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString("jsessionid") ?? "0";

    Map<String, dynamic> reqBody = {
      "applicationId": int.parse(appId),
      "email": email,
      "status": "Accept",
    };

    try {
      final response = await helper.postApi(
          'ctl/application-users/search;jsessionid=$jsessionid', reqBody);

      return response;
    } catch (e) {
      debugPrint("API Call Failed in httpServices: $e");
      return null;
    }
  }

  Forgotpassword({
    required String loginid,
  }) async {
    Map<String, dynamic> reqBody = {
      "loginId": loginid,
    };
    try {
      final response =
          await helper.postApi("/ctl/auth/fp;jsessionid=0", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    }
  }

  Changepassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString("jsessionid") ?? "0";
    int userid = prefs.getInt("authkey") ?? 0;

    String loginId = prefs.getString("loginId") ??
        prefs.getInt("loginId")?.toString() ??
        "0";

    Map<String, dynamic> reqBody = {
      "oldPassword": oldPassword,
      "newPassword": newPassword,
      "confirmPassword": confirmPassword,
      "loginId": loginId
    };

    try {
      final response = await helper.postApi(
          "/ctl/auth/cp/$userid;jsessionid=$jsessionid", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetMenuList(
      {required int defaultRoleId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
          "ctl/menus/getMenus/$defaultRoleId;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserAccess(
      {required String formId, required String applicationRoleId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    int applicationId = prefs.getInt('appId') ?? 0;

    Map<String, dynamic> reqBody = {
      "applicationId": applicationId,
      "formId": int.parse(formId),
      "applicationRoleId": int.parse(applicationRoleId),
    };
    try {
      final response = await helper.postApi(
          "ctl/application-role-usecase/search;jsessionid=$sessionId", reqBody);
      return response;
    } catch (e) {
      debugPrint("Error in getUserAccess: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetUserprofile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response =
          await helper.get("ctl/User/profile;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> upadateUserprofile({
    required int id,
    required String firstname,
    required String lastname,
    required String loginid,
    required int orgid,
    required int roleId,
    required int imageId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {
      "id": id,
      "firstName": firstname,
      "lastName": lastname,
      "loginId": loginid,
      "orgName": orgid,
      "roleId": roleId,
      "imageId": imageId
    };
    print('UpadateUserprofile===reqBody=====>${reqBody}');
    try {
      final response =
          await helper.postApi("/ctl/User/save;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<ApplicationModel?> Getapplications({required dynamic roleId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> reqBody = {};

    final response = await helper.get(
        "ctl/application-role/get/$roleId;jsessionid=${prefs.get('jsessionid')}",
        reqBody);
    try {
      return ApplicationModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<FormResponse?> GetForm({required String formId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> reqBody = {};
    final response = await helper.get(
        "ctl/uiform/get/$formId;jsessionid=${prefs.get('jsessionid')}",
        reqBody);

    try {
      return FormResponse.fromJson(response);
    } catch (e) {
      debugPrint("Error in GetForm_data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getList({
    required String url,
    required String field,
    required int currentPage,
    required int pageSize,
    int? isuserFilter,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    String loginId = '';

    if (isuserFilter == 1) {
      loginId = prefs.getString('loginId') ?? '';
    }

    Map<String, dynamic> reqBody = {
      "pageSize": pageSize.toString(),
    };
    if (isuserFilter == 1 && loginId.isNotEmpty) {
      reqBody["createdBy"] = loginId;
    }
    try {
      final response = await helper.postApi(
          "api/v1/$url/$field/search/$currentPage;jsessionid=$sessionId",
          reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetListusecase({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
          "ctl/usecase/get/$id;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetList({
    required String url,
    required String field,
    required int currentPage,
    int? isuserFilter,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    String loginId = '';

    if (isuserFilter == 1) {
      loginId = prefs.getString('loginId') ?? '';
    }

    Map<String, dynamic> reqBody = {
      "pageSize": "10",
      "createdBy": loginId,
    };

    try {
      final response = await helper.postApi(
          "api/v1/$url/$field/search/0;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> DeleteListItem(
      {required String appurl,
      required String field,
      required String id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
          "api/v1/$appurl/$field/delete/$id;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

Future<Map<String, dynamic>?> Getlistattribute(
      {required String formId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};

    try {
      final response = await helper.get(
        "ctl/userstoryattributes/list/$formId;jsessionid=$sessionId",
        reqBody,
      );

      // ✅ Terminal / Debug Console me response print
      debugPrint("Getlistattribute RESPONSE: $response");

      return response;
    } catch (e) {
      // ❌ Error bhi print kar do
      debugPrint("Getlistattribute ERROR: $e");
      return null;
    }
  }


  Future<Map<String, dynamic>?> Getpreloaddata(
      {required String appurl, required String formname}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "api/v1/$appurl/$formname/preload;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getParentFilterData({
    required String appCode,
    required String hrStatus,
    required String val,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> filterParams = {"val": val.toString()};

    try {
      final response = await helper.postApi(
          "api/v1/$appCode/$hrStatus/preloadData;jsessionid=$sessionId",
          filterParams);

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetFormdata(
      {required String formname,
      required String appurl,
      required String formId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "api/v1/$formname/$appurl/get/$formId;jsessionid=$sessionId",
          reqBody);
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> Getchartdata({
    required String type,
    required String appname,
    required String menu,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {};

    try {
      final response = await helper.postApi(
          "ctl/chart/$type/$appname.$menu;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> Getdashboardchartdata(
      {required String type,
      required String appname,
      required String menu,
      required String field}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    String loginId = '';

    loginId = prefs.getString('loginId') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.postApi(
          "ctl/chart/$type/$appname.$field;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetapplicationDetails(
      {required String appid}) async {
    debugPrint('Calling GetapplicationDetails with appid: $appid');
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "ctl/application/public/applicationDetails/$appid;jsessionid=0",
          reqBody);
      return response;
    } catch (e) {
      debugPrint("Error in GetapplicationDetails: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetORGDetails({required int orgid}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "ctl/organization/public/orgDetails/$orgid;jsessionid=0", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> Sharepdftomail(
      {required String appurl,
      required String field,
      required String formId,
      required int fieldid,
      required String name,
      required String email}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {
      "name": name,
      "email": email,
    };
    try {
      final response = await helper.postApi(
          "api/v1/$appurl/$field/sendForm/$fieldid/$formId;jsessionid=$sessionId",
          reqBody);
      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> Dashboarduiform(
      {required int applicationId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {
      "showDashboard": 1,
      "applicationId": applicationId
    };
    try {
      final response = await helper.postApi(
          "ctl/uiform/search/0;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> Get_tasklist(String? title) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    Map<String, dynamic> reqBody = {
      "orderBy": "priority",
      "asc": "DESC",
      "pageSize": 50,
    };

    if (title != null && title.isNotEmpty) {
      reqBody["title"] = title;
    }

    try {
      final response = await helper.postApi(
          "ctl/task/search/0;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> Save_task({
    required int id,
    required String title,
    required String desc,
    required String targetDate,
    required String targetTime,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {
      "id": id,
      "title": title,
      "description": desc,
    };

    if (targetDate.isNotEmpty) {
      reqBody["targetDate"] = targetDate;
    }

    if (targetTime.toString().isNotEmpty) {
      reqBody["targetTime"] = targetTime;
    }

    try {
      final response =
          await helper.postApi("ctl/task/save;jsessionid=$sessionId", reqBody);
      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");

      return null;
    }
  }

  changestatus({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "ctl/task/status/$id/Completed;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  changestartedstatus({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "ctl/task/status/$id/Not%20started;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  changeHigh({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "/ctl/task/priority/$id/High;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  deletetask({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "ctl/task/delete/$id;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  gettaskinfo({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response =
          await helper.get("ctl/task/get/$id;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  changeNA({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "/ctl/task/priority/$id/NA;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> Getexecutedata({
    required String rule,
    required Map<String, dynamic> reqBody,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await helper.postApi(
      "ctl/rules/execute/$rule;jsessionid=${prefs.get('jsessionid')}",
      reqBody,
    );

    try {
      return response;
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> Getuserdata(
      {required String rule,
      required String admissionId,
      required String collectionName}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> reqBody = {
      "admissionId": admissionId,
      "collectionName": collectionName,
    };

    final response = await helper.postApi(
        "ctl/rules/execute/$rule;jsessionid=${prefs.get('jsessionid')}",
        reqBody);

    try {
      return response;
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    }
  }

  savesupportEmail({
    required String id,
    required String title,
    required String category,
    required String desc,
    required String status,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {
      "id": id,
      "title": title,
      "category": category,
      "description": desc,
      "status": status
    };
    try {
      final response = await helper.postApi(
          "ctl/supportticket/supportEmail;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Getreportdata({
    required String id,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, String> reqBody = {};
    try {
      final response = await helper.get(
          "ctl/reports/get/$id;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetComments(
      {required String formId,
      required String recordId,
      required String userstoryId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';
    int? applicationId = prefs.getInt("appId");

    Map<String, dynamic> reqBody = {
      "applicationId": applicationId ?? 0,
      "formId": int.tryParse(formId) ?? 0,
      "recordId": int.tryParse(recordId) ?? 0,
      "userstoryId": int.tryParse(userstoryId) ?? 0,
      "orderBy": "modifiedDatetime",
      "asc": "DESC"
    };

    try {
      final response = await helper.postApi(
          "api/v1/cuickdev/page-comment/search;jsessionid=$jsessionid",
          reqBody);

      if (response != null && response.containsKey("success")) {}

      return response;
    } catch (e) {
      debugPrint("Error in GetComments: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> GetAttachment(
      {required String formId,
      required String recordId,
      required String userstoryId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';
    int? applicationId = prefs.getInt("appId");

    Map<String, dynamic> reqBody = {
      "applicationId": applicationId ?? 0,
      "formId": int.tryParse(formId) ?? 0,
      "recordId": int.tryParse(recordId) ?? 0,
      "userstoryId": int.tryParse(userstoryId) ?? 0,
      "orderBy": "modifiedDatetime",
      "asc": "DESC"
    };

    try {
      final response = await helper.postApi(
          "api/v1/cuickdev/page-attachment/search;jsessionid=$jsessionid",
          reqBody);

      if (response != null && response.containsKey("success")) {}

      return response;
    } catch (e) {
      debugPrint("Error in GetAttachment: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> SaveComments(
      {required String appcode,
      required String code,
      required String comment,
      required String formId,
      required String recordId,
      required String userstoryId,
      required int usecaseId,
      required int id}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsessionid = prefs.getString('jsessionid') ?? '';
    int? applicationId = prefs.getInt("appId");

    Map<String, dynamic> reqBody = {
      "applicationId": applicationId ?? 0,
      "comment": comment,
      "formId": int.tryParse(formId) ?? 0,
      "id": id,
      "recordId": int.tryParse(recordId) ?? 0,
      "usecaseId": usecaseId,
      "userstoryId": int.tryParse(userstoryId) ?? 0,
    };

    try {
      final response = await helper.postApi(
          "api/v1/$appcode/$code/addComment;jsessionid=$jsessionid", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in saveComments: $e");
      return null;
    }
  }

  tagitemsave({
    required String label,
    required String type,
    required String userstoryId,
    required String id,
    required String values,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
      return null;
    }

    Map<String, dynamic> reqBody = {
      "label": label,
      "type": type,
      "userstoryId": userstoryId.toString(),
      "id": id.toString(),
      "values": values,
    };

    try {
      final response = await helper.postApi(
          "ctl/userstoryattributes/save;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("Error in GetList: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> FetchruleAPI(
      {required String formname,
      required String appurl,
      required String formId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';
    Map<String, dynamic> reqBody = {"formId": formId};
    try {
      final response = await helper.postApi(
          "api/v1/$formname/$appurl/fetchRule;jsessionid=$sessionId", reqBody);

      return response;
    } catch (e) {
      debugPrint("FetchruleAPI Error: $e");
      return null;
    }
  }
}
