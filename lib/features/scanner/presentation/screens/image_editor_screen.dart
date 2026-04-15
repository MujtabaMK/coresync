import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({
    super.key,
    required this.imagePath,
    required this.pageIndex,
  });

  final String imagePath;
  final int pageIndex;

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late String _currentPath;
  bool _isProcessing = false;
  int _imageKey = 0;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
  }

  Future<void> _crop() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentPath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Page ${widget.pageIndex + 1}',
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Page ${widget.pageIndex + 1}',
        ),
      ],
    );
    if (cropped != null && mounted) {
      setState(() {
        _currentPath = cropped.path;
        _imageKey++;
      });
    }
  }

  Future<void> _rotate() async {
    setState(() => _isProcessing = true);
    try {
      final file = File(_currentPath);
      final bytes = await file.readAsBytes();
      final encoded = await compute(_rotateImage, bytes);
      await file.writeAsBytes(encoded);
      // Clear Flutter's image cache so it reloads the updated file
      imageCache.clear();
      imageCache.clearLiveImages();
      if (mounted) setState(() => _imageKey++);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rotate error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyGrayscale() async {
    setState(() => _isProcessing = true);
    try {
      final file = File(_currentPath);
      final bytes = await file.readAsBytes();
      final encoded = await compute(_grayscaleImage, bytes);
      await file.writeAsBytes(encoded);
      imageCache.clear();
      imageCache.clearLiveImages();
      if (mounted) setState(() => _imageKey++);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filter error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _save() {
    if (_currentPath != widget.imagePath) {
      File(_currentPath).copySync(widget.imagePath);
      imageCache.clear();
      imageCache.clearLiveImages();
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Page ${widget.pageIndex + 1}'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  child: Center(
                    child: File(_currentPath).existsSync()
                        ? Image.file(
                            File(_currentPath),
                            key: ValueKey(_imageKey),
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          )
                        : const Icon(Icons.broken_image_outlined, size: 64),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black38,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _EditorButton(
                    icon: Icons.crop,
                    label: 'Crop',
                    onTap: _isProcessing ? null : _crop,
                  ),
                  _EditorButton(
                    icon: Icons.rotate_90_degrees_cw,
                    label: 'Rotate',
                    onTap: _isProcessing ? null : _rotate,
                  ),
                  _EditorButton(
                    icon: Icons.filter_b_and_w,
                    label: 'Grayscale',
                    onTap: _isProcessing ? null : _applyGrayscale,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs in a separate isolate via compute().
Uint8List _rotateImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Failed to decode image');
  final rotated = img.copyRotate(decoded, angle: 90);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 95));
}

/// Runs in a separate isolate via compute().
Uint8List _grayscaleImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Failed to decode image');
  final gray = img.grayscale(decoded);
  return Uint8List.fromList(img.encodeJpg(gray, quality: 90));
}

class _EditorButton extends StatelessWidget {
  const _EditorButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
