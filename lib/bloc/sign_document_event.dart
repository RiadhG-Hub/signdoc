part of 'sign_document_bloc.dart';

sealed class SignDocumentEvent {
  const SignDocumentEvent();
}

class PrepareSignedDocument extends SignDocumentEvent {
  final Uint8List bytes;
  final String fileName;
  const PrepareSignedDocument({required this.bytes, required this.fileName});
}

class UploadSignedDocumentRequested extends SignDocumentEvent {
  final Uint8List bytes;
  final String fileName;
  const UploadSignedDocumentRequested({required this.bytes, required this.fileName});
}
