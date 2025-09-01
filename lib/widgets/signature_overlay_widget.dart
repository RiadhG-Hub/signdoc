import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SignatureOverlayWidget extends StatelessWidget {
  const SignatureOverlayWidget({
    super.key,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.image,
    required this.onDragDelta,
    required this.onResizeDelta,
    this.onPinchStart,
    this.onPinchUpdate,
    this.onPinchEnd,
    this.onDoubleTap,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final ui.Image image;

  /// Called when the main area is dragged. Provides delta in logical pixels (not pre-scaled).
  final ValueChanged<Offset> onDragDelta;

  /// Called when bottom-right resize handle is dragged. Provides raw delta.
  final ValueChanged<Offset> onResizeDelta;

  /// Called when a two-finger pinch starts over the signature area.
  final VoidCallback? onPinchStart;

  /// Called with the current gesture's scale factor (>1 enlarge, <1 shrink).
  final ValueChanged<double>? onPinchUpdate;

  /// Called when the pinch gesture ends.
  final VoidCallback? onPinchEnd;

  /// Called when the user double-taps the signature area.
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Use only scale gesture callbacks. Dragging is handled via focalPointDelta
            // in onScaleUpdate to avoid combining pan and scale recognizers.
            onScaleStart: (_) => onPinchStart?.call(),
            onScaleUpdate: (details) {
              // If scale is approximately 1.0, treat as drag; otherwise as pinch.
              final bool isScaling = (details.scale - 1.0).abs() > 0.01;
              if (isScaling) {
                onPinchUpdate?.call(details.scale);
              } else {
                onDragDelta(details.focalPointDelta);
              }
            },
            onScaleEnd: (_) => onPinchEnd?.call(),
            onDoubleTap: onDoubleTap,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
              ),
              child: RawImage(image: image, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            right: -12,
            bottom: -12,
            child: GestureDetector(
              onPanUpdate: (details) => onResizeDelta(details.delta),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_full,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
