import 'package:cached_network_image/cached_network_image.dart';
import 'package:cuickdevuser/components/Appcolor.dart';
import 'package:cuickdevuser/components/ThemeProvider.dart';
import 'package:cuickdevuser/model/form_response.dart';
import 'package:cuickdevuser/screen/utility.dart';
import 'package:cuickdevuser/service/httpservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../service/apihelper.dart';
import 'package:cuickdevuser/widgets/custom_scrollable_text_with_indicator.dart'; // Adjust path as needed


class MyDataTableWidget extends StatefulWidget {
  final List<dynamic> fields;
  final RxList<Map<String, dynamic>> list;
  final String url;
  final String title;
  final String userstoryId;
  final int itemlength;

  const MyDataTableWidget(
      {Key? key,
      required this.userstoryId,
      required this.fields,
      required this.itemlength,
      required this.list,
      required this.url,
      required this.title})
      : super(key: key);

  @override
  State<MyDataTableWidget> createState() => _MyDataTableWidgetState();
}

class _MyDataTableWidgetState extends State<MyDataTableWidget> {
  final ImageUrlHelper imageUrlHelper = ImageUrlHelper();

  HttpServices httpServices = HttpServices();
  List<Map<String, dynamic>> datalist = [];
  List<dynamic> filterLabelList = [];
  List<Field> fields = []; // Normal list instead of RxList
  List<dynamic> labelList = []; // Normal list
  final ApiBaseHelper helper = ApiBaseHelper();
  bool showDataNotFound = false;
  @override
  void initState() {
    super.initState();
    getdata();
  }

  Future<void> getdata() async {
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showDataNotFound = true;
      });
    });
    await Getitemcode(widget.userstoryId);
    await Getattributefield(widget.userstoryId);
  }

  Future<void> Getitemcode(String formid) async {
    var res = await httpServices.GetListusecase(
      id: formid,
    );

    if (res != null && res['success'] == true) {
      var dataResponse = res['result']['data']; // Cast to List<dynamic>

      await GetdataList(dataResponse['appCode'], dataResponse['code']);
    } else {}
  }

  Future<void> Getattributefield(String formId) async {
    filterLabelList.clear();
    var res = await httpServices.Getlistattribute(formId: formId);
    if (res!['success'] == true) {
      var filteredList = res['result']['data'];
      // var sortedFilteredList = filteredList.where((label) {
      //   return widget.fields.any((field) => field['id'] == label['id']);
      // }).toList();
      var sortedFilteredList = filteredList.where((label) {
        return widget.fields
            .any((field) => field['id'].toString() == label['id'].toString());
      }).toList();

      sortedFilteredList.sort((a, b) {
        int indexA = widget.fields.indexWhere(
            (field) => field['id'].toString() == a['id'].toString());
        int indexB = widget.fields.indexWhere(
            (field) => field['id'].toString() == b['id'].toString());
        return indexA.compareTo(indexB);
      });

      for (var item in sortedFilteredList) {
        var matchingField = widget.fields.firstWhere(
          (field) => field['id'].toString() == item['id'].toString(),
        );

        if (matchingField != "") {
          item['show'] =
              matchingField['show'] ?? ''; // Add the `show` field from `fields`
          item['group'] = matchingField['group'] ??
              ''; // Add the `show` field from `fields`
          item['event'] = matchingField['event'] ?? '';
          item['rule'] = matchingField['rule'] ?? '';
          item['label'] = matchingField['label'] ?? '';
          item['parentFilter'] = matchingField['parentFilter'] ?? '';
        }
      }

      if (sortedFilteredList.isNotEmpty) {
        if (sortedFilteredList.isNotEmpty) {
          setState(() {
            filterLabelList = sortedFilteredList;
          });
        } else {}
      } else {}
    }
  }

  Future GetdataList(String url, String field) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('jsessionid') ?? '';

    if (sessionId.isEmpty) {
      return {'success': false, 'message': 'Session ID is missing'};
    }

    String loginId = '';

    loginId = prefs.getString('loginId') ?? '';

    Map<String, dynamic> reqBody = {
      "pageSize": "10",
      // "createdBy":loginId,
    };

    try {
      final response = await helper.postApi(
        "api/v1/${url}/${field}/search/0;jsessionid=$sessionId",
        reqBody,
      );

      datalist.clear();
      if (response != null && response['success'] == true) {
        var responseData = response['result']['data'] as List<dynamic>;

        setState(() {
          datalist.addAll(responseData.cast<Map<String, dynamic>>());
        });
      } else {
        return response;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error occurred while saving the form'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    int rowsToShow = widget.itemlength == 1 ? 11 : 5;

// Ensure we don’t exceed datalist length
    int actualRows =
        datalist.length < rowsToShow ? datalist.length : rowsToShow;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    bool isDarkMode = themeNotifier.themeMode == ThemeMode.dark;
    return filterLabelList.isNotEmpty && datalist.isNotEmpty
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black
                    : Color(0xFFF5F5F5), // Dark mode background
              ),
              border: TableBorder.all(
                  color: isDarkMode ? Colors.white : Color(0xFFE0E0E0)),
              dataRowMinHeight: 1,
              columnSpacing: 20,
              dividerThickness: 0.2,
              columns: [
                DataColumn(
                    label: Text(
                  'SNo.',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold),
                )),
                ...List.generate(
                  filterLabelList.length,
                  (index) {
                    final item = filterLabelList[index];
                    final displayLabel =
                        item['refKey'] == 1 && item['depAttribute'] != null
                            ? _capitalize(item['label'])
                            : _capitalize(item['label']);
                    return DataColumn(
                      label: Text(
                        displayLabel,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
              rows: List<DataRow>.generate(
                actualRows,
                (rowIndex) {
                  final attribute = datalist[rowIndex];
                  final dynamicValues = filterLabelList.map((label) {
                    if (label['refKey'] == 1 && label['depAttribute'] != null) {
                      return attribute[label['depAttribute']];
                    }
                    return attribute[label['code']];
                  }).toList();

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) => isDarkMode
                          ? (rowIndex.isEven
                              ? Colors.grey[900]
                              : Colors.grey[800])
                          : (rowIndex.isEven ? Colors.white : Colors.grey[200]),
                    ),
                    cells: [
                      DataCell(Text(
                        (rowIndex + 1).toString(),
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      )), // Serial number

                      ...List.generate(
                        dynamicValues.length,
                        (columnIndex) {
                          final label = filterLabelList[columnIndex]['code'];
                          final type = filterLabelList[columnIndex]['type'];
                          final labelItem = filterLabelList[columnIndex];
                          final displayLabel = _capitalize(labelItem['label']);

                          final value = dynamicValues[columnIndex];
                          if (type == 'file') {
                            final imageId = dynamicValues[columnIndex];
                            final imageUrl = (imageId != null && imageId != 0)
                                ? "https://cuickdev.com/API/DOCS/api/doc/${imageId}?t=0"
                                : imageUrlHelper.applogourl;
                            return DataCell(
                              imageUrl.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () async {
                                        var finalimageId =
                                            (imageId == null || imageId == 0)
                                                ? 0
                                                : imageId;
                                        final Uri testUrl = Uri.parse(
                                            'https://cuickdev.com/API/DOCS/api/doc/$finalimageId');
                                        await launchUrl(testUrl);
                                      },
                                      child: Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      '-',
                                      style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                            );
                          }
                          if (type == 'text') {
                            return DataCell(
                              Text(
                                (dynamicValues[columnIndex]
                                                ?.toString()
                                                .length ??
                                            0) >
                                        40
                                    ? '${dynamicValues[columnIndex]!.toString().substring(0, 40)}...'
                                    : dynamicValues[columnIndex]?.toString() ??
                                        '-',
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }
                          if (type == 'textarea') {
  final textValue = dynamicValues[columnIndex]?.toString() ?? "";
  // No need for _scrollController here anymore!

  return DataCell(
    GestureDetector(
      onTap: () {
        if (textValue.isNotEmpty && textValue != '-') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Full Textarea Mayank'),//example
              content: SingleChildScrollView(
                child: Text(textValue),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0,),
        child: Container(
          width: 250,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          // >>> THIS IS THE ONLY LINE THAT CHANGES IN YOUR BLOCK <<<
          // Replace the old SingleChildScrollView with your new widget
          child: CustomScrollableTextWithIndicator(
            textValue: textValue,
            isDarkMode: isDarkMode, // Pass your dark mode state
          ),
        ),
      ),
    ),
  );
}
                          if (type == 'location') {
                            final loc = value;
                            String textToShow = '-';

                            if (loc is Map &&
                                loc.containsKey('lat') &&
                                loc.containsKey('lng')) {
                              final lat = loc['lat'];
                              final lng = loc['lng'];
                              textToShow = '$lat, $lng';
                            } else if (loc is String &&
                                loc.contains('lat') &&
                                loc.contains('lng')) {
                              try {
                                // Clean string and parse manually if it's a string like "{lat: 22.7, lng: 75.8}"
                                final cleaned =
                                    loc.replaceAll(RegExp(r'[{}]'), '');
                                final parts = cleaned.split(',');
                                final lat = parts[0].split(':')[1].trim();
                                final lng = parts[1].split(':')[1].trim();
                                textToShow = '$lat, $lng';
                              } catch (_) {
                                textToShow = '-';
                              }
                            }

                            return DataCell(
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: GestureDetector(
                                  onTap: () async {
                                    if (textToShow != '-') {
                                      final uri = Uri.parse(
                                          'https://www.google.com/maps?q=$textToShow');
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Text(
                                    textToShow,
                                    style: const TextStyle(
                                        color: Color(0xFF2962FF),
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (type == 'boolean') {
                            return DataCell(
                              Text(
                                dynamicValues[columnIndex] == "" ||
                                        dynamicValues[columnIndex] == null
                                    ? ""
                                    : dynamicValues[columnIndex] == 1 ||
                                            dynamicValues[columnIndex] == "1"
                                        ? 'True'
                                        : 'False',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            );
                          }
                          if (type == 'email') {
                            return DataCell(GestureDetector(
                              onTap: () async {
                                final Uri emailLaunchUri = Uri(
                                  scheme: 'mailto',
                                  path: dynamicValues[columnIndex],
                                  query: Uri.encodeQueryComponent(
                                      'subject=Your Subject&body=Your message here'),
                                );
                                launchUrl(emailLaunchUri);
                              },
                              child: Text(
                                dynamicValues[columnIndex]?.toString() ?? '-',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ));
                          }
                          if (type == 'url') {
                            return DataCell(GestureDetector(
                              onTap: () async {
                                final Uri testUrl =
                                    Uri.parse(dynamicValues[columnIndex]);
                                print('testUrl====testUrl======>>${testUrl}');
                                await launchUrl(testUrl);
                              },
                              child: Text(
                                dynamicValues[columnIndex]?.toString() ?? '-',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ));
                          }
                          if (type == 'doc') {
                            final imageId = value ?? 0;
                            final imageUrl = (imageId != null &&
                                    imageId != 0 &&
                                    imageId != "")
                                ? "https://cuickdev.com/API/DOCS/api/doc/th/${imageId}?t=${DateTime.now().millisecondsSinceEpoch}"
                                : imageUrlHelper.applogourl;
                            return DataCell(
                              GestureDetector(
                                  onTap: () async {
                                    var finalimageId =
                                        (imageId == null || imageId == 0)
                                            ? 0
                                            : imageId;
                                    final Uri testUrl = Uri.parse(
                                        'https://cuickdev.com/API/DOCS/api/doc/$finalimageId');
                                    await launchUrl(testUrl);
                                  },
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      width: 24, // Set your desired width
                                      height: 24, // Set your desired height
                                    ), // Show a loading indicator while the image is loading
                                    errorWidget: (context, url, error) => Icon(Icons
                                        .error), // Show an error icon if the image fails to load
                                  )),
                            );
                          } else {
                            // Handle other fields
                            return DataCell(Text(
                              dynamicValues[columnIndex]?.toString() ?? '-',
                              style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black),
                            ));
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        : showDataNotFound
            ? const Center(
                child: const Text(
                  "Data Not Found",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              )
            : Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                    size: 50, color: Appcolorblue));
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
