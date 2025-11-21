import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';

// 🔹 دالة تأكيد (Confirm Dialog)
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, false), // هنا التعديل المهم
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true), // وهنا برضه
          child: const Text("Confirm"),
        ),
      ],
    ),
  );

  return result ?? false;
}

// 🔹 دالة فيدباك (Snackbar)
void showFeedback({
  required String title,
  required String message,
  Color backgroundColor = Colors.green,
}) {
  Get.snackbar(
    title,
    message,
    backgroundColor: backgroundColor,
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(12),
    borderRadius: 16,
    duration: const Duration(seconds: 2),
  );
}
