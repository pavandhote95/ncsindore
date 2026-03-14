import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';

class SupportSystemScreen extends StatefulWidget {
  const SupportSystemScreen({super.key});

  @override
  State<SupportSystemScreen> createState() => _SupportSystemScreenState();
}

class _SupportSystemScreenState extends State<SupportSystemScreen> {

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedCategory;
  final List<String> categories = ["Issue", "Help", "Requirement"];
  HttpServices httpServices = HttpServices();
  Future<void> supportEmail() async {
    var res = await httpServices.savesupportEmail(id: "0", title: titleController.text, category: selectedCategory!, desc:descriptionController.text, status: 'Open');
    if (res['success'] == true) {
      debugPrint("------------------------->>>");

    } else {
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Appcolorblue,
        title: const Text('Support System',
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title TextField
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: selectedCategory,
                items: categories
                    .map((category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description TextField
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {

                      Navigator.pop(context); // Close the bottom sheet after saving
                    },
                    child: Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet on cancel
                    },
                    child: Container(
                      height: 50,
                      width: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
