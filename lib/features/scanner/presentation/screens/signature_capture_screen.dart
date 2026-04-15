import 'package:flutter/material.dart';

/// Shows signature capture as a bottom sheet.
/// Returns `List<List<Offset>>` of normalized 0..1 strokes on Done.
Future<List<List<Offset>>?> showSignatureCapture(BuildContext context) {
  return showModalBottomSheet<List<List<Offset>>>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _SignatureCaptureSheet(),
  );
}

class _SignatureCaptureSheet extends StatefulWidget {
  const _SignatureCaptureSheet();

  @override
  State<_SignatureCaptureSheet> createState() => _SignatureCaptureSheetState();
}

class _SignatureCaptureSheetState extends State<_SignatureCaptureSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  void _done() {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // We normalize in the GestureDetector's coordinate space
    // The LayoutBuilder gives us the canvas size
    Navigator.pop(context, _strokes);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 340,
        child: Column(
          children: [
            // Header: Cancel — Draw tab — Done
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  const Icon(Icons.draw_outlined, size: 20, color: Colors.blue),
                  const SizedBox(width: 4),
                  const Text('Draw',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: _done,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Drawing area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize =
                      Size(constraints.maxWidth, constraints.maxHeight);

                  return GestureDetector(
                    onPanStart: (d) {
                      setState(() {
                        _currentStroke = [d.localPosition];
                      });
                    },
                    onPanUpdate: (d) {
                      setState(() {
                        _currentStroke.add(d.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        if (_currentStroke.length > 1) {
                          // Normalize strokes to 0..1
                          final normalized = _currentStroke
                              .map((p) => Offset(
                                    (p.dx / canvasSize.width).clamp(0.0, 1.0),
                                    (p.dy / canvasSize.height).clamp(0.0, 1.0),
                                  ))
                              .toList();
                          _strokes.add(normalized);
                        }
                        _currentStroke = [];
                      });
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        canvasSize: canvasSize,
                      ),
                      child: Stack(
                        children: [
                          // "Sign Here" placeholder
                          if (_strokes.isEmpty && _currentStroke.isEmpty)
                            Center(
                              child: Text(
                                'Sign Here',
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.grey.shade300,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          // Signature line
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 40,
                            child: Container(
                              height: 1,
                              color: Colors.blue.shade200,
                            ),
                          ),
                          // Clear button
                          if (_strokes.isNotEmpty)
                            Positioned(
                              right: 12,
                              bottom: 8,
                              child: TextButton(
                                onPressed: _clear,
                                child: const Text('Clear'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.canvasSize,
  });

  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw saved strokes (normalized → pixel)
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      final first = stroke[0];
      path.moveTo(first.dx * canvasSize.width, first.dy * canvasSize.height);
      for (var i = 1; i < stroke.length; i++) {
        final p = stroke[i];
        path.lineTo(p.dx * canvasSize.width, p.dy * canvasSize.height);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke (raw pixels)
    if (currentStroke.length > 1) {
      final path = Path()
        ..moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (var i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
