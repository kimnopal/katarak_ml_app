import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:katarak_ml_app/routes/app_pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: '/',
      getPages: AppPages.routes,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    );
  }
}
