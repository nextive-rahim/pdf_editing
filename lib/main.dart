import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:jouls_labs_demo_app/sec/feature/authentication/controller/login_view_controller.dart';
import 'package:jouls_labs_demo_app/sec/routes/app_pages.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    Get.put(LoginViewController());
    return GetMaterialApp(
      navigatorObservers: [RouteObserver<ModalRoute<void>>()],
      title: 'Pdf Editing',
      debugShowCheckedModeBanner: false,
      getPages: AppPages.pages,
    );
  }
}
