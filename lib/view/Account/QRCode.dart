import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';
import '../../controller/Account/UserController.dart';
import 'package:get/get.dart';
import '../../theme/custom_themes/appbar_theme.dart';
import '../../theme/base_themes/colors.dart';

class Qrcode extends StatelessWidget {
  const Qrcode({super.key});

  @override
  Widget build(BuildContext context) {
      final UserController userController;
    if (!Get.isRegistered<UserController>()) {
      userController = Get.put(UserController(FirebaseFirestore.instance));
      userController.init();
    } else {
      userController = Get.find<UserController>();
    }

    final AuthController authController = Get.find<AuthController>();
    return Scaffold(
        backgroundColor: BColors.light,
        appBar: AppBar(
        title: const Text("QR Code"),
        backgroundColor: BAppBarTheme.lightAppBarTheme.backgroundColor,
        elevation: BAppBarTheme.lightAppBarTheme.elevation,
        iconTheme: BAppBarTheme.lightAppBarTheme.iconTheme,
        titleTextStyle: BAppBarTheme.lightAppBarTheme.titleTextStyle,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
         
           





        ),
      ),
    );
  }
}