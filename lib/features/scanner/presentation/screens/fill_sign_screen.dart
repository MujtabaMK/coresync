import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../../domain/annotation_model.dart';
import '../widgets/annotation_painter.dart';
import '../widgets/color_picker_bar.dart';
import '../widgets/fill_sign_toolbar.dart';
import 'signature_capture_screen.dart';

class FillSignScreen extends StatefulWidget {
  const FillSignScreen({
    super.key,
    required this.imagePath,
    required this.pageIndex,
  });

  final String imagePath;
  final int pageIndex;

  @override
  State<FillSignScreen> createState() => _FillSignScreenState();
}

class _FillSignScreenState extends State<FillSignScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  final List<Annotation> _annotations = [];
  AnnotationTool _selectedTool = AnnotationTool.pen;
  Color _selectedColor = Colors.black;
  String? _selectedAnnotationId;
  bool _isSaving = false;
  bool _showPlacementHint = false;

  List<List<Offset>>? _cachedSignature;

  // In-progress drawing state
  List<Offset> _currentStrokePoints = [];
  Offset? _dragStart;
  Offset? _dragCurrent;

  // For moving selected annotations
  Offset? _moveStartOffset;

  // Image rect tracking
  Rect _imageRect = Rect.zero;
  Size _imageSize = Size.zero;

  bool get _isTapTool =>
      _selectedAnnotationId == null &&
      const {
        AnnotationTool.text,
        AnnotationTool.checkmark,
        AnnotationTool.cross,
        AnnotationTool.dot,
        AnnotationTool.signature,
      }.contains(_selectedTool);

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final file = File(widget.imagePath);
    if (!file.existsSync()) return;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
    }
    frame.image.dispose();
    codec.dispose();
  }

  Rect _computeImageRect(BoxConstraints constraints) {
    if (_imageSize == Size.zero) return Rect.zero;

    final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
    final imageAspect = _imageSize.width / _imageSize.height;
    final containerAspect = containerSize.width / containerSize.height;

    double w, h;
    if (imageAspect > containerAspect) {
      w = containerSize.width;
      h = w / imageAspect;
    } else {
      h = containerSize.height;
      w = h * imageAspect;
    }

    final left = (containerSize.width - w) / 2;
    final top = (containerSize.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  Offset _normalizePosition(Offset localPosition) {
    return Offset(
      ((localPosition.dx - _imageRect.left) / _imageRect.width).clamp(0.0, 1.0),
      ((localPosition.dy - _imageRect.top) / _imageRect.height).clamp(0.0, 1.0),
    );
  }

  bool _isInsideImage(Offset localPosition) {
    return _imageRect.contains(localPosition);
  }

  void _undo() {
    if (_annotations.isEmpty) return;
    setState(() {
      _annotations.removeLast();
      _selectedAnnotationId = null;
    });
  }

  // ─── TAP handling ───

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;
    if (!_isInsideImage(pos)) return;
    final normalized = _normalizePosition(pos);

    // Try to select existing annotation
    for (var i = _annotations.length - 1; i >= 0; i--) {
      if (_hitTestAnnotation(_annotations[i], pos)) {
        setState(() => _selectedAnnotationId = _annotations[i].id);
        return;
      }
    }

    switch (_selectedTool) {
      case AnnotationTool.text:
        _showTextInput(normalized);
      case AnnotationTool.checkmark:
        setState(() => _annotations.add(StampAnnotation(
              position: normalized,
              stampType: StampType.checkmark,
              color: _selectedColor,
            )));
      case AnnotationTool.cross:
        setState(() => _annotations.add(StampAnnotation(
              position: normalized,
              stampType: StampType.cross,
              color: _selectedColor,
            )));
      case AnnotationTool.dot:
        setState(() => _annotations.add(StampAnnotation(
              position: normalized,
              stampType: StampType.dot,
              color: _selectedColor,
            )));
      case AnnotationTool.signature:
        _placeSignature(normalized);
      default:
        break;
    }
  }

  // ─── PAN handling ───

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    if (!_isInsideImage(pos)) return;

    if (_selectedAnnotationId != null) {
      _moveStartOffset = _normalizePosition(pos);
      return;
    }

    switch (_selectedTool) {
      case AnnotationTool.pen:
        _currentStrokePoints = [_normalizePosition(pos)];
      case AnnotationTool.line:
      case AnnotationTool.rectangle:
        _dragStart = _normalizePosition(pos);
        _dragCurrent = _dragStart;
      default:
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final pos = details.localPosition;

    if (_selectedAnnotationId != null && _moveStartOffset != null) {
      final currentNorm = _normalizePosition(pos);
      final dx = currentNorm.dx - _moveStartOffset!.dx;
      final dy = currentNorm.dy - _moveStartOffset!.dy;
      _moveSelectedAnnotation(dx, dy);
      _moveStartOffset = currentNorm;
      return;
    }

    switch (_selectedTool) {
      case AnnotationTool.pen:
        if (_currentStrokePoints.isNotEmpty) {
          setState(() => _currentStrokePoints.add(_normalizePosition(pos)));
        }
      case AnnotationTool.line:
      case AnnotationTool.rectangle:
        if (_dragStart != null) {
          setState(() => _dragCurrent = _normalizePosition(pos));
        }
      default:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selectedAnnotationId != null && _moveStartOffset != null) {
      _moveStartOffset = null;
      setState(() => _selectedAnnotationId = null);
      return;
    }

    switch (_selectedTool) {
      case AnnotationTool.pen:
        if (_currentStrokePoints.length > 1) {
          setState(() {
            _annotations.add(StrokeAnnotation(
              points: List.of(_currentStrokePoints),
              color: _selectedColor,
            ));
            _currentStrokePoints = [];
          });
        } else {
          _currentStrokePoints = [];
        }
      case AnnotationTool.line:
        if (_dragStart != null && _dragCurrent != null) {
          setState(() => _annotations.add(LineAnnotation(
                start: _dragStart!,
                end: _dragCurrent!,
                color: _selectedColor,
              )));
        }
        _dragStart = null;
        _dragCurrent = null;
      case AnnotationTool.rectangle:
        if (_dragStart != null && _dragCurrent != null) {
          setState(() => _annotations.add(RectAnnotation(
                topLeft: _dragStart!,
                bottomRight: _dragCurrent!,
                color: _selectedColor,
              )));
        }
        _dragStart = null;
        _dragCurrent = null;
      default:
        break;
    }
  }

  // ─── Hit test, move, text input, signature ───

  bool _hitTestAnnotation(Annotation a, Offset canvasPos) {
    const threshold = 20.0;

    if (a is StampAnnotation) {
      final center = Offset(
        _imageRect.left + a.position.dx * _imageRect.width,
        _imageRect.top + a.position.dy * _imageRect.height,
      );
      return (center - canvasPos).distance <
          a.size * _imageRect.height / 2 + threshold;
    }
    if (a is TextAnnotation) {
      final pos = Offset(
        _imageRect.left + a.position.dx * _imageRect.width,
        _imageRect.top + a.position.dy * _imageRect.height,
      );
      final fontSize = a.fontSize * _imageRect.height;
      final rect = Rect.fromLTWH(
          pos.dx, pos.dy, fontSize * a.text.length * 0.6, fontSize * 1.2);
      return rect.inflate(threshold).contains(canvasPos);
    }
    if (a is SignatureAnnotation) {
      final originX = _imageRect.left + a.position.dx * _imageRect.width;
      final originY = _imageRect.top + a.position.dy * _imageRect.height;
      final w = a.scale * _imageRect.width;
      final h = w * 0.5;
      return Rect.fromLTWH(originX, originY, w, h)
          .inflate(threshold)
          .contains(canvasPos);
    }
    return false;
  }

  void _moveSelectedAnnotation(double dx, double dy) {
    final idx = _annotations.indexWhere((a) => a.id == _selectedAnnotationId);
    if (idx < 0) return;

    final a = _annotations[idx];
    Annotation? moved;

    if (a is StampAnnotation) {
      moved = StampAnnotation(
        id: a.id,
        position: Offset(a.position.dx + dx, a.position.dy + dy),
        stampType: a.stampType,
        color: a.color,
        size: a.size,
      );
    } else if (a is TextAnnotation) {
      moved = TextAnnotation(
        id: a.id,
        position: Offset(a.position.dx + dx, a.position.dy + dy),
        text: a.text,
        color: a.color,
        fontSize: a.fontSize,
      );
    } else if (a is SignatureAnnotation) {
      moved = SignatureAnnotation(
        id: a.id,
        position: Offset(a.position.dx + dx, a.position.dy + dy),
        strokes: a.strokes,
        color: a.color,
        scale: a.scale,
      );
    }

    if (moved != null) {
      setState(() => _annotations[idx] = moved!);
    }
  }

  Future<void> _showTextInput(Offset position) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty && mounted) {
      setState(() => _annotations.add(TextAnnotation(
            position: position,
            text: text,
            color: _selectedColor,
          )));
    }
  }

  /// Opens text dialog immediately from toolbar tap.
  /// Places text at center of the visible image area.
  Future<void> _captureText() async {
    // Place at center of image
    const position = Offset(0.5, 0.5);
    await _showTextInput(position);
  }

  /// Opens signature popup immediately. Every tap on Sign creates a fresh signature.
  Future<void> _captureSignature() async {
    _cachedSignature = null;
    final result = await showSignatureCapture(context);
    if (result == null || result.isEmpty || !mounted) return;
    _cachedSignature = result;
    setState(() {
      _selectedTool = AnnotationTool.signature;
      _showPlacementHint = true;
    });
  }

  /// Places cached signature at tap position.
  void _placeSignature(Offset position) {
    if (_cachedSignature == null) return;
    setState(() {
      _annotations.add(SignatureAnnotation(
        position: position,
        strokes: _cachedSignature!,
        color: _selectedColor,
      ));
      _showPlacementHint = false;
    });
  }

  void _deleteSelectedAnnotation() {
    if (_selectedAnnotationId == null) return;
    setState(() {
      _annotations.removeWhere((a) => a.id == _selectedAnnotationId);
      _selectedAnnotationId = null;
    });
  }

  void _resizeSelectedAnnotation(double delta) {
    if (_selectedAnnotationId == null) return;
    final idx = _annotations.indexWhere((a) => a.id == _selectedAnnotationId);
    if (idx < 0) return;

    final a = _annotations[idx];
    if (a is TextAnnotation) {
      final newSize = (a.fontSize + delta).clamp(0.02, 0.12);
      setState(() => _annotations[idx] = TextAnnotation(
            id: a.id,
            position: a.position,
            text: a.text,
            color: a.color,
            fontSize: newSize,
          ));
    } else if (a is SignatureAnnotation) {
      final newScale = (a.scale + delta).clamp(0.1, 0.6);
      setState(() => _annotations[idx] = SignatureAnnotation(
            id: a.id,
            position: a.position,
            strokes: a.strokes,
            color: a.color,
            scale: newScale,
          ));
    }
  }

  // ─── Resize bar ───

  Widget _buildResizeBar() {
    final idx = _annotations.indexWhere((a) => a.id == _selectedAnnotationId);
    if (idx < 0) return const SizedBox.shrink();

    final a = _annotations[idx];
    final bool isResizable = a is TextAnnotation || a is SignatureAnnotation;

    String sizeLabel;
    if (a is TextAnnotation) {
      sizeLabel = '${(a.fontSize * 100).round()}';
    } else if (a is SignatureAnnotation) {
      sizeLabel = '${(a.scale * 100).round()}%';
    } else {
      sizeLabel = '';
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isResizable) ...[
            IconButton.filled(
              onPressed: () => _resizeSelectedAnnotation(
                  a is TextAnnotation ? -0.005 : -0.03),
              icon: const Icon(Icons.remove, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: 'Decrease size',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(sizeLabel,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            IconButton.filled(
              onPressed: () => _resizeSelectedAnnotation(
                  a is TextAnnotation ? 0.005 : 0.03),
              icon: const Icon(Icons.add, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: 'Increase size',
            ),
            const SizedBox(width: 24),
          ],
          IconButton(
            onPressed: _deleteSelectedAnnotation,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  // ─── Save ───

  Future<void> _save() async {
    if (_annotations.isEmpty) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final pixelRatio = _imageSize.width / _imageRect.width;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) throw Exception('Failed to capture image');

      final jpgBytes =
          await compute(_encodeAsJpg, byteData.buffer.asUint8List());
      await File(widget.imagePath).writeAsBytes(jpgBytes);

      imageCache.clear();
      imageCache.clearLiveImages();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveAnnotations = List<Annotation>.from(_annotations);

    if (_currentStrokePoints.length > 1) {
      liveAnnotations.add(StrokeAnnotation(
        points: List.of(_currentStrokePoints),
        color: _selectedColor,
        id: '__live_stroke__',
      ));
    }
    if (_dragStart != null && _dragCurrent != null) {
      if (_selectedTool == AnnotationTool.line) {
        liveAnnotations.add(LineAnnotation(
          start: _dragStart!,
          end: _dragCurrent!,
          color: _selectedColor,
          id: '__live_line__',
        ));
      } else if (_selectedTool == AnnotationTool.rectangle) {
        liveAnnotations.add(RectAnnotation(
          topLeft: _dragStart!,
          bottomRight: _dragCurrent!,
          color: _selectedColor,
          id: '__live_rect__',
        ));
      }
    }

    final isTap = _isTapTool;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fill & Sign — Page ${widget.pageIndex + 1}'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          ColorPickerBar(
            selectedColor: _selectedColor,
            onColorSelected: (c) => setState(() => _selectedColor = c),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _imageRect = _computeImageRect(constraints);

                return Stack(
                  children: [
                    GestureDetector(
                      key: ValueKey('gesture_$isTap'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: isTap ? _onTapUp : null,
                      onPanStart: isTap ? null : _onPanStart,
                      onPanUpdate: isTap ? null : _onPanUpdate,
                      onPanEnd: isTap ? null : _onPanEnd,
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: File(widget.imagePath).existsSync()
                                  ? Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(
                                      Icons.broken_image_outlined, size: 64),
                            ),
                            if (_imageRect != Rect.zero)
                              CustomPaint(
                                painter: AnnotationPainter(
                                  annotations: liveAnnotations,
                                  imageRect: _imageRect,
                                  selectedId: _selectedAnnotationId,
                                ),
                              ),
                            if (_isSaving)
                              Container(
                                color: Colors.black38,
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_showPlacementHint)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                'Tap anywhere to place signature',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_selectedAnnotationId != null)
            _buildResizeBar(),
          FillSignToolbar(
            selectedTool: _selectedTool,
            onToolSelected: (tool) => setState(() {
              _selectedTool = tool;
              _selectedAnnotationId = null;
              _showPlacementHint = false;
            }),
            onSignTap: _captureSignature,
            onTextTap: _captureText,
            onUndo: _undo,
            canUndo: _annotations.isNotEmpty,
          ),
        ],
      ),
    );
  }
}

Uint8List _encodeAsJpg(Uint8List pngBytes) {
  final decoded = img.decodeImage(pngBytes);
  if (decoded == null) throw Exception('Failed to decode captured image');
  return Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
}
