import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';
import 'package:cuickdevuser/controller/chart_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class ChartScreen extends StatefulWidget {
  final String appurl;
  final String menutitle;
  final String formID;

  const ChartScreen({super.key, required this.appurl, required this.menutitle, required this.formID});
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final List<String> _chartTypes = ['Table', 'Line', 'Bar', 'Doughnut', 'Pie'];
  final List<String> _valueRanges = ['value', 'Range'];
  final WelcomeController controller = Get.put(WelcomeController());
  String? _selectedChartType = '';
  String? _selectedfieldType = '';
  String? _selectedValueRange = '';
  final ChartController chartcontroller = Get.put(ChartController());
  int touchedIndex = -1;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    chartcontroller.chartData.clear();
  }

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
    // TODO: implement initState
    super.initState();
    chartcontroller.GetForm_API(widget.formID);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,

        body: SingleChildScrollView(
          child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10),
                        child: Obx(() {
                          final fieldItems = chartcontroller.filterlabellist
                              .map<DropdownMenuItem<String>>((item) {
                            return DropdownMenuItem<String>(
                              value: item['code'].toString(),
                              child: Text(item['label']),
                            );
                          }).toList();
          
                          return DropdownButtonFormField<String>(
                            hint: Text('Select Field'),
                            decoration: InputDecoration(
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
                            onChanged: (value) {
                              setState(() {
                                _selectedfieldType = value;
                              });

                            },
                          );
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10),
                        child: DropdownButtonFormField<String>(
                          hint: Text('Select Chart'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Appcolorblue),
                            ),
                          ),
                          value:
                          _selectedChartType!.isEmpty ? null : _selectedChartType,
                          // Handle empty case
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedChartType =
                                  newValue ?? ''; // Set an empty string if null
                            });
                          },
                          items: _chartTypes
                              .map<DropdownMenuItem<String>>((String chartType) {
                            return DropdownMenuItem<String>(
                              value: chartType,
                              child: Text(chartType),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10),
                        child: DropdownButtonFormField<String>(
                          hint: Text('Select value'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Appcolorblue),
                            ),
                          ),
                          value: _selectedValueRange!.isEmpty
                              ? null
                              : _selectedValueRange,
                          // Handle empty case
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedValueRange =
                                  newValue ?? ''; // Set an empty string if null
                            });
                          },
                          items: _valueRanges
                              .map<DropdownMenuItem<String>>((String chartType) {
                            return DropdownMenuItem<String>(
                              value: chartType,
                              child: Text(chartType),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            chartcontroller.GetChart_API(
          
                              _selectedValueRange!,
                              widget.appurl,
                              _selectedfieldType!,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                  height: 45,
                                  width: 120,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Color(0xFF2962FF)),
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.draw_outlined,
                                        size: 25,
                                        color: Color(0xFF2962FF),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        'Draw',
                                        style: TextStyle(
                                            color: Color(0xFF2962FF),
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Lato',
                                            fontSize: 15),
                                      )
                                    ],
                                  )),
                              Container(
                                  height: 45,
                                  width: 120,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Color(0xFF2962FF)),
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.star_border,
                                          size: 25,
                                          color: Color(0xFF2962FF),
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          'favourite',
                                          style: TextStyle(
                                              color: Color(0xFF2962FF),
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Lato',
                                              fontSize: 15),
                                        )
                                      ],
                                    ),
                                  )
                                // CircleAvatar(
                                //   backgroundColor: Color(0xFF2962FF),
                                //   radius: 25,
                                //   child: Icon(
                                //     Icons.draw,
                                //     size: 25,
                                //     color: Colors.white,
                                //   ),
                                // ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                SizedBox(
                  height: 400,
                  width: MediaQuery.of(context).size.width - 40,
                  child: Obx(() {
                    if (chartcontroller.chartData.isNotEmpty) {
                      return _buildChart();
                    } else {
                      return Center(child: Text('No data available'));
                    }
                  }),
                ),
              ]),
        ));
  }

  Widget _buildChart() {
    switch (_selectedChartType) {
      case 'Line':
        return AspectRatio(
          aspectRatio: 2,
          child: LineChart(

            curve: Curves.easeInOut,
            duration: Duration(milliseconds: 800),
            LineChartData(

              gridData: FlGridData(
                  show: true, verticalInterval: 0.3, horizontalInterval: 0.6),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // interval: 0.5,
                    reservedSize: 30, // Adjust space for the labels
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0), // Add some padding
                          child: Text(
                            value.toStringAsFixed(1), // Ensure single decimal format
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1, // Adjust this if you want fewer labels displayed
                    getTitlesWidget: (double value, TitleMeta meta) {
                      int index = value.toInt();
                      if (index < chartcontroller.chartData.keys.length) {
                        String name = chartcontroller.chartData.keys.elementAt(index);

                        // Shorten long labels if needed
                        String displayName = name.length > 18 ? '${name.substring(0, 18)}...' : name;

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6.0, // Add some spacing between the axis and label
                          child: displayName.length >18 ?
                          Transform.rotate(
                            angle: -0.3, // Rotate text for better fit (in radians, -0.4 is about -23 degrees)
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10, // Smaller font size for longer labels
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis, // Handles text overflow
                            ),
                          ):Text(
                              name,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10, // Smaller font size for longer labels
                                fontWeight: FontWeight.bold,
                              )),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),

              // Configure the chart borders
              borderData: FlBorderData(

                show: true,
                border: Border.all(color: Colors.grey),
              ),

              // Configure the line data
              lineBarsData: [
                LineChartBarData(
                  spots: chartcontroller.chartData.entries
                      .map((e) => FlSpot(
                    chartcontroller.chartData.keys
                        .toList()
                        .indexOf(e.key)
                        .toDouble(),
                    e.value.toDouble(),
                  ))
                      .toList(),
                  isCurved: false,
                  // Set to true for a smooth curve
                  color: Colors.indigo,
                  curveSmoothness: 0.3,
                  isStrokeCapRound: true,

                  barWidth: 3,
                  // Adjust the line thickness
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.indigo.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'Bar':
        return Padding(
          padding: const EdgeInsets.all(3.0),
          child: BarChart(
            swapAnimationDuration: Duration(milliseconds: 800), // Animation duration for bar chart
            swapAnimationCurve: Curves.easeInOut,  // Smooth easing for the animation


            BarChartData(

              gridData: FlGridData(
                show: true,
                verticalInterval: 0.3,
                horizontalInterval: 0.2,
              ),
              borderData: FlBorderData(
                border: const Border(
                  left: BorderSide(width: 1, color: Colors.grey),
                  bottom: BorderSide(width: 1, color: Colors.grey),
                  right: BorderSide(width: 1, color: Colors.grey),
                  top: BorderSide.none,
                ),
              ),
              groupsSpace: 10,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      String instituteName = chartcontroller.chartData.keys
                          .toList()[value.toInt()];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          instituteName,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato'),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // interval: 0.5,
                    reservedSize: 30, // Adjust space for the labels
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0), // Add some padding
                          child: Text(
                            value.toStringAsFixed(1), // Ensure single decimal format
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Lato',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: chartcontroller.chartData.entries
                  .toList() // Convert the Iterable to a List
                  .asMap() // Now you can use asMap()
                  .entries
                  .map((entry) {
                int index = entry.key;
                var e = entry.value;
                return BarChartGroupData(
                  x: index,
                  barsSpace: 10,
                  barRods: [
                    BarChartRodData(
                      width: 20,
                      color: customColors[index % customColors.length],
                      toY: e.value.toDouble(),
                      borderRadius: BorderRadius.circular(
                          5), // Rounded corners for a cleaner look
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      case 'Doughnut':
        return PieChart(
          PieChartData(

            sections: chartcontroller.chartData.entries.map((e) {
              final int index =
              chartcontroller.chartData.keys.toList().indexOf(e.key);
              return PieChartSectionData(

                color: customColors[index % customColors.length],
                value: e.value.toDouble(),
                title: '${e.key}\n${e.value}',
                radius: 100,
                titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              );
            }).toList(),

            sectionsSpace: 2,
            centerSpaceRadius:
            90, // Set a radius for the center space to create a doughnut effect
          ),
        );
      case 'Pie':

    return
      PieChart(
    swapAnimationDuration: Duration(milliseconds: 150), // Optional
    swapAnimationCurve: Curves.linear,
    PieChartData(
    sections: chartcontroller.chartData.entries.map((e) {
    final int index =
    chartcontroller.chartData.keys.toList().indexOf(e.key);
    return PieChartSectionData(
    color: customColors[index % customColors.length],
    value: e.value.toDouble(),
    title: '${e.key}\n${e.value}',
    // Display name and value inside the section
    radius: 180,
    titleStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white),
    );
    }).toList(),

    sectionsSpace: 0.3, // Space between each section
    centerSpaceRadius: 0, // No center space for a pie chart
    ),
    );
      case 'Table':
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            border: TableBorder.all(color: Colors.black12),
            columns: [
              DataColumn(
                  label: Text(
                    'Label',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
              DataColumn(
                  label: Text(
                    _selectedfieldType!.toUpperCase().toString(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
            ],
            rows: chartcontroller.chartData.entries.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text(e.key)), // Label
                  DataCell(Text(e.value.toString())), // Value
                ],
              );
            }).toList(),
          ),
        );
      default:
        return Center(child: Text('Invalid Chart Type'));
    }
  }
  List<PieChartSectionData> showingSections() {

    return chartcontroller.chartData.entries.map((entry) {
      int index = chartcontroller.chartData.keys.toList().indexOf(entry.key);
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 150.0 : 130.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      Color sectionColor = customColors[index % customColors.length];

      return PieChartSectionData(
        color: sectionColor,
        value: entry.value.toDouble(),
        title: '${entry.value.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows, // Shadow for better visibility
        ),
      );
    }).toList();
  }


}




class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}
