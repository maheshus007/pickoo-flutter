import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Modern draggable compare slider with circular handle, animated snapping and optional labels.
class CompareSlider extends StatefulWidget {
  final Uint8List before;
  final Uint8List after;
  final String beforeLabel;
  final String afterLabel;
  final bool showLabels;
  const CompareSlider({
    super.key,
    required this.before,
    required this.after,
    this.beforeLabel = 'Original',
    this.afterLabel = 'Edited',
    this.showLabels = true,
  });

  @override
  State<CompareSlider> createState() => _CompareSliderState();
}

class _CompareSliderState extends State<CompareSlider> with SingleTickerProviderStateMixin {
  double _position = 0.5; // 0..1 fraction
  late AnimationController _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapAnimation = Tween<double>(begin: _position, end: target).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapController
      ..reset()
      ..forward();
    _snapController.addListener(() {
      setState(() {
        _position = _snapAnimation!.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return GestureDetector(
        onHorizontalDragUpdate: (d) {
          setState(() {
            _position = (d.localPosition.dx / width).clamp(0.0, 1.0);
          });
        },
        onHorizontalDragEnd: (details) {
          // Snap to near edges if close.
          if (_position < 0.08) _animateTo(0.0); else if (_position > 0.92) _animateTo(1.0);
        },
        child: Stack(children: [
          // Show AFTER full-size as baseline.
          Positioned.fill(child: Image.memory(widget.after, fit: BoxFit.cover)),
          // Overlay BEFORE cropped to slider position but still scaled to container size.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: (width * _position).clamp(0.0, width),
            child: ClipRect(
              child: SizedBox.expand(
                child: Image.memory(
                  widget.before,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Vertical divider line
          Positioned(
            left: (_position * width) - 0.5,
            top: 0,
            bottom: 0,
            child: Container(width: 1.5, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
          ),
          // Drag handle
          Positioned(
            left: _position * width - 20,
            top: constraints.maxHeight / 2 - 20,
            child: _Handle(
              onTapCenter: () {
                // Quick toggle center
                _animateTo(0.5);
              },
            ),
          ),
          if (widget.showLabels) ...[
            Positioned(
              left: 12,
              top: 12,
              child: _Label(text: widget.beforeLabel),
            ),
            Positioned(
              // Shift the AFTER label left to avoid overlapping the top-right overlay buttons (e.g. download)
              // Original was right:12 which collided with external Positioned overlays in parent Stack.
              right: 60,
              top: 12,
              child: _Label(text: widget.afterLabel),
            ),
          ],
        ]),
      );
    });
  }
}

class _Handle extends StatelessWidget {
  final VoidCallback onTapCenter;
  const _Handle({required this.onTapCenter});
  @override
  Widget build(BuildContext context) {
    final neon = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onDoubleTap: onTapCenter,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: neon, width: 2),
          color: Colors.black.withOpacity(0.35),
          boxShadow: [BoxShadow(color: neon.withOpacity(0.4), blurRadius: 12)],
        ),
        child: Icon(Icons.compare_arrows, color: neon, size: 22),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.3)),
    );
  }
}
