import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A widget that overlays a draggable, resizable, and pinchable
/// signature image on top of a page.
///
/// Features:
/// - Drag the entire signature area.
/// - Resize using the bottom-right handle.
/// - Pinch to zoom in/out.
/// - Double-tap for custom actions.
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

  /// The left offset position of the signature.
  final double left;

  /// The top offset position of the signature.
  final double top;

  /// The current width of the signature area.
  final double width;

  /// The current height of the signature area.
  final double height;

  /// The signature image to render inside the area.
  final ui.Image image;

  /// Called when the main area is dragged.
  ///
  /// Provides the delta movement in logical pixels (not pre-scaled).
  final ValueChanged<Offset> onDragDelta;

  /// Called when the bottom-right resize handle is dragged.
  ///
  /// Provides the raw delta of the drag.
  final ValueChanged<Offset> onResizeDelta;

  /// Called when a two-finger pinch starts over the signature area.
  final VoidCallback? onPinchStart;

  /// Called with the current gesture's scale factor.
  ///
  /// Scale > 1 enlarges, < 1 shrinks.
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
          /// The main interactive area for drag, pinch, and double-tap.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Only use scale gesture callbacks. Dragging is handled
            // via focalPointDelta in onScaleUpdate to avoid conflict
            // between pan and scale recognizers.
            onScaleStart: (_) => onPinchStart?.call(),
            onScaleUpdate: (details) {
              // If scale is approximately 1.0 → treat as drag.
              // Otherwise, handle as a pinch zoom.
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

          /// Resize handle (bottom-right corner)
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
                child: const Icon(
                  Icons.open_in_full,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
