import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:signdoc/widgets/create_sing_view_widget.dart';
import 'package:signdoc/widgets/signature_overlay_widget.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'helper/pdf_downloader.dart';
import 'helper/signature_utils.dart';

class SignDocumentPage extends StatefulWidget {
  final File file;
  final ValueChanged<Exception>? onError;
  final ValueChanged<File>? onSignedDocument;
  const SignDocumentPage({
    super.key,
    required this.file,
    this.onError,
    this.onSignedDocument,
  });

  @override
  State<SignDocumentPage> createState() => _SignDocumentState();
}

class _SignDocumentState extends State<SignDocumentPage> {
  PDFViewController? _pdfController;
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  String? _pdfPath;
  ui.Image? _signatureImage;
  Uint8List? _signaturePng;
  final List<SignaturePlacement> _placements = [];
  final SignatureUtils _sigUtils = const SignatureUtils();
  final PdfDownloader _pdfDownloader = const PdfDownloader();
  Size _pdfViewSize = Size.zero;
  int _currentPage = 0;
  int _pageCount = 0;

  bool _pdfVisible = true;
  Key _pdfKey = UniqueKey();

  bool _isPinchingSignature = false;
  double? _pinchInitialScale;

  int? _pageToRestore;

  @override
  void initState() {
    _pdfVisible = false;
    _pdfController = null;
    _pdfKey = UniqueKey();
    _pdfPath = null;
    _signatureImage = null;
    _signaturePng = null;
    _placements.clear();
    _pdfViewSize = Size.zero;
    _currentPage = 0;
    _pageCount = 0;

    _transformationController.addListener(() {
      final m = _transformationController.value;
      final newScale = m.getMaxScaleOnAxis();
      if (mounted && (newScale - _currentScale).abs() > 0.01) {
        setState(() {
          _currentScale = newScale;
        });
      }
    });
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialPdf();
      try {
        await WidgetsBinding.instance.endOfFrame;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      setState(() {
        _pdfKey = UniqueKey();
        _pdfVisible = true;
      });
    });
  }

  Future<void> _loadInitialPdf() async {
    try {
      if (mounted) {
        setState(() {
          _pdfPath = widget.file.path;
          _pdfKey = UniqueKey();
        });
      } else {
        widget.onError?.call(Exception('Failed to load PDF: No valid path'));
      }
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      widget.onError?.call(
        e is Exception ? e : Exception('Failed to load PDF: $e'),
      );
    }
  }

  Future<void> _showPopupAndLoadSignature() async {
    // Remember current page to restore after dialog closes
    _pageToRestore = _currentPage;
    if (mounted) {
      setState(() {
        _pdfVisible = false;
        _pdfController = null;
        _pdfKey = UniqueKey();
      });
      try {
        await WidgetsBinding.instance.endOfFrame;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              const CreateSingViewWidget(key: Key('createSignatureDialog')),
    );

    if (mounted) {
      setState(() {
        _pdfVisible = true;
        _pdfKey = UniqueKey();
      });
    }
    // After making it visible, attempt to restore page soon after build
    if (_pageToRestore != null) {
      // give a short delay to ensure controller gets attached
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final controller = _pdfController;
      final target = _pageToRestore;
      if (controller != null && target != null) {
        try {
          await controller.setPage(target);
        } catch (_) {}
      }
    }

    if (result != null && result['image'] is ui.Image) {
      try {
        _signatureImage = result['image'] as ui.Image;
        _signaturePng = await _sigUtils.imageToPngBytes(_signatureImage!);
        final count = (result['count'] as int?) ?? 1;
        _placements
          ..clear()
          ..addAll(
            _sigUtils.initializePlacements(
              count: count,
              currentPage: _currentPage,
            ),
          );
        for (final p in _placements.where((p) => p.page == _currentPage)) {
          _centerPlacement(p);
        }
        await Future<void>.delayed(const Duration(seconds: 1));

        await _pdfController?.setPage(_currentPage);

        setState(() {});
      } catch (e, s) {
        debugPrint('Error loading signature: $e\n$s');
        widget.onError?.call(
          e is Exception ? e : Exception('Failed to load signature: $e'),
        );
      }
    }
  }

  Future<void> _savePdfWithSignatures() async {
    if (_pdfPath == null || _signaturePng == null || _signatureImage == null) {
      widget.onError?.call(
        Exception('Cannot save: Missing PDF or signature data'),
      );
      return;
    }
    try {
      final document = PdfDocument(
        inputBytes: File(_pdfPath!).readAsBytesSync(),
      );
      final sigWidth = _signatureImage!.width.toDouble();
      final sigHeight = _signatureImage!.height.toDouble();

      final viewerW = _pdfViewSize.width == 0 ? 1.0 : _pdfViewSize.width;
      final viewerH = _pdfViewSize.height == 0 ? 1.0 : _pdfViewSize.height;
      final pdfImage = PdfBitmap(_signaturePng!);

      for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
        final page = document.pages[pageIndex];
        final pageSize = page.getClientSize();
        final pageW = pageSize.width;
        final pageH = pageSize.height;

        final scale =
            (viewerW / pageW).clamp(0, double.infinity) <
                    (viewerH / pageH).clamp(0, double.infinity)
                ? viewerW / pageW
                : viewerH / pageH;

        final displayedW = pageW * scale;
        final displayedH = pageH * scale;
        final offsetX = (viewerW - displayedW) / 2.0;
        final offsetY = (viewerH - displayedH) / 2.0;

        final placementsForPage = _placements.where((p) => p.page == pageIndex);
        for (final p in placementsForPage) {
          final dx = (p.offsetDx - offsetX) / scale;
          final dy = (p.offsetDy - offsetY) / scale;
          final drawW = (sigWidth * p.scale) / scale;
          final drawH = (sigHeight * p.scale) / scale;

          page.graphics.drawImage(
            pdfImage,
            Rect.fromLTWH(dx, dy, drawW, drawH),
          );
        }
      }

      final List<int> signedBytes = await document.save();
      document.dispose();

      // Save the signed PDF to a file
      final signedFile = File('${_pdfPath!}_signed.pdf');
      await signedFile.writeAsBytes(signedBytes);

      // Simulate upload process locally
      _showLoadingDialog();
      try {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _hideLoadingDialogIfAny();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload successful')));
        // Call onSignedDocument with the signed file
        widget.onSignedDocument?.call(signedFile);
        setState(() {
          _signatureImage = null;
          _signaturePng = null;
          _placements.clear();
        });
      } catch (e) {
        _hideLoadingDialogIfAny();
        final error = Exception('Upload failed: $e');
        widget.onError?.call(error);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    } catch (e, s) {
      debugPrint('Error saving PDF: $e\n$s');
      widget.onError?.call(
        e is Exception ? e : Exception('Failed to save PDF: $e'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('saveFailedSnack'),
            content: Text('Failed to save PDF'),
          ),
        );
      }
    }
  }

  List<int> _indicesForCurrentPage() {
    final List<int> result = [];
    for (int i = 0; i < _placements.length; i++) {
      if (_placements[i].page == _currentPage) result.add(i);
    }
    return result;
  }

  Offset _getContentCenter() {
    final m = _transformationController.value;
    final s = m.getMaxScaleOnAxis();
    final double tX = m.storage[12];
    final double tY = m.storage[13];
    final viewerCenterX = _pdfViewSize.width / 2.0;
    final viewerCenterY = _pdfViewSize.height / 2.0;
    final contentCenterX = (viewerCenterX - tX) / s;
    final contentCenterY = (viewerCenterY - tY) / s;
    return Offset(contentCenterX, contentCenterY);
  }

  void _centerPlacement(SignaturePlacement p) {
    if (_signatureImage == null) return;
    final img = _signatureImage!;
    final center = _getContentCenter();
    final w = img.width.toDouble() * p.scale;
    final h = img.height.toDouble() * p.scale;
    p.offsetDx = center.dx - w / 2.0;
    p.offsetDy = center.dy - h / 2.0;
  }

  void _addPlacementForCurrentPage() {
    if (_signatureImage == null) return;
    setState(() {
      final p = _sigUtils.addPlacementForPage(
        placements: _placements,
        currentPage: _currentPage,
      );
      _centerPlacement(p);
      _placements.add(p);
    });
  }

  void _removePlacementForCurrentPage() {
    if (_signatureImage == null) return;

    final int countOnCurrentPage =
        _placements.where((p) => p.page == _currentPage).length;
    if (countOnCurrentPage <= 1) return;

    setState(() {
      for (int i = _placements.length - 1; i >= 0; i--) {
        if (_placements[i].page == _currentPage) {
          _placements.removeAt(i);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _pdfController = null;
    _pdfVisible = false;
    _pdfKey = UniqueKey();
    _transformationController.dispose();
    super.dispose();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 16),
                Text('Uploading...'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialogIfAny() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSignature = _signatureImage != null && _placements.isNotEmpty;

    return Scaffold(
      key: const Key('signDocumentScaffold'),
      backgroundColor: const Color(0xFFE0E8EA),
      appBar: AppBar(
        key: const Key('signDocumentAppBar'),
        elevation: 0.0,
        title: const Text('Sign Document', key: Key('signDocumentTitle')),
        leading: IconButton(
          key: const Key('backButton'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_signatureImage != null)
            IconButton(
              key: const Key('addSignatureIconButton'),
              tooltip: 'Add another signature',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addPlacementForCurrentPage,
            ),
        ],
        centerTitle: true,
      ),
      body: LayoutBuilder(
        key: const Key('outerLayoutBuilder'),
        builder: (context, constraints) {
          return Column(
            key: const Key('mainColumn'),
            children: [
              Expanded(
                key: const Key('pdfExpanded'),
                child: LayoutBuilder(
                  key: const Key('innerLayoutBuilder'),
                  builder: (context, innerConstraints) {
                    _pdfViewSize = Size(
                      innerConstraints.maxWidth,
                      innerConstraints.maxHeight,
                    );
                    return SizedBox(
                      key: const Key('pdfSizedBox'),
                      width: innerConstraints.maxWidth,
                      height: innerConstraints.maxHeight,
                      child:
                          _pdfPath == null
                              ? const Center(
                                key: Key('loadingIndicator'),
                                child: CircularProgressIndicator(),
                              )
                              : InteractiveViewer(
                                key: const Key('pdfInteractiveViewer'),
                                transformationController:
                                    _transformationController,
                                minScale: 1.0,
                                maxScale: 4.0,
                                panEnabled: true,
                                scaleEnabled: !_isPinchingSignature,
                                clipBehavior: Clip.none,
                                child: Stack(
                                  key: const Key('pdfStack'),
                                  children: [
                                    Positioned.fill(
                                      key: const Key('pdfPositionedFill'),
                                      child:
                                          _pdfVisible
                                              ? PDFView(
                                                key: _pdfKey,
                                                filePath: _pdfPath!,
                                                enableSwipe: false,
                                                swipeHorizontal: true,
                                                autoSpacing: true,
                                                pageFling: false,
                                                backgroundColor: Colors.grey,
                                                fitPolicy: FitPolicy.WIDTH,
                                                onViewCreated: (
                                                  controller,
                                                ) async {
                                                  setState(() {
                                                    _pdfController = controller;
                                                  });
                                                  // Try restoring page after controller is ready
                                                  final target = _pageToRestore;
                                                  if (target != null) {
                                                    try {
                                                      await controller.setPage(
                                                        target,
                                                      );
                                                    } catch (_) {}
                                                  }
                                                },
                                                onRender: (pages) async {
                                                  setState(() {
                                                    _pageCount = pages ?? 0;
                                                  });
                                                  // Also try restoring here in case not yet done
                                                  final controller =
                                                      _pdfController;
                                                  final target = _pageToRestore;
                                                  if (controller != null &&
                                                      target != null) {
                                                    try {
                                                      await controller.setPage(
                                                        target,
                                                      );
                                                    } catch (_) {}
                                                  }
                                                },
                                                onPageChanged: (page, total) {
                                                  // Once we receive a change to our intended page, clear restore flag
                                                  if (_pageToRestore != null &&
                                                      page == _pageToRestore) {
                                                    _pageToRestore = null;
                                                  }
                                                  setState(() {
                                                    _currentPage = page ?? 0;
                                                    _pageCount =
                                                        total ?? _pageCount;
                                                  });
                                                },
                                                onError: (error) {
                                                  debugPrint(error.toString());
                                                  widget.onError?.call(
                                                    Exception(
                                                      'PDFView error: $error',
                                                    ),
                                                  );
                                                },
                                                onPageError: (page, error) {
                                                  debugPrint(
                                                    '$page: ${error.toString()}',
                                                  );
                                                  widget.onError?.call(
                                                    Exception(
                                                      'PDFView page $page error: $error',
                                                    ),
                                                  );
                                                },
                                              )
                                              : const SizedBox.shrink(),
                                    ),
                                    if (hasSignature)
                                      ..._indicesForCurrentPage().map((idx) {
                                        final placement = _placements[idx];
                                        final img = _signatureImage!;
                                        final baseW = img.width.toDouble();
                                        final baseH = img.height.toDouble();
                                        final width = baseW * placement.scale;
                                        final height = baseH * placement.scale;
                                        return SignatureOverlayWidget(
                                          key: Key('signatureOverlay_$idx'),
                                          left: placement.offsetDx,
                                          top: placement.offsetDy,
                                          width: width,
                                          height: height,
                                          image: img,
                                          onDragDelta: (delta) {
                                            setState(() {
                                              final s =
                                                  _currentScale == 0
                                                      ? 1.0
                                                      : _currentScale;
                                              placement.offsetDx +=
                                                  delta.dx / s;
                                              placement.offsetDy +=
                                                  delta.dy / s;
                                            });
                                          },
                                          onResizeDelta: (delta) {
                                            setState(() {
                                              final s =
                                                  _currentScale == 0
                                                      ? 1.0
                                                      : _currentScale;
                                              final oldW =
                                                  baseW * placement.scale;
                                              final oldH =
                                                  baseH * placement.scale;
                                              final d =
                                                  (delta.dx + delta.dy) /
                                                  (300.0 * s);
                                              final newScale =
                                                  (placement.scale + d).clamp(
                                                    0.2,
                                                    3.0,
                                                  );
                                              final newW = baseW * newScale;
                                              final newH = baseH * newScale;
                                              placement.offsetDx +=
                                                  (oldW - newW) / 2.0;
                                              placement.offsetDy +=
                                                  (oldH - newH) / 2.0;
                                              placement.scale = newScale;
                                            });
                                          },
                                          onPinchStart: () {
                                            setState(() {
                                              _isPinchingSignature = true;
                                              _pinchInitialScale =
                                                  placement.scale;
                                            });
                                          },
                                          onPinchUpdate: (scaleFactor) {
                                            if (_pinchInitialScale == null)
                                              return;
                                            setState(() {
                                              final newScale =
                                                  (_pinchInitialScale! *
                                                          scaleFactor)
                                                      .clamp(0.2, 3.0);
                                              final currW =
                                                  baseW * placement.scale;
                                              final currH =
                                                  baseH * placement.scale;
                                              final centerX =
                                                  placement.offsetDx +
                                                  currW / 2.0;
                                              final centerY =
                                                  placement.offsetDy +
                                                  currH / 2.0;
                                              final newW = baseW * newScale;
                                              final newH = baseH * newScale;
                                              placement.offsetDx =
                                                  centerX - newW / 2.0;
                                              placement.offsetDy =
                                                  centerY - newH / 2.0;
                                              placement.scale = newScale;
                                            });
                                          },
                                          onPinchEnd: () {
                                            setState(() {
                                              _isPinchingSignature = false;
                                              _pinchInitialScale = null;
                                            });
                                          },
                                          onDoubleTap: () {
                                            setState(() {
                                              final currentIndex = _placements
                                                  .indexOf(placement);
                                              if (currentIndex != -1) {
                                                _placements.removeAt(
                                                  currentIndex,
                                                );
                                              }
                                            });
                                          },
                                        );
                                      }),
                                  ],
                                ),
                              ),
                    );
                  },
                ),
              ),
              const SizedBox(key: Key('bottomSpacing8'), height: 8),
              if (_pageCount != 1)
                Row(
                  key: const Key('navigationRow'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      key: const Key('prevButtonBuilder'),
                      builder: (context) {
                        final isRtl =
                            Directionality.of(context) == TextDirection.rtl;
                        return ElevatedButton.icon(
                          key: const Key('prevButton'),
                          onPressed:
                              (_currentPage > 0 && _pdfController != null)
                                  ? () async {
                                    final prev = _currentPage - 1;
                                    if (prev >= 0) {
                                      await _pdfController!.setPage(prev);
                                    }
                                  }
                                  : null,
                          icon: Icon(
                            isRtl ? Icons.chevron_right : Icons.chevron_left,
                          ),
                          label: const Text('Previous'),
                        );
                      },
                    ),
                    const SizedBox(key: Key('spacing16a'), width: 16),
                    Text(
                      '${_currentPage + 1} / ${_pageCount == 0 ? '-' : _pageCount}',
                      key: const Key('pageIndicator'),
                    ),
                    const SizedBox(key: Key('spacing16b'), width: 16),
                    Builder(
                      key: const Key('nextButtonBuilder'),
                      builder: (context) {
                        final isRtl =
                            Directionality.of(context) == TextDirection.rtl;
                        return ElevatedButton.icon(
                          key: const Key('nextButton'),
                          onPressed:
                              (_pageCount > 0 &&
                                      _currentPage < _pageCount - 1 &&
                                      _pdfController != null)
                                  ? () async {
                                    final next = _currentPage + 1;
                                    if (next < _pageCount) {
                                      await _pdfController!.setPage(next);
                                    }
                                  }
                                  : null,
                          icon: Icon(
                            isRtl ? Icons.chevron_left : Icons.chevron_right,
                          ),
                          label: const Text('Next'),
                        );
                      },
                    ),
                  ],
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Padding(
        key: const Key('bottomButtonPadding'),
        padding: const EdgeInsets.only(right: 12, left: 12, bottom: 60),
        child: MaterialButton(
          key: const Key('signatureSaveButton'),
          onPressed: () async {
            if (!hasSignature) {
              await _showPopupAndLoadSignature();
            } else {
              await _savePdfWithSignatures();
            }
          },
          child: Text(hasSignature ? 'Upload PDF' : 'Add Signature'),
        ),
      ),
    );
  }
}

@override
void onSignatureSucceed(File file) {
  debugPrint('Signed document saved: ${file.path}');
}

@override
void onSignatureFailed(Exception message) {
  debugPrint('Signature failed: $message');
}

mixin SignatureResult {
  void onSignatureSucceed(File file);
  void onSignatureFailed(Exception message);
}
