import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/screen/zoomming_lineChart.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';

class Mylinechartwidget extends StatefulWidget {
  final String formid;
  final String url;
  final String title;
  final List<dynamic> fields;
  final int itemlength;
  const Mylinechartwidget(
      {super.key,
      required this.formid,
      required this.itemlength,
      required this.url,
      required this.fields,
      required this.title});

  @override
  State<Mylinechartwidget> createState() => MyPieChartWidgetState();
}

class MyPieChartWidgetState extends State<Mylinechartwidget> {
  late TooltipBehavior _tooltipBehavior;
  late ZoomPanBehavior _zoomPanBehavior;
  List<dynamic> filterLabelList = []; // Normal list
  final List<String> allowedTypes = [
    'date',
    'time',
    'list',
  ];
  String? collection;

  Map<String, int> chartData = {}; // RxMap initialization
  HttpServices httpServices = HttpServices();
  List<Field> fields = []; // Normal list instead of RxList
  List<dynamic> labelList = []; // Normal list

  String? _selectedfieldType = '';
  final String _selectedValueRange = 'value';
  final List<String> _valueRanges = ['value', 'Range'];
  List<Color> customColors = [
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

  @override
  void initState() {
    super.initState();
    Getitemcode();

    _tooltipBehavior = TooltipBehavior(enable: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      zoomMode: ZoomMode.x,
      enableDoubleTapZooming: true,
    );
  }

  Future<void> getAttributeField(String formId) async {
    try {
      var res = await httpServices.Getlistattribute(
          formId:
              formId); // Assuming getListAttribute is a method inside HttpServices
      if (res != null && res['success'] == true) {
        var filteredList = res['result']['data'];
        var sortedFilteredList = filteredList.where((label) {
          return widget.fields.any((field) =>
          field['id'].toString() == label['id'].toString() &&
              allowedTypes.contains(
                  field['type']) // Ensure the type is in allowedTypes
          );
        }).toList();

        sortedFilteredList.sort((a, b) {
          int indexA = widget.fields.indexWhere((field) =>
          field['id'].toString() == a['id'].toString());
          int indexB = widget.fields.indexWhere((field) =>
          field['id'].toString() == b['id'].toString());
          return indexA.compareTo(indexB);
        });

        for (var item in sortedFilteredList) {
          var matchingField = widget.fields.firstWhere(
                (field) => field['id'].toString() == item['id'].toString(),
          );

          if (matchingField != "") {
            item['show'] = matchingField['show'] ?? '';
            item['group'] = matchingField['group'] ?? '';
            item['event'] = matchingField['event'] ?? '';
            item['rule'] = matchingField['rule'] ?? '';
            item['label'] = matchingField['label'] ?? '';
            item['parentFilter'] = matchingField['parentFilter'] ?? '';
          }
        }

        if (sortedFilteredList.isNotEmpty) {
          setState(() {
            filterLabelList = sortedFilteredList;
          });
        } else {
          // Handle empty case
        }

      }
    } catch (e) {
      print('Error fetching attributes: $e');
    }
  }

  Future<void> GetChart_API(String type, String field) async {
    var res = await httpServices.Getdashboardchartdata(
        type: type.toLowerCase(),
        field: field,
        appname: collection!,
        menu: widget.title.toLowerCase());
    if (res?['success'] == true) {
      var result = res?['result'];
      var data = result['data'];
      setState(() {
        chartData = Map<String, int>.from(data)
            .map((key, value) => MapEntry(key, value as int));
      });
    } else {}
  }

  Future<void> Getitemcode() async {
    var res = await httpServices.GetListusecase(
      id: widget.formid,
    );

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data']; // Cast to List<dynamic>
      setState(() {
        collection = dataResponse['collectionName'];
      });

      await getAttributeField(widget.formid);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final fieldItems = filterLabelList.map<DropdownMenuItem<String>>((item) {
      return DropdownMenuItem<String>(
        value: item['code'].toString(),
        child: Text(
          item['label'],
          style: TextStyle(fontSize: 12),
        ),
      );
    }).toList();
    String? getSelectedLabel() {
      final selectedItem = filterLabelList.firstWhere(
        (item) => item['code'] == _selectedfieldType,
        orElse: () => null,
      );
      return selectedItem?['label'];
    }

    Map<String, double> dataMap = chartData.map(
      (key, value) => MapEntry(key, value.toDouble()),
    );

    final List<_ChartData> chartdata = dataMap.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    // Filter to show only the last 15 or fewer items
    final List<_ChartData> filteredChartData = chartdata.length > 7
        ? chartdata.sublist(chartdata.length - 7)
        : chartdata;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Apply Flexible to the DropdownButtonFormField
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3.0, horizontal: 2),
                child: SizedBox(
                  width: 270,
                  height: 48,
                  child: DropdownButtonFormField<String>(
                    hint: Text(
                      'Select Field',
                      style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      fillColor: isDarkMode ? Colors.black : Colors.white,
                      labelStyle: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white : Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Appcolorblue),
                      ),
                    ),
                    value: fieldItems.any(
                            (element) => element.value == _selectedfieldType)
                        ? _selectedfieldType
                        : null,
                    items: fieldItems,
                    onChanged: (value) async {
                      setState(() {
                        _selectedfieldType = value;
                      });

                      // Call the method if the other dropdown has a value
                      if (_selectedfieldType != null) {
                        await GetChart_API(
                          _selectedValueRange!,
                          _selectedfieldType!,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          chartData.isEmpty
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Record not found',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              :
              //  const SizedBox(height: 10),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(), // Push the fullscreen button to the right
                    IconButton(
                      icon: Icon(Icons.fullscreen, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZoomableLineChartScreen(
                              dataMap: dataMap,
                              selectedLabel: getSelectedLabel() ?? '',
                              title: widget.title,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: SizedBox(
              // height: 190,
              height: widget.itemlength > 1 ? 190 : 400,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(
                      text: "Values",
                      textStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black)),
                  numberFormat: NumberFormat.compact(),
                  labelStyle: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                tooltipBehavior: _tooltipBehavior,
                zoomPanBehavior: _zoomPanBehavior,
                series: <CartesianSeries>[
                  LineSeries<_ChartData, String>(
                    name: getSelectedLabel()?.toUpperCase(),
                    dataSource: filteredChartData,
                    xValueMapper: (_ChartData data, _) => data.name,
                    yValueMapper: (_ChartData data, _) => data.value,
                    dataLabelSettings: DataLabelSettings(isVisible: false),
                    enableTooltip: true,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: Colors.red,
                      borderWidth: 2,
                      borderColor: Colors.white,
                      height: 6,
                      width: 6,
                    ),
                  )
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              getSelectedLabel() ?? '', // Display the selected label
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.name, this.value);

  final String name; // Names from dataMap
  final double value; //Values from dataMap
}
