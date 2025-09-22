import 'package:flutter/material.dart';
import 'package:lumra_project/theme/base_themes/sizes.dart';

class MoodRow extends StatelessWidget {
  const MoodRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _MoodIcon(icon: Icons.sentiment_satisfied_alt, color: Colors.green),
        _MoodIcon(icon: Icons.sentiment_neutral, color: Colors.brown),
        _MoodIcon(icon: Icons.sentiment_dissatisfied, color: Colors.red),
      ],
    );
  }
}

class _MoodIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MoodIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 45,
      backgroundColor: Colors.transparent,
      child: Icon(icon, color: color, size: 40),
    );
  }
}
