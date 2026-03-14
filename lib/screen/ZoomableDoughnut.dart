import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';

class ZoomableDoughnut extends StatefulWidget {
  final Map<String, double> dataMap;
  final String selectedLabel ;
  final String title;

  ZoomableDoughnut({required this.dataMap,required this.selectedLabel,required this.title});

  @override
  _PieChartScreenState createState() => _PieChartScreenState();

}

class _PieChartScreenState extends State<ZoomableDoughnut> {
  late TooltipBehavior _tooltipBehavior;
  late ZoomPanBehavior _zoomPanBehavior;


  @override
  void initState(){
    super.initState();
    _tooltipBehavior=TooltipBehavior(enable: true);
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true, // Enable panning
      enablePinching: true, // Enable zooming (pinching)
      zoomMode: ZoomMode.xy, // Zoom only along the x-axis (optional, adjust as needed)
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
      backgroundColor:isDarkMode? Colors.black:Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor:isDarkMode? Colors.grey[850]:Appcolorblue,
        title: Text(widget.title+" Chart",
            style: TextStyle(color: Colors.white, fontSize: 20)),
      ),

      body: Column(
        children: [
          // Empty space or content above the chart
          Expanded(
            flex: 2, // Top 20% for future content or empty space
            child: Container(
              color: Colors.transparent, // Placeholder for any content you want in the future
            ),
          ),
          // Chart occupying 80% of the screen height
          Expanded(
            flex: 8, // Bottom 80% for the chart
            child: Container(

              child:
              SfCircularChart(
                tooltipBehavior: _tooltipBehavior,
                legend: Legend(isVisible: true,textStyle:  TextStyle(color:isDarkMode ? Colors.white:Colors.black,fontSize: 12,fontWeight: FontWeight.bold)  ),
                series: <CircularSeries>[
                  DoughnutSeries<_ChartData, String>(
                    dataSource: chartData,
                    pointColorMapper: (_ChartData data, _) => data.color,
                    xValueMapper: (_ChartData data, _) => data.name,
                    yValueMapper: (_ChartData data, _) => data.value,
                    innerRadius: '50%', // Controls the doughnut hole size
                    cornerStyle: CornerStyle.bothFlat,

                    explode: true,
                    explodeIndex: 1,
                    dataLabelSettings:  DataLabelSettings(isVisible: true,
                      textStyle: TextStyle(  color:isDarkMode ? Colors.white:Colors.black,
                        fontSize: 13,fontWeight: FontWeight.bold,),),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 20.0), // Add bottom padding
            child: Center(
              child: Text(
                widget.selectedLabel, // Display the selected label
                style:  TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:isDarkMode ? Colors.white:Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

}

class _ChartData {
  _ChartData(this.name, this.value,[this.color]);
  final String name; // Names from dataMap
  final double value;//Values from dataMap
  final Color? color;
}