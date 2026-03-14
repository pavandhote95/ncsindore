
class LoginModel {
  final bool success;
  final Result result;

  LoginModel({
    required this.success,
    required this.result,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      success: json['success'],
      result: Result.fromJson(json['result']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'result': result.toJson(),
    };
  }
}

class Result {
  final String jsessionid;
  final String appURL;
  final int authKey;
  final Data data;

  Result({
    required this.jsessionid,
    required this.appURL,
    required this.authKey,
    required this.data,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      jsessionid: json['jsessionid'],
      appURL: json['AppURL'],
      authKey: json['AuthKey']??0,
      data: Data.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jsessionid': jsessionid,
      'AppURL': appURL,
      'AuthKey': authKey,
      'data': data.toJson(),
    };
  }
}

class Data {
  final int skey;
  final int authKey;
  final int userId;
  final String loginId;
  final String name;
  final String firstName;
  final String lastName;
  final int imageId;
  final dynamic mobileId;
  final int defaultRoleId;
  final String roleName;
  final int orgId;
  final String orgName;
  final int orgImageId;
  final int orgLogoId;
  final int appId;
  final String appName;
  final List<Org> orgList;
  final List<App> appList;
  Data({
    required this.skey,
    required this.authKey,
    required this.userId,
    required this.loginId,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.imageId,
    this.mobileId,
    required this.defaultRoleId,
    required this.roleName,
    required this.orgId,
    required this.orgName,
    required this.orgImageId,
    required this.orgLogoId,
    required this.appId,
    required this.appName,
    required this.orgList,
    required this.appList
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    var list = json['orgList'] as List;
    var applist = json['appList'] as List;
    List<Org> orgList = list.map((i) => Org.fromJson(i)).toList();
    List<App> AppList = applist.map((i) => App.fromJson(i)).toList();
    return Data(
      skey: json['skey']??0,
      authKey: json['authKey']??0,
      userId: json['userId']??0,
      loginId: json['loginId'],
      name: json['name'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      imageId: json['imageId']??0,
      mobileId: json['mobileId'],
      defaultRoleId: json['defaultRoleId']??0,
      roleName: json['roleName'],
      orgId: json['orgId']??0,
      orgName: json['orgName'],
      orgImageId: json['orgImageId']??0,
      orgLogoId: json['orgLogoId']??0,
      appId: json['appId'],
      appName: json['appName'],
      orgList: orgList,
      appList: AppList,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> orgList = this.orgList.map((i) => i.toJson()).toList();
    List<Map<String, dynamic>> applist = this.appList.map((i) => i.toJson()).toList();
    return {
      'skey': skey,
      'authKey': authKey,
      'userId': userId,
      'loginId': loginId,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'imageId': imageId,
      'mobileId': mobileId,
      'defaultRoleId': defaultRoleId,
      'roleName': roleName,
      'orgId': orgId,
      'orgName': orgName,
      'orgImageId': orgImageId,
      'orgLogoId': orgLogoId,
      'appId': appId,
      'appName': appName,
      'orgList': orgList,
      'appList': applist,
    };
  }
}

class Org {
  final String key;
  final String value;
  final int id;

  Org({
    required this.key,
    required this.value,
    required this.id,
  });

  factory Org.fromJson(Map<String, dynamic> json) {
    return Org(
      key: json['key'],
      value: json['value'],
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'id': id,
    };
  }
}
// Define the App class
class App {
  final int? id;
  final String createdBy;
  final String modifiedBy;
  final DateTime? createdDatetime;
  final DateTime? modifiedDatetime;
  final int? orgId;
  final String? orgName;
  final String? skey;
  final int appId;
  final int archived;
  final int version;
  final bool groupFilter;
  final bool archiveEnabled;
  final int? usecaseId;
  final String? usecaseName;
  final String? searchOrderBy;
  final bool? searchAsc;
  final bool changeLog;
  final bool versionHistory;
  final String name;
  final String? applicationCode;
  final String? address;
  final String? phone;
  final String? email;
  final String status;
  final int logoId;
  final String appUrl;
  final String value;
  final String key;
  final Map<String, dynamic> csvinfo;

  App({
    this.id,
    required this.createdBy,
    required this.modifiedBy,
    this.createdDatetime,
    this.modifiedDatetime,
    this.orgId,
    this.orgName,
    this.skey,
    required this.appId,
    required this.archived,
    required this.version,
    required this.groupFilter,
    required this.archiveEnabled,
    this.usecaseId,
    this.usecaseName,
    this.searchOrderBy,
    this.searchAsc,
    required this.changeLog,
    required this.versionHistory,
    required this.name,
    this.applicationCode,
    this.address,
    this.phone,
    this.email,
    required this.status,
    required this.logoId,
    required this.appUrl,
    required this.value,
    required this.key,
    required this.csvinfo,
  });

  factory App.fromJson(Map<String, dynamic> json) {
    return App(
      id: json['id'] ??0,
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
      createdDatetime: json['createdDatetime'] != null
          ? DateTime.parse(json['createdDatetime'])
          : null,
      modifiedDatetime: json['modifiedDatetime'] != null
          ? DateTime.parse(json['modifiedDatetime'])
          : null,
      orgId: json['orgId']??0,
      orgName: json['orgName'],
      skey: json['skey'],
      appId: json['appId']??0,
      archived: json['archived']??0,
      version: json['version']??0,
      groupFilter: json['groupFilter'],
      archiveEnabled: json['archiveEnabled'],
      usecaseId: json['usecaseId']??0,
      usecaseName: json['usecaseName'],
      searchOrderBy: json['searchOrderBy'],
      searchAsc: json['searchAsc'],
      changeLog: json['changeLog'],
      versionHistory: json['versionHistory'],
      name: json['name'],
      applicationCode: json['applicationCode'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      status: json['status'],
      logoId: json['logoId']??0,
      appUrl: json['appUrl'],
      value: json['value'],
      key: json['key'],
      csvinfo: json['csvinfo'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
      'createdDatetime': createdDatetime?.toIso8601String(),
      'modifiedDatetime': modifiedDatetime?.toIso8601String(),
      'orgId': orgId,
      'orgName': orgName,
      'skey': skey,
      'appId': appId,
      'archived': archived,
      'version': version,
      'groupFilter': groupFilter,
      'archiveEnabled': archiveEnabled,
      'usecaseId': usecaseId,
      'usecaseName': usecaseName,
      'searchOrderBy': searchOrderBy,
      'searchAsc': searchAsc,
      'changeLog': changeLog,
      'versionHistory': versionHistory,
      'name': name,
      'applicationCode': applicationCode,
      'address': address,
      'phone': phone,
      'email': email,
      'status': status,
      'logoId': logoId,
      'appUrl': appUrl,
      'value': value,
      'key': key,
      'csvinfo': csvinfo,
    };
  }
}