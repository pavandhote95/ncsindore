class ApplicationModel {
  final bool success;
  final Result result;
  final String? message;

  ApplicationModel({
    required this.success,
    required this.result,
    this.message,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      success: json['success'] ?? false,
      result: Result.fromJson(json['result'] ?? {}),
      message: json['message']?.toString(),
    );
  }
}

class Result {
  final Data data;

  Result({required this.data});

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      data: Data.fromJson(json['data'] ?? {}),
    );
  }
}

class Data {
  final int appId;
  final int applicationId;
  final String applicationName;
  final String rolename;
  final String code;
  final String orgName;
  final String usecaseName;
  final int modifiedDatetime;
  final int version;
  final int usecaseId;
  final String orgId;
  final String createdBy;
  final int createdDatetime;
  final int id;
  final String name;
  final String modifiedBy;
  final List<Menu> menus;
  final List<Report> reports;

  Data({
    required this.name,
    required this.appId,
    required this.applicationId,
    required this.applicationName,
    required this.rolename,
    required this.code,
    required this.orgName,
    required this.usecaseName,
    required this.modifiedDatetime,
    required this.version,
    required this.usecaseId,
    required this.orgId,
    required this.createdBy,
    required this.createdDatetime,
    required this.id,
    required this.modifiedBy,
    required this.menus,
    required this.reports,

  });

  factory Data.fromJson(Map<String, dynamic> json) {
    var menusFromJson = json['menus'] as List? ?? [];
    var reportsFromJson = json['reports'] as List? ?? [];

    return Data(
      name: json['name']?.toString() ?? '',
      appId: json['appId']?.toInt() ?? 0,
      applicationId: json['applicationId']?.toInt() ?? 0,
      applicationName: json['applicationName']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      rolename: json['name']?.toString() ?? '',
      orgName: json['orgName']?.toString() ?? '',
      usecaseName: json['usecaseName']?.toString() ?? '',
      modifiedDatetime: json['modifiedDatetime']?.toInt() ?? 0,
      version: json['version']?.toInt() ?? 0,
      usecaseId: json['usecaseId']?.toInt() ?? 0,
      orgId: json['orgId']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      createdDatetime: json['createdDatetime']?.toInt() ?? 0,
      id: json['id']?.toInt() ?? 0,
      modifiedBy: json['modifiedBy']?.toString() ?? '',

      menus: menusFromJson.map((menu) => Menu.fromJson(menu)).toList(),
      reports: reportsFromJson.map((report) => Report.fromJson(report)).toList(),
    );
  }
}

class Menu {
  final int index;
  final String code;
  final String name;
  final int id;
  final String createdBy;
  final int createdDatetime;
  final String modifiedBy;
  final int modifiedDatetime;
  final String linkto;
  final bool isExpanded;
  final dynamic formId;
  final int? userstoryId;
  final int? applicationId;
  final int? reportsId;
  final String? reportsTitle;
  final String? applicationName;
  final String? formTitle;
  final String? url;
  final List<Menu> children;

  Menu({
    required this.index,
    required this.code,
    required this.name,
    required this.id,
    required this.createdBy,
    required this.createdDatetime,
    required this.modifiedBy,
    required this.modifiedDatetime,
    required this.linkto,
    required this.isExpanded,
    this.formId,
    this.userstoryId,
    this.applicationId,
    this.reportsId,
    this.reportsTitle,
    this.applicationName,
    this.formTitle,
    this.url,
    required this.children,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    var childrenFromJson = json['children'] as List? ?? [];
    return Menu(
      index: json['index']?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      id: json['id']?.toInt() ?? 0,
      createdBy: json['createdBy']?.toString() ?? '',
      createdDatetime: json['createdDatetime']?.toInt() ?? 0,
      modifiedBy: json['modifiedBy']?.toString() ?? '',
      modifiedDatetime: json['modifiedDatetime']?.toInt() ?? 0,
      linkto: json['linkto']?.toString() ?? '',
      isExpanded: json['isExpanded'] ?? false,
      formId: json['formId'],
      userstoryId: json['userstoryId']?.toInt(),
      applicationId: json['applicationId']?.toInt(),
      reportsId: json['reportsId']?.toInt(),
      reportsTitle: json['reportsTitle']?.toString(),
      applicationName: json['applicationName']?.toString(),
      formTitle: json['formTitle']?.toString(),
      url: json['url']?.toString(),
      children: childrenFromJson.isNotEmpty
          ? childrenFromJson.map((child) => Menu.fromJson(child)).toList()
          : [],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      "index": index,
      "code": code,
      "name": name,
      "id": id,
      "createdBy": createdBy,
      "createdDatetime": createdDatetime,
      "modifiedBy": modifiedBy,
      "modifiedDatetime": modifiedDatetime,
      "linkto": linkto,
      "isExpanded": isExpanded,
      "formId": formId,
      "userstoryId": userstoryId,
      "applicationId": applicationId,
      "reportsId": reportsId,
      "reportsTitle": reportsTitle,
      "applicationName": applicationName,
      "formTitle": formTitle,
      "url": url,
      "children": children.map((child) => child.toMap()).toList() ?? []
    };
  }
}

class Report {
  final int index;
  final String name;
  final String reportTitle;
  final String reportId;
  final dynamic formId;
  final bool enable;
  final bool newTab;

  Report({
    required this.index,
    required this.name,
    required this.reportTitle,
    required this.reportId,
    required this.formId,
    required this.enable,
    required this.newTab,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      index: json['index']?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      reportTitle: json['reporttitle']?.toString() ?? '',
      reportId: json['reportId']?.toString() ?? '',
      formId: json['formId'],
      enable: json['enable'] ?? false,
      newTab: json['new_tab'] ?? false,
    );
  }
}
