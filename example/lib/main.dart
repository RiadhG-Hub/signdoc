import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:open_filex/open_filex.dart';
import 'package:signdoc/sign_document_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const DocumentSigner(),
      theme: ThemeData(
        primaryColor: const Color(0xFF2A6BCC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A6BCC),
          primary: const Color(0xFF2A6BCC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2A6BCC),
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2A6BCC),
          ),
        ),
      ),
    );
  }
}

class DocumentSigner extends StatefulWidget {
  const DocumentSigner({super.key});

  @override
  State<DocumentSigner> createState() => _DocumentSignerState();
}

class _DocumentSignerState extends State<DocumentSigner> {
  File? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
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
        appBar: AppBar(
          title: const Text("Document Signer"),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5F7F9), Color(0xFFE8EDF1)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 60,
                    color: Color(0xFF2A6BCC),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Sign Your Documents",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A6BCC),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Select a PDF document to add your signature and create a legally binding document",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6BCC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: const Color(0xFF2A6BCC).withValues(alpha: 0.3),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Select PDF Document",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Supported format: PDF",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SignDocumentPage(
      file: _selectedFile!,
      onError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() {
          _selectedFile = null;
        });
      },
      onSignedDocument: (file) async {
        debugPrint("Signed file path: ${file.path}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Document signed successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Open the signed file immediately
        await OpenFilex.open(file.path);

        // Reset state so user can sign another document
        setState(() {
          _selectedFile = null;
        });
      },
      onCancelled: (reason) {
        setState(() {
          _selectedFile = null;
        });
      },
      uploadButtonMessage: "Save PDF",
      signatureColor: Colors.black,
      onSign: (file) {},
    );
  }
}
