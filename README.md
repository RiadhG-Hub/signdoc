# Signdoc

A powerful Flutter package for adding digital signatures to PDF documents. Integrate signature functionality into your Flutter applications with a beautiful, customizable UI.

<img src="https://raw.githubusercontent.com/RiadhG-Hub/signdoc/main/example/demo.gif" width="174" height="374" alt="Demo Animation 1" />
<img src="https://raw.githubusercontent.com/RiadhG-Hub/signdoc/main/example/demo2.gif" width="174" height="374" alt="Demo Animation 2" />
<img src="https://raw.githubusercontent.com/RiadhG-Hub/signdoc/main/example/demo3.gif" width="174" height="374" alt="Demo Animation 3" />




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

Add `signdoc` to your `pubspec.yaml`:

```yaml
dependencies:
  signdoc: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart


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
      body: SignDocumentPage(file: File()!,
        onError: (message) {
// TODO: Show an error message to the user (e.g., Snackbar or dialog)
        },
        onSignedDocument: (file) async {
// TODO: Handle the signed document (save, upload, or preview it)
        },
        onCancelled: (reason) {
// TODO: Handle user cancellation (e.g., show notice or reset state)
        },
        uploadButtonMessage: "Save PDF",
        signatureColor: Colors.black,

        onSign: (signature) {
// TODO: Process the raw signature image (save locally, upload, or preview)
        },
        onPageChanged: (currentPage) {
// TODO: Update UI to show the current page number
        },
        onPlacementsChanged: (placements) {
// TODO: Track and update signature placements in the document
        },
        onSignatureModeChanged: (isSignatureMode) {
// TODO: Update UI when signature mode is toggled (enabled/disabled)
        },
      ));
  }
}
```



## API Reference



### Callbacks

- `onSignedDocument(File signedFile)`: Called when the document is successfully signed and saved
- `onError(Exception error)`: Called when an error occurs during the signing process
- `onCancelled(String message)`: Called when the user cancels the signing process

## Example

```dart
SignDocumentPage(file: File()!,
onError: (message) {
// TODO: Show an error message to the user (e.g., Snackbar or dialog)
},
onSignedDocument: (file) async {
// TODO: Handle the signed document (save, upload, or preview it)
},
onCancelled: (reason) {
// TODO: Handle user cancellation (e.g., show notice or reset state)
},
uploadButtonMessage: "Save PDF",
signatureColor: Colors.black,

onSign: (signature) {
// TODO: Process the raw signature image (save locally, upload, or preview)
},
onPageChanged: (currentPage) {
// TODO: Update UI to show the current page number
},
onPlacementsChanged: (placements) {
// TODO: Track and update signature placements in the document
},
onSignatureModeChanged: (isSignatureMode) {
// TODO: Update UI when signature mode is toggled (enabled/disabled)
},
)

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




## Support

For support and questions, please contact us at support@signdoc.com or create an issue in our GitHub repository.