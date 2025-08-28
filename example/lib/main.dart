import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:signdoc/sign_document_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SignDocWrapper());
  }
}

class SignDocWrapper extends StatefulWidget {
  const SignDocWrapper({super.key});

  @override
  State<SignDocWrapper> createState() => _SignDocWrapperState();
}

class _SignDocWrapperState extends State<SignDocWrapper> with SignatureResult {
  File? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pick a File")),
        body: Center(
          child: ElevatedButton(
            onPressed: _pickFile,
            child: const Text("Select PDF or Image"),
          ),
        ),
      );
    }

    return SignDocumentPage(
      file: _selectedFile!,
      onError: onSignatureFailed,
      onSignedDocument: onSignatureSucceed,
    );
  }

  @override
  void onSignatureFailed(Exception message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Signature failed: $message")));
  }

  @override
  void onSignatureSucceed(File file) async {
    debugPrint("Signed file path: ${file.path}");

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Signed file saved: ${file.path}")));

    // Open the signed file immediately
    await OpenFilex.open(file.path);
  }
}
