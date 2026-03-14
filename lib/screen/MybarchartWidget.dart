import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'Zoomming_barChart.dart';
import 'package:provider/provider.dart';

class MybarchartWidget extends StatefulWidget {
  final String formid;
  final String url;
  final String title;
  final List<dynamic> fields;
  final int itemlength;
  const MybarchartWidget(
      {super.key,
      required this.formid,
      required this.itemlength,
      required this.url,
      required this.fields,
      required this.title});

  @override
  State<MybarchartWidget> createState() => MyPieChartWidgetState();
}

class MyPieChartWidgetState extends State<MybarchartWidget> {
  late TooltipBehavior _tooltipBehavior;
  late ZoomPanBehavior _zoomPanBehavior;
  List<dynamic> filterLabelList = []; // Normal list
  final List<String> allowedTypes = [
    'date',
    'time',
    'list',
  ];
  HttpServices httpServices = HttpServices();
  List<Field> fields = []; // Normal list instead of RxList
  List<dynamic> labelList = []; // Normal list
  Map<String, int> chartData = {}; // RxMap initialization
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
  String? collection;

  @override
  void initState() {
    super.initState();
    Getitemcode();

    _tooltipBehavior = TooltipBehavior(enable: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      // Enable panning
      enablePinching: true,
      // Enable zooming (pinching)
      zoomMode: ZoomMode.x,
      // Zoom only along the x-axis (optional, adjust as needed)
      //maxZoomLevel: 1.5, // Maximum zoom level (optional)
      enableDoubleTapZooming: true, // Optional: enable zooming on double tap
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
      // Handle any errors gracefully
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

    await  getAttributeField(widget.formid);
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
          style: TextStyle(fontSize: 11),
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
        .map((entry) => _ChartData(
              entry.key,
              entry.value,
              Colors.primaries[dataMap.keys.toList().indexOf(entry.key) %
                  Colors.primaries.length],
            ))
        .toList();

    final List<_ChartData> filteredChartData = chartdata.length > 7
        ? chartdata.sublist(chartdata.length - 7)
        : chartdata;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3.0, horizontal: 2),
                child: SizedBox(
                  width: 270,
                  height: 48,
                  child: DropdownButtonFormField<String>(
                    dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                    hint: Text(
                      'Select Field',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
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
                      if (_selectedfieldType != null) {
                      await  GetChart_API(
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
          SizedBox(height: 10),
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Spacer(), // Push the fullscreen button to the right
                    IconButton(
                      icon: Icon(Icons.fullscreen, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ZoomableBarChartScreen(
                                    dataMap: dataMap,
                                    selectedLabel: getSelectedLabel() ?? '',
                                    title: widget.title,
                                  )),
                        );
                      },
                    ),
                  ],
                ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Stack(
              children: [
                SizedBox(
                  height: widget.itemlength > 1 ? 190 : 400,
                  child: Container(
                    child: SfCartesianChart(
                        // title: ChartTitle(text: 'Yearly sales analysis'),
                        primaryXAxis: CategoryAxis(
                          labelStyle: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.black),
                        ),
                        // X-axis for categories (names)
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(
                              text: "Values",
                              textStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                          numberFormat: NumberFormat.compact(),
                          labelStyle: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.black),
                        ),
                        tooltipBehavior: _tooltipBehavior,
                        zoomPanBehavior: _zoomPanBehavior,
                        series: <CartesianSeries>[
                          // Renders line chart
                          ColumnSeries<_ChartData, String>(
                            name: getSelectedLabel()?.toUpperCase(),
                            dataSource: filteredChartData,
                            xValueMapper: (_ChartData data, _) => data.name,
                            yValueMapper: (_ChartData data, _) => data.value,
                            pointColorMapper: (_ChartData data, _) =>
                                data.color,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: false,
                              textStyle: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black),
                            ),
                            enableTooltip: true,
                            color: isDarkMode ? Colors.white : Colors.black,
                          )
                        ]),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              getSelectedLabel() ?? '',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.name, this.value, this.color);

  final String name; // Names from dataMap
  final double value; //Values from dataMap
  final Color color;
}
