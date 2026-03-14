import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:zoom_widget/zoom_widget.dart';

class ZoomableHtml extends StatefulWidget {
  final String htmlContent;
  final int datarow;

  ZoomableHtml({required this.htmlContent,required this.datarow});

  @override
  _ZoomableHtmlState createState() => _ZoomableHtmlState();
}

class _ZoomableHtmlState extends State<ZoomableHtml> {
  double _scale = 1.0;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return
    widget.datarow < 8 ?

      HtmlWidget(
        widget.htmlContent,
        textStyle: const TextStyle(fontSize: 13),
        // renderMode: RenderMode.listView,

        customStylesBuilder: (element) {
          if (element.localName == 'table') {
            return {
              'border': '1px solid #ddd',
              'border-collapse': 'collapse',
            };
          } else if (element.localName == 'th' || element.localName == 'td') {
            return {
              'border': '1px solid #ddd',
              'padding': '18px',
            };
          } else if (element.localName == 'tr') {
            if (element.parent != null) {
              int rowIndex = element.parent!.children.indexOf(element);
              return {'background-color': rowIndex % 2 == 0 ? '#f9f9f9' : '#ffffff'};
            }
          }
          return null;
        },
      ):

      SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: HtmlWidget(
        widget.htmlContent,
        textStyle: const TextStyle(fontSize: 13),
        customStylesBuilder: (element) {
          if (element.localName == 'table') {
            return {
              'border': '1px solid #ddd',
              'border-collapse': 'collapse',
              'width': '100%',
            };
          } else if (element.localName == 'th') {
            return {
              'border': '1px solid #ddd',
              'text-align': 'center',
              'padding': '18px',
            };
          } else if (element.localName == 'td') {
            return {
              'border': '1px solid #ddd',
              'padding': '18px',
              'vertical-align': 'middle',
              'text-align': 'center',
            };
          } else if (element.localName == 'tr') {
            if (element.parent != null) {
              int rowIndex = element.parent!.children.indexOf(element);
              return {
                'padding': '8px',
                'background-color': rowIndex % 2 == 0 ? '#f9f9f9' : '#ffffff',
              };
            }
          }
          return null;
        },
      ),
    );




  }
}
