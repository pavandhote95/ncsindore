import 'package:get/get.dart';

class AttendanceTableController extends GetxController {
  List<Map<String, String>> generateMonthData(int totalDays) {
    return List.generate(totalDays, (index) {
      int day = index + 1;
      bool present = day % 5 != 0;

      return {
        "day": day.toString(),
        "status": present ? "P" : "A",
        "hrs": present ? "9.30 hr" : "0 hr",
      };
    });
  }

  late final List<Map<String, String>> januaryData;
  late final List<Map<String, String>> novemberData;

  @override
  void onInit() {
    januaryData = generateMonthData(31);
    novemberData = generateMonthData(30);
    super.onInit();
  }
}
