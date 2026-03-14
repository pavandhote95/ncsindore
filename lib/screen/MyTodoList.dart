/*
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/todo_controller.dart';
import 'package:cuickdevuser/screen/Addtask_screen.dart';
import 'package:cuickdevuser/screen/EdittaskScreen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controller/Edittodocontroller.dart';

class MyTodoList extends StatefulWidget {
  const MyTodoList({super.key});

  @override
  State<MyTodoList> createState() => _MyTodoListScreenState();
}

class _MyTodoListScreenState extends State<MyTodoList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pageController = PageController();
  }

  final ScrollController _scrollController = ScrollController();

  bool _showAll = false;
  bool starttask = false;

  void _toggleViewAll() {
    setState(() {
      _showAll = !_showAll;
    });

    if (_showAll) {
    } else {}
  }

  final int initialItemCount = 3;
  final int totalItemCount = 10;

  Future onRefresh() async {
    // todoController.taskstatuslist();
    // todoController.TasklistAPI();
  }

  Todocontroller todocontroller = Get.put(Todocontroller());
  late PageController _pageController;
  int activePageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = ''; // Variable to store the search query

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    todocontroller.Gettodolist();
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
            title: const Text('Task',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            actions: [
              GestureDetector(
                onTap: () {
                  Get.to(const AddtaskScreen());
                  // _showTaskBottomSheet(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Appcolorblue,
                        ),
                        Text(
                          AppStrings.addTaskButton,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: isDarkMode ? Colors.white : Appcolorblue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15),
                  child: TextField(
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black, // Dynamic color
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                        fillColor: isDarkMode ? Colors.black : Colors.white,
                        labelText: 'Search by title',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : Colors.black, // Dynamic color
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Appcolorblue,
                            )),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.white : Colors.black,
                        )),
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query;
                        todocontroller.Filtertodolist(searchQuery);// Update the search query
                      });
                    },
                  ),
                ),
                searchController.text.isEmpty && searchQuery.isEmpty
                    ? GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,

                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: _menuBar(context),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.99,
                            child: PageView(
                              controller: _pageController,
                              physics: const ClampingScrollPhysics(),
                              onPageChanged: (int i) {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                setState(() {
                                  activePageIndex = i;
                                });
                              },
                              children: <Widget>[
                                ConstrainedBox(
                                    constraints:
                                    const BoxConstraints.expand(),
                                    child: Obx(() {
                                      var allTasks = todocontroller.todolist;

                                      if (allTasks.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No Task',
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                        );
                                      }

                                      // ✅ Sort High priority tasks to top
                                      List sortedTasks = List.from(allTasks);
                                      sortedTasks.sort((a, b) {
                                        if (a['priority'] == 'High' && b['priority'] != 'High') return -1;
                                        if (a['priority'] != 'High' && b['priority'] == 'High') return 1;
                                        return 0;
                                      });

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: sortedTasks.length,
                                          itemBuilder: (context, index) {
                                            final task = sortedTasks[index];
                                            String? rawDate = task['targetDate'];
                                            DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                                                ? DateFormat('yyyy-MM-dd').parse(rawDate)
                                                : null;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: _getColorForStatus(
                                                    task['status'],
                                                    task['targetDate'],
                                                    task['targetTime'],
                                                  ),
                                                  border: Border.all(color: Colors.black26),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // ✅ Status Icon
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 10),
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          if (task['status'] == 'Not started') {
                                                            todocontroller.Updatestatus(task['id'].toString());
                                                          }
                                                        },
                                                        child: Icon(
                                                          _getIconForStatus(task['status']),
                                                          color: _getColorForicon(task['status']),
                                                          size: 35,
                                                        ),
                                                      ),
                                                    ),

                                                    // ✅ Task Info
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            task['title'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            task['description'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              const Text('Target: ',
                                                                  style: TextStyle(
                                                                      fontWeight: FontWeight.bold, fontSize: 13)),
                                                              Text(_getDateLabel(targetDate),
                                                                  style: const TextStyle(fontSize: 12)),
                                                              Text(" | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                                  style: const TextStyle(fontSize: 12)),
                                                            ],
                                                          ),
                                                          if (task['completionDate'] != null &&
                                                              task['completionDate'] != "")
                                                            Row(
                                                              children: [
                                                                const Text('Completion: ',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 13)),
                                                                Text(
                                                                  formatCompletionDate(task['completionDate']),
                                                                  style: const TextStyle(fontSize: 12),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // ✅ Actions Column
                                                    Column(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            final isHigh = task['priority'] == 'High';
                                                            final id = task['id'].toString();
                                                            isHigh
                                                                ? todocontroller.UpdateNAstatus(id)
                                                                : todocontroller.UpdatechangeHigh(id);
                                                          },
                                                          child: Icon(
                                                            task['priority'] == 'High'
                                                                ? Icons.star
                                                                : Icons.star_border,
                                                            size: 22,
                                                            color: task['priority'] == 'High'
                                                                ? const Color(0xFFFA8806)
                                                                : const Color(0xFF0C0C0C),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        if (task['status'] != 'Completed')
                                                          GestureDetector(
                                                            onTap: () {
                                                              Get.to(Edittaskscreen(
                                                                  taskid: task['id'].toString()));
                                                            },
                                                            child: SvgPicture.asset(
                                                              'assets/images/edit.svg',
                                                              width: 24,
                                                              height: 24,
                                                              color: const Color(0xFF1366EE),
                                                            ),
                                                          ),
                                                        const SizedBox(height: 8),
                                                        GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                backgroundColor:
                                                                isDarkMode ? Colors.black : Colors.white,
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const SizedBox(height: 15),
                                                                    Text(
                                                                      "Are you sure you want to delete this item?",
                                                                      style: TextStyle(
                                                                        fontSize: 15,
                                                                        fontFamily: "lato",
                                                                        fontWeight: FontWeight.w500,
                                                                        color: isDarkMode
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 15),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                      MainAxisAlignment.spaceAround,
                                                                      children: [
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: isDarkMode
                                                                                ? Colors.grey[800]
                                                                                : const Color(0xFFB0B0B4),
                                                                          ),
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(),
                                                                          child: const Text("Cancel",
                                                                              style: TextStyle(
                                                                                  fontSize: 13,
                                                                                  color: Colors.white)),
                                                                        ),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                              backgroundColor:
                                                                              const Color(0xFFFF043B)),
                                                                          onPressed: () {
                                                                            Get.back();
                                                                            todocontroller.Deletetask(
                                                                                task['id'].toString());
                                                                          },
                                                                          child: const Text("Delete",
                                                                              style: TextStyle(
                                                                                  fontSize: 13,
                                                                                  color: Colors.white)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: SvgPicture.asset(
                                                            'assets/images/delete.svg',
                                                            width: 24,
                                                            height: 24,
                                                            color: const Color(0xFFEC3C3C),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    })

                                ),
                                ConstrainedBox(
                                    constraints:
                                    const BoxConstraints.expand(),
                                    child: Obx(() {
                                      var completedTasks = todocontroller.todolist
                                          .where((task) => task['status'] == 'Completed')
                                          .toList();

                                      // ✅ Sort High priority tasks to the top
                                      completedTasks.sort((a, b) {
                                        if (a['priority'] == 'High' && b['priority'] != 'High') return -1;
                                        if (a['priority'] != 'High' && b['priority'] == 'High') return 1;
                                        return 0;
                                      });

                                      if (completedTasks.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No Completed Tasks',
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                        );
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: completedTasks.length,
                                          itemBuilder: (context, index) {
                                            final task = completedTasks[index];

                                            String? rawDate = task['targetDate'];
                                            DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                                                ? DateFormat('yyyy-MM-dd').parse(rawDate)
                                                : null;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: _getColorForStatus(
                                                    task['status'],
                                                    task['targetDate'],
                                                    task['targetTime'],
                                                  ),
                                                  border: Border.all(color: Colors.black26),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // ✅ Status Icon (Optional, not interactive in "Completed")
                                                    Icon(
                                                      _getIconForStatus(task['status']),
                                                      color: _getColorForicon(task['status']),
                                                      size: 35,
                                                    ),
                                                    const SizedBox(width: 10),

                                                    // ✅ Task Info
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            task['title'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            task['description'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Target: ',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              Text(
                                                                _getDateLabel(targetDate),
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                              Text(
                                                                " | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                          if (task['completionDate'] != null &&
                                                              task['completionDate'] != '')
                                                            Row(
                                                              children: [
                                                                const Text(
                                                                  'Completion: ',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 13,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  formatCompletionDate(task['completionDate']),
                                                                  style: const TextStyle(fontSize: 12),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // ✅ Action Buttons: Priority Toggle & Delete
                                                    Column(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            final isHigh = task['priority'] == 'High';
                                                            final id = task['id'].toString();
                                                            isHigh
                                                                ? todocontroller.UpdateNAstatus(id)
                                                                : todocontroller.UpdatechangeHigh(id);
                                                          },
                                                          child: Icon(
                                                            task['priority'] == 'High'
                                                                ? Icons.star
                                                                : Icons.star_border,
                                                            size: 22,
                                                            color: task['priority'] == 'High'
                                                                ? const Color(0xFFFA8806)
                                                                : const Color(0xFF0C0C0C),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                backgroundColor:
                                                                isDarkMode ? Colors.black : Colors.white,
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const SizedBox(height: 15),
                                                                    Text(
                                                                      "Are you sure you want to delete this item?",
                                                                      style: TextStyle(
                                                                        fontSize: 15,
                                                                        fontFamily: "Lato",
                                                                        fontWeight: FontWeight.w500,
                                                                        color: isDarkMode
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 15),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                      MainAxisAlignment.spaceAround,
                                                                      children: [
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: isDarkMode
                                                                                ? Colors.grey[800]
                                                                                : const Color(0xFFB0B0B4),
                                                                          ),
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(),
                                                                          child: const Text(
                                                                            "Cancel",
                                                                            style: TextStyle(
                                                                                fontSize: 13,
                                                                                color: Colors.white),
                                                                          ),
                                                                        ),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                            const Color(0xFFFF043B),
                                                                          ),
                                                                          onPressed: () {
                                                                            Get.back();
                                                                            todocontroller.Deletetask(
                                                                                task['id'].toString());
                                                                          },
                                                                          child: const Text(
                                                                            "Delete",
                                                                            style: TextStyle(
                                                                                fontSize: 13,
                                                                                color: Colors.white),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: SvgPicture.asset(
                                                            'assets/images/delete.svg',
                                                            width: 24,
                                                            height: 24,
                                                            color: const Color(0xFFEC3C3C),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    })

                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints.expand(),
                                  child: Obx(() {
                                    // Filter tasks with 'Not started' status
                                    var notStartedTasks = todocontroller.todolist
                                        .where((task) => task['status'] == 'Not started')
                                        .toList();

                                    // Sort tasks so that high priority ones come first
                                    notStartedTasks.sort((a, b) {
                                      if (a['priority'] == 'High' && b['priority'] != 'High') {
                                        return -1; // High priority comes before non-high
                                      } else if (a['priority'] != 'High' && b['priority'] == 'High') {
                                        return 1; // Non-high priority comes after high
                                      }
                                      return 0; // If both have the same priority (e.g., both 'Not started')
                                    });

                                    if (notStartedTasks.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No Pending Tasks',
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        physics: const BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: notStartedTasks.length,
                                        itemBuilder: (context, index) {
                                          final task = notStartedTasks[index];
                                          String? rawDate = task['targetDate'];
                                          DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                                              ? DateFormat('yyyy-MM-dd').parse(rawDate)
                                              : null;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: _getColorForStatus(
                                                  task['status'],
                                                  task['targetDate'],
                                                  task['targetTime'],
                                                ),
                                                border: Border.all(color: Colors.black26),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Status Icon
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (task['status'] == 'Not started') {
                                                        todocontroller.Updatestatus(task['id'].toString());
                                                      }
                                                    },
                                                    child: Icon(
                                                      _getIconForStatus(task['status']),
                                                      color: _getColorForicon(task['status']),
                                                      size: 35,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),

                                                  // Task Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          task['title'],
                                                          style: const TextStyle(
                                                            fontFamily: 'Gilroy',
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          task['description'] ?? '',
                                                          style: const TextStyle(
                                                            fontFamily: 'Gilroy',
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 12,
                                                            color: Colors.black,
                                                          ),
                                                          maxLines: 3,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Target: ',
                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                            ),
                                                            Text(
                                                              _getDateLabel(targetDate),
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                            Text(
                                                              " | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ],
                                                        ),
                                                        if (task['completionDate'] != null && task['completionDate'] != '')
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Completion: ',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                              ),
                                                              Text(
                                                                formatCompletionDate(task['completionDate']),
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Action Buttons
                                                  Column(
                                                    children: [
                                                      // Priority Icon
                                                      GestureDetector(
                                                        onTap: () {
                                                          final isHigh = task['priority'] == 'High';
                                                          final id = task['id'].toString();
                                                          if (isHigh) {
                                                            todocontroller.UpdateNAstatus(id); // Remove High priority
                                                          } else {
                                                            todocontroller.UpdatechangeHigh(id); // Set to High priority
                                                          }
                                                        },
                                                        child: Icon(
                                                          task['priority'] == 'High' ? Icons.star : Icons.star_border,
                                                          size: 22,
                                                          color: task['priority'] == 'High'
                                                              ? const Color(0xFFFA8806)
                                                              : const Color(0xFF0C0C0C),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Edit Task
                                                      GestureDetector(
                                                        onTap: () {
                                                          Get.to(Edittaskscreen(taskid: task['id'].toString()));
                                                        },
                                                        child: SvgPicture.asset(
                                                          'assets/images/edit.svg',
                                                          width: 24,
                                                          height: 24,
                                                          color: const Color(0xFF1366EE),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Delete Task
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              backgroundColor: isDarkMode ? Colors.black : Colors.white,
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const SizedBox(height: 15),
                                                                  Text(
                                                                    "Are you sure you want to delete this item?",
                                                                    style: TextStyle(
                                                                      fontSize: 15,
                                                                      fontFamily: "Lato",
                                                                      fontWeight: FontWeight.w500,
                                                                      color: isDarkMode ? Colors.white : Colors.black,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 15),
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                    children: [
                                                                      ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: isDarkMode
                                                                              ? Colors.grey[800]
                                                                              : const Color(0xFFB0B0B4),
                                                                        ),
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                        child: const Text("Cancel", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                      ),
                                                                      ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color(0xFFFF043B),
                                                                        ),
                                                                        onPressed: () {
                                                                          Get.back();
                                                                          todocontroller.Deletetask(task['id'].toString());
                                                                        },
                                                                        child: const Text("Delete", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: SvgPicture.asset(
                                                          'assets/images/delete.svg',
                                                          width: 24,
                                                          height: 24,
                                                          color: const Color(0xFFEC3C3C),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                ),
                                ConstrainedBox(
                                  constraints:
                                  const BoxConstraints.expand(),
                                  child: Obx(() {
                                    // Filter tasks with 'High' priority
                                    var priorityTasks =
                                    todocontroller.todolist
                                        .where((task) {
                                      return task['priority'] ==
                                          'High';
                                    }).toList();

                                    if (priorityTasks.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No Priority Tasks',
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            color: Colors.indigo,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 10.0,
                                          vertical: 10),
                                      child: ListView.builder(
                                        physics:
                                        const BouncingScrollPhysics(),
                                        controller:
                                        _scrollController,
                                        shrinkWrap: true,
                                        itemCount:
                                        priorityTasks.length,
                                        itemBuilder:
                                            (context, index) {
                                          final task =
                                          priorityTasks[index];
                                          String? rawDate =
                                          task['targetDate'];
                                          DateTime? targetDate =
                                          (rawDate != null &&
                                              rawDate
                                                  .isNotEmpty)
                                              ? DateFormat(
                                              'yyyy-MM-dd')
                                              .parse(
                                              rawDate)
                                              : null;

                                          return Padding(
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                vertical: 4.0),
                                            child: Container(
                                              padding:
                                              const EdgeInsets
                                                  .all(10),
                                              decoration:
                                              BoxDecoration(
                                                color: Colors.yellow
                                                    .shade100,
                                                border: Border.all(
                                                    color: Colors
                                                        .black26),
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    10),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  // Status Icon
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (task[
                                                      'status'] ==
                                                          'Not started') {
                                                        todocontroller.Updatestatus(
                                                            task['id']
                                                                .toString());
                                                      }
                                                    },
                                                    child: Icon(
                                                      _getIconForStatus(
                                                          task[
                                                          'status']),
                                                      color: _getColorForicon(
                                                          task[
                                                          'status']),
                                                      size: 35,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: 10),

                                                  // Task Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          task['title'] ??
                                                              '',
                                                          style:
                                                          const TextStyle(
                                                            fontFamily:
                                                            'Gilroy',
                                                            fontWeight:
                                                            FontWeight.w500,
                                                            fontSize:
                                                            18,
                                                            color: Colors
                                                                .black,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height:
                                                            6),
                                                        Text(
                                                          task['description'] ??
                                                              '',
                                                          style:
                                                          const TextStyle(
                                                            fontFamily:
                                                            'Gilroy',
                                                            fontWeight:
                                                            FontWeight.w400,
                                                            fontSize:
                                                            12,
                                                            color: Colors
                                                                .black,
                                                          ),
                                                          maxLines:
                                                          3,
                                                          overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height:
                                                            6),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                                'Target: ',
                                                                style:
                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                            Text(
                                                                _getDateLabel(
                                                                    targetDate),
                                                                style:
                                                                const TextStyle(fontSize: 12)),
                                                            Text(
                                                                " | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                                style:
                                                                const TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                        if (task['completionDate'] !=
                                                            null &&
                                                            task['completionDate'] !=
                                                                '')
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                  'Completion: ',
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                              Text(
                                                                formatCompletionDate(task['completionDate']),
                                                                style:
                                                                const TextStyle(fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Action Buttons
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          final isHigh =
                                                              task['priority'] ==
                                                                  'High';
                                                          final id =
                                                          task['id']
                                                              .toString();
                                                          isHigh
                                                              ? todocontroller.UpdateNAstatus(
                                                              id)
                                                              : todocontroller.UpdatechangeHigh(
                                                              id);
                                                        },
                                                        child: Icon(
                                                          task['priority'] ==
                                                              'High'
                                                              ? Icons
                                                              .star
                                                              : Icons
                                                              .star_border,
                                                          size: 22,
                                                          color: task['priority'] ==
                                                              'High'
                                                              ? const Color(
                                                              0xFFFA8806)
                                                              : const Color(
                                                              0xFF0C0C0C),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height:
                                                          8),
                                                      if (task[
                                                      'status'] !=
                                                          'Completed')
                                                        GestureDetector(
                                                          onTap:
                                                              () {
                                                            Get.to(Edittaskscreen(
                                                                taskid:
                                                                task['id'].toString()));
                                                          },
                                                          child: SvgPicture
                                                              .asset(
                                                            'assets/images/edit.svg',
                                                            width:
                                                            24,
                                                            height:
                                                            24,
                                                            color: const Color(
                                                                0xFF1366EE),
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                          height:
                                                          8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context:
                                                            context,
                                                            builder:
                                                                (context) =>
                                                                AlertDialog(
                                                                  backgroundColor: isDarkMode
                                                                      ? Colors.black
                                                                      : Colors.white,
                                                                  content:
                                                                  Column(
                                                                    mainAxisSize:
                                                                    MainAxisSize.min,
                                                                    children: [
                                                                      const SizedBox(height: 15),
                                                                      Text(
                                                                        "Are you sure you want to delete this item?",
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          fontFamily: "Lato",
                                                                          fontWeight: FontWeight.w500,
                                                                          color: isDarkMode ? Colors.white : Colors.black,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 15),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                        children: [
                                                                          ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: isDarkMode ? Colors.grey[800] : const Color(0xFFB0B0B4),
                                                                            ),
                                                                            onPressed: () => Navigator.of(context).pop(),
                                                                            child: const Text("Cancel", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                          ),
                                                                          ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF043B)),
                                                                            onPressed: () {
                                                                              Get.back();
                                                                              todocontroller.Deletetask(task['id'].toString());
                                                                            },
                                                                            child: const Text("Delete", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                          );
                                                        },
                                                        child: SvgPicture
                                                            .asset(
                                                          'assets/images/delete.svg',
                                                          width: 24,
                                                          height:
                                                          24,
                                                          color: const Color(
                                                              0xFFEC3C3C),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : Obx(() {

                  return todocontroller.filtertodolist.isEmpty
                      ? const Center(
                    child: Text(
                      'No Task Found',
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 10),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: todocontroller.filtertodolist.length,
                        itemBuilder: (context, index) {
                          final task = todocontroller.filtertodolist[index];
                          String? rawDate = task['targetDate'];
                          DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                              ? DateFormat('yyyy-MM-dd').parse(rawDate)
                              : null;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getColorForStatus(
                                  task['status'],
                                  task['targetDate'],
                                  task['targetTime'],
                                ),
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ✅ Status Icon
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (task['status'] == 'Not started') {
                                          todocontroller.Updatestatus(task['id'].toString());
                                        }
                                      },
                                      child: Icon(
                                        _getIconForStatus(task['status']),
                                        color: _getColorForicon(task['status']),
                                        size: 35,
                                      ),
                                    ),
                                  ),

                                  // ✅ Task Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['title'],
                                          style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          task['description'],
                                          style: const TextStyle(
                                            fontFamily: 'Gilroy',
                                            color: Colors.black,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Text('Target: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(_getDateLabel(targetDate),
                                                style: const TextStyle(fontSize: 12)),
                                            Text(" | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                        if (task['completionDate'] != null &&
                                            task['completionDate'] != "")
                                          Row(
                                            children: [
                                              const Text('Completion: ',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13)),
                                              Text(
                                                formatCompletionDate(task['completionDate']),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),

                                  // ✅ Actions Column
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final isHigh = task['priority'] == 'High';
                                          final id = task['id'].toString();
                                          isHigh
                                              ? todocontroller.UpdateNAstatus(id)
                                              : todocontroller.UpdatechangeHigh(id);
                                        },
                                        child: Icon(
                                          task['priority'] == 'High'
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 22,
                                          color: task['priority'] == 'High'
                                              ? const Color(0xFFFA8806)
                                              : const Color(0xFF0C0C0C),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (task['status'] != 'Completed')
                                        GestureDetector(
                                          onTap: () {
                                            Get.to(Edittaskscreen(
                                                taskid: task['id'].toString()));
                                          },
                                          child: SvgPicture.asset(
                                            'assets/images/edit.svg',
                                            width: 24,
                                            height: 24,
                                            color: const Color(0xFF1366EE),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor:
                                              isDarkMode ? Colors.black : Colors.white,
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 15),
                                                  Text(
                                                    "Are you sure you want to delete this item?",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily: "lato",
                                                      fontWeight: FontWeight.w500,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.spaceAround,
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: isDarkMode
                                                              ? Colors.grey[800]
                                                              : const Color(0xFFB0B0B4),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.of(context).pop(),
                                                        child: const Text("Cancel",
                                                            style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.white)),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                            const Color(0xFFFF043B)),
                                                        onPressed: () {
                                                          Get.back();
                                                          todocontroller.Deletetask(
                                                              task['id'].toString());
                                                        },
                                                        child: const Text("Delete",
                                                            style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.white)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: SvgPicture.asset(
                                          'assets/images/delete.svg',
                                          width: 24,
                                          height: 24,
                                          color: const Color(0xFFEC3C3C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),


                      */
/*ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        controller: _scrollController,
                        itemCount: todocontroller.filtertodolist.length,
                        itemBuilder: (context, index) {
                          String? rawDate = todocontroller.filtertodolist[index]['targetDate'];
                          DateTime? targetDate;

                          if (rawDate != null &&
                              rawDate.isNotEmpty) {
                            targetDate = DateFormat('yyyy-MM-dd')
                                .parse(rawDate);
                          } else {
                            targetDate =
                            null; // Or assign DateTime.now() if you want a default date
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2.0, vertical: 2),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0, vertical: 10),
                              decoration: BoxDecoration(
                                color: _getColorForStatus(
                                  todocontroller.filtertodolist[index]['status'],
                                  todocontroller.filtertodolist[index]['targetDate'],
                                  todocontroller.filtertodolist[index]['targetTime'],
                                ),

                                border: Border.all(
                                    color: Colors.black26),
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (todocontroller.filtertodolist[index]
                                        ['status'] ==
                                            'Not started') {
                                          todocontroller
                                              .Updatestatus(
                                              todocontroller.filtertodolist[
                                              index]
                                              ['id']
                                                  .toString());
                                        } else {
                                          // todocontroller.Updatestatusnotstarted(
                                          //     filteredTasks[index]['id']
                                          //         .toString());
                                        }
                                      },
                                      child: Icon(
                                        _getIconForStatus(
                                            todocontroller.filtertodolist[index]
                                            ['status']),
                                        color: _getColorForicon(
                                            todocontroller.filtertodolist[index]
                                            ['status']),
                                        size: 35,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 5.0,
                                          vertical: 5.0),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                        children: [
                                          Text(
                                            todocontroller.filtertodolist[index]
                                            ['title'],
                                            style: const TextStyle(
                                                fontFamily:
                                                'Gilroy',
                                                color: Colors.black,
                                                fontWeight:
                                                FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .start,
                                            children: [
                                              Container(
                                                height: 30,
                                                width: 120,
                                                decoration:
                                                BoxDecoration(
                                                  color:
                                                  Colors.white,
                                                  border: Border.all(
                                                      color: Colors
                                                          .black12),
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      10),
                                                ),
                                                child: Row(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .center,
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                    children: [
                                                      Text(
                                                        _getDateLabel(
                                                            targetDate),
                                                        style: const TextStyle(
                                                            fontFamily:
                                                            'Gilroy',
                                                            color: Colors
                                                                .black,
                                                            fontWeight:
                                                            FontWeight
                                                                .w500,
                                                            fontSize:
                                                            15),
                                                      ),
                                                    ]),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              todocontroller.filtertodolist[index][
                                              'targetTime'] ==
                                                  null
                                                  ? const SizedBox()
                                                  : Container(
                                                height: 30,
                                                width: 80,
                                                decoration:
                                                BoxDecoration(
                                                  color: Colors
                                                      .white,
                                                  border: Border.all(
                                                      color: Colors
                                                          .black12),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .center,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceEvenly,
                                                  children: [
                                                    Text(
                                                      convertTo12HourFormat(todocontroller.filtertodolist[index]['targetTime'] ??
                                                          ""),
                                                      style: const TextStyle(
                                                          fontFamily:
                                                          'Gilroy',
                                                          color:
                                                          Colors.black,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 15),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: IconButton(
                                      onPressed: () async {
                                        if (todocontroller.filtertodolist[index]
                                        ['priority'] ==
                                            'High') {
                                          todocontroller
                                              .UpdateNAstatus(
                                              todocontroller.filtertodolist[
                                              index]
                                              ['id']
                                                  .toString());
                                        } else {
                                          todocontroller
                                              .UpdatechangeHigh(
                                              todocontroller.filtertodolist[
                                              index]
                                              ['id']
                                                  .toString());
                                        }
                                      },
                                      icon: todocontroller.filtertodolist[index]
                                      ['priority'] ==
                                          'High'
                                          ? const Icon(Icons.star,
                                          color:
                                          Color(0xFFFA8806))
                                          : const Icon(
                                        Icons.star_border,
                                        color:
                                        Color(0xFF0C0C0C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),*//*

                    ),
                  );
                }),
              ],
            ),
          )),
    );
  }

  Widget _menuBar(BuildContext context) {
    return Container(
      width: 380.0,
      height: 47.0,
      decoration: const BoxDecoration(
        color: Color(0XFFE0E0E0),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: Onnalll,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: (activePageIndex == 0)
                    ? const BoxDecoration(
                  color: Color(0xFF374A8B),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
                    : null,
                child: Text(
                  "All",
                  style: (activePageIndex == 0)
                      ? const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)
                      : const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: oncompleted,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: (activePageIndex == 1)
                    ? const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
                    : null,
                child: Text(
                  "Completed",
                  style: (activePageIndex == 1)
                      ? const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)
                      : const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: Onnotstared,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: (activePageIndex == 2)
                    ? const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
                    : null,
                child: Text(
                  "Not Started",
                  style: (activePageIndex == 2)
                      ? const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)
                      : const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: Onprority,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: (activePageIndex == 3)
                      ? const BoxDecoration(
                    color: Color(0xFFF47B19),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  )
                      : null,
                  child: Icon(
                      activePageIndex == 3 ? Icons.star : Icons.star_border,
                      color: activePageIndex == 3
                          ? Colors.white
                          : Color(0xFFFA8806))
                // Text(
                //   "Priority",
                //   style: (activePageIndex == 3) ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold) : const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void Onnalll() {
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void oncompleted() {
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void Onnotstared() {
    _pageController.animateToPage(2,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void Onprority() {
    _pageController.animateToPage(3,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }
  TimeOfDay _parseTime(String timeStr) {
    final format = DateFormat.jm(); // e.g. 5:08 PM
    final dt = format.parse(timeStr);
    return TimeOfDay.fromDateTime(dt);
  }


  Color _getColorForStatus(String status, String? targetDateStr, String? targetTimeStr) {
    final now = DateTime.now();
    bool isOverdue = false;

    if (targetDateStr != null && targetDateStr.isNotEmpty) {
      try {
        final targetDate = DateFormat('yyyy-MM-dd').parse(targetDateStr);
        DateTime targetDateTime;

        if (targetTimeStr != null && targetTimeStr.isNotEmpty) {
          final timeParts = targetTimeStr.split(':');
          int hour = int.tryParse(timeParts[0]) ?? 0;
          int minute = 0;

          if (timeParts.length > 1) {
            minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;
          }

          bool isPM = targetTimeStr.toLowerCase().contains('pm');
          if (isPM && hour < 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;

          targetDateTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            hour,
            minute,
          );
        } else {
          // Default to midnight if time not available
          targetDateTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          );
        }



        // Mark overdue if now is after the target datetime
        if (now.isAfter(targetDateTime)) {
          isOverdue = true;
        }
      } catch (e) {
        debugPrint('Error parsing date/time: $e');
      }
    }

    switch (status) {
      case 'Completed':
        return Colors.green.shade100;
      case 'Not started':
        return isOverdue ? Colors.red.shade200 : Colors.white;
      default:
        return isOverdue ? Colors.red.shade200 : Colors.orange.shade100;
    }
  }





  Color _getColorForicon(String status) {
    switch (status) {
      case 'Completed':
        return Color(0xFF1B5E20);
      case 'Not started':
        return Color(0xFFB71C1C);
      default:
        return Color(0xFFE65100); // Default color for other statuses
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Not Started':
        return Icons.radio_button_unchecked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getDateLabel(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == tomorrow) {
      return "Tomorrow";
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  String convertTo12HourFormat(String time) {
    try {
      final DateFormat inputFormat =
      DateFormat("HH:mm"); // Input format: 24-hour format
      final DateFormat outputFormat =
      DateFormat("hh:mm a"); // Output format: 12-hour format with AM/PM
      DateTime parsedTime = inputFormat.parse(time);
      return outputFormat.format(parsedTime);
    } catch (e) {
      return time; // If parsing fails, return the original time string
    }
  }

  String formatCompletionDate(String completionDate) {
    try {
      // Input format: "yyyy-MM-dd HH:mm:ss"
      final DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

      // Output format: "MMM dd, yyyy hh:mm a" (e.g., April 03, 2025, 12:26 PM)
      final DateFormat outputFormat = DateFormat("MMMM dd, yyyy hh:mm a");

      DateTime parsedDate =
      inputFormat.parse(completionDate); // Parse the input date
      return outputFormat
          .format(parsedDate); // Format and return the formatted date
    } catch (e) {
      return completionDate; // If parsing fails, return the original date string
    }
  }

  String datastring(String dateString) {
    // DateTime parsedDateTime = DateTime.parse(dateString);
    DateTime utcDateTime = DateTime.parse(dateString);

    // Convert UTC time to IST (UTC +05:30)
    DateTime istDateTime = utcDateTime.add(Duration(hours: 5, minutes: 30));

    // Format IST DateTime to desired string format
    String formattedDateTime =
    // DateFormat('dd/MM/yy hh:mm:ss a').format(istDateTime);
    DateFormat('dd/MM/yy ').format(istDateTime);

    return formattedDateTime;
  }
}

class AppStrings {
  static const String taskTitle = 'Tasks';
  static const String addTaskButton = 'Add Task';
  static const String taskStatus = 'Task Status !';
  static const String noTaskMessage = 'No';
  static const String taskForToday = 'Task for Today!';
  static const String todayTab = 'Today';
  static const String allTab = 'All';
  static const String completedTab = 'Completed';
}
*/
import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/todo_controller.dart';
import 'package:cuickdevuser/screen/Addtask_screen.dart';
import 'package:cuickdevuser/screen/EdittaskScreen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controller/Edittodocontroller.dart';

class MyTodoList extends StatefulWidget {
  const MyTodoList({super.key});

  @override
  State<MyTodoList> createState() => _MyTodoListScreenState();
}

class _MyTodoListScreenState extends State<MyTodoList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pageController = PageController();
  }

  final ScrollController _scrollController = ScrollController();

  bool _showAll = false;
  bool starttask = false;

  void _toggleViewAll() {
    setState(() {
      _showAll = !_showAll;
    });

    if (_showAll) {
    } else {}
  }

  final int initialItemCount = 3;
  final int totalItemCount = 10;

  Future onRefresh() async {
    // todoController.taskstatuslist();
    // todoController.TasklistAPI();
  }

  Todocontroller todocontroller = Get.put(Todocontroller());
  late PageController _pageController;
  int activePageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  TextEditingController searchController = TextEditingController();
  String searchQuery = ''; // Variable to store the search query

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    todocontroller.Gettodolist();
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: isDarkMode ? Colors.grey[850] : Appcolorblue,
            title: const Text('Task',
                style: TextStyle(color: Colors.white, fontSize: 20)),
            actions: [
              GestureDetector(
                onTap: () {
                  Get.to(const AddtaskScreen());
                  // _showTaskBottomSheet(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Appcolorblue,
                        ),
                        Text(
                          AppStrings.addTaskButton,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            color: isDarkMode ? Colors.white : Appcolorblue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15),
                  child: TextField(
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black, // Dynamic color
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                        fillColor: isDarkMode ? Colors.black : Colors.white,
                        labelText: 'Search by title',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : Colors.black, // Dynamic color
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Appcolorblue,
                            )),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.white : Colors.black,
                        )),
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query; // Update the search query
                      });
                    },
                  ),
                ),
                searchController.text.isEmpty  && searchQuery.isEmpty
                    ? GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,

                      height: MediaQuery.of(context).size.height * (645 / MediaQuery.of(context).size.height), // Equivalent to height: 645,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: _menuBar(context),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * (590 / MediaQuery.of(context).size.height),
                            // height: 590,
                            child: PageView(
                              controller: _pageController,
                              physics: const ClampingScrollPhysics(),
                              onPageChanged: (int i) {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                setState(() {
                                  activePageIndex = i;
                                });
                              },
                              children: <Widget>[
                                ConstrainedBox(
                                    constraints:
                                    const BoxConstraints.expand(),
                                    child: Obx(() {
                                      var allTasks = todocontroller.todolist;

                                      if (allTasks.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No Task',
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                        );
                                      }

                                      // ✅ Sort High priority tasks to top
                                      List sortedTasks = List.from(allTasks);
                                      sortedTasks.sort((a, b) {
                                        if (a['priority'] == 'High' && b['priority'] != 'High') return -1;
                                        if (a['priority'] != 'High' && b['priority'] == 'High') return 1;
                                        return 0;
                                      });

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          physics: const BouncingScrollPhysics(),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: sortedTasks.length,
                                          itemBuilder: (context, index) {
                                            final task = sortedTasks[index];
                                            String? rawDate = task['targetDate'];
                                            DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                                                ? DateFormat('yyyy-MM-dd').parse(rawDate)
                                                : null;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: _getColorForStatus(
                                                    task['status'],
                                                    task['targetDate'],
                                                    task['targetTime'],
                                                  ),
                                                  border: Border.all(color: Colors.black26),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // ✅ Status Icon
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 10),
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          if (task['status'] == 'Not started') {
                                                            todocontroller.Updatestatus(task['id'].toString());
                                                          }
                                                        },
                                                        child: Icon(
                                                          _getIconForStatus(task['status']),
                                                          color: _getColorForicon(task['status']),
                                                          size: 35,
                                                        ),
                                                      ),
                                                    ),

                                                    // ✅ Task Info
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            task['title'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            task['description'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              const Text('Target: ',
                                                                  style: TextStyle(
                                                                      fontWeight: FontWeight.bold, fontSize: 13)),
                                                              Text(_getDateLabel(targetDate),
                                                                  style: const TextStyle(fontSize: 12)),
                                                              Text(" | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                                  style: const TextStyle(fontSize: 12)),
                                                            ],
                                                          ),
                                                          if (task['completionDate'] != null &&
                                                              task['completionDate'] != "")
                                                            Row(
                                                              children: [
                                                                const Text('Completion: ',
                                                                    style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 13)),
                                                                Text(
                                                                  formatCompletionDate(task['completionDate']),
                                                                  style: const TextStyle(fontSize: 12),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // ✅ Actions Column
                                                    Column(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            final isHigh = task['priority'] == 'High';
                                                            final id = task['id'].toString();
                                                            isHigh
                                                                ? todocontroller.UpdateNAstatus(id)
                                                                : todocontroller.UpdatechangeHigh(id);
                                                          },
                                                          child: Icon(
                                                            task['priority'] == 'High'
                                                                ? Icons.star
                                                                : Icons.star_border,
                                                            size: 22,
                                                            color: task['priority'] == 'High'
                                                                ? const Color(0xFFFA8806)
                                                                : const Color(0xFF0C0C0C),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        if (task['status'] != 'Completed')
                                                          GestureDetector(
                                                            onTap: () {
                                                              Get.to(Edittaskscreen(
                                                                  taskid: task['id'].toString()));
                                                            },
                                                            child: SvgPicture.asset(
                                                              'assets/images/edit.svg',
                                                              width: 24,
                                                              height: 24,
                                                              color: const Color(0xFF1366EE),
                                                            ),
                                                          ),
                                                        const SizedBox(height: 8),
                                                        GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                backgroundColor:
                                                                isDarkMode ? Colors.black : Colors.white,
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const SizedBox(height: 15),
                                                                    Text(
                                                                      "Are you sure you want to delete this item?",
                                                                      style: TextStyle(
                                                                        fontSize: 15,
                                                                        fontFamily: "lato",
                                                                        fontWeight: FontWeight.w500,
                                                                        color: isDarkMode
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 15),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                      MainAxisAlignment.spaceAround,
                                                                      children: [
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: isDarkMode
                                                                                ? Colors.grey[800]
                                                                                : const Color(0xFFB0B0B4),
                                                                          ),
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(),
                                                                          child: const Text("Cancel",
                                                                              style: TextStyle(
                                                                                  fontSize: 13,
                                                                                  color: Colors.white)),
                                                                        ),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                              backgroundColor:
                                                                              const Color(0xFFFF043B)),
                                                                          onPressed: () {
                                                                            Get.back();
                                                                            todocontroller.Deletetask(
                                                                                task['id'].toString());
                                                                          },
                                                                          child: const Text("Delete",
                                                                              style: TextStyle(
                                                                                  fontSize: 13,
                                                                                  color: Colors.white)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: SvgPicture.asset(
                                                            'assets/images/delete.svg',
                                                            width: 24,
                                                            height: 24,
                                                            color: const Color(0xFFEC3C3C),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    })

                                ),
                                ConstrainedBox(
                                    constraints:
                                    const BoxConstraints.expand(),
                                    child: Obx(() {
                                      var completedTasks = todocontroller.todolist
                                          .where((task) => task['status'] == 'Completed')
                                          .toList();

                                      // ✅ Sort High priority tasks to the top
                                      completedTasks.sort((a, b) {
                                        if (a['priority'] == 'High' && b['priority'] != 'High') return -1;
                                        if (a['priority'] != 'High' && b['priority'] == 'High') return 1;
                                        return 0;
                                      });

                                      if (completedTasks.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No Completed Tasks',
                                            style: TextStyle(
                                              fontFamily: 'Gilroy',
                                              color: Colors.indigo,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                            ),
                                          ),
                                        );
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          physics: const BouncingScrollPhysics(),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: completedTasks.length,
                                          itemBuilder: (context, index) {
                                            final task = completedTasks[index];

                                            String? rawDate = task['targetDate'];
                                            DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                                                ? DateFormat('yyyy-MM-dd').parse(rawDate)
                                                : null;

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: _getColorForStatus(
                                                    task['status'],
                                                    task['targetDate'],
                                                    task['targetTime'],
                                                  ),
                                                  border: Border.all(color: Colors.black26),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // ✅ Status Icon (Optional, not interactive in "Completed")
                                                    Icon(
                                                      _getIconForStatus(task['status']),
                                                      color: _getColorForicon(task['status']),
                                                      size: 35,
                                                    ),
                                                    const SizedBox(width: 10),

                                                    // ✅ Task Info
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            task['title'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            task['description'],
                                                            style: const TextStyle(
                                                              fontFamily: 'Gilroy',
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Target: ',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              Text(
                                                                _getDateLabel(targetDate),
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                              Text(
                                                                " | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                          if (task['completionDate'] != null &&
                                                              task['completionDate'] != '')
                                                            Row(
                                                              children: [
                                                                const Text(
                                                                  'Completion: ',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 13,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  formatCompletionDate(task['completionDate']),
                                                                  style: const TextStyle(fontSize: 12),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // ✅ Action Buttons: Priority Toggle & Delete
                                                    Column(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            final isHigh = task['priority'] == 'High';
                                                            final id = task['id'].toString();
                                                            isHigh
                                                                ? todocontroller.UpdateNAstatus(id)
                                                                : todocontroller.UpdatechangeHigh(id);
                                                          },
                                                          child: Icon(
                                                            task['priority'] == 'High'
                                                                ? Icons.star
                                                                : Icons.star_border,
                                                            size: 22,
                                                            color: task['priority'] == 'High'
                                                                ? const Color(0xFFFA8806)
                                                                : const Color(0xFF0C0C0C),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        GestureDetector(
                                                          onTap: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                backgroundColor:
                                                                isDarkMode ? Colors.black : Colors.white,
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    const SizedBox(height: 15),
                                                                    Text(
                                                                      "Are you sure you want to delete this item?",
                                                                      style: TextStyle(
                                                                        fontSize: 15,
                                                                        fontFamily: "Lato",
                                                                        fontWeight: FontWeight.w500,
                                                                        color: isDarkMode
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 15),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                      MainAxisAlignment.spaceAround,
                                                                      children: [
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: isDarkMode
                                                                                ? Colors.grey[800]
                                                                                : const Color(0xFFB0B0B4),
                                                                          ),
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(),
                                                                          child: const Text(
                                                                            "Cancel",
                                                                            style: TextStyle(
                                                                                fontSize: 13,
                                                                                color: Colors.white),
                                                                          ),
                                                                        ),
                                                                        ElevatedButton(
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                            const Color(0xFFFF043B),
                                                                          ),
                                                                          onPressed: () {
                                                                            Get.back();
                                                                            todocontroller.Deletetask(
                                                                                task['id'].toString());
                                                                          },
                                                                          child: const Text(
                                                                            "Delete",
                                                                            style: TextStyle(
                                                                                fontSize: 13,
                                                                                color: Colors.white),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: SvgPicture.asset(
                                                            'assets/images/delete.svg',
                                                            width: 24,
                                                            height: 24,
                                                            color: const Color(0xFFEC3C3C),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    })

                                ),
                                ConstrainedBox(
                                  constraints: const BoxConstraints.expand(),
                                  child: Obx(() {
                                    // Filter tasks with 'Not started' status
                                    var notStartedTasks = todocontroller.todolist
                                        .where((task) => task['status'] == 'Not started')
                                        .toList();

                                    // Sort tasks so that high priority ones come first
                                    notStartedTasks.sort((a, b) {
                                      if (a['priority'] == 'High' && b['priority'] != 'High') {
                                        return -1; // High priority comes before non-high
                                      } else if (a['priority'] != 'High' && b['priority'] == 'High') {
                                        return 1; // Non-high priority comes after high
                                      }
                                      return 0; // If both have the same priority (e.g., both 'Not started')
                                    });

                                    if (notStartedTasks.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No Pending Tasks',
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        physics: const BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount: notStartedTasks.length,
                                        itemBuilder: (context, index) {
                                          final task = notStartedTasks[index];
                                          String? rawDate = task['targetDate'];
                                          DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                                              ? DateFormat('yyyy-MM-dd').parse(rawDate)
                                              : null;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: _getColorForStatus(
                                                  task['status'],
                                                  task['targetDate'],
                                                  task['targetTime'],
                                                ),
                                                border: Border.all(color: Colors.black26),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Status Icon
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (task['status'] == 'Not started') {
                                                        todocontroller.Updatestatus(task['id'].toString());
                                                      }
                                                    },
                                                    child: Icon(
                                                      _getIconForStatus(task['status']),
                                                      color: _getColorForicon(task['status']),
                                                      size: 35,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),

                                                  // Task Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          task['title'],
                                                          style: const TextStyle(
                                                            fontFamily: 'Gilroy',
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: 18,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          task['description'] ?? '',
                                                          style: const TextStyle(
                                                            fontFamily: 'Gilroy',
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 12,
                                                            color: Colors.black,
                                                          ),
                                                          maxLines: 3,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                              'Target: ',
                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                            ),
                                                            Text(
                                                              _getDateLabel(targetDate),
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                            Text(
                                                              " | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                              style: const TextStyle(fontSize: 12),
                                                            ),
                                                          ],
                                                        ),
                                                        if (task['completionDate'] != null && task['completionDate'] != '')
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                'Completion: ',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                              ),
                                                              Text(
                                                                formatCompletionDate(task['completionDate']),
                                                                style: const TextStyle(fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Action Buttons
                                                  Column(
                                                    children: [
                                                      // Priority Icon
                                                      GestureDetector(
                                                        onTap: () {
                                                          final isHigh = task['priority'] == 'High';
                                                          final id = task['id'].toString();
                                                          if (isHigh) {
                                                            todocontroller.UpdateNAstatus(id); // Remove High priority
                                                          } else {
                                                            todocontroller.UpdatechangeHigh(id); // Set to High priority
                                                          }
                                                        },
                                                        child: Icon(
                                                          task['priority'] == 'High' ? Icons.star : Icons.star_border,
                                                          size: 22,
                                                          color: task['priority'] == 'High'
                                                              ? const Color(0xFFFA8806)
                                                              : const Color(0xFF0C0C0C),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Edit Task
                                                      GestureDetector(
                                                        onTap: () {
                                                          Get.to(Edittaskscreen(taskid: task['id'].toString()));
                                                        },
                                                        child: SvgPicture.asset(
                                                          'assets/images/edit.svg',
                                                          width: 24,
                                                          height: 24,
                                                          color: const Color(0xFF1366EE),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Delete Task
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => AlertDialog(
                                                              backgroundColor: isDarkMode ? Colors.black : Colors.white,
                                                              content: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const SizedBox(height: 15),
                                                                  Text(
                                                                    "Are you sure you want to delete this item?",
                                                                    style: TextStyle(
                                                                      fontSize: 15,
                                                                      fontFamily: "Lato",
                                                                      fontWeight: FontWeight.w500,
                                                                      color: isDarkMode ? Colors.white : Colors.black,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 15),
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                    children: [
                                                                      ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: isDarkMode
                                                                              ? Colors.grey[800]
                                                                              : const Color(0xFFB0B0B4),
                                                                        ),
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                        child: const Text("Cancel", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                      ),
                                                                      ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color(0xFFFF043B),
                                                                        ),
                                                                        onPressed: () {
                                                                          Get.back();
                                                                          todocontroller.Deletetask(task['id'].toString());
                                                                        },
                                                                        child: const Text("Delete", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: SvgPicture.asset(
                                                          'assets/images/delete.svg',
                                                          width: 24,
                                                          height: 24,
                                                          color: const Color(0xFFEC3C3C),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                ),
                                ConstrainedBox(
                                  constraints:
                                  const BoxConstraints.expand(),
                                  child: Obx(() {
                                    // Filter tasks with 'High' priority
                                    var priorityTasks =
                                    todocontroller.todolist
                                        .where((task) {
                                      return task['priority'] ==
                                          'High';
                                    }).toList();

                                    if (priorityTasks.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No Priority Tasks',
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            color: Colors.indigo,
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 10.0,
                                          vertical: 10),
                                      child: ListView.builder(
                                        physics:
                                        const BouncingScrollPhysics(),
                                        controller:
                                        _scrollController,
                                        shrinkWrap: true,
                                        itemCount:
                                        priorityTasks.length,
                                        itemBuilder:
                                            (context, index) {
                                          final task =
                                          priorityTasks[index];
                                          String? rawDate =
                                          task['targetDate'];
                                          DateTime? targetDate =
                                          (rawDate != null &&
                                              rawDate
                                                  .isNotEmpty)
                                              ? DateFormat(
                                              'yyyy-MM-dd')
                                              .parse(
                                              rawDate)
                                              : null;

                                          return Padding(
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                                vertical: 4.0),
                                            child: Container(
                                              padding:
                                              const EdgeInsets
                                                  .all(10),
                                              decoration:
                                              BoxDecoration(
                                                color: Colors.yellow
                                                    .shade100,
                                                border: Border.all(
                                                    color: Colors
                                                        .black26),
                                                borderRadius:
                                                BorderRadius
                                                    .circular(
                                                    10),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  // Status Icon
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (task[
                                                      'status'] ==
                                                          'Not started') {
                                                        todocontroller.Updatestatus(
                                                            task['id']
                                                                .toString());
                                                      }
                                                    },
                                                    child: Icon(
                                                      _getIconForStatus(
                                                          task[
                                                          'status']),
                                                      color: _getColorForicon(
                                                          task[
                                                          'status']),
                                                      size: 35,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: 10),

                                                  // Task Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          task['title'] ??
                                                              '',
                                                          style:
                                                          const TextStyle(
                                                            fontFamily:
                                                            'Gilroy',
                                                            fontWeight:
                                                            FontWeight.w500,
                                                            fontSize:
                                                            18,
                                                            color: Colors
                                                                .black,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height:
                                                            6),
                                                        Text(
                                                          task['description'] ??
                                                              '',
                                                          style:
                                                          const TextStyle(
                                                            fontFamily:
                                                            'Gilroy',
                                                            fontWeight:
                                                            FontWeight.w400,
                                                            fontSize:
                                                            12,
                                                            color: Colors
                                                                .black,
                                                          ),
                                                          maxLines:
                                                          3,
                                                          overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                            height:
                                                            6),
                                                        Row(
                                                          children: [
                                                            const Text(
                                                                'Target: ',
                                                                style:
                                                                TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                            Text(
                                                                _getDateLabel(
                                                                    targetDate),
                                                                style:
                                                                const TextStyle(fontSize: 12)),
                                                            Text(
                                                                " | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                                                style:
                                                                const TextStyle(fontSize: 12)),
                                                          ],
                                                        ),
                                                        if (task['completionDate'] !=
                                                            null &&
                                                            task['completionDate'] !=
                                                                '')
                                                          Row(
                                                            children: [
                                                              const Text(
                                                                  'Completion: ',
                                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                              Text(
                                                                formatCompletionDate(task['completionDate']),
                                                                style:
                                                                const TextStyle(fontSize: 12),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Action Buttons
                                                  Column(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          final isHigh =
                                                              task['priority'] ==
                                                                  'High';
                                                          final id =
                                                          task['id']
                                                              .toString();
                                                          isHigh
                                                              ? todocontroller.UpdateNAstatus(
                                                              id)
                                                              : todocontroller.UpdatechangeHigh(
                                                              id);
                                                        },
                                                        child: Icon(
                                                          task['priority'] ==
                                                              'High'
                                                              ? Icons
                                                              .star
                                                              : Icons
                                                              .star_border,
                                                          size: 22,
                                                          color: task['priority'] ==
                                                              'High'
                                                              ? const Color(
                                                              0xFFFA8806)
                                                              : const Color(
                                                              0xFF0C0C0C),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height:
                                                          8),
                                                      if (task[
                                                      'status'] !=
                                                          'Completed')
                                                        GestureDetector(
                                                          onTap:
                                                              () {
                                                            Get.to(Edittaskscreen(
                                                                taskid:
                                                                task['id'].toString()));
                                                          },
                                                          child: SvgPicture
                                                              .asset(
                                                            'assets/images/edit.svg',
                                                            width:
                                                            24,
                                                            height:
                                                            24,
                                                            color: const Color(
                                                                0xFF1366EE),
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                          height:
                                                          8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context:
                                                            context,
                                                            builder:
                                                                (context) =>
                                                                AlertDialog(
                                                                  backgroundColor: isDarkMode
                                                                      ? Colors.black
                                                                      : Colors.white,
                                                                  content:
                                                                  Column(
                                                                    mainAxisSize:
                                                                    MainAxisSize.min,
                                                                    children: [
                                                                      const SizedBox(height: 15),
                                                                      Text(
                                                                        "Are you sure you want to delete this item?",
                                                                        style: TextStyle(
                                                                          fontSize: 15,
                                                                          fontFamily: "Lato",
                                                                          fontWeight: FontWeight.w500,
                                                                          color: isDarkMode ? Colors.white : Colors.black,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 15),
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                        children: [
                                                                          ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: isDarkMode ? Colors.grey[800] : const Color(0xFFB0B0B4),
                                                                            ),
                                                                            onPressed: () => Navigator.of(context).pop(),
                                                                            child: const Text("Cancel", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                          ),
                                                                          ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF043B)),
                                                                            onPressed: () {
                                                                              Get.back();
                                                                              todocontroller.Deletetask(task['id'].toString());
                                                                            },
                                                                            child: const Text("Delete", style: TextStyle(fontSize: 13, color: Colors.white)),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                          );
                                                        },
                                                        child: SvgPicture
                                                            .asset(
                                                          'assets/images/delete.svg',
                                                          width: 24,
                                                          height:
                                                          24,
                                                          color: const Color(
                                                              0xFFEC3C3C),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : Obx(() {
                  // Filter tasks based on the search query
                  var sortedTasks = todocontroller.todolist
                      .where((task) => task['title']
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                      .toList();

                  return sortedTasks.isEmpty
                      ? const Center(
                    child: Text(
                      'No Task Found',
                      style: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: sortedTasks.length,
                      itemBuilder: (context, index) {
                        final task = sortedTasks[index];
                        String? rawDate = task['targetDate'];
                        DateTime? targetDate = (rawDate != null && rawDate.isNotEmpty)
                            ? DateFormat('yyyy-MM-dd').parse(rawDate)
                            : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
                            decoration: BoxDecoration(
                              color: _getColorForStatus(
                                task['status'],
                                task['targetDate'],
                                task['targetTime'],
                              ),
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ Status Icon
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (task['status'] == 'Not started') {
                                        todocontroller.Updatestatus(task['id'].toString());
                                      }
                                    },
                                    child: Icon(
                                      _getIconForStatus(task['status']),
                                      color: _getColorForicon(task['status']),
                                      size: 35,
                                    ),
                                  ),
                                ),

                                // ✅ Task Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['title'],
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        task['description'],
                                        style: const TextStyle(
                                          fontFamily: 'Gilroy',
                                          color: Colors.black,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Text('Target: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text(_getDateLabel(targetDate),
                                              style: const TextStyle(fontSize: 12)),
                                          Text(" | ${convertTo12HourFormat(task['targetTime'] ?? '')}",
                                              style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                      if (task['completionDate'] != null &&
                                          task['completionDate'] != "")
                                        Row(
                                          children: [
                                            const Text('Completion: ',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            Text(
                                              formatCompletionDate(task['completionDate']),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                // ✅ Actions Column
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        final isHigh = task['priority'] == 'High';
                                        final id = task['id'].toString();
                                        isHigh
                                            ? todocontroller.UpdateNAstatus(id)
                                            : todocontroller.UpdatechangeHigh(id);
                                      },
                                      child: Icon(
                                        task['priority'] == 'High'
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 22,
                                        color: task['priority'] == 'High'
                                            ? const Color(0xFFFA8806)
                                            : const Color(0xFF0C0C0C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (task['status'] != 'Completed')
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(Edittaskscreen(
                                              taskid: task['id'].toString()));
                                        },
                                        child: SvgPicture.asset(
                                          'assets/images/edit.svg',
                                          width: 24,
                                          height: 24,
                                          color: const Color(0xFF1366EE),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor:
                                            isDarkMode ? Colors.black : Colors.white,
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(height: 15),
                                                Text(
                                                  "Are you sure you want to delete this item?",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: "lato",
                                                    fontWeight: FontWeight.w500,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: isDarkMode
                                                            ? Colors.grey[800]
                                                            : const Color(0xFFB0B0B4),
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.of(context).pop(),
                                                      child: const Text("Cancel",
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: Colors.white)),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          const Color(0xFFFF043B)),
                                                      onPressed: () {
                                                        Get.back();
                                                        todocontroller.Deletetask(
                                                            task['id'].toString());
                                                      },
                                                      child: const Text("Delete",
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              color: Colors.white)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: SvgPicture.asset(
                                        'assets/images/delete.svg',
                                        width: 24,
                                        height: 24,
                                        color: const Color(0xFFEC3C3C),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );;
                }),
              ],
            ),
          )),
    );
  }

  Widget _menuBar(BuildContext context) {
    return Container(
      width: 380.0,
      height: 47.0,
      decoration: const BoxDecoration(
        color: Color(0XFFE0E0E0),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: Onnalll,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: (activePageIndex == 0)
                    ? const BoxDecoration(
                  color: Color(0xFF374A8B),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
                    : null,
                child: Text(
                  "All",
                  style: (activePageIndex == 0)
                      ? const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)
                      : const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: oncompleted,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: (activePageIndex == 1)
                    ? const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
                    : null,
                child: Text(
                  "Completed",
                  style: (activePageIndex == 1)
                      ? const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)
                      : const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: Onnotstared,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: (activePageIndex == 2)
                    ? const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                )
                    : null,
                child: Text(
                  "Not Started",
                  style: (activePageIndex == 2)
                      ? const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)
                      : const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              onTap: Onprority,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: (activePageIndex == 3)
                      ? const BoxDecoration(
                    color: Color(0xFFF47B19),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  )
                      : null,
                  child: Icon(
                      activePageIndex == 3 ? Icons.star : Icons.star_border,
                      color: activePageIndex == 3
                          ? Colors.white
                          : Color(0xFFFA8806))
                // Text(
                //   "Priority",
                //   style: (activePageIndex == 3) ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold) : const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void Onnalll() {
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void oncompleted() {
    _pageController.animateToPage(1,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void Onnotstared() {
    _pageController.animateToPage(2,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }

  void Onprority() {
    _pageController.animateToPage(3,
        duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
  }
  TimeOfDay _parseTime(String timeStr) {
    final format = DateFormat.jm(); // e.g. 5:08 PM
    final dt = format.parse(timeStr);
    return TimeOfDay.fromDateTime(dt);
  }


  Color _getColorForStatus(String status, String? targetDateStr, String? targetTimeStr) {
    final now = DateTime.now();
    bool isOverdue = false;

    if (targetDateStr != null && targetDateStr.isNotEmpty) {
      try {
        final targetDate = DateFormat('yyyy-MM-dd').parse(targetDateStr);
        DateTime targetDateTime;

        if (targetTimeStr != null && targetTimeStr.isNotEmpty) {
          final timeParts = targetTimeStr.split(':');
          int hour = int.tryParse(timeParts[0]) ?? 0;
          int minute = 0;

          if (timeParts.length > 1) {
            minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;
          }

          bool isPM = targetTimeStr.toLowerCase().contains('pm');
          if (isPM && hour < 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;

          targetDateTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            hour,
            minute,
          );
        } else {
          // Default to midnight if time not available
          targetDateTime = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          );
        }



        // Mark overdue if now is after the target datetime
        if (now.isAfter(targetDateTime)) {
          isOverdue = true;
        }
      } catch (e) {
        debugPrint('Error parsing date/time: $e');
      }
    }

    switch (status) {
      case 'Completed':
        return Colors.green.shade100;
      case 'Not started':
        return isOverdue ? Colors.red.shade200 : Colors.white;
      default:
        return isOverdue ? Colors.red.shade200 : Colors.orange.shade100;
    }
  }





  Color _getColorForicon(String status) {
    switch (status) {
      case 'Completed':
        return Color(0xFF1B5E20);
      case 'Not started':
        return Color(0xFFB71C1C);
      default:
        return Color(0xFFE65100); // Default color for other statuses
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Not Started':
        return Icons.radio_button_unchecked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getDateLabel(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == tomorrow) {
      return "Tomorrow";
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  String convertTo12HourFormat(String time) {
    try {
      final DateFormat inputFormat =
      DateFormat("HH:mm"); // Input format: 24-hour format
      final DateFormat outputFormat =
      DateFormat("hh:mm a"); // Output format: 12-hour format with AM/PM
      DateTime parsedTime = inputFormat.parse(time);
      return outputFormat.format(parsedTime);
    } catch (e) {
      return time; // If parsing fails, return the original time string
    }
  }

  String formatCompletionDate(String completionDate) {
    try {
      // Input format: "yyyy-MM-dd HH:mm:ss"
      final DateFormat inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

      // Output format: "MMM dd, yyyy hh:mm a" (e.g., April 03, 2025, 12:26 PM)
      final DateFormat outputFormat = DateFormat("MMMM dd, yyyy hh:mm a");

      DateTime parsedDate =
      inputFormat.parse(completionDate); // Parse the input date
      return outputFormat
          .format(parsedDate); // Format and return the formatted date
    } catch (e) {
      return completionDate; // If parsing fails, return the original date string
    }
  }

  String datastring(String dateString) {
    // DateTime parsedDateTime = DateTime.parse(dateString);
    DateTime utcDateTime = DateTime.parse(dateString);

    // Convert UTC time to IST (UTC +05:30)
    DateTime istDateTime = utcDateTime.add(Duration(hours: 5, minutes: 30));

    // Format IST DateTime to desired string format
    String formattedDateTime =
    // DateFormat('dd/MM/yy hh:mm:ss a').format(istDateTime);
    DateFormat('dd/MM/yy ').format(istDateTime);

    return formattedDateTime;
  }
}

class AppStrings {
  static const String taskTitle = 'Tasks';
  static const String addTaskButton = 'Add Task';
  static const String taskStatus = 'Task Status !';
  static const String noTaskMessage = 'No';
  static const String taskForToday = 'Task for Today!';
  static const String todayTab = 'Today';
  static const String allTab = 'All';
  static const String completedTab = 'Completed';
}
