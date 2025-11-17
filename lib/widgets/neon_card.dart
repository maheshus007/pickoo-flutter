import 'package:flutter/material.dart';

/// Futuristic neon card with glow border and subtle hover/press animation.
class NeonCard extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const NeonCard({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final neon = Theme.of(context).colorScheme.primary;
    final baseBorder = Border.all(color: Colors.grey.shade800, width: 1.5);
    final selBorder = Border.all(color: neon, width: 2.0);
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: selected ? selBorder : baseBorder,
        boxShadow: selected
            ? [
                BoxShadow(color: neon.withOpacity(0.35), blurRadius: 16, spreadRadius: 1),
              ]
            : [
                const BoxShadow(color: Colors.black, blurRadius: 8, spreadRadius: 0),
              ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: card);
  }
}
