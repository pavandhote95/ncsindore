import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zoom_widget/zoom_widget.dart';

class ZoomableSvg extends StatefulWidget {
  final String svgContent;

  ZoomableSvg({required this.svgContent});

  @override
  _ZoomableSvgState createState() => _ZoomableSvgState();
}

class _ZoomableSvgState extends State<ZoomableSvg> {
  double _scale = 1.0;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:Alignment.topCenter,
      child: Zoom(
        initTotalZoomOut: true, // Ensures the image starts at the minimum size
        doubleTapZoom: true, // Allows double-tap zooming
        backgroundColor: Colors.transparent,
        centerOnScale: false,
        enableScroll: true,
        zoomSensibility: 0.05,
        maxScale: 5.0, // Adjust maximum zoom level
        canvasColor: Colors.transparent, // Keeps background transparent
        onPositionUpdate: (position){

        },
        onScaleUpdate: (scale,zoom){

        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 600,
            maxWidth: 400,
          ),
          child: SvgPicture.string(
            widget.svgContent,
            fit: BoxFit.contain, // Ensures it fits within the constraints
            colorFilter: const ColorFilter.srgbToLinearGamma(),
          ),
        ),
      ),
    );
  }
}
