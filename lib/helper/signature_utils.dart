import 'dart:typed_data';
import 'dart:ui' as ui;

class SignaturePlacement {
  SignaturePlacement({
    required this.offsetDx,
    required this.offsetDy,
    required this.page,
    this.scale = 1.0,
  });

  double offsetDx;
  double offsetDy;
  double scale;
  int page; // zero-based page index
}

class SignatureUtils {
  const SignatureUtils();

  Future<Uint8List> imageToPngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  List<SignaturePlacement> initializePlacements({
    required int count,
    required int currentPage,
    double baseScale = 0.6,
  }) {
    final placements = <SignaturePlacement>[];
    const double gap = 24.0;
    for (int i = 0; i < count; i++) {
      placements.add(
        SignaturePlacement(
          offsetDx: 40 + i * gap,
          offsetDy: 120 + i * gap,
          page: currentPage,
          scale: baseScale,
        ),
      );
    }
    return placements;
  }

  List<int> indicesForCurrentPage(
      List<SignaturePlacement> placements, int currentPage) {
    final result = <int>[];
    for (int i = 0; i < placements.length; i++) {
      if (placements[i].page == currentPage) result.add(i);
    }
    return result;
  }

  SignaturePlacement addPlacementForPage({
    required List<SignaturePlacement> placements,
    required int currentPage,
    double baseScale = 0.6,
  }) {
    const double gap = 24.0;
    final countOnPage = placements.where((p) => p.page == currentPage).length;
    return SignaturePlacement(
      offsetDx: 40 + countOnPage * gap,
      offsetDy: 120 + countOnPage * gap,
      page: currentPage,
      scale: baseScale,
    );
  }
}
