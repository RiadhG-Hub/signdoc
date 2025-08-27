import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../bloc/sign_document_bloc.dart';

class CreateSingViewWidget extends StatefulWidget {
  const CreateSingViewWidget({super.key});

  @override
  State<CreateSingViewWidget> createState() => _CreateSingViewWidgetState();
}

class _CreateSingViewWidgetState extends State<CreateSingViewWidget> {
  int signatureCount = 1;
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
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      signatureCount++;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ), // Border color/width
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    foregroundColor: Colors.black, // Text/icon color
                  ),
                  child: Icon(Icons.add, color: Colors.black), // Icon color
                ),
                Text(
                  "$signatureCount",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      if (signatureCount == 1) return; // Prevent negative count
                      signatureCount--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      width: 1.0,
                      color: Colors.black,
                    ), // Border color/width
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    foregroundColor: Colors.black, // Text/icon color
                  ),
                  child: Icon(Icons.remove, color: Colors.black), // Icon color
                ),
                Text("signatureLabel", style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Color(0XFFE7E7E7),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SfSignaturePad(
                  key: context.read<SignDocumentBloc>().getSignaturePadKey,
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
                        final signaturePadKey =
                            context.read<SignDocumentBloc>().getSignaturePadKey;
                        ui.Image image =
                            await signaturePadKey.currentState!.toImage();
                        if (context.mounted) {
                          context.read<SignDocumentBloc>().setSignatureImage =
                              image;
                          context.read<SignDocumentBloc>().setSignatureCount =
                              signatureCount;
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
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
                      context.read<SignDocumentBloc>().clearSignature();
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
                      context
                          .read<SignDocumentBloc>()
                          .getSignaturePadKey
                          .currentState!
                          .clear();
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
