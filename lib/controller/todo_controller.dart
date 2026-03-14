import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';

class Todocontroller  extends GetxController {
  HttpServices httpServices = HttpServices();
  var titleError = ''.obs;
  var descriptionError = ''.obs;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

  }
  RxList<dynamic> todolist = RxList<dynamic>();
  RxList<dynamic> filtertodolist = RxList<dynamic>();
  Future<void> Gettodolist() async {
    todolist.clear();

    var res = await httpServices.Get_tasklist("");
    if (res!['success'] == true) {
      var filteredList = res['result']['data']; // Update labellist

      todolist.assignAll(filteredList);
      update();
    }else{

    }
  }

  Future<void> Filtertodolist(String title) async {
    filtertodolist.clear();

    var res = await httpServices.Get_tasklist(title);
    if (res!['success'] == true) {
      var filteredList = res['result']['data']; // Update labellist

      filtertodolist.assignAll(filteredList);

      update();
    }else{

    }
  }
  Future<void> Updatestatus(String id) async {


    var res = await httpServices.changestatus(id: id);
    if (res!['success'] == true) {
      var filteredList = res['result']; // Update labellist
      Gettodolist();
    }else{

    }
  }
  Future<void> UpdateNAstatus(String id) async {


    var res = await httpServices.changeNA(id: id);
    if (res!['success'] == true) {
      var filteredList = res['result']; // Update labellist
      Gettodolist();
    }else{

    }
  }
  Future<void> UpdatechangeHigh(String id) async {


    var res = await httpServices.changeHigh(id: id);
    if (res!['success'] == true) {

      Gettodolist();
    }else{

    }
  }
  Future<void> Updatestatusnotstarted(String id) async {


    var res = await httpServices.changestartedstatus(id: id);
    if (res!['success'] == true) {

      Gettodolist();
    }else{

    }
  }
  Future<void> Deletetask(String id) async {


    var res = await httpServices.deletetask(id: id);
    if (res!['success'] == true) {
      CherryToast.success(
        backgroundColor: Color(0xFFDDF4DE),
        animationDuration: Durations.short1,
        title: const Text("Record deleted successfully!",
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);

      Gettodolist();
      update();
    }else{

    }
  }
  Map<String, String?> resulterror = {};
  Future<void> Savetask(String title, String desc, String targetDate, String targettime) async {

    var res = await httpServices.Save_task(id: 0, title: title, desc: desc, targetDate: targetDate, targetTime: targettime);

    if (res != null && res['success'] == true) {  // First check if 'res' is not null
      Get.back();
      CherryToast.success(
        backgroundColor: Color(0xFFDDF4DE),
        animationDuration: Durations.short1,
        title: const Text("Task Saved successfully!", style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
      Gettodolist();
    } else {
      update();

    }
  }

}