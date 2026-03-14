// image_url_helper.dart

import 'package:get/get.dart';
import 'package:cuickdevuser/controller/WelcomeController.dart';

import '../controller/login_controller.dart';

/// A helper class to manage image URLs, particularly the app logo.
class ImageUrlHelper {
  final WelcomeController _welcontroller = Get.find<WelcomeController>();
  // final LoginController controller =  Get.put(LoginController(), permanent: true);

  /// A dynamic getter for the app logo URL.
  String get applogourl {
    final imageId = _welcontroller.imageId.value;
    // final imageId = controller.appimageid.value;

    if (imageId == 0) {
      return "https://cuickdev.com/API/DOCS/api/doc/th/0?t==${DateTime.now().millisecondsSinceEpoch}";
    }

    return "https://cuickdev.com/API/DOCS/api/doc/th/${_welcontroller.imageId.value}?t==${DateTime.now().millisecondsSinceEpoch}";
  }
}