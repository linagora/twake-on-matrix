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
    final count = qrImage.moduleCount;
    final moduleSize = size.width / count;

    // Only rebuild size-dependent data if size changed
    if (_cachedSize != size) {
      _cachedSize = size;

      // Build gradient paint
      _cachedGradientPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: [Color(0xFFE8A6FF), Color(0xFF8135FE)],
        ).createShader(Offset.zero & size);

      // Build circles path in one pass
      final radius = moduleSize * 0.35;
      _cachedCirclesPath = Path();
      for (int x = 0; x < count; x++) {
        final cx = centers[x] * moduleSize;
        for (int y = 0; y < count; y++) {
          if (qrImage.isDark(y, x) && !finderMask[x][y]) {
            final cy = centers[y] * moduleSize;
            _cachedCirclesPath!.addOval(
              Rect.fromCircle(center: Offset(cx, cy), radius: radius),
            );
          }
        }
      }
    }

    // Draw the circles with a single canvas call
    canvas.drawPath(_cachedCirclesPath!, _cachedGradientPaint!);

    // Draw Finder Patterns
    _drawFinder(canvas, 0, 0, moduleSize);
    _drawFinder(canvas, count - 7, 0, moduleSize);
    _drawFinder(canvas, 0, count - 7, moduleSize);
  }

  bool _isFinderPattern(int x, int y, int count) {
    const int f = 7;
    if (x < f && y < f) return true;
    if (x >= count - f && y < f) return true;
    if (x < f && y >= count - f) return true;
    return false;
  }

  void _drawFinder(Canvas canvas, int xOffset, int yOffset, double m) {
    final double startX = xOffset * m;
    final double startY = yOffset * m;

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
