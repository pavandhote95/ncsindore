class UserProfile {
  String firstName;
  String lastName;
  String loginId;
  String orgName;
  String roleName;
  String usecaseName;
  String loginCode;
  String mobileId;

  final int imageId;
  final int roleId;
  final int orgId;
  final int appId;
  final int id;

  UserProfile(
      {required this.firstName,
      required this.lastName,
      required this.loginId,
      required this.orgName,
      required this.roleName,
      required this.imageId,
      required this.roleId,
      required this.usecaseName,
      required this.orgId,
      required this.appId,
      required this.id,
      required this.loginCode,
      required this.mobileId});

  // Factory method to create a UserProfile instance from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] is String ? json['firstName'] : '',
      lastName: json['lastName'] is String ? json['lastName'] : '',
      loginId: json['loginId'] is String ? json['loginId'] : '',
      orgName: json['orgName'] is String ? json['orgName'] : '',
      roleName: json['roleName'] is String ? json['roleName'] : '',
      usecaseName: json['usecaseName'] is String ? json['usecaseName'] : '',
      loginCode: json['loginCode'] is String ? json['loginCode'] : '',
      mobileId: json['mobileId'] is String ? json['mobileId'] : '',
      imageId: json['imageId'] is int ? json['imageId'] : 0,
      roleId: json['roleId'] is int ? json['roleId'] : 0,
      orgId: json['orgId'] is int ? json['orgId'] : 0,
      appId: json['appId'] is int ? json['appId'] : 0,
      id: json['id'] is int ? json['id'] : 0,
    );
  }

  // To JSON method (optional, if needed for sending data back to the server)
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'loginId': loginId,
      'orgName': orgName,
      'roleName': roleName,
      'imageId': imageId,
      'roleId': roleId,
      'usecaseName': usecaseName,
      'orgId': orgId,
      'appId': appId,
      'id': id,
      'mobileId': mobileId,
      'loginCode': loginCode,
    };
  }
}
