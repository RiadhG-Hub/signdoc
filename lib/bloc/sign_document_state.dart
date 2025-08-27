part of 'sign_document_bloc.dart';

sealed class SignDocumentState {
  const SignDocumentState();
}

class SignDocumentInitial extends SignDocumentState {}

class PrepareSignedDocumentLoading extends SignDocumentState {
  const PrepareSignedDocumentLoading();
}

class PrepareSignedDocumentSuccess extends SignDocumentState {
  final Uint8List bytes;
  final String fileName;
  const PrepareSignedDocumentSuccess({
    required this.bytes,
    required this.fileName,
  });
}

class PrepareSignedDocumentFailure extends SignDocumentState {
  final String message;
  const PrepareSignedDocumentFailure({required this.message});
}

// Upload flow states
class UploadSignedDocumentInProgress extends SignDocumentState {
  const UploadSignedDocumentInProgress();
}

class UploadSignedDocumentSuccess extends SignDocumentState {
  const UploadSignedDocumentSuccess();
}

class UploadSignedDocumentFailure extends SignDocumentState {
  final String message;
  const UploadSignedDocumentFailure({required this.message});
}
