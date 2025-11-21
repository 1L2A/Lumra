import 'package:flutter/material.dart';
import "package:lumra_project/view/ChatBootADHD/ChatBootADHD.dart";
import 'package:lumra_project/view/ChatBootADHD/ChatPage.dart';
import 'package:lumra_project/theme/base_themes/colors.dart';
import 'package:get/get.dart';
import 'dart:async';

// controllers
import 'package:lumra_project/controller/ChatBoot/baseController.dart';
import 'package:lumra_project/controller/ChatBoot/AdhdChatBootController.dart';
import 'package:lumra_project/controller/ChatBoot/careGiverController.dart';

class ChatBotWidget extends StatefulWidget {
  final String role; // 'adhd' or 'caregiver'
  const ChatBotWidget({super.key, required this.role});

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  bool _showHint = false; // start hidden
  Timer? _hintTimer;
  late final AdhdChatController adhdCtrl;
  late final CaregiverChatController cgCtrl;

  // choose controller based on role
  BaseChatController get _activeCtrl =>
      widget.role == 'caregiver' ? cgCtrl : adhdCtrl;

  @override
  void initState() {
    super.initState();

    // register once
    adhdCtrl = Get.put(AdhdChatController(), permanent: true);
    cgCtrl = Get.put(CaregiverChatController(), permanent: true);
    // Show after first frame, then auto-hide after 5s
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showHint = true);
      _hintTimer = Timer(const Duration(seconds: 7), () {
        ////////////////HERE WE HANDLE THE SECONDS OF THE 💬
        if (mounted) setState(() => _showHint = false);
      });
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _toggleChat() {
    // Hide hint when opening chat
    setState(() {
      _showHint = false;
    });
    _hintTimer?.cancel(); // stop any pending auto-hide

    // Navigate to dedicated chat page
    Get.to(() => ChatPage(controller: _activeCtrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Positioned(
          bottom: 170,
          right: 35,
          child: AnimatedOpacity(
            opacity: _showHint ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !_showHint,
              child: ChatHintBubble(
                message: widget.role == 'caregiver'
                    ? "💬 Need to talk? Chat with Lumra!"
                    : "👋 Need a new activity? Chat with Lumra!",
              ),
            ),
          ),
        ),

        // 💬 Chat button
        Positioned(
          bottom: 110,
          right: 23,
          child: Container(
            decoration: BoxDecoration(
              color: BColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              tooltip: 'Open chat',
              icon: const Icon(
                Icons.chat_bubble_rounded,
                color: BColors.primary,
                size: 24,
              ),
              onPressed: _toggleChat,
            ),
          ),
        ),
      ],
    );
  }
}

class ChatHintBubble extends StatelessWidget {
  final String message;
  const ChatHintBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
