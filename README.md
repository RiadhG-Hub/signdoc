# DocSign

A powerful Flutter package for adding digital signatures to PDF documents. Integrate signature functionality into your Flutter applications with a beautiful, customizable UI.

## Features

- 📄 **PDF Viewer**: Built-in PDF viewer with smooth navigation
- ✍️ **Signature Creation**: Draw or create digital signatures with ease
- 🎨 **Customizable UI**: Fully customizable button texts and messages
- 📱 **Responsive Design**: Works on both mobile and desktop
- 🔧 **Easy Integration**: Simple API for quick implementation
- 💾 **Export & Save**: Save signed PDFs with embedded signatures
- 🖱️ **Gesture Support**: Drag, resize, and pinch-to-zoom signatures
- 📊 **Multi-page Support**: Navigate through multipage documents

## Installation

Add `docsign` to your `pubspec.yaml`:

```yaml
dependencies:
  docsign: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:docsign/docsign.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignatureDemo(),
    );
  }
}

class SignatureDemo extends StatelessWidget {
  final File pdfFile = File('path/to/your/document.pdf');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Document')),
      body: SignDocumentPage(
        file: pdfFile,
        onSignedDocument: (signedFile) {
          print('Document signed: ${signedFile.path}');
        },
        onError: (error) {
          print('Error: $error');
        },
        onCancelled: (message) {
          print('Cancelled: $message');
        },
      ),
    );
  }
}
```

### Advanced Usage with Custom Messages

```dart
SignDocumentPage(
  file: pdfFile,
  uploadButtonMessage: 'Save Signed PDF',
  nextButtonMessage: 'Next Page →',
  prevButtonMessage: '← Previous Page',
  addSignatureMessage: 'Create Your Signature',
  onSignedDocument: (signedFile) {
    // Handle the signed document
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessPage(file: signedFile),
      ),
    );
  },
  onError: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.toString()}')),
    );
  },
  onCancelled: (message) {
    Navigator.pop(context);
  },
)
```

## API Reference

### SignDocumentPage Parameters

| Parameter           | Type                    | Description                                   | Default         |
|---------------------|-------------------------|-----------------------------------------------|-----------------|
| file                | File                    | Required - The PDF file to sign               | -               |
| onSignedDocument    | ValueChanged<File>      | Callback when document is successfully signed | -               |
| onError             | ValueChanged<Exception> | Callback for error handling                   | -               |
| onCancelled         | ValueChanged<String>    | Callback when user cancels signing            | -               |
| uploadButtonMessage | String                  | Text for the upload/save button               | 'Upload PDF'    |
| nextButtonMessage   | String                  | Text for the next page button                 | 'Next'          |
| prevButtonMessage   | String                  | Text for the previous page button             | 'Previous'      |
| addSignatureMessage | String                  | Text for add signature button                 | 'Add Signature' |

### Callbacks

- `onSignedDocument(File signedFile)`: Called when the document is successfully signed and saved
- `onError(Exception error)`: Called when an error occurs during the signing process
- `onCancelled(String message)`: Called when the user cancels the signing process

## Example

```dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:signdoc/sign_document_page.dart';

class DocumentSigner extends StatefulWidget {
  const DocumentSigner({super.key});

  @override
  State<DocumentSigner> createState() => _DocumentSignerState();
}

class _DocumentSignerState extends State<DocumentSigner> with SignatureResult {
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
      onCancelled: onSignatureCancelled,
      uploadButtonMessage: "Save pdf",
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
    _selectedFile = null;
    setState(() {});
  }

  @override
  void onSignatureCancelled(String message) {
    debugPrint(message);
    setState(() {
      _selectedFile = null;
    });
  }
}
```

## Dependencies

This package uses the following dependencies:

- `flutter_pdfview`: For PDF rendering
- `syncfusion_flutter_pdf`: For PDF manipulation and signature embedding
- `flutter`: Flutter framework

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅ Yes   |
| iOS      | ✅ Yes   |


## Getting Help

If you encounter any issues or have questions:

- Check the example above
- Look at the API reference
- Open an issue on our GitHub repository

## Contributing

We welcome contributions! Please feel free to:

- Fork the repository
- Create a feature branch
- Make your changes
- Submit a pull request

## License

MIT License

Copyright (c) 2024 DocSign

Permission is hereby granted, free of charge, to any person getting a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or significant portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



## Support

For support and questions, please contact us at support@docsign.com or create an issue in our GitHub repository.