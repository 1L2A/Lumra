import 'package:flutter/material.dart';
 import '../../theme/base_themes/colors.dart'; 
 import '../../theme/custom_themes/text_theme.dart'; 
import '../Account/viewProfile.dart';
 import 'package:get/get.dart'; 
 import '../../controller/Account/ProfileController.dart';




class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
   
    final UserController userController = Get.find<UserController>();

    return Scaffold(
      backgroundColor: BColors.light,
      appBar: AppBar(
        title: const Text("Account"),
        centerTitle: true,
        backgroundColor: BColors.light,
        elevation: 0,
        foregroundColor: BColors.texBlack,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 100,
              backgroundImage: AssetImage('assets/images/profile_image.jpeg'),
            ),
          ),
          const SizedBox(height: 20),
          // Name of user
          Obx(() => Text(
                userController.user.value?.name ?? "Loading...",
                style: BTextTheme.lightTextTheme.headlineMedium,
              )),
          const SizedBox(height: 20),
          // Options
          _buildOption(
            icon: Icons.edit,
            text: "Profile Information",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViewProfile()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildOption(
            icon: Icons.article,
            text: "Posts",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildOption(
            icon: Icons.bookmark,
            text: "Saved Posts",
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _buildOption(
            icon: Icons.qr_code,
            text: "Generate QR Code For Caregiver",
            onTap: () {},
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.textwhite,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: BTextTheme.lightTextTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
Widget _buildOption({required IconData icon, required String text, VoidCallback? onTap}) 
{ return ListTile( leading: Icon(icon, color: BColors.iconColor), 
title: Text(text, style: BTextTheme.lightTextTheme.headlineSmall),
 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: BColors.iconColor),
  onTap: onTap, ); }