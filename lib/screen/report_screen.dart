import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/controller/report_controller.dart';
import 'package:cuickdevuser/screen/ZoomableHtml.dart';
import 'package:cuickdevuser/screen/ZoomableSvg.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:html/parser.dart' show parse;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ReportpageScreen extends StatefulWidget {
  final reportid ;
  final reporttitle ;
  final subReports ;
   ReportpageScreen({super.key,this.reportid,this.reporttitle,this.subReports});

  @override
  State<ReportpageScreen> createState() => _ReportpageState();
}

class _ReportpageState extends State<ReportpageScreen> {
  final Reportcontroller reportcontroller = Get.find<Reportcontroller>();
  String reportitem = "";
  Map<String, TextEditingController> _controllers = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isButtonEnabled = false;
  bool isPortrait = true;
  String? iwantvalue;

  @override
  void initState() {
    super.initState();
    reportitem = widget.reporttitle;
    reportcontroller.Getreportdatavalue(widget.reportid.toString());
    _searchController.addListener(() {
      setState(() {
        _isButtonEnabled = _searchController.text.trim().isNotEmpty;
      });
    });
  }


  List<Map<String, String>> addedFilters = []; // name, condition, value

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
    reportcontroller.selectedField = null;
    reportcontroller.selectedCondition = null;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    isPortrait = true;
  }

  void _onAddPressed() {
    if (reportcontroller.selectedField != null && reportcontroller.selectedCondition != null && _searchController.text.trim().isNotEmpty) {
      setState(() {
        addedFilters.add({
          'field': reportcontroller.selectedField!,
          'condition': reportcontroller.selectedCondition!,
          'value': _searchController.text.trim()
        });
        _searchController.clear();
        _isButtonEnabled = false;
      });
    }
  }


  bool showfilter = false;
  final GlobalKey _globalKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;


    return Scaffold(

      backgroundColor: isDarkMode? Colors.black:Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: toggleOrientation,
        backgroundColor: isDarkMode ? Colors.grey[850]:Color(0xFF243262), // Your custom color
        child: Icon(
          isPortrait ? Icons.screen_rotation : Icons.screen_lock_rotation,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: isDarkMode ? Colors.grey[850]: Appcolorblue,
        title: Text('Report > ${reportitem}', style: TextStyle(color: Colors.white, fontSize: 15,fontWeight: FontWeight.bold))

      ),
      body:SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: RepaintBoundary(
          key: _globalKey,
          child: Column(

            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      _captureAndPrintFullContent();

                    },
                    child: Container(
                      height: 40,
                      width: 50,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF4F76E2) : Appcolorblue,
                        border: Border.all(color: Appcolorblue),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                        child: Icon(Icons.picture_as_pdf, size: 30, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      reportcontroller.Getreportdatavalue(widget.reportid.toString() );
                    },
                    child: Container(
                      height: 40,
                      width: 50,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF4F76E2) : Appcolorblue,
                        border: Border.all(color: Appcolorblue),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.refresh, size: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      _showFilterDialog(context, isDarkMode);
                    },
                    child: Container(
                      height: 40,
                      width: 50,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Color(0xFF4F76E2) : Appcolorblue,
                        border: Border.all(color: Appcolorblue),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.filter_list_rounded, size: 30, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              isPortrait?
              Container(
                width: MediaQuery.of(context).size.width,
                color: isDarkMode ? Colors.black : Colors.white,
                height: MediaQuery.of(context).size.height * 0.80,
                child:
                SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: getChart()),
              )
:
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 2, // Example, adjust as needed
                  height: MediaQuery.of(context).size.height * 1.9, // Example, adjust as needed
                  child: getChart(),
                ),
              ),

            ],
          ),
        ),
      )

    );
  }

  Widget getChart() {
    return Obx(() {

      if (reportcontroller.chart.value.contains('{"code":"UNEXPECTED_ERROR",')) {
        print('==>${reportcontroller.chart.value}');
        Map<String, dynamic> error =
        jsonDecode(reportcontroller.chart.value);
        String? apiErrorMessage = error['details'];

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
      if (reportcontroller.chart.value.contains('{"code":"EMPTY_DATA",')) {


        Map<String, dynamic> error = jsonDecode(reportcontroller.chart.value);
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
      else if  (reportcontroller.chart.value.toLowerCase() == "html") {
        if (reportcontroller.pivotchart.value.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        } else {
          String htmlview = reportcontroller.pivotchart.value;

          return

            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ZoomableHtml(htmlContent: htmlview,datarow: reportcontroller.dataRows.length,), // Zoomable for HTML

          );
        }
      }
      else if (reportcontroller.chart.value.toLowerCase() == "line" ||
          reportcontroller.chart.value.toLowerCase() == "bar" ||
          reportcontroller.chart.value.toLowerCase() == "area") {

        if (reportcontroller.pivotchart.value.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        } else {
          final document = parse(reportcontroller.pivotchart.value);
          final svgElement = document.querySelector('svg');

          if (svgElement != null) {
            return ZoomableSvg(svgContent: svgElement.outerHtml);
          } else {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }
        }
      } else {
        return const SizedBox();
      }
    });
  }

  Future<void> _captureAndPrintFullContent() async {
    // Delay ensures build finishes
    await Future.delayed(Duration(milliseconds: 300));

    RenderRepaintBoundary boundary =
    _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,

        build: (pw.Context context) => pw.Center(child: pw.Image(pdfImage)),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
  Future _showFilterDialog(BuildContext context, bool isDarkMode) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Wrapping the content in StatefulBuilder to manage internal state updates
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  height: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [


                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8),
                                child: Obx(() {
                                  final fieldItems = reportcontroller.filterlist
                                      .map<DropdownMenuItem<String>>((item) {
                                    String label = item['label'].toString();
                                    String type = item['type'].toString();
                                    String firstLetter = ['object', 'map', 'list'].contains(type.toLowerCase())
                                        ? 'C'
                                        : (type.isNotEmpty ? type[0].toUpperCase() : '?');
                                    Color avatarColor;


                                    if (['object', 'map', 'list'].contains(type.toLowerCase())) {
                                      firstLetter = 'C';
                                      avatarColor =const Color(0xFF1976D2);
                                    } else if (type.toLowerCase() == 'date') {
                                      firstLetter = 'D';
                                      avatarColor =const Color(0xFFFBC02D);
                                    } else if (type.toLowerCase() == 'text' ) {
                                      firstLetter = 'T';
                                      avatarColor = const Color(0xFF2E7D32);
                                    } else if (type.toLowerCase() == 'email' ) {
                                      firstLetter = 'E';
                                      avatarColor =const Color(0xFF2E7D32);
                                    } else if (type.toLowerCase() == 'number' ||
                                        type.toLowerCase() == 'expression' ||
                                        type.toLowerCase() == 'decimal'|| type.toLowerCase() == 'long') {
                                      firstLetter = 'N';
                                      avatarColor =const Color(0xFF1976D2);
                                    }else {
                                      firstLetter = type.isNotEmpty ? type[0].toUpperCase() : '?';
                                      avatarColor = Colors.grey;
                                    }

                                    return DropdownMenuItem<String>(
                                      value: item['code'].toString(),
                                      child: ConstrainedBox(
                                        constraints:
                                        BoxConstraints(
                                          maxWidth: MediaQuery.of(
                                              context)
                                              .size
                                              .width *
                                              0.70,),
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
                                              constraints:
                                              BoxConstraints(
                                                maxWidth: MediaQuery.of(
                                                    context)
                                                    .size
                                                    .width *
                                                    0.55,
                                              ),
                                              child: Text(
                                                label,
                                                maxLines: 2,
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors
                                                      .white
                                                      : Colors
                                                      .black,
                                                  fontSize: 10,
                                                  fontWeight:
                                                  FontWeight
                                                      .bold,
                                                  overflow: TextOverflow.ellipsis,


                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList();

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              hint: Text(
                                                'Select Field',
                                                style: TextStyle(
                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                              decoration: InputDecoration(
                                                labelStyle: TextStyle(
                                                  color: isDarkMode ? Colors.white : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                hoverColor: Colors.indigo.shade200,
                                                fillColor: isDarkMode ? Colors.black : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: Color(0xFF2962FF)),
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              value: fieldItems.any((element) => element.value == iwantvalue)
                                                  ? iwantvalue
                                                  : null,
                                              items: fieldItems,
                                              selectedItemBuilder: (BuildContext context) {
                                                return reportcontroller.filterlist.map<Widget>((item) {
                                                  String label = item['label'].toString();
                                                  return ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: MediaQuery.of(context).size.width * 0.55, // adjust width
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 10,
                                                          backgroundColor: Colors.grey, // optional: same logic as above
                                                          child: Text(
                                                            label.isNotEmpty ? label[0].toUpperCase() : '?',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            label,
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                            style: TextStyle(
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
                                              onChanged: (value) {
                                                setState(() {
                                                  reportcontroller.selectedField = value;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 5,),

                                          Tooltip(
                                            preferBelow: false,
                                            verticalOffset: 20,
                                            margin: const EdgeInsets.symmetric(horizontal: 50),
                                            padding:const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                            triggerMode: TooltipTriggerMode.tap,
                                            decoration: BoxDecoration(
                                              color: Colors.black87, // Background color of the tooltip
                                              borderRadius: BorderRadius.circular(10), // Rounded corners
                                              border: Border.all(color: Colors.white, width: 1), // Optional border
                                            ),
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            message: "Use categorical fields with fewer unique values to make comparisons (e.g., Customer Type, Year).",
                                            child: SizedBox(
                                              width: 40, // Define the width for the icon
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 30,
                                                color: isDarkMode ? Colors.blueAccent : Appcolorblue,
                                              ),
                                            ),
                                          ),



                                        ],
                                      ),

                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(height: 10,),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                        decoration:  InputDecoration(
                                          labelText: "Condition",
                                          labelStyle: TextStyle(
                                            color: isDarkMode ? Colors.white : Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          hoverColor: Colors.indigo.shade200,
                                          fillColor: isDarkMode ? Colors.black : Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF2962FF)),
                                          ),

                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                        ),
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        hint:  Text("Select Condition", style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),),
                                        value: reportcontroller.conditions
                                            .any((e) => e['value'] == reportcontroller.selectedCondition)
                                            ? reportcontroller.selectedCondition
                                            : null,

                                        items: reportcontroller.conditions.map((condition) {
                                          return DropdownMenuItem<String>(
                                            value: condition['value'],
                                            child: Text(condition['label']!),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            reportcontroller.selectedCondition = value;
                                          });
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      preferBelow: false,
                                      verticalOffset: 20,
                                      margin: const EdgeInsets.symmetric(horizontal: 50),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      triggerMode: TooltipTriggerMode.tap,
                                      decoration: BoxDecoration(
                                        color: Colors.black87, // Background color of the tooltip
                                        borderRadius: BorderRadius.circular(10), // Rounded corners
                                        border: Border.all(color: Colors.white, width: 1), // Optional border
                                      ),
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      message: "Use categorical fields with fewer unique values to make comparisons (e.g., Customer Type, Year).",
                                      child: SizedBox(
                                        width: 40, // Define the width for the icon
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 30,
                                          color: isDarkMode ? Colors.blueAccent : Appcolorblue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const  SizedBox(height: 10,),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2.0, horizontal: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          fillColor: isDarkMode
                                              ? Colors.black
                                              : Colors.white,
                                          hintText: 'Enter search value',
                                          hintStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          labelStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          addedFilters.add({
                                            'field': reportcontroller.selectedField!,
                                            'value': _searchController.text.trim(),
                                            'condition': reportcontroller.selectedCondition!,
                                          });


                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:isDarkMode
                                            ? const Color(0xFF4F76E2)
                                            : Appcolorblue,
                                        disabledForegroundColor: Colors.grey,
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
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding:
                                  const EdgeInsets.only(left: 8.0),
                                  child: Wrap(
                                    spacing: 8,
                                    children: addedFilters.map((filter) {
                                      String label = "${filter['field']} ${filter['condition']} ${filter['value']}";
                                      return Chip(
                                        label: Text(label),
                                        deleteIcon: const Icon(Icons.close),
                                        onDeleted: () {
                                          setState(() {
                                            addedFilters.remove(filter);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  reportcontroller.selectedCondition ="";
                                  reportcontroller.selectedField ="";
                                  _searchController.clear();
                                  addedFilters.clear();
                                });

                                Navigator.pop(context);
                              },
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () async {
                                reportcontroller.Getreportseachdata(addedFilters).then((value) {
                                  reportcontroller.selectedCondition ="";
                                  reportcontroller.selectedField ="";
                                  _searchController.clear();
                                  addedFilters.clear();
                                  if (value?['message'] == "Record not found") {

                                      reportcontroller.selectedCondition ="";
                                      reportcontroller.selectedField ="";
                                      _searchController.clear();
                                      addedFilters.clear();

                                  }
                                },);


                                Navigator.pop(context);
                              },
                              style:
                              ElevatedButton.styleFrom(
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

  void toggleOrientation() {
    if (isPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    setState(() {
      isPortrait = !isPortrait;
    });
  }



  Future<void> exportSvgToPdf(String svgData) async {
    try {
      // Load SVG as a Picture
      final pictureInfo = await vg.loadPicture(SvgStringLoader(svgData), null);
      final picture = pictureInfo.picture;

      // Convert Picture to Image
      final img = await pictureToImage(picture, 800, 400); // Adjust width/height
      ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      Uint8List imageData = byteData!.buffer.asUint8List();

      // Create a PDF document
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(imageData);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
                child: pw.Image(pdfImage)
            );
          },
        ),
      );
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/$reportitem.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      // Open the PDF
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

      print("✅ PDF saved at: ${file.path}");
    } catch (e) {
      print("❌ Error exporting SVG to PDF: $e");
    }
  }
  Future<ui.Image> pictureToImage(ui.Picture picture, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawPicture(picture);
    return await recorder.endRecording().toImage(width, height);
  }
}
