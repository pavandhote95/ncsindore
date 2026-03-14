import 'dart:convert';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';
import 'package:cuickdevuser/controller/pivotcontroller.dart';
import 'package:cuickdevuser/screen/ZoomableHtml.dart';
import 'package:cuickdevuser/screen/ZoomableSvg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' show parse;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'Menucontroller.dart';

class Pivotchartscreen extends StatefulWidget {
  final String appurl;
  final String menutitle;
  final String formID;

  const Pivotchartscreen(
      {super.key,
      required this.appurl,
      required this.menutitle,
      required this.formID});

  @override
  State<Pivotchartscreen> createState() => _PivotchartscreenState();
}

class _PivotchartscreenState extends State<Pivotchartscreen> {
  final List<String> _chartTypes = ['Table', 'Line', 'Bar', 'Area'];
  final List<String> _valueRanges = [
    'Sum',
    'Mean',
    'Count',
    'Min',
    'Max',
    'Std',
    'Median'
  ];
  String? categoryType = '';
  String? groupType = '';
  String? iwantvalue;

  String? numeric = '';
  String? _selectedValueRange = '';
  List<String> iwantselectedValues = [];
  List<String> groupselectvalue = [];
  List<String> categoryselectvalue = [];
  bool _showTotal = false;
  String? selectedDayOnly;
  String? selectedMonthOnly;
  int touchedIndex = -1;

  final Map<String, String> chartImages = {
    'Table': 'assets/Backgrounds/tablechart.png',
    'Line': 'assets/Backgrounds/line-chart.png',
    'Bar': 'assets/Backgrounds/bar-graph.png',
    'Area': 'assets/Backgrounds/pie-chart.png',
  };
  List<Color> customColors = const [
    Color(0xFF495057), // #1E3E62
    Color(0xFF344C64), // #0B192C
    Color(0xFF087990), // #000000
    Color(0xFF451952), // #451952
    Color(0xFF662549), // #662549
    Color(0xFFAE445A), // #AE445A
    Color(0xFF57A6A1),
    Color(0xFFA87C7C),
    Color(0xFFFF6500), // #F39F5A
  ];
  final WelcomeController controller = Get.put(WelcomeController());
  final Pivotcontroller pivotcontroller = Get.put(Pivotcontroller());
  final Menucontroller menucontroller = Get.put(Menucontroller());
  bool showfilter = false;
  List<Map<String, String>> addedFilters = []; // name, condition, value
  final TextEditingController _searchController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void dispose() {
    super.dispose();
    Get.delete<Pivotcontroller>();
    // Force portrait mode when the screen is opened
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    pivotcontroller.selectedChartType.value = "";
  }

  @override
  void initState() {
    super.initState();
    pivotcontroller.GetForm_API(widget.formID);
    _searchController.addListener(() {
      setState(() {
        _isButtonEnabled = _searchController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    return Obx(() => Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        floatingActionButton: FloatingActionButton(
          onPressed: pivotcontroller.toggleOrientation,
          backgroundColor: isDarkMode
              ? Colors.grey[850]
              : const Color(0xFF243262), // Your custom color
          child: Icon(
            pivotcontroller.isPortrait.value
                ? Icons.screen_rotation
                : Icons.screen_lock_rotation,
            color: Colors.white,
          ),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: [
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor:
                                  isDarkMode ? Colors.grey[800] : Colors.white,
                              isScrollControlled: true,
                              isDismissible: false,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                       
                                  builder: (context, setModalState) {
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: SingleChildScrollView(
                                        child: Container(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.white,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.75,
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 20),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2.0,
                                                ),
                                                child: Obx(() {
                                                  final fieldItems =
                                                      pivotcontroller
                                                          .iwantlist
                                                          .map<
                                                              DropdownMenuItem<
                                                                  String>>((item) {
                                                    String label = item['label']
                                                        .toString();
                                                    String type =
                                                        item['type'].toString();
                                                    String firstLetter = [
                                                      'object',
                                                      'map',
                                                      'list'
                                                    ].contains(
                                                            type.toLowerCase())
                                                        ? 'C'
                                                        : (type.isNotEmpty
                                                            ? type[0]
                                                                .toUpperCase()
                                                            : '?');
                                                    Color avatarColor;

                                                    if ([
                                                      'object',
                                                      'map',
                                                      'list'
                                                    ].contains(
                                                        type.toLowerCase())) {
                                                      firstLetter = 'C';
                                                      avatarColor = const Color(
                                                          0xFF1976D2);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'date') {
                                                      firstLetter = 'D';
                                                      avatarColor = const Color(
                                                          0xFFFBC02D);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'text') {
                                                      firstLetter = 'T';
                                                      avatarColor = const Color(
                                                          0xFF2E7D32);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'email') {
                                                      firstLetter = 'E';
                                                      avatarColor = const Color(
                                                          0xFF2E7D32);
                                                    } else if (type
                                                                .toLowerCase() ==
                                                            'number' ||
                                                        type.toLowerCase() ==
                                                            'expression' ||
                                                        type.toLowerCase() ==
                                                            'decimal' ||
                                                        type.toLowerCase() ==
                                                            'long') {
                                                      firstLetter = 'N';
                                                      avatarColor = const Color(
                                                          0xFF1976D2);
                                                    } else {
                                                      firstLetter =
                                                          type.isNotEmpty
                                                              ? type[0]
                                                                  .toUpperCase()
                                                              : '?';
                                                      avatarColor = Colors.grey;
                                                    }

                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: label,
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 10,
                                                            backgroundColor:
                                                                avatarColor,
                                                            child: Text(
                                                              firstLetter,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                              maxWidth: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.58,
                                                            ),
                                                            child: Text(
                                                              label,
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList();

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                DropdownButtonFormField<
                                                                    String>(
                                                              hint: Text(
                                                                'I want',
                                                                style:
                                                                    TextStyle(
                                                                  color: isDarkMode
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              dropdownColor:
                                                                  isDarkMode
                                                                      ? Colors.grey[
                                                                          800]
                                                                      : Colors
                                                                          .white,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelStyle:
                                                                    TextStyle(
                                                                  color: isDarkMode
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                hoverColor: Colors
                                                                    .indigo
                                                                    .shade200,
                                                                fillColor: isDarkMode
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  borderSide:
                                                                      const BorderSide(
                                                                          color:
                                                                              Color(0xFF2962FF)),
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              value: fieldItems.any(
                                                                      (element) =>
                                                                          element
                                                                              .value ==
                                                                          iwantvalue)
                                                                  ? iwantvalue
                                                                  : null,
                                                              items: fieldItems,
                                                              selectedItemBuilder:
                                                                  (BuildContext
                                                                      context) {
                                                                return pivotcontroller
                                                                    .iwantlist
                                                                    .map<Widget>(
                                                                        (item) {
                                                                  String label =
                                                                      item['label']
                                                                          .toString();
                                                                  return ConstrainedBox(
                                                                    constraints:
                                                                        BoxConstraints(
                                                                      maxWidth: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.55, // adjust width
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        CircleAvatar(
                                                                          radius:
                                                                              10,
                                                                          backgroundColor:
                                                                              Colors.grey, // optional: same logic as above
                                                                          child:
                                                                              Text(
                                                                            label.isNotEmpty
                                                                                ? label[0].toUpperCase()
                                                                                : '?',
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            label,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: isDarkMode ? Colors.white : Colors.black,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }).toList();
                                                              },
                                                              onChanged:
                                                                  (value) {
                                                                setModalState(
                                                                    () {
                                                                  iwantvalue =
                                                                      value;
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Tooltip(
                                                            preferBelow: false,
                                                            verticalOffset: 20,
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        50),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        10),
                                                            triggerMode:
                                                                TooltipTriggerMode
                                                                    .tap,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 1),
                                                            ),
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            message:
                                                                "Choose numerical fields for aggregation like Sum of Sales, Count of Orders, or Average Quantity.",
                                                            child: SizedBox(
                                                              width: 20,
                                                              child: Icon(
                                                                Icons
                                                                    .info_outline,
                                                                size: 20,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .blueAccent
                                                                    : Appcolorblue,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          GestureDetector(
                                                            child: CircleAvatar(
                                                                radius: 18,
                                                                backgroundColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .blueAccent
                                                                        : Appcolorblue,
                                                                child:
                                                                    const Icon(
                                                                  Icons.add,
                                                                  size: 15,
                                                                  color: Colors
                                                                      .white,
                                                                )),
                                                            onTap: () {
                                                              if (_selectedValueRange ==
                                                                  "") {
                                                                CherryToast
                                                                    .error(
                                                                  backgroundColor:
                                                                      const Color(
                                                                          0xFFF8D0D9),
                                                                  animationType:
                                                                      AnimationType
                                                                          .fromLeft,
                                                                  animationDuration:
                                                                      Durations
                                                                          .short1,
                                                                  title: const Text(
                                                                      "Please select an aggregation value first.",
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.black)),
                                                                ).show(Get
                                                                    .overlayContext!);

                                                                return;
                                                              }
                                                              if (iwantvalue !=
                                                                      "" &&
                                                                  !iwantselectedValues
                                                                      .contains(
                                                                          iwantvalue)) {
                                                                setState(() {
                                                                  iwantselectedValues
                                                                      .add(
                                                                          iwantvalue!);
                                                                });
                                                                setModalState(
                                                                    () {});
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      Wrap(
                                                        spacing: 8,
                                                        direction:
                                                            Axis.horizontal,
                                                        children:
                                                            iwantselectedValues
                                                                .map((value) {
                                                          return Chip(
                                                            label: Text(
                                                              "$value (${_selectedValueRange ?? ''})",
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                            ),
                                                            onDeleted: () {
                                                              setState(() {
                                                                iwantselectedValues
                                                                    .remove(
                                                                        value);
                                                              });
                                                              setModalState(
                                                                  () {});
                                                            },
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          DropdownButtonFormField<
                                                              String>(
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        hint: Text(
                                                          'Select aggregation',
                                                          style: TextStyle(
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        dropdownColor:
                                                            isDarkMode
                                                                ? Colors
                                                                    .grey[800]
                                                                : Colors.white,
                                                        decoration:
                                                            InputDecoration(
                                                          labelStyle: TextStyle(
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          fillColor: isDarkMode
                                                              ? Colors.black
                                                              : Colors.white,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Color(
                                                                        0xFF2962FF)),
                                                          ),
                                                        ),
                                                        value: _valueRanges
                                                                .contains(
                                                                    _selectedValueRange)
                                                            ? _selectedValueRange
                                                            : null,
                                                        onChanged:
                                                            (String? newValue) {
                                                          setState(() {
                                                            _selectedValueRange =
                                                                newValue;
                                                          });
                                                        },
                                                        items: _valueRanges
                                                            .toSet()
                                                            .toList()
                                                            .map<
                                                                DropdownMenuItem<
                                                                    String>>((String
                                                                chartType) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: chartType,
                                                            child: Text(
                                                              chartType,
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Tooltip(
                                                      preferBelow: false,
                                                      verticalOffset: 20,
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 50),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 20,
                                                          vertical: 10),
                                                      triggerMode:
                                                          TooltipTriggerMode
                                                              .tap,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black87,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                            color: Colors.white,
                                                            width: 1),
                                                      ),
                                                      textStyle:
                                                          const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      message:
                                                          "Select an aggregation option to group and summarize data effectively.",
                                                      child: SizedBox(
                                                        width: 20,
                                                        child: Icon(
                                                          Icons.info_outline,
                                                          size: 20,
                                                          color: isDarkMode
                                                              ? Colors
                                                                  .blueAccent
                                                              : Appcolorblue,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2.0,
                                                ),
                                                child: Obx(() {
                                                  final fieldItems =
                                                      pivotcontroller
                                                          .groupbylist
                                                          .map<
                                                              DropdownMenuItem<
                                                                  String>>((item) {
                                                    String label = item['label']
                                                        .toString();
                                                    String type =
                                                        item['type'].toString();
                                                    String firstLetter = [
                                                      'object',
                                                      'map',
                                                      'list'
                                                    ].contains(
                                                            type.toLowerCase())
                                                        ? 'C'
                                                        : (type.isNotEmpty
                                                            ? type[0]
                                                                .toUpperCase()
                                                            : '?');
                                                    Color avatarColor;

                                                    if ([
                                                      'object',
                                                      'map',
                                                      'list'
                                                    ].contains(
                                                        type.toLowerCase())) {
                                                      firstLetter = 'C';
                                                      avatarColor = const Color(
                                                          0xFF1976D2);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'date') {
                                                      firstLetter = 'D';
                                                      avatarColor = const Color(
                                                          0xFFFBC02D);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'text') {
                                                      firstLetter = 'T';
                                                      avatarColor = const Color(
                                                          0xFF2E7D32);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'email') {
                                                      firstLetter = 'E';
                                                      avatarColor = const Color(
                                                          0xFF2E7D32);
                                                    } else if (type
                                                                .toLowerCase() ==
                                                            'number' ||
                                                        type.toLowerCase() ==
                                                            'expression' ||
                                                        type.toLowerCase() ==
                                                            'decimal' ||
                                                        type.toLowerCase() ==
                                                            'long') {
                                                      firstLetter = 'N';
                                                      avatarColor = const Color(
                                                          0xFF1976D2);
                                                    } else {
                                                      firstLetter =
                                                          type.isNotEmpty
                                                              ? type[0]
                                                                  .toUpperCase()
                                                              : '?';
                                                      avatarColor = Colors.grey;
                                                    }
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: label,
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 10,
                                                            backgroundColor:
                                                                avatarColor,
                                                            child: Text(
                                                              firstLetter,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                              maxWidth: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.58,
                                                            ),
                                                            child: Text(
                                                              label,
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList();

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                DropdownButtonFormField<
                                                                    String>(
                                                              isExpanded: true,
                                                              hint: Text(
                                                                'Group by',
                                                                style:
                                                                    TextStyle(
                                                                  color: isDarkMode
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              dropdownColor:
                                                                  isDarkMode
                                                                      ? Colors.grey[
                                                                          800]
                                                                      : Colors
                                                                          .white,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelStyle:
                                                                    TextStyle(
                                                                  color: isDarkMode
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                hoverColor: Colors
                                                                    .indigo
                                                                    .shade200,
                                                                fillColor: isDarkMode
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  borderSide:
                                                                      const BorderSide(
                                                                          color:
                                                                              Color(0xFF2962FF)),
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              value: null,
                                                              items: fieldItems,
                                                              selectedItemBuilder:
                                                                  (BuildContext
                                                                      context) {
                                                                return pivotcontroller
                                                                    .groupbylist
                                                                    .map<Widget>(
                                                                        (item) {
                                                                  String label =
                                                                      item['label']
                                                                          .toString();
                                                                  return ConstrainedBox(
                                                                    constraints:
                                                                        BoxConstraints(
                                                                      maxWidth: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.55,
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        CircleAvatar(
                                                                          radius:
                                                                              10,
                                                                          backgroundColor:
                                                                              Colors.grey,
                                                                          child:
                                                                              Text(
                                                                            label.isNotEmpty
                                                                                ? label[0].toUpperCase()
                                                                                : '?',
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            label,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: isDarkMode ? Colors.white : Colors.black,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }).toList();
                                                              },
                                                              onChanged:
                                                                  (value) {
                                                                setModalState(
                                                                    () {
                                                                  groupType =
                                                                      value;
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Tooltip(
                                                            preferBelow: false,
                                                            verticalOffset: 20,
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        50),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        10),
                                                            triggerMode:
                                                                TooltipTriggerMode
                                                                    .tap,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 1),
                                                            ),
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            message:
                                                                "Choose categorical fields which is grater then 10 ( 10 >) like Region, Product Category, or Date to group data.",
                                                            child: SizedBox(
                                                              width: 20,
                                                              child: Icon(
                                                                Icons
                                                                    .info_outline,
                                                                size: 20,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .blueAccent
                                                                    : Appcolorblue,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          GestureDetector(
                                                            onTap: () {
                                                              if (groupType !=
                                                                      "" &&
                                                                  !groupselectvalue
                                                                      .contains(
                                                                          groupType)) {
                                                                setState(() {
                                                                  groupselectvalue
                                                                      .add(
                                                                          groupType!);
                                                                });
                                                                setModalState(
                                                                    () {});
                                                              }
                                                            },
                                                            child: CircleAvatar(
                                                                radius: 18,
                                                                backgroundColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .blueAccent
                                                                        : Appcolorblue,
                                                                child:
                                                                    const Icon(
                                                                  Icons.add,
                                                                  size: 15,
                                                                  color: Colors
                                                                      .white,
                                                                )),
                                                          ),
                                                        ],
                                                      ),
                                                      Wrap(
                                                        spacing: 8,
                                                        direction:
                                                            Axis.horizontal,
                                                        children:
                                                            groupselectvalue
                                                                .map((value) {
                                                          return Chip(
                                                            label: Text(value,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            12)),
                                                            onDeleted: () {
                                                              setState(() {
                                                                groupselectvalue
                                                                    .remove(
                                                                        value);
                                                              });
                                                              setModalState(
                                                                  () {});
                                                            },
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 2.0,
                                                ),
                                                child: Obx(() {
                                                  final fieldItems =
                                                      pivotcontroller
                                                          .catergorylist
                                                          .map<
                                                              DropdownMenuItem<
                                                                  String>>((item) {
                                                    String label = item['label']
                                                        .toString();
                                                    String type =
                                                        item['type'].toString();
                                                    String firstLetter = [
                                                      'object',
                                                      'map',
                                                      'list'
                                                    ].contains(
                                                            type.toLowerCase())
                                                        ? 'C'
                                                        : (type.isNotEmpty
                                                            ? type[0]
                                                                .toUpperCase()
                                                            : '?');
                                                    Color avatarColor;

                                                    if ([
                                                      'object',
                                                      'map',
                                                      'list'
                                                    ].contains(
                                                        type.toLowerCase())) {
                                                      firstLetter = 'C';
                                                      avatarColor = const Color(
                                                          0xFF1976D2);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'date') {
                                                      firstLetter = 'D';
                                                      avatarColor = const Color(
                                                          0xFFFBC02D);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'text') {
                                                      firstLetter = 'T';
                                                      avatarColor = const Color(
                                                          0xFF2E7D32);
                                                    } else if (type
                                                            .toLowerCase() ==
                                                        'email') {
                                                      firstLetter = 'E';
                                                      avatarColor = const Color(
                                                          0xFF2E7D32);
                                                    } else if (type
                                                                .toLowerCase() ==
                                                            'number' ||
                                                        type.toLowerCase() ==
                                                            'expression' ||
                                                        type.toLowerCase() ==
                                                            'decimal' ||
                                                        type.toLowerCase() ==
                                                            'long') {
                                                      firstLetter = 'N';
                                                      avatarColor = const Color(
                                                          0xFF1976D2);
                                                    } else {
                                                      firstLetter =
                                                          type.isNotEmpty
                                                              ? type[0]
                                                                  .toUpperCase()
                                                              : '?';
                                                      avatarColor = Colors.grey;
                                                    }
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: label,
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 10,
                                                            backgroundColor:
                                                                avatarColor,
                                                            child: Text(
                                                              firstLetter,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                              maxWidth: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.58,
                                                            ),
                                                            child: Text(
                                                              label,
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList();

                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                DropdownButtonFormField<
                                                                    String>(
                                                              isExpanded: true,
                                                              hint: Text(
                                                                'Category by',
                                                                style:
                                                                    TextStyle(
                                                                  color: isDarkMode
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              dropdownColor:
                                                                  isDarkMode
                                                                      ? Colors.grey[
                                                                          800]
                                                                      : Colors
                                                                          .white,
                                                              decoration:
                                                                  InputDecoration(
                                                                labelStyle:
                                                                    TextStyle(
                                                                  color: isDarkMode
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                hoverColor: Colors
                                                                    .indigo
                                                                    .shade200,
                                                                fillColor: isDarkMode
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  borderSide:
                                                                      const BorderSide(
                                                                          color:
                                                                              Color(0xFF2962FF)),
                                                                ),
                                                              ),
                                                              style: TextStyle(
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              value: fieldItems.any(
                                                                      (element) =>
                                                                          element
                                                                              .value ==
                                                                          categoryType)
                                                                  ? categoryType
                                                                  : null,
                                                              items: fieldItems,
                                                              selectedItemBuilder:
                                                                  (BuildContext
                                                                      context) {
                                                                return pivotcontroller
                                                                    .catergorylist
                                                                    .map<Widget>(
                                                                        (item) {
                                                                  String label =
                                                                      item['label']
                                                                          .toString();
                                                                  return ConstrainedBox(
                                                                    constraints:
                                                                        BoxConstraints(
                                                                      maxWidth: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.55,
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        CircleAvatar(
                                                                          radius:
                                                                              10,
                                                                          backgroundColor:
                                                                              Colors.grey,
                                                                          child:
                                                                              Text(
                                                                            label.isNotEmpty
                                                                                ? label[0].toUpperCase()
                                                                                : '?',
                                                                            style:
                                                                                const TextStyle(
                                                                              color: Colors.white,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                4),
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            label,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                            style:
                                                                                TextStyle(
                                                                              color: isDarkMode ? Colors.white : Colors.black,
                                                                              fontSize: 10,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }).toList();
                                                              },
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  categoryType =
                                                                      value;
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Tooltip(
                                                            preferBelow: false,
                                                            verticalOffset: 20,
                                                            margin:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        50),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        20,
                                                                    vertical:
                                                                        10),
                                                            triggerMode:
                                                                TooltipTriggerMode
                                                                    .tap,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 1),
                                                            ),
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            message:
                                                                "Use categorical fields  which is lesser then 10 ( > 10 ) with fewer unique values to make comparisons (e.g., Customer Type, Year).",
                                                            child: SizedBox(
                                                              width: 20,
                                                              child: Icon(
                                                                Icons
                                                                    .info_outline,
                                                                size: 20,
                                                                color: isDarkMode
                                                                    ? Colors
                                                                        .blueAccent
                                                                    : Appcolorblue,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          GestureDetector(
                                                            onTap: () {
                                                              if (categoryType !=
                                                                      "" &&
                                                                  !categoryselectvalue
                                                                      .contains(
                                                                          categoryType)) {
                                                                setState(() {
                                                                  categoryselectvalue
                                                                      .add(
                                                                          categoryType!);
                                                                });
                                                                setModalState(
                                                                    () {});
                                                              }
                                                            },
                                                            child: CircleAvatar(
                                                                radius: 18,
                                                                backgroundColor:
                                                                    isDarkMode
                                                                        ? Colors
                                                                            .blueAccent
                                                                        : Appcolorblue,
                                                                child:
                                                                    const Icon(
                                                                  Icons.add,
                                                                  size: 15,
                                                                  color: Colors
                                                                      .white,
                                                                )),
                                                          ),
                                                        ],
                                                      ),
                                                      Wrap(
                                                        spacing: 8,
                                                        direction:
                                                            Axis.horizontal,
                                                        children:
                                                            categoryselectvalue
                                                                .map((value) {
                                                          return Chip(
                                                            label: Text(value,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            12)),
                                                            onDeleted: () {
                                                              setState(() {
                                                                categoryselectvalue
                                                                    .remove(
                                                                        value);
                                                              });
                                                              setModalState(
                                                                  () {});
                                                            },
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    flex: 5,
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 2.0,
                                                          horizontal: 5),
                                                      child:
                                                          DropdownButtonFormField<
                                                              String>(
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        hint: Text(
                                                          'Select Chart',
                                                          style: TextStyle(
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        dropdownColor:
                                                            isDarkMode
                                                                ? Colors
                                                                    .grey[800]
                                                                : Colors.white,
                                                        decoration:
                                                            InputDecoration(
                                                          labelStyle: TextStyle(
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          fillColor: isDarkMode
                                                              ? Colors.black
                                                              : Colors.white,
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            borderSide:
                                                                const BorderSide(
                                                                    color: Color(
                                                                        0xFF2962FF)),
                                                          ),
                                                        ),
                                                        value: pivotcontroller
                                                                    .selectedChartType
                                                                    .value
                                                                    .isEmpty ==
                                                                true
                                                            ? null
                                                            : pivotcontroller
                                                                .selectedChartType
                                                                .value,
                                                        onChanged:
                                                            (String? newValue) {
                                                          pivotcontroller
                                                                  .selectedChartType
                                                                  .value =
                                                              newValue ?? '';
                                                        },
                                                        items: _chartTypes.map<
                                                            DropdownMenuItem<
                                                                String>>((String
                                                            chartType) {
                                                          return DropdownMenuItem<
                                                              String>(
                                                            value: chartType,
                                                            child: Row(
                                                              children: [
                                                                Image.asset(
                                                                  chartImages[
                                                                      chartType]!,
                                                                  width: 20,
                                                                  height: 20,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Text(chartType,
                                                                    style:
                                                                        TextStyle(
                                                                      color: isDarkMode
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    )),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: CheckboxListTile(
                                                      activeColor:
                                                          Colors.blueAccent,
                                                      fillColor:
                                                          WidgetStatePropertyAll(
                                                              isDarkMode
                                                                  ? const Color(
                                                                      0xFF2962FF)
                                                                  : const Color(
                                                                      0xFFAFAAAA)),
                                                      title: Text(
                                                        "Show Total",
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      value: _showTotal,
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          _showTotal =
                                                              value ?? false;
                                                        });
                                                        setModalState(() {});
                                                      },
                                                      checkColor: isDarkMode
                                                          ? Colors.white
                                                          : Appcolorblue,
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Center(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        pivotcontroller
                                                            .selectedChartType
                                                            .value = "";
                                                        _selectedValueRange =
                                                            "";
                                                        groupType = "";
                                                        iwantvalue = "";
                                                        categoryType = "";
                                                        pivotcontroller
                                                            .update();
                                                        groupselectvalue
                                                            .clear();
                                                        categoryselectvalue
                                                            .clear();
                                                        iwantselectedValues
                                                            .clear();
                                                        Get.back();
                                                      },
                                                      child: Container(
                                                          height: 45,
                                                          width: 120,
                                                          decoration:
                                                              BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                    color: isDarkMode
                                                                        ? const Color(
                                                                            0xFF4F76E2)
                                                                        : const Color(
                                                                            0xFF1A237E),
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5)),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons.close,
                                                                size: 25,
                                                                color: isDarkMode
                                                                    ? const Color(
                                                                        0xFF4F76E2)
                                                                    : const Color(
                                                                        0xFF1A237E),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Text(
                                                                'Cancel',
                                                                style: TextStyle(
                                                                    color: isDarkMode
                                                                        ? const Color(
                                                                            0xFF4F76E2)
                                                                        : const Color(
                                                                            0xFF1A237E),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        'Lato',
                                                                    fontSize:
                                                                        15),
                                                              )
                                                            ],
                                                          )),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        if (pivotcontroller
                                                                .isuserFilter
                                                                .value !=
                                                            0) {
                                                          pivotcontroller.GetdataList(
                                                                  pivotcontroller
                                                                      .code
                                                                      .value
                                                                      .toString(),
                                                                  pivotcontroller
                                                                      .appCode
                                                                      .value
                                                                      .toString())
                                                              .then((value) {
                                                            if (pivotcontroller
                                                                    .selectedChartType
                                                                    .toLowerCase() ==
                                                                "table") {
                                                              pivotcontroller
                                                                  .Getpivotchart(
                                                                "html",
                                                                widget
                                                                    .menutitle,
                                                                iwantselectedValues,
                                                                groupselectvalue,
                                                                categoryselectvalue,
                                                                iwantvalue ??
                                                                    "",
                                                                _selectedValueRange ??
                                                                    "",
                                                                _showTotal,
                                                              );
                                                            } else {
                                                              pivotcontroller
                                                                  .Getpivotchart(
                                                                pivotcontroller
                                                                    .selectedChartType
                                                                    .value
                                                                    .toLowerCase(),
                                                                widget
                                                                    .menutitle,
                                                                iwantselectedValues,
                                                                groupselectvalue,
                                                                categoryselectvalue,
                                                                iwantvalue ??
                                                                    "",
                                                                _selectedValueRange ??
                                                                    "",
                                                                _showTotal,
                                                              );
                                                            }
                                                          });
                                                        } else {
                                                          await pivotcontroller
                                                                  .Getreportseachdata(
                                                                      addedFilters)
                                                              .then((value) {
                                                            print(
                                                                '==addedFilters===addedFilters=======>${addedFilters}');
                                                            if (pivotcontroller
                                                                    .selectedChartType
                                                                    .toLowerCase() ==
                                                                "table") {
                                                              pivotcontroller.Getpivotchart(
                                                                  "html",
                                                                  widget
                                                                      .menutitle,
                                                                  iwantselectedValues,
                                                                  groupselectvalue,
                                                                  categoryselectvalue,
                                                                  iwantvalue ??
                                                                      "",
                                                                  _selectedValueRange ??
                                                                      "",
                                                                  _showTotal);
                                                            } else {
                                                              pivotcontroller.Getpivotchart(
                                                                  pivotcontroller
                                                                      .selectedChartType
                                                                      .value
                                                                      .toLowerCase(),
                                                                  widget
                                                                      .menutitle,
                                                                  iwantselectedValues,
                                                                  groupselectvalue,
                                                                  categoryselectvalue,
                                                                  iwantvalue ??
                                                                      "",
                                                                  _selectedValueRange ??
                                                                      "",
                                                                  _showTotal);
                                                            }
                                                          });
                                                        }

                                                        Get.back();
                                                      },
                                                      child: Container(
                                                          height: 45,
                                                          width: 120,
                                                          decoration:
                                                              BoxDecoration(
                                                                  border: Border
                                                                      .all(
                                                                    color: isDarkMode
                                                                        ? const Color(
                                                                            0xFF4F76E2)
                                                                        : const Color(
                                                                            0xFF1A237E),
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5)),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .draw_outlined,
                                                                size: 25,
                                                                color: isDarkMode
                                                                    ? const Color(
                                                                        0xFF4F76E2)
                                                                    : const Color(
                                                                        0xFF1A237E),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Text(
                                                                'Draw',
                                                                style: TextStyle(
                                                                    color: isDarkMode
                                                                        ? const Color(
                                                                            0xFF4F76E2)
                                                                        : const Color(
                                                                            0xFF1A237E),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontFamily:
                                                                        'Lato',
                                                                    fontSize:
                                                                        15),
                                                              )
                                                            ],
                                                          )),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ).whenComplete(
                              () {},
                            );
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : const Color(0xFF243262),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.black
                                    : const Color(0xFF243262),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Report',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                Icon(
                                  Icons.draw_outlined,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            _showFilterDialog(context, isDarkMode);
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : const Color(0xFF243262),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.black
                                    : const Color(0xFF243262),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.filter_list_alt,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      GestureDetector(
                        onTap: () async {
                          setState(() {
                            pivotcontroller.selectedField = "";
                            iwantselectedValues.clear();
                            groupselectvalue.clear();
                            categoryselectvalue.clear();
                            pivotcontroller.selectedChartType.value = '';
                            pivotcontroller.selectedCondition = "";
                            _searchController.clear();
                            addedFilters.clear();
                          });
                          if (pivotcontroller.isuserFilter.value != 0) {
                            pivotcontroller.GetdataList(
                                    pivotcontroller.code.value.toString(),
                                    pivotcontroller.appCode.value.toString())
                                .then((value) {
                              if (pivotcontroller.selectedChartType
                                      .toLowerCase() ==
                                  "table") {
                                pivotcontroller.Getpivotchart(
                                  "html",
                                  widget.menutitle,
                                  iwantselectedValues,
                                  groupselectvalue,
                                  categoryselectvalue,
                                  iwantvalue ?? "",
                                  _selectedValueRange ?? "",
                                  _showTotal,
                                );
                              } else {
                                pivotcontroller.Getpivotchart(
                                  pivotcontroller.selectedChartType.value
                                      .toLowerCase(),
                                  widget.menutitle,
                                  iwantselectedValues,
                                  groupselectvalue,
                                  categoryselectvalue,
                                  iwantvalue ?? "",
                                  _selectedValueRange ?? "",
                                  _showTotal,
                                );
                              }
                            });
                          } else {
                            await pivotcontroller.Getreportseachdata(
                                    addedFilters)
                                .then((value) {
                              if (pivotcontroller.selectedChartType
                                      .toLowerCase() ==
                                  "table") {
                                pivotcontroller.Getpivotchart(
                                  "html",
                                  widget.menutitle,
                                  iwantselectedValues,
                                  groupselectvalue,
                                  categoryselectvalue,
                                  iwantvalue ?? "",
                                  _selectedValueRange ?? "",
                                  _showTotal,
                                );
                              } else {
                                pivotcontroller.Getpivotchart(
                                  pivotcontroller.selectedChartType.value
                                      .toLowerCase(),
                                  widget.menutitle,
                                  iwantselectedValues,
                                  groupselectvalue,
                                  categoryselectvalue,
                                  iwantvalue ?? "",
                                  _selectedValueRange ?? "",
                                  _showTotal,
                                );
                              }
                            });
                          }
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[800]
                                : const Color(0xFF243262),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.black
                                  : const Color(0xFF243262),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  pivotcontroller.isPortrait.value
                      ? Container(
                          width: MediaQuery.of(context).size.width,
                          color: isDarkMode ? Colors.black : Colors.white,
                          height: MediaQuery.of(context).size.height * 0.71,
                          child: pivotcontroller.selectedChartType.value ==
                                      "table" ||
                                  pivotcontroller.selectedChartType.value == ""
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: getChart())
                              : SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: 0,
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.71,
                                    ),
                                    child: getChart(),
                                  ),
                                ))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                              color: isDarkMode ? Colors.black : Colors.white,
                              height: MediaQuery.of(context).size.height - 40,
                              width: MediaQuery.of(context).size.width,
                              child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: getChart())),
                        )
                ],
              ),
            ),
          ]),
        )));
  }

  Widget getChart() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    return Obx(() {
      if (pivotcontroller.pivotchart.value
          .contains('{"code":"UNEXPECTED_ERROR",')) {
        Map<String, dynamic> error =
            jsonDecode(pivotcontroller.pivotchart.value);
        String? apiErrorMessage = error['message'];

        return Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            children: [
              Image.network(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSBxmrzeQWjgFaDXiWXQHCAX3rM-uuoXtOhdw&s',
                width: 30,
                height: 30,
              ),
              Text(
                apiErrorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }
      if (pivotcontroller.pivotchart.value.contains('{"code":"EMPTY_DATA",')) {
        Map<String, dynamic> error =
            jsonDecode(pivotcontroller.pivotchart.value);
        String? apiErrorMessage = error['message'];

        return Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            children: [
              Image.network(
                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSBxmrzeQWjgFaDXiWXQHCAX3rM-uuoXtOhdw&s',
                width: 30,
                height: 30,
              ),
              Text(
                apiErrorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      } else if (pivotcontroller.selectedChartType.value.toLowerCase() ==
          "table") {
        if (pivotcontroller.pivotchart.value.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: LoadingAnimationWidget.threeArchedCircle(
                    size: 50,
                    color: isDarkMode ? Colors.black : const Color(0xFF243262),
                  ),
                )),
          );
        } else {
          String htmlview = pivotcontroller.pivotchart.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ZoomableHtml(
              htmlContent: htmlview,
              datarow: pivotcontroller.dataRows.length,
            ),
          );
        }
      } else if (pivotcontroller.selectedChartType.value.toLowerCase() ==
              "line" ||
          pivotcontroller.selectedChartType.value.toLowerCase() == "bar" ||
          pivotcontroller.selectedChartType.value.toLowerCase() == "area") {
        if (pivotcontroller.pivotchart.value.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: LoadingAnimationWidget.threeArchedCircle(
                    size: 50,
                    color: isDarkMode ? Colors.black : const Color(0xFF243262),
                  ),
                )),
          );
        } else {
          final document = parse(pivotcontroller.pivotchart.value);
          final svgElement = document.querySelector('svg');

          if (svgElement != null) {
            return ZoomableSvg(svgContent: svgElement.outerHtml);
          } else {
            return Center(
                child: CircularProgressIndicator(
              color: isDarkMode ? Colors.black : const Color(0xFF243262),
            ));
          }
        }
      } else {
        String htmlview = pivotcontroller.pivotchart.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ZoomableHtml(
            htmlContent: htmlview,
            datarow: pivotcontroller.dataRows.length,
          ),
        );
      }
    });
  }

  String getSelectedFieldType() {
    if (pivotcontroller.selectedField == null ||
        pivotcontroller.selectedField!.isEmpty) {
      return '';
    }
    try {
      final fieldData = pivotcontroller.iwantlist.firstWhere(
          (item) => item['code'] == pivotcontroller.selectedField,
          orElse: () => {'type': ''});
      return fieldData['type'].toString().toLowerCase();
    } catch (e) {
      return '';
    }
  }



Future<void> _showFilterDialog(BuildContext context, bool isDarkMode) {
    // ✅ FIX 1: सभी TextEditingController और STATE वेरिएबल्स बाहर डिक्लेयर करें
    final TextEditingController _fromDateController = TextEditingController();
    final TextEditingController _toDateController = TextEditingController();
    final TextEditingController _searchController = TextEditingController();
    String? selectedDayOnly;
    String? selectedMonthOnly;
    DateTime? selectedFromDate;
    DateTime? selectedToDate;

    // Available days (01-31)
    List<String> days =
        List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'));

    // Available months
    List<Map<String, dynamic>> months = [
      {'value': '01', 'label': 'January'},
      {'value': '02', 'label': 'February'},
      {'value': '03', 'label': 'March'},
      {'value': '04', 'label': 'April'},
      {'value': '05', 'label': 'May'},
      {'value': '06', 'label': 'June'},
      {'value': '07', 'label': 'July'},
      {'value': '08', 'label': 'August'},
      {'value': '09', 'label': 'September'},
      {'value': '10', 'label': 'October'},
      {'value': '11', 'label': 'November'},
      {'value': '12', 'label': 'December'},
    ];

    // Available years (last 10 years + current + next 5)
    List<int> years = [];
    int currentYear = DateTime.now().year;
    for (int i = currentYear - 10; i <= currentYear + 5; i++) {
      years.add(i);
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final selectedFieldType = getSelectedFieldType();
            final isDateField = selectedFieldType == 'date';

            // ✅ FIX 2: Date Picker Functions - StatefulBuilder के अंदर, setState का use करें
            Future<void> _selectDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary:
                            isDarkMode ? const Color(0xFF4F76E2) : Appcolorblue,
                        onPrimary: Colors.white,
                        onSurface: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? const Color(0xFF4F76E2)
                              : Appcolorblue,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                // ✅ Local setState का use करें
                setState(() {
                  _searchController.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  print('✅ Date selected: ${_searchController.text}');
                });
              }
            }

            // Date picker for BETWEEN condition
            Future<void> _selectRangeDate(
                BuildContext context, bool isFromDate) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary:
                            isDarkMode ? const Color(0xFF4F76E2) : Appcolorblue,
                        onPrimary: Colors.white,
                        onSurface: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? const Color(0xFF4F76E2)
                              : Appcolorblue,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                // ✅ Local setState का use करें
                setState(() {
                  if (isFromDate) {
                    selectedFromDate = picked;
                    _fromDateController.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    print('📅 From Date: ${_fromDateController.text}');
                  } else {
                    selectedToDate = picked;
                    _toDateController.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    print('📅 To Date: ${_toDateController.text}');
                  }
                });
              }
            }

            // Check condition types
            bool isSpecialCondition() {
              final condition = pivotcontroller.selectedCondition;
              return condition == 'IS_NULL' ||
                  condition == 'IS_NOT_NULL' ||
                  condition == 'IS_EMPTY';
            }

            bool isDayCondition() {
              return pivotcontroller.selectedCondition == 'DAY';
            }

            bool isMonthCondition() {
              return pivotcontroller.selectedCondition == 'MONTH';
            }

            bool isDayMonthCondition() {
              return pivotcontroller.selectedCondition == 'DAY_MONTH';
            }

            bool isBetweenCondition() {
              return pivotcontroller.selectedCondition == 'BETWEEN';
            }

            bool shouldShowDatePicker() {
              return isDateField &&
                  !isSpecialCondition() &&
                  !isDayCondition() &&
                  !isMonthCondition() &&
                  !isDayMonthCondition() &&
                  !isBetweenCondition();
            }

            // ✅ FIX 3: _addFilter Function में main widget का setState() use करें
            void _addFilter() {
              if (pivotcontroller.selectedField == null ||
                  pivotcontroller.selectedField!.isEmpty) {
                CherryToast.error(
                  backgroundColor: const Color(0xFFF8D0D9),
                  animationDuration: Durations.short1,
                  title: const Text(
                    "Please select a field first.",
                    style: TextStyle(color: Colors.black),
                  ),
                ).show(Get.overlayContext!);
                return;
              }

              if (pivotcontroller.selectedCondition == null ||
                  pivotcontroller.selectedCondition!.isEmpty) {
                CherryToast.error(
                  backgroundColor: const Color(0xFFF8D0D9),
                  animationDuration: Durations.short1,
                  title: const Text(
                    "Please select a condition first.",
                    style: TextStyle(color: Colors.black),
                  ),
                ).show(Get.overlayContext!);
                return;
              }

              bool isValid = false;
              String valueToAdd = "";
              DateTime now = DateTime.now();
              String currentYear = now.year.toString();

              final condition = pivotcontroller.selectedCondition!;

              // Special conditions (IS_NULL, IS_NOT_NULL, IS_EMPTY)
              if (condition == 'IS_NULL' ||
                  condition == 'IS_NOT_NULL' ||
                  condition == 'IS_EMPTY') {
                isValid = true;
                valueToAdd = "";
                print('✅ Special condition: $condition');
              }
              // BETWEEN condition
              else if (condition == 'BETWEEN') {
                if (selectedFromDate == null || selectedToDate == null) {
                  CherryToast.error(
                    backgroundColor: const Color(0xFFF8D0D9),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "Please select both From and To dates for BETWEEN condition.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }

                // Check for duplicate BETWEEN filter
                bool isDuplicate = addedFilters.any((filter) =>
                    filter['field'] == pivotcontroller.selectedField &&
                    filter['condition'] == 'BETWEEN' &&
                    filter['rangeFrom'] == _fromDateController.text &&
                    filter['rangeTo'] == _toDateController.text);

                if (isDuplicate) {
                  CherryToast.warning(
                    backgroundColor: const Color(0xFFFFF3CD),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "This BETWEEN filter already exists.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }

                // ✅ FIX: Main widget का setState use करें (addedFilters external है)
                this.setState(() {
                  addedFilters.add({
                    'field': pivotcontroller.selectedField!,
                    'condition': 'BETWEEN',
                    'rangeFrom': _fromDateController.text,
                    'rangeTo': _toDateController.text,
                  });
                });

                print('=========================================');
                print('✅ BETWEEN FILTER ADDED');
                print('📋 Field: ${pivotcontroller.selectedField}');
                print('📅 From Date: ${_fromDateController.text}');
                print('📅 To Date: ${_toDateController.text}');
                print('=========================================');

                // Clear fields - Local setState का use करें
                setState(() {
                  _fromDateController.clear();
                  _toDateController.clear();
                  selectedFromDate = null;
                  selectedToDate = null;
                });
                return;
              }
              // DAY condition
              else if (condition == 'DAY') {
                if (selectedDayOnly != null && selectedDayOnly!.isNotEmpty) {
                  isValid = true;
                  String month = now.month.toString().padLeft(2, '0');
                  valueToAdd =
                      "$currentYear-$month-${selectedDayOnly!.padLeft(2, '0')}";
                  print('✅ DAY condition: $valueToAdd');
                } else {
                  CherryToast.error(
                    backgroundColor: const Color(0xFFF8D0D9),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "Please select a day.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }
              }
              // MONTH condition
              else if (condition == 'MONTH') {
                if (selectedMonthOnly != null &&
                    selectedMonthOnly!.isNotEmpty) {
                  isValid = true;
                  valueToAdd =
                      "$currentYear-${selectedMonthOnly!.padLeft(2, '0')}-06";
                  print('✅ MONTH condition: $valueToAdd');
                } else {
                  CherryToast.error(
                    backgroundColor: const Color(0xFFF8D0D9),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "Please select a month.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }
              }
              // DAY_MONTH condition
              else if (condition == 'DAY_MONTH') {
                if (selectedDayOnly != null &&
                    selectedDayOnly!.isNotEmpty &&
                    selectedMonthOnly != null &&
                    selectedMonthOnly!.isNotEmpty) {
                  isValid = true;
                  valueToAdd =
                      "$currentYear-${selectedMonthOnly!.padLeft(2, '0')}-${selectedDayOnly!.padLeft(2, '0')}";
                  print('✅ DAY_MONTH condition: $valueToAdd');
                } else {
                  CherryToast.error(
                    backgroundColor: const Color(0xFFF8D0D9),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "Please select both day and month.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }
              }
              
              // Regular conditions with date picker
              else if (shouldShowDatePicker()) {
                if (_searchController.text.trim().isNotEmpty) {
                  isValid = true;
                  valueToAdd = _searchController.text.trim();
                  print('✅ Date field: $valueToAdd');
                } else {
                  CherryToast.error(
                    backgroundColor: const Color(0xFFF8D0D9),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "Please select a date.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }
              }
              // Regular conditions with text input
              else {
                if (_searchController.text.trim().isNotEmpty) {
                  isValid = true;
                  valueToAdd = _searchController.text.trim();
                  print('✅ Regular condition: $condition = $valueToAdd');
                } else {
                  CherryToast.error(
                    backgroundColor: const Color(0xFFF8D0D9),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "Please enter a value.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }
              }

              // Add non-BETWEEN filters
              if (isValid && condition != 'BETWEEN') {
                // Check for duplicate
                bool isDuplicate = addedFilters.any((filter) =>
                    filter['field'] == pivotcontroller.selectedField &&
                    filter['condition'] == pivotcontroller.selectedCondition &&
                    filter['value'] == valueToAdd);

                if (isDuplicate) {
                  CherryToast.warning(
                    backgroundColor: const Color(0xFFFFF3CD),
                    animationDuration: Durations.short1,
                    title: const Text(
                      "This filter already exists.",
                      style: TextStyle(color: Colors.black),
                    ),
                  ).show(Get.overlayContext!);
                  return;
                }

                // ✅ FIX: Main widget का setState use करें (addedFilters external है)
                this.setState(() {
                  addedFilters.add({
                    'field': pivotcontroller.selectedField!,
                    'value': valueToAdd,
                    'condition': pivotcontroller.selectedCondition!,
                  });
                });

                print('=========================================');
                print('✅ FILTER ADDED');
                print('📋 Field: ${pivotcontroller.selectedField}');
                print('⚡ Condition: ${pivotcontroller.selectedCondition}');
                print('🎯 Value: $valueToAdd');
                print('=========================================');

                // Clear fields - Local setState का use करें
                setState(() {
                  _searchController.clear();
                  selectedDayOnly = null;
                  selectedMonthOnly = null;
                });
              }
            }

            // बाकी का UI code यहाँ से शुरू होता है (वही रहेगा)
            // ... (आपका मूल UI code यहाँ आएगा - बिल्कुल वैसा ही)
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                color: isDarkMode ? Colors.grey[800]! : Colors.white,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  height: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              // Field Dropdown
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                  horizontal: 8,
                                ),
                                child: Obx(() {
                                  final fieldItems = pivotcontroller.iwantlist
                                      .map<DropdownMenuItem<String>>((item) {
                                    String label = item['label'].toString();
                                    String type = item['type'].toString();

                                    String firstLetter;
                                    Color avatarColor;
                                    if (['object', 'map', 'list']
                                        .contains(type.toLowerCase())) {
                                      firstLetter = 'C';
                                      avatarColor = const Color(0xFF1976D2);
                                    } else if (type.toLowerCase() == 'date') {
                                      firstLetter = 'D';
                                      avatarColor = const Color(0xFFFBC02D);
                                    } else if (type.toLowerCase() == 'text' ||
                                        type.toLowerCase() == 'email') {
                                      firstLetter = type.isNotEmpty
                                          ? type[0].toUpperCase()
                                          : '?';
                                      avatarColor = const Color(0xFF2E7D32);
                                    } else if ([
                                      'number',
                                      'expression',
                                      'decimal',
                                      'long'
                                    ].contains(type.toLowerCase())) {
                                      firstLetter = 'N';
                                      avatarColor = const Color(0xFF1976D2);
                                    } else {
                                      firstLetter = type.isNotEmpty
                                          ? type[0].toUpperCase()
                                          : '?';
                                      avatarColor = Colors.grey;
                                    }

                                    return DropdownMenuItem<String>(
                                      value: item['code'].toString(),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.70,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: avatarColor,
                                              child: Text(
                                                firstLetter,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.55,
                                              ),
                                              child: Text(
                                                label,
                                                maxLines: 2,
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList();

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              hint: Text(
                                                'Select Field',
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              dropdownColor: isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.white,
                                              decoration: InputDecoration(
                                                labelStyle: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                hoverColor:
                                                    Colors.indigo.shade200,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFF2962FF)),
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              value: pivotcontroller
                                                              .selectedField !=
                                                          null &&
                                                      pivotcontroller
                                                          .selectedField!
                                                          .isNotEmpty &&
                                                      fieldItems.any((element) =>
                                                          element.value ==
                                                          pivotcontroller
                                                              .selectedField)
                                                  ? pivotcontroller
                                                      .selectedField
                                                  : null,
                                              items: fieldItems,
                                              selectedItemBuilder:
                                                  (BuildContext context) {
                                                return pivotcontroller.iwantlist
                                                    .map<Widget>((item) {
                                                  String label =
                                                      item['label'].toString();
                                                  return ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.55,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 10,
                                                          backgroundColor:
                                                              Colors.grey,
                                                          child: Text(
                                                            label.isNotEmpty
                                                                ? label[0]
                                                                    .toUpperCase()
                                                                : '?',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            label,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                            style: TextStyle(
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                              onChanged: (value) {
                                                setState(() {
                                                  pivotcontroller
                                                      .selectedField = value;
                                                  _searchController.clear();
                                                  selectedDayOnly = null;
                                                  selectedMonthOnly = null;
                                                  selectedFromDate = null;
                                                  selectedToDate = null;
                                                  _fromDateController.clear();
                                                  _toDateController.clear();
                                                });
                                              },
                                            ),
                                          ),
                                          Tooltip(
                                            preferBelow: false,
                                            verticalOffset: 20,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 30),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            triggerMode: TooltipTriggerMode.tap,
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1),
                                            ),
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            message:
                                                "Select a field to apply filters. Date fields support special conditions like DAY, MONTH, BETWEEN, etc.",
                                            child: SizedBox(
                                              width: 40,
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 25,
                                                color: isDarkMode
                                                    ? Colors.blueAccent
                                                    : Appcolorblue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(height: 10),

                              // Condition Dropdown
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2.0, horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        dropdownColor: isDarkMode
                                            ? Colors.grey[800]!
                                            : Colors.white,
                                        decoration: InputDecoration(
                                          labelText: "Condition",
                                          labelStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          hoverColor: Colors.indigo.shade200,
                                          fillColor: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                                color: Color(0xFF2962FF)),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 12),
                                        ),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        hint: Text(
                                          "Select Condition",
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        value: pivotcontroller.conditions.any(
                                                (e) =>
                                                    e['value'] ==
                                                    pivotcontroller
                                                        .selectedCondition)
                                            ? pivotcontroller.selectedCondition
                                            : null,
                                        items: pivotcontroller.conditions
                                            .map((condition) {
                                          return DropdownMenuItem<String>(
                                            value: condition['value'],
                                            child: Text(
                                              condition['label']!,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            pivotcontroller.selectedCondition =
                                                value;
                                            _searchController.clear();
                                            selectedDayOnly = null;
                                            selectedMonthOnly = null;
                                            selectedFromDate = null;
                                            selectedToDate = null;
                                            _fromDateController.clear();
                                            _toDateController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      preferBelow: false,
                                      verticalOffset: 20,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 50),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      triggerMode: TooltipTriggerMode.tap,
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      message:
                                          "Special conditions: IS NULL, IS NOT NULL, IS EMPTY, DAY, MONTH, DAY & MONTH, BETWEEN (date range)",
                                      child: SizedBox(
                                        width: 40,
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 25,
                                          color: isDarkMode
                                              ? Colors.blueAccent
                                              : Appcolorblue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // BETWEEN Condition UI
                              if (isBetweenCondition())
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 10),
                                  child: Column(
                                    children: [
                                      // From Date
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _selectRangeDate(
                                                  context, true),
                                              child: AbsorbPointer(
                                                absorbing: true,
                                                child: TextField(
                                                  controller:
                                                      _fromDateController,
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  decoration: InputDecoration(
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    labelText: 'From Date',
                                                    hintText:
                                                        'Select Start Date (YYYY-MM-DD)',
                                                    hintStyle: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    labelStyle: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    border:
                                                        const OutlineInputBorder(),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 12),
                                                    suffixIcon: Icon(
                                                      Icons.calendar_today,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "to",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // To Date
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _selectRangeDate(
                                                  context, false),
                                              child: AbsorbPointer(
                                                absorbing: true,
                                                child: TextField(
                                                  controller: _toDateController,
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  decoration: InputDecoration(
                                                    fillColor: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    labelText: 'To Date',
                                                    hintText:
                                                        'Select End Date (YYYY-MM-DD)',
                                                    hintStyle: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    labelStyle: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    border:
                                                        const OutlineInputBorder(),
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 12),
                                                    suffixIcon: Icon(
                                                      Icons.calendar_today,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: _addFilter,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDarkMode
                                                  ? const Color(0xFF4F76E2)
                                                  : Appcolorblue,
                                              shape: const CircleBorder(),
                                              padding: const EdgeInsets.all(15),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Display selected range
                                      if (selectedFromDate != null &&
                                          selectedToDate != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            "Selected Range: ${_fromDateController.text} to ${_toDateController.text}",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.greenAccent
                                                  : Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              // DAY Condition
                              if (isDayCondition())
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          dropdownColor: isDarkMode
                                              ? Colors.grey[800]!
                                              : Colors.white,
                                          decoration: InputDecoration(
                                            labelText: "Select Day",
                                            labelStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            hoverColor: Colors.indigo.shade200,
                                            fillColor: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF2962FF)),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 12),
                                          ),
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          hint: Text(
                                            "Select Day (01-31)",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          value: selectedDayOnly,
                                          items: [
                                            DropdownMenuItem<String>(
                                              value: null,
                                              child: Text(
                                                "Select Day",
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                            ...days.map((day) {
                                              return DropdownMenuItem<String>(
                                                value: day,
                                                child: Text(
                                                  "Day $day",
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              selectedDayOnly = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _addFilter,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDarkMode
                                              ? const Color(0xFF4F76E2)
                                              : Appcolorblue,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(15),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // MONTH Condition
                              if (isMonthCondition())
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          dropdownColor: isDarkMode
                                              ? Colors.grey[800]!
                                              : Colors.white,
                                          decoration: InputDecoration(
                                            labelText: "Select Month",
                                            labelStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            hoverColor: Colors.indigo.shade200,
                                            fillColor: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF2962FF)),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 12),
                                          ),
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          hint: Text(
                                            "Select Month",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          value: selectedMonthOnly,
                                          items: [
                                            DropdownMenuItem<String>(
                                              value: null,
                                              child: Text(
                                                "Select Month",
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ),
                                            ...months.map((month) {
                                              return DropdownMenuItem<String>(
                                                value: month['value'],
                                                child: Text(
                                                  month['label'],
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              selectedMonthOnly = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _addFilter,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDarkMode
                                              ? const Color(0xFF4F76E2)
                                              : Appcolorblue,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(15),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // DAY_MONTH Condition
                              if (isDayMonthCondition())
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 10),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              dropdownColor: isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.white,
                                              decoration: InputDecoration(
                                                labelText: "Select Day",
                                                labelStyle: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                hoverColor:
                                                    Colors.indigo.shade200,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFF2962FF)),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 12),
                                              ),
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              hint: Text(
                                                "Select Day",
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              value: selectedDayOnly,
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: null,
                                                  child: Text(
                                                    "Select Day",
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                                ...days.map((day) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: day,
                                                    child: Text(
                                                      "Day $day",
                                                      style: TextStyle(
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedDayOnly = value;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                              dropdownColor: isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.white,
                                              decoration: InputDecoration(
                                                labelText: "Select Month",
                                                labelStyle: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                hoverColor:
                                                    Colors.indigo.shade200,
                                                fillColor: isDarkMode
                                                    ? Colors.black
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFF2962FF)),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 12),
                                              ),
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              hint: Text(
                                                "Select Month",
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              value: selectedMonthOnly,
                                              items: [
                                                DropdownMenuItem<String>(
                                                  value: null,
                                                  child: Text(
                                                    "Select Month",
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                                ...months.map((month) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: month['value'],
                                                    child: Text(
                                                      month['label'],
                                                      style: TextStyle(
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedMonthOnly = value;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: _addFilter,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDarkMode
                                                  ? const Color(0xFF4F76E2)
                                                  : Appcolorblue,
                                              shape: const CircleBorder(),
                                              padding: const EdgeInsets.all(15),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (selectedDayOnly != null &&
                                          selectedMonthOnly != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            "Selected: Day $selectedDayOnly, Month ${months.firstWhere((m) => m['value'] == selectedMonthOnly, orElse: () => {
                                                  'label': ''
                                                })['label']}",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.greenAccent
                                                  : Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              // Special Conditions (IS_NULL, IS_NOT_NULL, IS_EMPTY)
                              if (isSpecialCondition())
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.grey[900]!
                                                : Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDarkMode
                                                  ? Colors.blueAccent
                                                  : Appcolorblue,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "No value required for ${pivotcontroller.selectedCondition == 'IS_NULL' ? 'IS NULL' : pivotcontroller.selectedCondition == 'IS_NOT_NULL' ? 'IS NOT NULL' : 'IS EMPTY'} condition",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _addFilter,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDarkMode
                                              ? const Color(0xFF4F76E2)
                                              : Appcolorblue,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(15),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Regular Input for other conditions
                              if (!isSpecialCondition() &&
                                  !isDayCondition() &&
                                  !isMonthCondition() &&
                                  !isDayMonthCondition() &&
                                  !isBetweenCondition())
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, horizontal: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: shouldShowDatePicker()
                                            ? GestureDetector(
                                                onTap: () =>
                                                    _selectDate(context),
                                                child: AbsorbPointer(
                                                  absorbing: true,
                                                  child: TextField(
                                                    controller:
                                                        _searchController,
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    decoration: InputDecoration(
                                                      fillColor: isDarkMode
                                                          ? Colors.black
                                                          : Colors.white,
                                                      hintText:
                                                          'Select Date (YYYY-MM-DD)',
                                                      hintStyle: TextStyle(
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      labelStyle: TextStyle(
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      border:
                                                          const OutlineInputBorder(),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 12),
                                                      suffixIcon: Icon(
                                                        Icons.calendar_today,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : TextField(
                                                controller: _searchController,
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                decoration: InputDecoration(
                                                  fillColor: isDarkMode
                                                      ? Colors.black
                                                      : Colors.white,
                                                  hintText:
                                                      'Enter search value',
                                                  hintStyle: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  labelStyle: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  border:
                                                      const OutlineInputBorder(),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _addFilter,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDarkMode
                                              ? const Color(0xFF4F76E2)
                                              : Appcolorblue,
                                          shape: const CircleBorder(),
                                          padding: const EdgeInsets.all(15),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Display added filters as chips
                              if (addedFilters.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]!
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: Text(
                                            "Applied Filters (${addedFilters.length}):",
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: addedFilters.map((filter) {
                                            String label;

                                            if (filter['condition'] ==
                                                'BETWEEN') {
                                              label =
                                                  "${filter['field']} BETWEEN ${filter['rangeFrom']} AND ${filter['rangeTo']}";
                                            } else if (filter['condition'] ==
                                                'IS_NULL') {
                                              label =
                                                  "${filter['field']} IS NULL";
                                            } else if (filter['condition'] ==
                                                'IS_NOT_NULL') {
                                              label =
                                                  "${filter['field']} IS NOT NULL";
                                            } else if (filter['condition'] ==
                                                'IS_EMPTY') {
                                              label =
                                                  "${filter['field']} IS EMPTY";
                                            } else if (filter['condition'] ==
                                                'DAY') {
                                              label =
                                                  "${filter['field']} DAY = ${filter['value']}";
                                            } else if (filter['condition'] ==
                                                'MONTH') {
                                              final monthName =
                                                  months
                                                      .firstWhere(
                                                          (m) =>
                                                              m['value'] ==
                                                              filter['value'],
                                                          orElse:
                                                              () => {
                                                                    'label':
                                                                        filter['value'] ??
                                                                            ''
                                                                  })['label'];
                                              label =
                                                  "${filter['field']} MONTH = $monthName";
                                            } else if (filter['condition'] ==
                                                'DAY_MONTH') {
                                              label =
                                                  "${filter['field']} DAY & MONTH = ${filter['value']}";
                                            } else {
                                              final conditionSymbol =
                                                  pivotcontroller.conditions
                                                      .firstWhere(
                                                          (c) =>
                                                              c['value'] ==
                                                              filter[
                                                                  'condition'],
                                                          orElse: () => {
                                                                'label': filter[
                                                                    'condition']!
                                                              })['label']!
                                                      .toString();
                                              label =
                                                  "${filter['field']} $conditionSymbol ${filter['value']}";
                                            }

                                            return Chip(
                                              label: Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 16),
                                              onDeleted: () {
                                                // ✅ Main widget का setState use करें
                                                setState(() {
                                                  addedFilters.remove(filter);
                                                });
                                              },
                                              backgroundColor: isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.white,
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // ✅ Main widget का setState use करें (addedFilters clear करने के लिए)
                                this.setState(() {
                                  pivotcontroller.selectedField = "";
                                  pivotcontroller.selectedCondition = "";
                                  addedFilters.clear();
                                });
                                // ✅ Local setState use करें (dialog के fields clear करने के लिए)
                                setState(() {
                                  _searchController.clear();
                                  selectedDayOnly = null;
                                  selectedMonthOnly = null;
                                  selectedFromDate = null;
                                  selectedToDate = null;
                                  _fromDateController.clear();
                                  _toDateController.clear();
                                });
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                if (addedFilters.isNotEmpty) {
                                  final result =
                                      await pivotcontroller.Getreportseachdata(
                                          addedFilters);

                                  if (result != null &&
                                      result['success'] == true) {
                                    if (result['emptyData'] == true) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: isDarkMode
                                                ? Colors.grey[800]!
                                                : Colors.white,
                                            title: Text(
                                              "No Records Found",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              result['message'] ??
                                                  "No records found for the applied filters.",
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  "OK",
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.blueAccent
                                                        : Appcolorblue,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      if (pivotcontroller.selectedChartType
                                              .toLowerCase() ==
                                          "table") {
                                        pivotcontroller.Getpivotchart(
                                          "html",
                                          widget.menutitle,
                                          iwantselectedValues,
                                          groupselectvalue,
                                          categoryselectvalue,
                                          iwantvalue ?? "",
                                          _selectedValueRange ?? "",
                                          _showTotal,
                                        );
                                      } else {
                                        pivotcontroller.Getpivotchart(
                                          pivotcontroller
                                              .selectedChartType.value
                                              .toLowerCase(),
                                          widget.menutitle,
                                          iwantselectedValues,
                                          groupselectvalue,
                                          categoryselectvalue,
                                          iwantvalue ?? "",
                                          _selectedValueRange ?? "",
                                          _showTotal,
                                        );
                                      }
                                      Future.delayed(
                                        const Duration(milliseconds: 500),
                                        () {
                                          Navigator.pop(context);
                                        },
                                      );
                                    }
                                  } else {
                                    CherryToast.error(
                                      backgroundColor: const Color(0xFFF8D0D9),
                                      animationDuration: Durations.short1,
                                      title: Text(
                                        result?['message'] ??
                                            "Something went wrong. Please try again.",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                    ).show(Get.overlayContext!);
                                  }
                                } else {
                                  CherryToast.error(
                                    backgroundColor: const Color(0xFFF8D0D9),
                                    animationDuration: Durations.short1,
                                    title: const Text(
                                      "Add at least one filter before searching.",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ).show(Get.overlayContext!);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF4F76E2)
                                    : Appcolorblue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: const Text(
                                "Search",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

