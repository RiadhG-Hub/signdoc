import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signdoc/sign_document_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return SignDocWrapper();
  }
}

class SignDocWrapper extends StatelessWidget with SignatureResult {
  const SignDocWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignDocumentPage(
        file: File(
          "/var/mobile/Containers/Data/Application/EC7B473E-538B-4206-B13E-DAEC7CF2CFA2/Library/Caches/link-user-manual.pdf_signed.pdf",
        ),
        onError: onSignatureFailed,
        onSignedDocument: onSignatureSucceed,
      ),
    );
  }

  @override
  void onSignatureFailed(Exception message) {
    // TODO: implement onSignatureFailed
  }

  @override
  void onSignatureSucceed(File file) {
    print("Signed file path: ${file.path}");
    // TODO: implement onSignatureSucceed
  }
}
