import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class CreateSingViewWidget extends StatefulWidget {
  final ValueChanged<String>? onCancelled;

  const CreateSingViewWidget({super.key, this.onCancelled});

  @override
  State<CreateSingViewWidget> createState() => _CreateSingViewWidgetState();
}

class _CreateSingViewWidgetState extends State<CreateSingViewWidget> {
  int signatureCount = 1;
  final GlobalKey<SfSignaturePadState> _signatureKey =
      GlobalKey<SfSignaturePadState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, color: Colors.black),
                ),
                Text(
                  "createSignatureTitle",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),

            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Color(0XFFE7E7E7),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SfSignaturePad(
                  key: _signatureKey,
                  minimumStrokeWidth: 1,
                  maximumStrokeWidth: 3,
                  strokeColor: Colors.black,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.max,
              spacing: 12,
              children: [
                Flexible(
                  child: MaterialButton(
                    child: Text("save"),
                    onPressed: () async {
                      try {
                        final signaturePadKey = _signatureKey;
                        ui.Image image =
                            await signaturePadKey.currentState!.toImage();
                        if (!context.mounted) return;
                        Navigator.pop(context, {
                          'image': image,
                          'count': signatureCount,
                        });
                      } catch (e, s) {
                        print("error: $e, stack: $s");
                      }
                    },

                    height: 42,
                  ),
                ),
                Flexible(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onCancelled?.call("cancel signature");
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        width: 1.0,
                        color: Colors.black,
                      ), // Border color/width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      foregroundColor: Colors.black, // Text/icon color
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [Text("cancel")],
                    ), // Icon color
                  ),
                ),
                Flexible(
                  child: OutlinedButton(
                    onPressed: () async {
                      _signatureKey.currentState?.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        width: 1.0,
                        color: Colors.black,
                      ), // Border color/width
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      foregroundColor: Colors.black, // Text/icon color
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [Text("clear")],
                    ), // Icon color
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
