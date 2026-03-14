import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/todo_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controller/Edittodocontroller.dart';

class AddtaskScreen extends StatefulWidget {
  const AddtaskScreen({super.key});

  @override
  State<AddtaskScreen> createState() => _AddtaskScreenState();
}

class _AddtaskScreenState extends State<AddtaskScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  Todocontroller todocontroller = Get.put(Todocontroller()) ;
  String?
  formattedTime;

 @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    todocontroller.titleError.value = "";
    todocontroller.descriptionError.value = "";
  }
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final labelStyle = TextStyle(
      color: isDarkMode ? Colors.white : Colors.black, // Dynamic color
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    return Scaffold(
        backgroundColor: isDarkMode? Colors.black:Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: isDarkMode ? Colors.grey[850]:Appcolorblue,
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Task',
          style: TextStyle(color: Colors.white, fontSize: 20,),
        ),
      ),
      body:
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment:MainAxisAlignment.start ,
          crossAxisAlignment:CrossAxisAlignment.start ,
          children: [
             Text('Title:',style: TextStyle(fontWeight: FontWeight.bold,color: isDarkMode ? Colors.white : Colors.black,),),
            const SizedBox(
              height: 8,
            ),
            Obx(
                  () {

                return  TextFormField(
                  style:labelStyle ,
                  controller: titleController,
                  onChanged: (value) {
                    setState(() {
                      todocontroller.titleError.value ="";
                    });

                  },// Set controller
                  decoration: InputDecoration(
                    fillColor: isDarkMode? Colors.black:Colors.white,
                    labelText: 'Enter the title',
                    labelStyle:labelStyle,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Appcolorblue)),
                    errorText: todocontroller.titleError.value.isEmpty
                        ? null
                        : todocontroller.titleError.value,
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                );
              },

            ),

            const SizedBox(
              height: 8,
            ),
              Text('Description:',style: TextStyle(fontWeight: FontWeight.bold,color: isDarkMode ? Colors.white : Colors.black,),),
            const SizedBox(
              height: 8,
            ),

            Obx(
         () {

           return TextFormField(
             style:labelStyle ,
             controller: descriptionController,
             onChanged: (value) {
               setState(() {
                 todocontroller.descriptionError.value = "";
               });


             },// Set controller
             decoration: InputDecoration(
         labelText: 'Enter Description',
         labelStyle:labelStyle,
         fillColor: isDarkMode? Colors.black:Colors.white,
         border: OutlineInputBorder(
             borderSide: BorderSide(color: Appcolorblue)),
         errorText: todocontroller.descriptionError.value.isEmpty
             ? null
             : todocontroller.descriptionError.value,
             ),
             keyboardType: TextInputType.text,
             validator: (value) {
         if (value == null || value.trim().isEmpty) {
           return 'Description is required';
         }
         return null;
             },
           );
         },

            ),

            const SizedBox(
              height: 8,
            ),
             Text('Date:',style: TextStyle(fontWeight: FontWeight.bold,color: isDarkMode ? Colors.white : Colors.black,),),
            const SizedBox(
              height: 8,
            ),
            TextFormField(
              controller: dateController, // Set controller
              readOnly: true,
              style:labelStyle ,
              decoration: InputDecoration(
                fillColor: isDarkMode? Colors.black:Colors.white,
                labelText: 'Select date',
                labelStyle:labelStyle,
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Appcolorblue)),
              ),
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  String formattedDate =
                  "${selectedDate.toLocal()}".split(' ')[0];
                  dateController.text = formattedDate;
                }
              },
            ),
            const SizedBox(
              height: 20,
            ),

            Text('Time:',style: TextStyle(fontWeight: FontWeight.bold,color: isDarkMode ? Colors.white : Colors.black,),),
            const SizedBox(
              height: 8,
            ),
            TextFormField(
              controller: timeController, // Set controller
              readOnly: true,
              style:labelStyle ,

              decoration: InputDecoration(
                fillColor: isDarkMode? Colors.black:Colors.white,
                labelText: 'Select Time',
                labelStyle:labelStyle,
                suffixIcon: const Icon(Icons.access_time_sharp),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Appcolorblue)),

              ),

              onTap: () async {
                TimeOfDay?
                selectedTime =
                await showTimePicker(
                  context: context,
                  initialTime:
                  TimeOfDay
                      .now(),
                );
                if (selectedTime !=
                    null) {
                  // Convert TimeOfDay to DateTime
                  final now =
                  DateTime
                      .now();
                  final dateTime =
                  DateTime(
                      now.year,
                      now.month,
                      now.day,
                      selectedTime
                          .hour,
                      selectedTime
                          .minute);
                  final format = DateFormat.jm(); // gives 5:08 PM
                  final timeString = format.format(dateTime);



                  setState(() {
                    formattedTime =
                        DateFormat(
                            'HH:mm')
                            .format(
                            dateTime);
                    timeController.text = timeString;
                  });
                }
              },


            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    String title = titleController.text;
                    String description = descriptionController.text;
                    String targetDate = dateController.text;
                    String targettime = formattedTime.toString();

                    if (description.isEmpty && title.isEmpty) {
                      todocontroller.descriptionError.value = "Description is required";
                      todocontroller.titleError.value = "Title is required";
                    } else if (description.isEmpty) {
                      todocontroller.descriptionError.value = "Description is required";
                      todocontroller.titleError.value = ""; // Clear title error if valid
                    } else if (title.isEmpty) {
                      todocontroller.titleError.value = "Title is required";
                      todocontroller.descriptionError.value = ""; // Clear description error if valid
                    } else {
                      // Clear both errors
                      todocontroller.descriptionError.value = "";
                      todocontroller.titleError.value = "";

                      // Proceed to save
                      if (formattedTime == null) {
                        todocontroller.Savetask(title, description, targetDate, "");
                      } else {
                        todocontroller.Savetask(title, description, targetDate, targettime);
                      }
                    }


                  },
                  child: Container(
                    height: 50,
                    width: 150,
                    decoration:  BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(  color:isDarkMode ? Colors.blue: Color(0xFF1A237E),)
                    ),
                    child:  Center(
                      child: Text(
                        'Save',
                          style:  TextStyle(
                            color: isDarkMode ? Colors.blue: Color(0xFF1A237E),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Lato',
                            fontSize: 15,
                          ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    Get.back();
                  },
                  child: Container(
                    height: 50,
                    width: 150,
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                      border: Border.all(  color:isDarkMode ? Colors.blue: Color(0xFF1A237E),)
                    ),
                    child:  Center(
                      child: Text(
                        'Cancel',
                        style:  TextStyle(
                          color: isDarkMode ? Colors.blue: Color(0xFF1A237E),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Lato',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    )

    );
  }
}
