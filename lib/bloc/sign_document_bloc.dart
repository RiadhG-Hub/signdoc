import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

part 'sign_document_event.dart';
part 'sign_document_state.dart';

class SignDocumentBloc extends Bloc<SignDocumentEvent, SignDocumentState> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  ui.Image? signatureImage;
  int signatureCount = 1;

  // Prepared payload for HTTP (optional storage if consumers want to read later)
  Uint8List? preparedSignedPdf;
  String? preparedFileName;

  SignDocumentBloc() : super(SignDocumentInitial()) {
    on<PrepareSignedDocument>((event, emit) async {
      emit(const PrepareSignedDocumentLoading());
      try {
        // Store prepared data in bloc (so other layers can access/observe state)
        preparedSignedPdf = event.bytes;
        preparedFileName = event.fileName;
        emit(
          PrepareSignedDocumentSuccess(
            bytes: event.bytes,
            fileName: event.fileName,
          ),
        );
      } catch (e) {
        emit(PrepareSignedDocumentFailure(message: e.toString()));
      }
    });

    on<UploadSignedDocumentRequested>((event, emit) async {
      emit(const UploadSignedDocumentInProgress());
      try {
        // Mock network delay
        await Future<void>.delayed(const Duration(seconds: 2));
        // Simple mock rule: if fileName contains "fail", throw error
        if (event.fileName.toLowerCase().contains('fail')) {
          throw Exception('Mocked upload failed');
        }
        // pretend upload succeeded
        emit(const UploadSignedDocumentSuccess());
      } catch (e) {
        emit(UploadSignedDocumentFailure(message: e.toString()));
      }
    });
  }

  set setSignatureImage(ui.Image image) {
    signatureImage = image;
  }

  set setSignatureCount(int count) {
    signatureCount = count;
  }

  get getSignaturePadKey => _signaturePadKey;

  void clearSignature() {
    signatureImage = null;
    signatureCount = 1;
    preparedSignedPdf = null;
    preparedFileName = null;
  }
}
