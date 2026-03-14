import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/Appcolor.dart';
import '../controller/tableview_controller.dart';
import '../service/apihelper.dart';

class TagSelectionDialog extends StatefulWidget {
  final List<String> initialSelected;
  final List<String> allTags;
  final bool isDarkMode;
  final int  id;
  // final int  formid;
  final Future<void> Function(String tag) onAddTag;
  final Future<void> Function(String tag) onDeleteTag;

  TagSelectionDialog({
    Key? key,
    required this.initialSelected,
    required this.allTags,
    required this.isDarkMode,
    required this.id,
    // required this.formid,
    required this.onAddTag,
    required this.onDeleteTag,
  }) : super(key: key);

  @override
  _TagSelectionDialogState createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<TagSelectionDialog> {
  late List<String> selectedTags;
  late List<String> availableTags;
  TextEditingController tagController = TextEditingController();
  final TableviewController viewcontroller = Get.put(TableviewController());
  List<String> allTagValues = [];
  @override
  void initState() {
    super.initState();
    selectedTags = List.from(widget.initialSelected);
    availableTags = List.from(widget.allTags);
  }
  @override
  Widget build(BuildContext context) {
    for (var item in viewcontroller.taglist) {
      if (item['type'] == 'tag' && item['values'] != null) {
        var values = item['values'];

        // If values is not a List, convert it to a List
        if (values is List) {
          allTagValues.addAll(values.map((v) => v.toString()));
        } else if (values is String) {
          allTagValues.add(values.toString());
        }
      }
    }
if(allTagValues != null){
  availableTags = allTagValues.toSet().toList();
}
    // Remove duplicates (if needed)

    final labelStyle = TextStyle(
      color: widget.isDarkMode ? Colors.white : Colors.black, // Dynamic color
      fontSize: 15,
      fontWeight: FontWeight.w400,
    );
    return AlertDialog(
      backgroundColor: Colors.white,
      contentPadding:const EdgeInsets.symmetric(horizontal: 20),
      title: const Text('Tags',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15),),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(

                    decoration: InputDecoration(
                      fillColor: widget.isDarkMode
                          ? Colors.black
                          : Colors.white,
                      hintText: 'Enter tags (comma separated)',

                      labelStyle: labelStyle,
                      border: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Appcolorblue)),
                    ),
                    controller: tagController,

                  ),
                ),
                IconButton(
                  icon: const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.add)),
                  onPressed: () async {
                    String newTag = tagController.text.trim();
                    if (newTag.isNotEmpty && !availableTags.contains(newTag)) {
                      // await widget.onAddTag(newTag); // call API
                      setState(() {
                        availableTags.add(newTag);

                      });

                      await AddTagitem();

                    }
                  },
                ),
              ],
            ),
            ...availableTags.map((tag) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Row(
                  children: [
                    Checkbox(
                      value: selectedTags.contains(tag),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedTags.add(tag);
                            SaveTag(widget.id, selectedTags);
                          } else {
                            selectedTags.remove(tag);
                            SaveTag(widget.id, "");
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Text(tag, style: labelStyle),
                    ),
                  ],
                ),
              );
            }).toList(),

          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            viewcontroller.onSearch();
       // SaveTag(widget.id, selectedTags) ;
  Navigator.pop(context);
          },


          child: const Text('OK'),
        ),
      ],
    );
  }

  final ApiBaseHelper helper = ApiBaseHelper();
  final HttpServices httpServices = HttpServices();


  Future<Map<String, dynamic>?> AddTagitem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
    }


    print('SaveTag====AddTagitem==========>${availableTags}');
    try {
      final response = await httpServices.tagitemsave(
          label: "tag",
          type: "tag",
          userstoryId: viewcontroller.userstortyid.value.toString(), // Ensure it's an int
          id: widget.id.toString(),  // Ensure it's an int
          values: availableTags.toString());

      if (response != null && response['success'] == true) {
        print('SaveTag====AddTagitem==========>${response}');
        tagController.clear();
        SaveTag(widget.id, selectedTags);
        return response;
      } else {
        return response;
      }
    } catch (e) {
      return {'message': 'Error occurred while saving the form'};
    }
  }
  Future<Map<String, dynamic>?> SaveTag(int id , dynamic tag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      debugPrint("Session ID is missing.");
    }
    String tagString = tag.join(',');

    Map<String, dynamic> reqBody = {
      'id': id,
      'tag':tagString
    }; // Add the 'id' field first


    debugPrint("reqBody....................$reqBody");
    try {
      final response = await helper.postApi(
        "api/v1/${viewcontroller.appCode.value}/${viewcontroller.code.value}/${viewcontroller.saveformcode.value.toString()}/saveForm;jsessionid=$sessionId",
        reqBody,
      );
      debugPrint("response....................$response");
      if (response != null && response['success'] == true) {


        return response;
      } else {
        return response;
      }
    } catch (e) {
      return {'message': 'Error occurred while saving the form'};
    }
  }
}