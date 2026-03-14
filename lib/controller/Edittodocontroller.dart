import 'package:cherry_toast/cherry_toast.dart';
import 'package:cuickdevuser/controller/todo_controller.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';

class Edittodocontroller  extends GetxController {
  HttpServices httpServices = HttpServices();
  var taskdata = Rxn<Map<String, dynamic>>(); // Rxn allows null values
  var titleError = ''.obs;
  var descriptionError = ''.obs;
 int formid =0;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

  }
  RxList<dynamic> todolist = RxList<dynamic>();
  Future<void> GettaskInfo(String id) async {
    print('Fetching task info for ID: $id');
    formid = int.parse(id);
    var res = await httpServices.gettaskinfo(id: id);

    if (res != null && res['success'] == true) {
      var data = res['result']['data'];

      if (data != null) {
        taskdata.value = data as Map<String, dynamic>;
        update();
      } else {
        print('No data found in response.');
      }
    } else {
      print('API call failed or returned unexpected data: $res');
    }
  }

  Future<void> Getlist() async {


    var res = await httpServices.Get_tasklist("");
    if (res!['success'] == true) {
      var filteredList = res['result']['data']; // Update labellist
      todolist.assignAll(filteredList);


      update();
    }else{

    }
  }



  Todocontroller todocontroller = Get.put(Todocontroller());
  Future<void> Savetask(String title,String desc ,String targetDate,String targettime) async {

    var res = await httpServices.Save_task(
        id: formid,
        title: title, desc: desc, targetDate: targetDate,targetTime: targettime


    );
    if (res!['success'] == true) {
      CherryToast.success(
        backgroundColor: Color(0xFFDDF4DE),
        animationDuration: Durations.short1,
        title: const Text("Task updated successfully!",
            style: TextStyle(color: Colors.black)),
      ).show(Get.overlayContext!);
      todocontroller.refresh();
      todocontroller.update();
      todocontroller.Gettodolist();
      Get.back();
    }else{
      update();
    }
  }
}