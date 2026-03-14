import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Image View",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Appcolorblue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Image.network(
                imageUrl,
                fit: BoxFit.none, // Important for actual size
                alignment: Alignment.topLeft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
