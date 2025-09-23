import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/custom_themes/appbar_theme.dart';
import '../../theme/base_themes/colors.dart';

class Qrcode extends StatelessWidget {
  const Qrcode({super.key});

  @override
  Widget build(BuildContext context) {
    final String userUid = FirebaseAuth.instance.currentUser?.uid ?? "no-user";

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
        child: QrImageView(
          data: userUid,
          version: QrVersions.auto,
          size: 200.0,
          gapless: true,
        ),
      ),
    );
  }
}
