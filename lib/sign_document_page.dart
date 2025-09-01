import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:signdoc/widgets/create_sing_view_widget.dart';
import 'package:signdoc/widgets/signature_overlay_widget.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'helper/signature_utils.dart';

class SignDocumentPage extends StatefulWidget {
  final File file;
  final ValueChanged<Exception>? onError;
  final ValueChanged<File>? onSignedDocument;
  final ValueChanged<String>? onCancelled;
  final ValueChanged<ui.Image>? onSign;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<List<SignaturePlacement>>? onPlacementsChanged;
  final ValueChanged<bool>? onSignatureModeChanged;
  final Widget Function(BuildContext, int, int)? pageIndicatorBuilder;
  final Widget Function(BuildContext)? loadingIndicatorBuilder;
  final Widget Function(BuildContext, Exception)? errorWidgetBuilder;
  final String uploadButtonMessage;
  final String nextButtonMessage;
  final String prevButtonMessage;
  final String addSignatureMessage;
  final Color primaryColor;
  final Color backgroundColor;
  final Color signatureColor;
  final double minSignatureScale;
  final double maxSignatureScale;
  final bool enableMultipleSignatures;
  final bool enableSignatureDeletion;
  final bool enableSignatureResizing;
  final bool enableSignatureRotation;
  final bool showPageNavigation;
  final bool showSignatureCount;

  const SignDocumentPage({
    super.key,
    required this.file,
    this.onError,
    this.onSignedDocument,
    this.onCancelled,
    this.onSign,
    this.onPageChanged,
    this.onPlacementsChanged,
    this.onSignatureModeChanged,
    this.pageIndicatorBuilder,
    this.loadingIndicatorBuilder,
    this.errorWidgetBuilder,
    this.uploadButtonMessage = 'Upload PDF',
    this.nextButtonMessage = 'Next',
    this.prevButtonMessage = 'Previous',
    this.addSignatureMessage = 'Add Signature',
    this.primaryColor = const Color(0xFF2A6BCC),
    this.backgroundColor = const Color(0xFFF5F7F9),
    this.signatureColor = Colors.black,
    this.minSignatureScale = 0.2,
    this.maxSignatureScale = 3.0,
    this.enableMultipleSignatures = true,
    this.enableSignatureDeletion = true,
    this.enableSignatureResizing = true,
    this.enableSignatureRotation = false,
    this.showPageNavigation = true,
    this.showSignatureCount = false,
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
      try {
        await _loadInitialPdf();
        await _showPopupAndLoadSignature();
        await WidgetsBinding.instance.endOfFrame;
      } catch (e, s) {
        debugPrint('End of frame error: $e\n$s');
        if (mounted) {
          _handleError(
              e is Exception ? e : Exception('Initialization error: $e'));
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      setState(() {
        _pdfKey = UniqueKey();
        _pdfVisible = true;
      });
    });
  }

  void _handleError(Exception error) {
    widget.onError?.call(error);
    if (widget.errorWidgetBuilder != null) {
      // Error widget would be shown in build method
      setState(() {});
    }
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
      _handleError(e is Exception ? e : Exception('Failed to load PDF: $e'));
    }
  }

  Future<void> _showPopupAndLoadSignature() async {
    widget.onSignatureModeChanged?.call(true);
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
    if (!mounted) return;
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateSingViewWidget(
        key: Key('createSignatureDialog'),
        onCancelled: widget.onCancelled,
        signatureColor: widget.signatureColor,
      ),
    );

    if (mounted) {
      setState(() {
        _pdfVisible = true;
        _pdfKey = UniqueKey();
      });
    }

    widget.onSignatureModeChanged?.call(false);

    if (_pageToRestore != null) {
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
        widget.onSign?.call(_signatureImage!);
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

        widget.onPlacementsChanged?.call(_placements);

        for (final p in _placements.where((p) => p.page == _currentPage)) {
          _centerPlacement(p);
        }
        await Future<void>.delayed(const Duration(seconds: 1));

        await _pdfController?.setPage(_currentPage);

        setState(() {});
      } catch (e, s) {
        debugPrint('Error loading signature: $e\n$s');
        _handleError(
            e is Exception ? e : Exception('Failed to load signature: $e'));
      }
    }
  }

  Future<void> _savePdfWithSignatures() async {
    if (_pdfPath == null || _signaturePng == null || _signatureImage == null) {
      _handleError(Exception('Cannot save: Missing PDF or signature data'));
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

        final scale = (viewerW / pageW).clamp(0, double.infinity) <
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

      final signedFile = File('${_pdfPath!}_signed.pdf');
      await signedFile.writeAsBytes(signedBytes);

      _showLoadingDialog();
      try {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _hideLoadingDialogIfAny();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('Upload successful'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        widget.onSignedDocument?.call(signedFile);
        setState(() {
          _signatureImage = null;
          _signaturePng = null;
          _placements.clear();
        });
        widget.onPlacementsChanged?.call(_placements);
      } catch (e) {
        _hideLoadingDialogIfAny();
        final error = Exception('Upload failed: $e');
        _handleError(error);
      }
    } catch (e, s) {
      debugPrint('Error saving PDF: $e\n$s');
      _handleError(e is Exception ? e : Exception('Failed to save PDF: $e'));
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
    if (_signatureImage == null || !widget.enableMultipleSignatures) return;
    setState(() {
      final p = _sigUtils.addPlacementForPage(
        placements: _placements,
        currentPage: _currentPage,
      );
      _centerPlacement(p);
      _placements.add(p);
      widget.onPlacementsChanged?.call(_placements);
    });
  }

  void _removePlacement(SignaturePlacement placement) {
    if (!widget.enableSignatureDeletion) return;
    setState(() {
      final currentIndex = _placements.indexOf(placement);
      if (currentIndex != -1) {
        _placements.removeAt(currentIndex);
        widget.onPlacementsChanged?.call(_placements);
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
          backgroundColor: Colors.white,
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.primaryColor),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Uploading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
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

  Widget _buildPageIndicator() {
    if (widget.pageIndicatorBuilder != null) {
      return widget.pageIndicatorBuilder!(context, _currentPage, _pageCount);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_currentPage + 1} / ${_pageCount == 0 ? '-' : _pageCount}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (widget.loadingIndicatorBuilder != null) {
      return widget.loadingIndicatorBuilder!(context);
    }

    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSignature = _signatureImage != null && _placements.isNotEmpty;
    final signaturesOnCurrentPage = _indicesForCurrentPage().length;

    if (_pdfPath == null) {
      return _buildLoadingIndicator();
    }

    return Scaffold(
      key: Key('signDocumentScaffold'),
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        key: Key('signDocumentAppBar'),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        backgroundColor: Colors.white,
        foregroundColor: widget.primaryColor,
        title: Text(
          'Sign Document',
          key: Key('signDocumentTitle'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          key: Key('backButton'),
          onPressed: () {
            widget.onCancelled?.call("back button pressed");
          },
          icon: Icon(Icons.arrow_back, size: 24),
        ),
        actions: [
          if (widget.showSignatureCount && signaturesOnCurrentPage > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$signaturesOnCurrentPage',
                style: TextStyle(
                  color: widget.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_signatureImage != null && widget.enableMultipleSignatures)
            IconButton(
              key: Key('addSignatureIconButton'),
              tooltip: 'Add another signature',
              icon: Icon(Icons.add_circle, size: 24),
              color: widget.primaryColor,
              onPressed: _addPlacementForCurrentPage,
            ),
        ],
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: LayoutBuilder(
        key: Key('outerLayoutBuilder'),
        builder: (context, constraints) {
          return Column(
            key: Key('mainColumn'),
            children: [
              Expanded(
                key: Key('pdfExpanded'),
                child: Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LayoutBuilder(
                      key: Key('innerLayoutBuilder'),
                      builder: (context, innerConstraints) {
                        _pdfViewSize = Size(
                          innerConstraints.maxWidth,
                          innerConstraints.maxHeight,
                        );
                        return SizedBox(
                          key: Key('pdfSizedBox'),
                          width: innerConstraints.maxWidth,
                          height: innerConstraints.maxHeight,
                          child: InteractiveViewer(
                            key: Key('pdfInteractiveViewer'),
                            transformationController: _transformationController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            panEnabled: true,
                            scaleEnabled: !_isPinchingSignature,
                            clipBehavior: Clip.none,
                            child: Stack(
                              key: Key('pdfStack'),
                              children: [
                                Positioned.fill(
                                  key: Key('pdfPositionedFill'),
                                  child: _pdfVisible
                                      ? PDFView(
                                          key: _pdfKey,
                                          filePath: _pdfPath!,
                                          enableSwipe: false,
                                          swipeHorizontal: true,
                                          autoSpacing: true,
                                          pageFling: false,
                                          backgroundColor: Colors.grey[200],
                                          fitPolicy: FitPolicy.WIDTH,
                                          onViewCreated: (controller) async {
                                            setState(() {
                                              _pdfController = controller;
                                            });
                                            final target = _pageToRestore;
                                            if (target != null) {
                                              try {
                                                await controller
                                                    .setPage(target);
                                              } catch (_) {}
                                            }
                                          },
                                          onRender: (pages) async {
                                            setState(() {
                                              _pageCount = pages ?? 0;
                                            });
                                            final controller = _pdfController;
                                            final target = _pageToRestore;
                                            if (controller != null &&
                                                target != null) {
                                              try {
                                                await controller
                                                    .setPage(target);
                                              } catch (_) {}
                                            }
                                          },
                                          onPageChanged: (page, total) {
                                            if (_pageToRestore != null &&
                                                page == _pageToRestore) {
                                              _pageToRestore = null;
                                            }
                                            setState(() {
                                              _currentPage = page ?? 0;
                                              _pageCount = total ?? _pageCount;
                                            });
                                            widget.onPageChanged
                                                ?.call(_currentPage);
                                          },
                                          onError: (error) {
                                            debugPrint(error.toString());
                                            _handleError(Exception(
                                                'PDFView error: $error'));
                                          },
                                          onPageError: (page, error) {
                                            debugPrint(
                                                '$page: ${error.toString()}');
                                            _handleError(Exception(
                                                'PDFView page $page error: $error'));
                                          },
                                        )
                                      : SizedBox.shrink(),
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
                                          placement.offsetDx += delta.dx;
                                          placement.offsetDy += delta.dy;
                                        });
                                      },
                                      onPinchStart:
                                          widget.enableSignatureResizing
                                              ? () {
                                                  setState(() {
                                                    _isPinchingSignature = true;
                                                    _pinchInitialScale =
                                                        placement.scale;
                                                  });
                                                }
                                              : null,
                                      onPinchUpdate: widget
                                              .enableSignatureResizing
                                          ? (scaleFactor) {
                                              if (_pinchInitialScale == null) {
                                                return;
                                              }
                                              setState(() {
                                                final newScale = (_pinchInitialScale! *
                                                        scaleFactor)
                                                    .clamp(
                                                        widget
                                                            .minSignatureScale,
                                                        widget
                                                            .maxSignatureScale);
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
                                              widget.onPlacementsChanged
                                                  ?.call(_placements);
                                            }
                                          : null,
                                      onPinchEnd: widget.enableSignatureResizing
                                          ? () {
                                              setState(() {
                                                _isPinchingSignature = false;
                                                _pinchInitialScale = null;
                                              });
                                            }
                                          : null,
                                      onDoubleTap:
                                          widget.enableSignatureDeletion
                                              ? () {
                                                  _removePlacement(placement);
                                                }
                                              : null,
                                      onResizeDelta: (Offset value) {},
                                    );
                                  }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(key: Key('bottomSpacing16'), height: 16),
              if (widget.showPageNavigation && _pageCount > 1)
                Container(
                  key: Key('navigationContainer'),
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    key: Key('navigationRow'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(
                        key: Key('prevButtonBuilder'),
                        builder: (context) {
                          final isRtl =
                              Directionality.of(context) == TextDirection.rtl;
                          return ElevatedButton.icon(
                            key: Key('prevButton'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
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
                              size: 20,
                            ),
                            label: Text(
                              widget.prevButtonMessage,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                      SizedBox(key: Key('spacing16a'), width: 16),
                      _buildPageIndicator(),
                      SizedBox(key: Key('spacing16b'), width: 16),
                      Builder(
                        key: Key('nextButtonBuilder'),
                        builder: (context) {
                          final isRtl =
                              Directionality.of(context) == TextDirection.rtl;
                          return ElevatedButton.icon(
                            key: Key('nextButton'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            onPressed: (_pageCount > 0 &&
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
                              size: 20,
                            ),
                            label: Text(
                              widget.nextButtonMessage,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: hasSignature
          ? Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: MaterialButton(
                key: Key('signatureSaveButton'),
                height: 50,
                onPressed: () async {
                  if (!hasSignature) {
                    await _showPopupAndLoadSignature();
                  } else {
                    await _savePdfWithSignatures();
                  }
                },
                color: widget.primaryColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasSignature
                      ? widget.uploadButtonMessage
                      : widget.addSignatureMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : SizedBox(height: 80),
    );
  }
}

mixin SignatureResult {
  void onSignatureSucceed(File file);
  void onSignatureFailed(Exception message);
  void onSignatureCancelled(String message);
  void onSign(ui.Image signature);
  void onPageChanged(int currentPage);
  void onPlacementsChanged(List<SignaturePlacement> placements);
  void onSignatureModeChanged(bool isSignatureMode);
}
