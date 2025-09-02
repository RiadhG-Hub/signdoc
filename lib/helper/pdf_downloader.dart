import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Simple utility to obtain a PDF file path for viewing/signing.
/// - ensurePdfFromUrl: downloads a PDF if the URL is a PDF, or downloads an image and converts it to a one-page PDF.
/// - downloadFromUrl: legacy helper that downloads bytes and saves with .pdf extension (use ensurePdfFromUrl for robust behavior).
/// - downloadExample: generates a small example PDF and saves it to a temporary file.
class PdfDownloader {
  const PdfDownloader();

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
      return '${base.isEmpty ? 'download' : base}.pdf';
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
