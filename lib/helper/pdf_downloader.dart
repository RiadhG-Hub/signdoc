import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Simple utility to obtain a PDF file path for viewing/signing.
/// - ensurePdfFromUrl: downloads a PDF if the URL is a PDF, or downloads an image and converts it to a one-page PDF.
/// - downloadFromUrl: legacy helper that downloads bytes and saves with .pdf extension (use ensurePdfFromUrl for robust behavior).
/// - downloadExample: generates a small example PDF and saves it to a temporary file.
class PdfDownloader {
  const PdfDownloader();

  /// Smart method that ensures a PDF file path from [url].
  /// - If content is a PDF, saves and returns it.
  /// - If content is an image, embeds it into a single-page PDF and returns the PDF path.
  /// Returns null if the download or conversion fails.
  Future<String?> ensurePdfFromUrl(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      final headers = response.headers.map;
      final contentType =
          headers['content-type']?.join(',').toLowerCase() ?? '';
      final bytes = response.data ?? <int>[];

      // Decide by content-type first, fallback to URL extension.
      final isPdf =
          contentType.contains('application/pdf') || _looksLikePdfUrl(url);
      final isImage =
          contentType.startsWith('image/') || _looksLikeImageUrl(url);

      if (isPdf) {
        return _savePdfBytes(bytes, suggestedName: _fileNameFromUrl(url));
      }
      if (isImage) {
        return _imageBytesToPdf(bytes, suggestedName: _fileNameFromUrl(url));
      }

      // Fallback strategy: try PDF first; if that fails to open later, caller will handle error.
      return _savePdfBytes(bytes, suggestedName: _fileNameFromUrl(url));
    } catch (_) {
      return null;
    }
  }

  /// Legacy method: downloads the content and saves with .pdf extension (may fail for non-PDF).
  Future<String?> downloadFromUrl(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = _fileNameFromUrl(url);
      final savePath = p.join(dir.path, fileName);

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        options:
            Options(responseType: ResponseType.bytes, followRedirects: true),
      );

      final file = File(savePath);
      if (await file.exists() && await file.length() > 0) {
        return savePath;
      }
    } catch (_) {
      // swallow and return null for robustness
    }
    return null;
  }

  /// Generates a simple example PDF and returns its file path.
  Future<String?> downloadExample() async {
    try {
      final document = PdfDocument();
      final page = document.pages.add();

      // Draw a simple header and body text
      page.graphics.drawString(
        'Example PDF',
        PdfStandardFont(PdfFontFamily.helvetica, 22, style: PdfFontStyle.bold),
        bounds: const Rect.fromLTWH(0, 0, 500, 40),
      );
      page.graphics.drawString(
        'This is a generated PDF to demonstrate signing.\nYou can place your signature on any page.',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: const Rect.fromLTWH(0, 60, 500, 200),
      );

      final bytes = await document.save();
      document.dispose();

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'example.pdf'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final base = p.basename(uri.path);
      if (base.toLowerCase().endsWith('.pdf')) return base;
      return (base.isEmpty ? 'download' : base) + '.pdf';
    } catch (_) {
      return 'download.pdf';
    }
  }

  bool _looksLikePdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf');
  }

  bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  Future<String?> _savePdfBytes(List<int> bytes,
      {required String suggestedName}) async {
    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, suggestedName);
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _imageBytesToPdf(List<int> imageBytes,
      {required String suggestedName}) async {
    try {
      final document = PdfDocument();
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      final image = PdfBitmap(imageBytes);
      // Draw the image to cover the page (may stretch if aspect ratios differ).
      page.graphics.drawImage(
          image, Rect.fromLTWH(0, 0, pageSize.width, pageSize.height));

      final bytes = await document.save();
      document.dispose();

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, suggestedName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
