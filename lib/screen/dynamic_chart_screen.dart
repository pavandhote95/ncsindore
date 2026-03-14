import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';
import 'package:cuickdevuser/controller/dynamic_chart.dart';
import 'package:cuickdevuser/screen/ZoomableDoughnut.dart';
import 'package:cuickdevuser/screen/Zoomming_barChart.dart';
import 'package:cuickdevuser/screen/zooming_piechart.dart';
import 'package:cuickdevuser/screen/zoomming_lineChart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../components/Appcolor.dart';
import 'Menucontroller.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DynamicChartScreen extends StatefulWidget {
  final String appurl;
  final String menutitle;
  final String formID;

  const DynamicChartScreen(
      {super.key,
      required this.appurl,
      required this.menutitle,
      required this.formID});

  @override
  State<DynamicChartScreen> createState() => _dynamicChartScreenState();
}

class _dynamicChartScreenState extends State<DynamicChartScreen> {
  final WelcomeController controller = Get.put(WelcomeController());
  final Dynamic_chart dynamiccontroller = Get.put(Dynamic_chart());
  Menucontroller menucontroller = Get.put(Menucontroller());
  int touchedIndex = -1;
  String? _selectedfieldType = '';
  TooltipBehavior? _tooltipBehavior;
  ZoomPanBehavior? _zoomPanBehavior;
  final GlobalKey _globalKey = GlobalKey();
  List<Color> customColors = const [
    Color(0xFF495057), // #1E3E62
    Color(0xFF643462), // #0B192C
    Color(0xFFffc107), // #000000
    Color(0xFF6f42c1), // #451952
    Color(0xFF198754), // #662549
    Color(0xFFAE445A), // #AE445A
    Color(0xFF20c997),
    Color(0xFFfd7e14), // #F39F5A
    Color(0xFF6610f2), // #F39F5A
  ];

  @override
  void dispose() {
    super.dispose();
    Get.delete<Dynamic_chart>();
  }
late TrackballBehavior _trackballBehavior;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
     _trackballBehavior = TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
  );
    _tooltipBehavior = TooltipBehavior(enable: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      // Enable panning
      enablePinching: true,
      // Enable zooming (pinching)
      zoomMode: ZoomMode.x,
      // Zoom only along the x-axis (optional, adjust as needed)
      enableDoubleTapZooming: true, // Optional: enable zooming on double tap
    );
    dynamiccontroller.getuser_role_access(widget.formID);
    dynamiccontroller.GetForm_API(widget.formID);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),


            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {

      final fieldItems = [
      DropdownMenuItem<String>(
      value: null,
      child: Text(
      '-Select Field-',
      style: TextStyle(
      color: isDarkMode ? Colors.white : Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      ),
      ),
      ),
      ...dynamiccontroller.filterlabellist
          .map<DropdownMenuItem<String>>((item) {
      return DropdownMenuItem<String>(
      value: item['code'].toString(),
      child: Text(item['label']),
      );
      }).toList(),
      ];
return  Expanded(
                  child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                  labelText: 'Select Field',
                  hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.black : Colors.white,
                  labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                  ),
                  ),
                  dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  disabledHint: const Text(
                  'No fields available',
                  style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  ),
                  ),
                  value: fieldItems.any((element) => element.value == _selectedfieldType)
                  ? _selectedfieldType
                      : null,
                  items: fieldItems.map((item) {
                  return DropdownMenuItem<String>(
                  value: item.value,
                  child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Text(
                  (item.child as Text).data ?? '',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  ),
                  ),
                  );
                  }).toList(),
                  selectedItemBuilder: (BuildContext context) {
                      return fieldItems.map<Widget>((item) {
                        String label =   (item.child as Text).data ?? '';
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.55, // adjust width
                          ),
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
                        );
                      }).toList();
                    },
                  style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  ),
                  onChanged: fieldItems.isEmpty
                  ? null
                      : (value) {
                  setState(() {
                  _selectedfieldType = value;
                  });

                  if (value != null) {
                    dynamiccontroller.isuserFilter.value !=0?
                    dynamiccontroller.GetdataList(
                        dynamiccontroller.code.value,dynamiccontroller.appCode.value,      _selectedfieldType!,
                    ):
                  dynamiccontroller.GetChart_API(
                  '',
                  widget.appurl,
                  _selectedfieldType!,
                  );
                  }
                  },
                  ),
                  );
      }

                ),

                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: GestureDetector(
                    onTap: () {
                      _captureAndPrintFullContent();
                    },
                    child: Image.asset(
                      'assets/icons/export-pdf.png',
                      width: 45,
                      height: 45,
                      color: isDarkMode ? Colors.white : Appcolorblue,
                    ),
                  ),
                ),
              ],
            ),



            const SizedBox(height: 20),
            if (_selectedfieldType != null && _selectedfieldType!.isNotEmpty)
              Expanded(
                  child: _buildChartsForSelectedField(_selectedfieldType!)),
          ],
        ),
      ),
    );
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

  Widget _buildChartsForSelectedField(String fieldCode) {
    return Obx(() {
      var valueCounts = dynamiccontroller.chartData;

      // Find the selected field from filterlabellist
      var selectedField = dynamiccontroller.filterlabellist.firstWhere(
        (item) => item['code'] == fieldCode,
        orElse: () => null,
      );

      bool isDateType =
          selectedField != null && selectedField['type'] == "date";
      bool isTimeType =
          selectedField != null && selectedField['type'] == "time";
      bool isLargeData = valueCounts.length > 10;

      return SingleChildScrollView(
        child: RepaintBoundary(
          key: _globalKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isDateType ||
                  isTimeType) // Show only Line Chart for date type fields
                _buildChartContainer(
                  child: _buildLineChart(valueCounts),
                )
              else if (isLargeData) // Only Bar Chart if data length > 10
                _buildChartContainer(
                  child: _buildBarChart(valueCounts),
                )
              else ...[
                _buildChartContainer(child: _buildBarChart(valueCounts)),
                const SizedBox(height: 40),
                _buildChartContainer(child: _buildPieChart(valueCounts)),
                const SizedBox(height: 40),
                _buildChartContainer(child: _buildDoughnutChart(valueCounts)),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildChartContainer({required Widget child}) {
    return Container(
      width: double.infinity, // Take up full width
      height: 420, // Set a fixed height for each chart
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),

      child: child,
    );
  }

  String? getSelectedLabel() {
    final selectedItem = dynamiccontroller.filterlabellist.firstWhere(
      (item) => item['code'] == _selectedfieldType,
      orElse: () => null,
    );
    return selectedItem?['label'];
  }

  Widget _buildBarChart(Map<String, double> valueCounts) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;

    final List<_ChartData> chartData = valueCounts.entries
        .map((entry) => _ChartData(
              entry.key,
              entry.value,
              Colors.primaries[valueCounts.keys.toList().indexOf(entry.key) %
                  Colors.primaries.length],
            ))
        .toList();

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.grey, spreadRadius: 0.5, offset: Offset(0.2, 1)),
          ]),
      child: Column(
        children: [
          Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ZoomableBarChartScreen(
                              dataMap: dynamiccontroller.chartData,
                              selectedLabel: getSelectedLabel() ?? '',
                              title: widget.menutitle,
                            )),
                  );
                },
                child: Image.asset(
                  'assets/Backgrounds/chartview.png',
                  width: 40,
                  height: 40,
                ),
              )),
          chartData.length <= 10
              ? SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: SfCartesianChart(
                      tooltipBehavior: _tooltipBehavior,
                      trackballBehavior: _trackballBehavior, //mayank
                      zoomPanBehavior: _zoomPanBehavior,
                      legend: Legend(
                          isVisible: true,
                          textStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      enableAxisAnimation: true,
                      primaryXAxis: CategoryAxis(
                        autoScrollingMode: AutoScrollingMode.start,
                        labelRotation: 42,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 11, // Y-axis label font size
                          fontWeight: FontWeight.bold, // Y-axis label weight
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        enableAutoIntervalOnZooming: true,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 10, // Y-axis label font size
                          fontWeight: FontWeight.bold, // Y-axis label weight
                        ),
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<_ChartData, String>(
                          name: _selectedfieldType?.toUpperCase(),
                          dataSource: chartData,
                          xValueMapper: (_ChartData data, _) => data.name,
                          yValueMapper: (_ChartData data, _) => data.value,
                          pointColorMapper: (_ChartData data, _) => data.color,
                          dataLabelSettings: DataLabelSettings(
                            isVisible: false,
                            textStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          enableTooltip: true,
                        )
                      ]),
                )
              : SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: SfCartesianChart(
                      tooltipBehavior: _tooltipBehavior,
                      trackballBehavior: _trackballBehavior, //mayank
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: true,
                        enablePanning: true,
                        zoomMode: ZoomMode.y,
                        enableDoubleTapZooming: true,
                      ),
                      // legend:const Legend(isVisible: true,),
                      legend: Legend(
                          isVisible: true,
                          textStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      enableAxisAnimation: true,
                      primaryXAxis: CategoryAxis(
                        labelRotation: 270,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 13, // Y-axis label font size
                          fontWeight: FontWeight.bold, // Y-axis label weight
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        enableAutoIntervalOnZooming: true,
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 10, // Y-axis label font size
                          fontWeight: FontWeight.bold, // Y-axis label weight
                        ),
                      ),
                      series: <CartesianSeries>[
                        BarSeries<_ChartData, String>(
                          name: _selectedfieldType?.toUpperCase(),
                          dataSource: chartData,
                          xValueMapper: (_ChartData data, _) => data.name,
                          yValueMapper: (_ChartData data, _) => data.value,
                          pointColorMapper: (_ChartData data, _) => data.color,
                          dataLabelSettings: DataLabelSettings(
                            isVisible: false,
                            textStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          enableTooltip: true,

                        )
                      ]),
                ),
        ],
      ),
    );
  }


  Widget _buildLineChart(Map<String, double> valueCounts) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final List<_ChartData> chartData = valueCounts.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.grey, spreadRadius: 0.5, offset: Offset(0.2, 1)),
          ]),
      child: Column(
        children: [
          Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ZoomableLineChartScreen(
                              dataMap: dynamiccontroller.chartData,
                              selectedLabel: getSelectedLabel() ?? '',
                              title: widget.menutitle,
                            )),
                  );
                },
                child: Image.asset(
                  'assets/Backgrounds/chartview.png',
                  width: 40,
                  height: 40,
                ),
              )),

          SfCartesianChart(
            primaryXAxis: CategoryAxis(
              labelRotation: 42,
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 13, // Y-axis label font size
                fontWeight: FontWeight.bold, // Y-axis label weight
              ),
            ),
            primaryYAxis: NumericAxis(
              enableAutoIntervalOnZooming: true,
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 10, // Y-axis label font size
                fontWeight: FontWeight.bold, // Y-axis label weight
              ),
            ),
            tooltipBehavior: _tooltipBehavior,
            zoomPanBehavior: _zoomPanBehavior,
            legend: Legend(
                isVisible: true,
                textStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            enableAxisAnimation: true,
            series: <CartesianSeries>[
              LineSeries<_ChartData, String>(
                name: _selectedfieldType!.toUpperCase(),
                dataSource: chartData,
                xValueMapper: (_ChartData data, _) => data.name,
                yValueMapper: (_ChartData data, _) => data.value,
                dataLabelSettings: DataLabelSettings(
                  isVisible: false,
                  textStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                enableTooltip: true,
                color: Colors.red,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  shape: DataMarkerType.circle,
                  color: Colors.red,
                  borderWidth: 2,
                  borderColor: Colors.white,
                  height: 9,
                  width: 9,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> valueCounts) {
    final List<_ChartData> chartData = valueCounts.entries
        .map((entry) => _ChartData(
              entry.key,
              entry.value,
              Colors.primaries[valueCounts.keys.toList().indexOf(entry.key) %
                  Colors.primaries.length],
            ))
        .toList();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.grey, spreadRadius: 0.5, offset: Offset(0.2, 1)),
          ]),
      child: Column(
        children: [
          Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PieChartScreen(
                              dataMap: dynamiccontroller.chartData,
                              selectedLabel: getSelectedLabel() ?? '',
                              title: widget.menutitle,
                            )),
                  );
                },
                child: Image.asset(
                  'assets/Backgrounds/chartview.png',
                  width: 40,
                  height: 40,
                ),
              )),

          chartData.isEmpty
              ? SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                trackballBehavior: _trackballBehavior, //mayank
                zoomPanBehavior: _zoomPanBehavior,
                legend: Legend(
                    isVisible: false,
                    textStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                enableAxisAnimation: true,
                primaryXAxis: CategoryAxis(
                  autoScrollingMode: AutoScrollingMode.start,
                  labelRotation: 42,
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 11, // Y-axis label font size
                    fontWeight: FontWeight.bold, // Y-axis label weight
                  ),
                ),
                primaryYAxis: NumericAxis(
                  enableAutoIntervalOnZooming: true,
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 10, // Y-axis label font size
                    fontWeight: FontWeight.bold, // Y-axis label weight
                  ),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<_ChartData, String>(
                    name: _selectedfieldType?.toUpperCase(),
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.name,
                    yValueMapper: (_ChartData data, _) => data.value,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: false,
                      textStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    enableTooltip: true,
                  )
                ]),
          )
              :
          SfCircularChart(
            tooltipBehavior: _tooltipBehavior,
            legend: Legend(
                isVisible: true,
                textStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            series: <CircularSeries>[
              PieSeries<_ChartData, String>(
                  dataSource: chartData,
                  pointColorMapper: (_ChartData data, _) => data.color,
                  xValueMapper: (_ChartData data, _) => data.name,
                  yValueMapper: (_ChartData data, _) => data.value,
                  strokeColor: Colors.black,
                  explode: true,
                  // First segment will be exploded on initial rendering
                  explodeIndex: 1,
                  strokeWidth: 0.3,
                  // radius: "98",
                  enableTooltip: true,
                  dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      labelPosition: ChartDataLabelPosition.outside,
                      useSeriesColor: true))
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoughnutChart(Map<String, double> data) {
    final List<_ChartData> chartData = data.entries
        .map((entry) => _ChartData(
              entry.key,
              entry.value,
              Colors.accents[data.keys.toList().indexOf(entry.key) %
                  Colors.accents.length],
            ))
        .toList();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.grey, spreadRadius: 0.5, offset: Offset(0.2, 1)),
          ]),
      child: Column(
        children: [
          Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ZoomableDoughnut(
                              dataMap: dynamiccontroller.chartData,
                              selectedLabel: getSelectedLabel() ?? '',
                              title: widget.menutitle,
                            )),
                  );
                },
                child: Image.asset(
                  'assets/Backgrounds/chartview.png',
                  width: 40,
                  height: 40,
                ),
              )),
          chartData.isEmpty
              ? SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SfCartesianChart(
                tooltipBehavior: _tooltipBehavior,
                trackballBehavior: _trackballBehavior, //mayank
                zoomPanBehavior: _zoomPanBehavior,
                legend: Legend(
                    isVisible: false,
                    textStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                enableAxisAnimation: true,
                primaryXAxis: CategoryAxis(
                  autoScrollingMode: AutoScrollingMode.start,
                  labelRotation: 42,
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 11, // Y-axis label font size
                    fontWeight: FontWeight.bold, // Y-axis label weight
                  ),
                ),
                primaryYAxis: NumericAxis(
                  enableAutoIntervalOnZooming: true,
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 10, // Y-axis label font size
                    fontWeight: FontWeight.bold, // Y-axis label weight
                  ),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<_ChartData, String>(
                    name: _selectedfieldType?.toUpperCase(),
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.name,
                    yValueMapper: (_ChartData data, _) => data.value,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: false,
                      textStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    enableTooltip: true,
                  )
                ]),
          )
              :
          SfCircularChart(
            tooltipBehavior: _tooltipBehavior,
            legend: Legend(
                isVisible: true,
                textStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            series: <CircularSeries>[
              DoughnutSeries<_ChartData, String>(
                dataSource: chartData,
                pointColorMapper: (_ChartData data, _) => data.color,
                xValueMapper: (_ChartData data, _) => data.name,
                yValueMapper: (_ChartData data, _) => data.value,
                innerRadius: '50%',
                // Controls the doughnut hole size
                cornerStyle: CornerStyle.bothFlat,

                explode: true,
                explodeIndex: 1,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.name, this.value, [this.color]);

  final String name; // Names from dataMap
  final double value; //Values from dataMap
  final Color? color;
}
