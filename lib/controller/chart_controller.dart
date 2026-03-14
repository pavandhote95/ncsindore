import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../screen/Menucontroller.dart';

class ChartController extends GetxController {
  HttpServices httpServices = HttpServices();
  RxList<dynamic> labellist = RxList<dynamic>();
  RxList<dynamic> filterlabellist = RxList<dynamic>();
  // String appname = "";
  String menu = "";
  RxList<Button> buttons = <Button>[].obs;
  RxList<Field> fields = <Field>[].obs;

  Future<void> GetForm_API(String id) async {

    var res = await httpServices.GetForm(formId: id);
    if (res?.success == true) {
      var data = res?.data;

      menu = res!.data!.userstoryName.toLowerCase();
      buttons.assignAll(data!.buttons);
      fields.assignAll(data.fields);
      Getattributefield(data.userstoryId.toString());
    } else {
    }
  }
  var list = <Map<String, dynamic>>[].obs;
  final Menucontroller menuController = Get.put(Menucontroller());
  Future<void> GetdataList(String field,String url) async {
    var res = await httpServices.GetList(field: field.toLowerCase(), url: url,currentPage:0,isuserFilter: menuController.isuserFilter.value,);

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data'] as List; // Cast to List<dynamic>

      list.assignAll(dataResponse.map((item) => item as Map<String, dynamic>).toList());

    } else {

    }
  }
  final List<String> allowedTypes = [
    'text',
    'date',
    'number',
    'object',
    'email',
    'time',
    'url',
    'map',
    'textarea'
  ];

  Future<void> Getattributefield(String formId) async {
    labellist.clear();
    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {


       var filteredList =  res['result']['data']; // Update labellist

      labellist.assignAll(filteredList.where((label) {
        return fields.any((field) => field.id == label['id']);
      }).toList());
      filterlabellist.assignAll(labellist.where((e) => allowedTypes.contains(e['type'])).toList());

    }
  }

  RxMap<String, int> chartData = <String, int>{}.obs; // RxMap initialization
  Future<void> GetChart_API(String type, String appname,String field) async {
    chartData.clear();
    var res = await httpServices.Getchartdata(
        type: type.toLowerCase(),  appname: appname, menu: menu);
    if (res?['success'] == true) {
      var result = res?['result'];
      var data = result['data'];
      chartData.value = Map<String, int>.from(data).map((key, value) => MapEntry(key, value as int));
    } else {
    }
  }
}
