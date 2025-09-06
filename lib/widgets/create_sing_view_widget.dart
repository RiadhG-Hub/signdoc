import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

/// A dialog widget for creating a handwritten signature using
/// [SfSignaturePad] from the Syncfusion package.
///
/// Provides options to:
/// - Cancel the signature creation.
/// - Clear the signature pad.
/// - Save and return the signature as a [ui.Image].
class CreateSingViewWidget extends StatefulWidget {
  /// Callback triggered when the user cancels the signature.
  ///
  /// Provides a string message ("cancel signature").
  final ValueChanged<String>? onCancelled;

  /// The color of the signature stroke.
  final ui.Color signatureColor;

  const CreateSingViewWidget({
    super.key,
    this.onCancelled,
    required this.signatureColor,
  });

  @override
  State<CreateSingViewWidget> createState() => _CreateSingViewWidgetState();
}

class _CreateSingViewWidgetState extends State<CreateSingViewWidget> {
  /// Counter for the number of signatures created.
  int signatureCount = 1;

  /// Key to access the state of the signature pad widget.
  final GlobalKey<SfSignaturePadState> _signatureKey =
      GlobalKey<SfSignaturePadState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              /// Header row with close button and title
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Close button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close, color: Colors.grey[700], size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(4),
                    ),
                  ),

                  /// Dialog title
                  Text(
                    "Create Signature",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A6BCC),
                    ),
                  ),

                  /// Spacer for symmetry
                  SizedBox(width: 48),
                ],
              ),

              SizedBox(height: 24),

              /// Signature pad container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SfSignaturePad(
                    key: _signatureKey,
                    minimumStrokeWidth: 1,
                    maximumStrokeWidth: 3,
                    strokeColor: widget.signatureColor,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),

              SizedBox(height: 24),

              /// Action buttons row: Cancel, Clear, Save
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onCancelled?.call("cancel signature");
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          width: 1.0,
                          color: Colors.grey[500]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  /// Clear button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        _signatureKey.currentState?.clear();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          width: 1.0,
                          color: Colors.grey[500]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        "Clear",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  /// Save button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final signaturePadKey = _signatureKey;

                          // Export signature as an image
                          ui.Image image =
                              await signaturePadKey.currentState!.toImage();

                          if (!context.mounted) return;

                          // Return the image and count
                          Navigator.pop(context, {
                            'image': image,
                            'count': signatureCount,
                          });
                        } catch (e, s) {
                          if (kDebugMode) {
                            print("error: $e, stack: $s");
                          }
                          rethrow;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2A6BCC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
