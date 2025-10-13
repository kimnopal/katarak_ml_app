import 'package:get/get.dart';
import 'package:katarak_ml_app/bindings/home_binding.dart';
import 'package:katarak_ml_app/views/home_view.dart';

class AppPages {
  static final routes = [
    GetPage(name: '/', page: () => const HomeView(), binding: HomeBinding()),
  ];
}
