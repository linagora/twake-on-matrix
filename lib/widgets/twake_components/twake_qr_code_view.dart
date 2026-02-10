import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

class TwakeQrCodeView extends StatelessWidget {
  const TwakeQrCodeView({super.key, required this.data, required this.size});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);

    return CustomPaint(
      size: Size.square(size),
      painter: _QrCodePainter(qrImage: qrImage),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final QrImage qrImage;
  late final List<List<bool>> finderMask;
  late final List<double> centers;
  late final Paint whitePaint;

  // Cached size-dependent data
  Size? _cachedSize;
  Paint? _cachedGradientPaint;
  Path? _cachedCirclesPath;

  _QrCodePainter({required this.qrImage}) {
    final count = qrImage.moduleCount;

    // Build finder mask
    finderMask = List.generate(count, (x) {
      return List.generate(count, (y) => _isFinderPattern(x, y, count));
    });

    // Prepare center coords for all circles
    centers = List.generate(count, (i) => (i + 0.5));

    // Create white paint once
    whitePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFFFFF);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Add quiet zone (white margin) - 4 modules recommended by QR spec
    const quietZoneModules = 4;
    final count = qrImage.moduleCount;
    final totalModules = count + (quietZoneModules * 2);
    final moduleSize = size.width / totalModules;
    final quietZoneOffset = quietZoneModules * moduleSize;

    // Draw white background for quiet zone
    canvas.drawRect(Offset.zero & size, whitePaint);

    // Only rebuild size-dependent data if size changed
    if (_cachedSize != size) {
      _cachedSize = size;

      // Build gradient paint with darker colors for better contrast
      _cachedGradientPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B21A8), Color(0xFF4C1D95)],
        ).createShader(Offset.zero & size);

      // Module sizing constants
      const moduleScale = 0.9; // Module size relative to cell
      const moduleCornerRatio = 0.3; // Corner radius relative to module
      final centeringOffset = moduleSize * (1 - moduleScale) / 2;

      // Build modules path using rounded rectangles for better scanning
      final moduleRadius = moduleSize * moduleCornerRatio;
      _cachedCirclesPath = Path();
      for (int x = 0; x < count; x++) {
        final left = (x * moduleSize) + quietZoneOffset + centeringOffset;
        for (int y = 0; y < count; y++) {
          if (qrImage.isDark(y, x) && !finderMask[x][y]) {
            final top = (y * moduleSize) + quietZoneOffset + centeringOffset;
            _cachedCirclesPath!.addRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  left,
                  top,
                  moduleSize * moduleScale,
                  moduleSize * moduleScale,
                ),
                Radius.circular(moduleRadius),
              ),
            );
          }
        }
      }
    }

    // Draw the modules with a single canvas call
    canvas.drawPath(_cachedCirclesPath!, _cachedGradientPaint!);

    // Draw Finder Patterns with offset for quiet zone
    _drawFinder(canvas, 0, 0, moduleSize, quietZoneOffset);
    _drawFinder(canvas, count - 7, 0, moduleSize, quietZoneOffset);
    _drawFinder(canvas, 0, count - 7, moduleSize, quietZoneOffset);
  }

  bool _isFinderPattern(int x, int y, int count) {
    const int f = 7;
    if (x < f && y < f) return true;
    if (x >= count - f && y < f) return true;
    if (x < f && y >= count - f) return true;
    return false;
  }

  void _drawFinder(
    Canvas canvas,
    int xOffset,
    int yOffset,
    double m,
    double quietZoneOffset,
  ) {
    final double startX = (xOffset * m) + quietZoneOffset;
    final double startY = (yOffset * m) + quietZoneOffset;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, startY, 7 * m, 7 * m),
      Radius.circular(2.3 * m),
    );

    final middle = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX + m, startY + m, 5 * m, 5 * m),
      Radius.circular(1.7 * m),
    );

    final innerWhite = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX + 2 * m, startY + 2 * m, 3 * m, 3 * m),
      Radius.circular(1.1 * m),
    );

    final outerPath = Path()..addRRect(outer);
    final middlePath = Path()..addRRect(middle);
    final innerPath = Path()..addRRect(innerWhite);

    final outerRing = Path.combine(
      PathOperation.difference,
      outerPath,
      middlePath,
    );

    final whiteRing = Path.combine(
      PathOperation.difference,
      middlePath,
      innerPath,
    );

    final center = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX + 2 * m, startY + 2 * m, 3 * m, 3 * m),
      Radius.circular(0.9 * m),
    );

    // Draw layers: outer ring (gradient) -> white ring -> center (gradient)
    canvas.drawPath(outerRing, _cachedGradientPaint!);
    canvas.drawPath(whiteRing, whitePaint);
    canvas.drawRRect(center, _cachedGradientPaint!);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
