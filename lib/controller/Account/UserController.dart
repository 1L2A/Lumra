import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/Account/ProfileModel.dart';
import 'package:lumra_project/controller/auth/auth_controller.dart';

class UserController {
  final FirebaseFirestore db;

 
  final AuthController authController = Get.find<AuthController>();

  UserController(this.db);

  
  final user = Rxn<UserModel>();

 
  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController emailController;

  
  var role = ''.obs;
  var gender = ''.obs;
  var dob = DateTime.now().obs;

  
  void init() {
    nameController = TextEditingController();
    usernameController = TextEditingController();
    emailController = TextEditingController();

    final uid = authController.currentUser?.uid;
    if (uid != null) {
      _watchUser(uid);
    }
  }

 
  void _watchUser(String uid) {
    db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        user.value = UserModel.fromDoc(doc);

        nameController.text = user.value!.name;
        role.value = user.value!.role;
        emailController.text = user.value!.email;
        gender.value = user.value!.gender;
        dob.value = user.value!.dob;
      }
    });
  }

  
  void updateUserFromControllers() {
    if (user.value == null) return;

    final updatedUser = user.value!.copyWith(
      name: nameController.text,
      email: emailController.text,
      gender: gender.value,
      dob: dob.value,
      role: role.value,
    );

    final uid = authController.currentUser?.uid;
    if (uid != null) {
      db.collection('users').doc(uid).update(updatedUser.toJson());
    }
  }

 
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
  }
}
