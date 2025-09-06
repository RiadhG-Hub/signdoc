import 'dart:typed_data';
import 'dart:ui' as ui;

/// Represents the placement of a signature on a page.
class SignaturePlacement {
  SignaturePlacement({
    required this.offsetDx,
    required this.offsetDy,
    required this.page,
    this.scale = 1.0,
  });

  /// Horizontal offset (x-axis) of the signature.
  double offsetDx;

  /// Vertical offset (y-axis) of the signature.
  double offsetDy;

  /// Scale factor for resizing the signature (default = 1.0).
  double scale;

  /// Page number where the signature should be placed.
  /// Note: This is zero-based (page 0 = first page).
  int page;
}

/// Utility class for handling signature placements and image conversions.
class SignatureUtils {
  const SignatureUtils();

  /// Converts a [ui.Image] object into PNG byte data.
  ///
  /// Returns the PNG as a [Uint8List].
  Future<Uint8List> imageToPngBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Initializes a list of [SignaturePlacement] objects.
  ///
  /// [count] → number of signatures to place.
  /// [currentPage] → the page where the signatures should be added.
  /// [baseScale] → scale of the signatures (default = 0.6).
  ///
  /// Each signature is placed with a constant gap so they don’t overlap.
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

  /// Returns the indices of signatures that belong to [currentPage].
  ///
  /// Example: If placements contain signatures across multiple pages,
  /// this method filters out only the ones on the specified page.
  List<int> indicesForCurrentPage(
      List<SignaturePlacement> placements, int currentPage) {
    final result = <int>[];
    for (int i = 0; i < placements.length; i++) {
      if (placements[i].page == currentPage) result.add(i);
    }
    return result;
  }

  /// Adds a new signature placement for the given [currentPage].
  ///
  /// [placements] → existing list of placements.
  /// [currentPage] → page where the new signature should be placed.
  /// [baseScale] → scale of the signature (default = 0.6).
  ///
  /// The new placement position is offset by a fixed [gap] from
  /// existing signatures on that page.
  SignaturePlacement addPlacementForPage({
    required List<SignaturePlacement> placements,
    required int currentPage,
    double baseScale = 0.6,
  }) {
    const double gap = 24.0;

    // Count how many signatures already exist on the page
    final countOnPage = placements.where((p) => p.page == currentPage).length;

    // Position new signature relative to the count
    return SignaturePlacement(
      offsetDx: 40 + countOnPage * gap,
      offsetDy: 120 + countOnPage * gap,
      page: currentPage,
      scale: baseScale,
    );
  }
}
