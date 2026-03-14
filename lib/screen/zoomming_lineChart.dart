import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart%20';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';

class ZoomableLineChartScreen extends StatefulWidget {
  final Map<String, double> dataMap;
  final String selectedLabel;
  final String title;

  ZoomableLineChartScreen({required this.dataMap,required this.selectedLabel,required this.title});

  @override
  _ZoomableLineChartState createState() => _ZoomableLineChartState();
}

class _ZoomableLineChartState extends State<ZoomableLineChartScreen> {

  late TooltipBehavior _tooltipBehavior;
  late ZoomPanBehavior _zoomPanBehavior;


  @override
  void initState(){
    super.initState();
    _tooltipBehavior=TooltipBehavior(enable: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true, // Enable panning
      enablePinching: true, // Enable zooming (pinching)
      zoomMode: ZoomMode.x, // Zoom only along the x-axis (optional, adjust as needed)
      //maxZoomLevel: 1.5, // Maximum zoom level (optional)
      enableDoubleTapZooming: true, // Optional: enable zooming on double tap
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    final List<_ChartData> chartData = widget.dataMap.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();

    return Scaffold(
      backgroundColor: isDarkMode? Colors.black:Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor:isDarkMode? Colors.grey[850]:Appcolorblue,
        title: Text(widget.title+" Chart",
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2, // Top 20% for future content or empty space
            child: Container(
              color: Colors.transparent, // Placeholder for any content you want in the future
            ),
          ),
          Expanded(
            flex: 8, // Bottom 80% for the chart
            child: SfCartesianChart(
                title: ChartTitle(text: widget.title,
                    textStyle: TextStyle(color: isDarkMode ? Colors.white:Colors.black)),
                primaryXAxis: CategoryAxis(
                  labelRotation: 42,
                  title: AxisTitle(text: widget.selectedLabel,
                  textStyle: TextStyle(color: isDarkMode ? Colors.white:Colors.black)),
                  labelStyle: TextStyle(fontSize: 12,color: isDarkMode ? Colors.white:Colors.black),
                  // labelRotation: 45,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: "Values",
                  textStyle: TextStyle(color: isDarkMode ? Colors.white:Colors.black)),
                  numberFormat: NumberFormat.compact(),
                  majorGridLines: MajorGridLines(width: 1, dashArray: [5, 5]),
                  labelStyle: TextStyle(fontSize: 12,color: isDarkMode ? Colors.white:Colors.black),
                ),
              tooltipBehavior: _tooltipBehavior,
              zoomPanBehavior: _zoomPanBehavior,
              series: <CartesianSeries>[
                LineSeries<_ChartData, String>(
                  name: widget.selectedLabel.toUpperCase(),
                  dataSource: chartData,
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
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.name, this.value);
  final String name; // Names from dataMap
  final double value; // Values from dataMap
}