
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
    iconTheme: const IconThemeData(color: Colors.white),
    backgroundColor: Appcolorblue,
    title: const Text('Dashboard Screen',
    style: TextStyle(color: Colors.white, fontSize: 20)),
    ),
      body: Container(),
    );
  }
}
