import 'package:get/get.dart';
import 'package:katarak_ml_app/controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}
