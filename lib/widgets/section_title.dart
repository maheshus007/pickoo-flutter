import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    final neon = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(height: 2, width: 64, decoration: BoxDecoration(color: neon, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }
}
