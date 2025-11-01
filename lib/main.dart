import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import 'package:lumra_project/controller/Registration/registration_flow_controller.dart';
import 'package:lumra_project/navigation/role_aware_root.dart';
import 'package:lumra_project/view/Account/AccountPage.dart';
//import "package:lumra_project/view/ChatBoot/ChatBootADHD/ChatBootADHD.dart";
import 'package:lumra_project/view/SplashPage/splashScreen.dart';
import 'package:lumra_project/view/welcomepage.dart';
import 'package:lumra_project/theme/custom_themes/text_field_theme.dart';
import 'package:lumra_project/view/homepage/adhdHomePage.dart';
import 'package:lumra_project/theme/theme.dart';
import 'package:flutter/services.dart';
//import "package:lumra_project/view/ChatBoot/ChatBotWidget.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/Activity/ActivityController.dart';
import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  //1- Register AuthController first
  Get.put(AuthController()); //dont worry it wont effect the app

  // 2- Then register RegistrationFlowController
  Get.put(RegistrationFlowController());

  // 3- Then Activitycontroller (now AuthController exists)
  Get.put<Activitycontroller>(
    Activitycontroller(FirebaseFirestore.instance),
    permanent: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AuthController()); // to make it shared (to get the user data)

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Stack(
        children: [
          GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lumra',
            theme: LumraAppTheme.lightTheme,
            home: SplashGifScreen(
              nextScreen: Welcomepage(),
            ), //splash then we start! :)
            getPages: [GetPage(name: '/app', page: () => RoleAwareRoot())],
          ),
          //const ChatBotWidget(), //  stays visible on pages but dont forget to remove it from login, splash, other pages
        ],
      ),
    );
  }
}
