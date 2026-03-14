
class FormResponse {
  final bool success;
  final Data data;

  FormResponse({
    required this.success,
    required this.data,
  });

  factory FormResponse.fromJson(Map<String, dynamic> json) {
    var resultData = json['result'] != null ? json['result']['data'] : null;

    return FormResponse(
      success: json['success'] as bool? ?? false, // Default to false if null
      data: resultData != null ? Data.fromJson(resultData) : Data.fromJson({}),
    );
  }
}

class Data {
  var code;
  var orgName;
  final List<Button> buttons;
  final List<GroupLabels> groupLabels;
  final List<ChildForm> childFormList;
  var columns;
  var usecaseName;
  var description;
  var modifiedDatetime;
  var title;
  var version;
  var usecaseId;
  var orgId;
  var createdBy;
  var subtitle;
  var appId;
  var modifiedBy;
  var createdDatetime;
  var id;
  var userstoryName;
  var userstoryId;
  var applicationId;
  List<Field> fields;
  var applicationName;

  Data({
    required this.code,
    required this.orgName,
    required this.buttons,
    required this.columns,
    required this.usecaseName,
    required this.description,
    required this.modifiedDatetime,
    required this.title,
    required this.version,
    required this.usecaseId,
    required this.orgId,
    required this.createdBy,
    required this.subtitle,
    required this.appId,
    required this.modifiedBy,
    required this.createdDatetime,
    required this.id,
    required this.userstoryName,
    required this.userstoryId,
    required this.applicationId,
    required this.fields,
    required this.applicationName,
    required this.groupLabels,
    required this.childFormList,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      code: json['code']?.toString(),
      orgName: json['orgName']?.toString(),
      buttons: (json['buttons'] as List?)
          ?.map((buttonData) => Button.fromJson(buttonData))
          .toList() ??
          [],
      columns: json['columns'],
      usecaseName: json['usecaseName']?.toString(),
      description: json['description']?.toString(),
      modifiedDatetime: json['modifiedDatetime']?.toString(),
      title: json['title']?.toString(),
      version: json['version']?.toString(),
      usecaseId: json['usecaseId']?.toString(),
      orgId: json['orgId']?.toString(),
      createdBy: json['createdBy']?.toString(),
      subtitle: json['subtitle']?.toString(),
      appId: json['appId']?.toString(),
      modifiedBy: json['modifiedBy']?.toString(),
      createdDatetime: json['createdDatetime']?.toString(),
      id: json['id']?.toString(),
      userstoryName: json['userstoryName']?.toString(),
      userstoryId: json['userstoryId']?.toString(),
      applicationId: json['applicationId']?.toString(),
      fields: (json['fields'] as List?)
          ?.map((fieldData) => Field.fromJson(fieldData))
          .toList() ??
          [],
      groupLabels: (json['groupLabels'] as List?)
          ?.map((groupData) => GroupLabels.fromJson(groupData))
          .toList() ??
          [],
      childFormList: json['childFormList'] != null
          ? List<ChildForm>.from(
          (json['childFormList'] as List).where((e) => e != null).map((e) => ChildForm.fromJson(e)))
          : [],
      applicationName: json['applicationName']?.toString(),
    );
  }
}
class ChildForm {
  var code;
  final List<Button> buttons;
  var columns;
  var usecaseName;
  var description;
  var modifiedDatetime;
  var readOnly;
  var title;
  var version;
  var usecaseId;
  var orgId;
  var createdBy;
  var appId;
  var modifiedBy;
  var createdDatetime;
  var userstoryName;
  var id;
  var userstoryId;
  var applicationId;
  final List<Field> fields;
  var applicationName;

  ChildForm({
    required this.code,
    required this.buttons,
    required this.columns,
    required this.usecaseName,
    required this.description,
    required this.modifiedDatetime,
    required this.readOnly,
    required this.title,
    required this.version,
    required this.usecaseId,
    required this.orgId,
    required this.createdBy,
    required this.appId,
    required this.modifiedBy,
    required this.createdDatetime,
    required this.userstoryName,
    required this.id,
    required this.userstoryId,
    required this.applicationId,
    required this.fields,
    required this.applicationName,
  });

  factory ChildForm.fromJson(Map<String, dynamic> json) {
    return ChildForm(
      code: json['code'],
      buttons: List<Button>.from(json['buttons'].map((x) => Button.fromJson(x))),
      columns: json['columns'],
      usecaseName: json['usecaseName'],
      description: json['description'],
      modifiedDatetime: json['modifiedDatetime'],
      readOnly: json['readOnly'],
      title: json['title'],
      version: json['version'],
      usecaseId: json['usecaseId'],
      orgId: json['orgId'],
      createdBy: json['createdBy'],
      appId: json['appId'],
      modifiedBy: json['modifiedBy'],
      createdDatetime: json['createdDatetime'],
      userstoryName: json['userstoryName'],
      id: json['id'],
      userstoryId: json['userstoryId'],
      applicationId: json['applicationId'],
      fields: List<Field>.from(json['fields'].map((x) => Field.fromJson(x))),
      applicationName: json['applicationName'],
    );
  }
}


class GroupLabels {
  var label;
  var index;
  var allowedTimeEnd;
  var allowedTimeStart;
  var allowedTimeEndMeridian;
  var allowedTimeStartMeridian;


  GroupLabels({required this.label, required this.index, required this.allowedTimeEnd, required this.allowedTimeStart, required this.allowedTimeEndMeridian, required this.allowedTimeStartMeridian,
  });  // ✅ Include fields in constructor

  factory GroupLabels.fromJson(Map<String, dynamic> json) {
    return GroupLabels(
      label: json['label']?.toString(),
      index: json['index']?.toString(),
      allowedTimeEnd: json['allowedTimeEnd']?.toString(),
      allowedTimeStart: json['allowedTimeStart']?.toString(),
      allowedTimeStartMeridian: json['allowedTimeStartMeridian']?.toString(),
      allowedTimeEndMeridian: json['allowedTimeEndMeridian']?.toString(),

    );
  }
}


class Field {
  var label;
  var id;
  var index;
  var code;
  var refKey;
  var type;
  var group;
  var show;
  var event;
  var rule;
  var parentFilter;

  Field({
    required this.label,
    required this.id,
    required this.index,
    this.code,
    this.refKey,
    this.type,
    this.group,
    this.show,
    this.event,
    this.rule,
    this.parentFilter,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      label: json['label']?.toString(),
      id: json['id']?.toString(),
      index: json['index']?.toString(),
      code: json['code']?.toString(),
      refKey: json['refKey']?.toString(),
      type: json['type']?.toString(),
      group: json['group']?.toString(),
      show: json['show']?.toString(),
      event: json['event']?.toString(),
      rule: json['rule']?.toString(),
      parentFilter: json['parentFilter']?.toString(),
    );
  }
}

class Button {
  final String name;
  final String url;

  Button({required this.name, required this.url});

  factory Button.fromJson(Map<String, dynamic> json) {
    return Button(
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}
