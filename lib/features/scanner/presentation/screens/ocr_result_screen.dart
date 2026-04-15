import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/share_utils.dart';

import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../data/docx_service.dart';
import '../../data/ocr_service.dart';
import '../../data/translation_service.dart';
import '../../domain/ocr_block.dart';

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

class _PageData {
  _PageData({
    required this.imagePath,
    required this.imageSize,
    required this.blocks,
  });

  final String imagePath;
  final Size imageSize;
  final List<OcrBlock> blocks;
}

sealed class _UndoAction {}

class _EditAction extends _UndoAction {
  _EditAction({
    required this.pageIndex,
    required this.blockIndex,
    required this.oldText,
    required this.newText,
  });
  final int pageIndex;
  final int blockIndex;
  final String oldText;
  final String newText;
}

class _DeleteAction extends _UndoAction {
  _DeleteAction({
    required this.pageIndex,
    required this.blockIndex,
  });
  final int pageIndex;
  final int blockIndex;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class OcrResultScreen extends StatefulWidget {
  const OcrResultScreen({
    super.key,
    required this.imagePaths,
    required this.documentTitle,
  });

  final List<String> imagePaths;
  final String documentTitle;

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // OCR
  bool _isProcessing = true;
  String? _ocrError;
  final List<_PageData> _pages = [];
  int _currentPage = 0;

  // Edit
  int? _selectedBlockIndex;
  final List<_UndoAction> _undoStack = [];
  final List<_UndoAction> _redoStack = [];

  // Translate (text)
  String _selectedLanguage = 'Spanish';
  String? _translatedText;
  bool _isTranslating = false;
  String? _translationError;

  // Photo translate
  String _photoTranslateLang = 'Spanish';
  bool _isPhotoTranslating = false;
  String? _photoTranslateError;
  // pageIndex -> { blockIndex -> translatedText }
  final Map<int, Map<int, String>> _translatedBlocks = {};

  // Capture keys for sharing as image
  final GlobalKey _editRepaintKey = GlobalKey();
  final GlobalKey _photoRepaintKey = GlobalKey();

  // Per-block background colors sampled from image: page -> blockIndex -> Color
  final Map<int, Map<int, Color>> _blockBgColors = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedBlockIndex = null);
      }
    });
    _performOcr();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // OCR
  // -----------------------------------------------------------------------

  Future<void> _performOcr() async {
    try {
      for (var i = 0; i < widget.imagePaths.length; i++) {
        final path = widget.imagePaths[i];
        final blocks = await OcrService.recognizeBlocks(path);
        final result = await _getImageDataAndSampleColors(path, blocks, i);
        _pages.add(
            _PageData(imagePath: path, imageSize: result, blocks: blocks));
      }
      if (mounted) setState(() => _isProcessing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _ocrError = e.toString();
        });
      }
    }
  }

  /// Gets image size and samples per-block background colors.
  Future<Size> _getImageDataAndSampleColors(
      String path, List<OcrBlock> blocks, int pageIndex) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    final size = Size(w.toDouble(), h.toDouble());

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return size;

    final data = byteData.buffer.asUint8List();
    final colors = <int, Color>{};

    for (var j = 0; j < blocks.length; j++) {
      colors[j] = _sampleBlockBgColor(data, w, h, blocks[j].boundingBox);
    }
    _blockBgColors[pageIndex] = colors;

    return size;
  }

  /// Samples background color around a specific block's bounding box.
  /// Picks the lightest pixels (most likely background, not text).
  Color _sampleBlockBgColor(
      Uint8List data, int imgW, int imgH, Rect bbox) {
    final left = bbox.left.round().clamp(0, imgW - 1);
    final top = bbox.top.round().clamp(0, imgH - 1);
    final right = bbox.right.round().clamp(0, imgW - 1);
    final bottom = bbox.bottom.round().clamp(0, imgH - 1);

    // Sample from edges of the block + slightly outside
    final samples = <(int, int, int)>[]; // (r, g, b)

    void addSample(int x, int y) {
      final cx = x.clamp(0, imgW - 1);
      final cy = y.clamp(0, imgH - 1);
      final offset = (cy * imgW + cx) * 4;
      if (offset + 2 < data.length) {
        samples.add((data[offset], data[offset + 1], data[offset + 2]));
      }
    }

    // Sample along top edge (just above the block)
    final aboveY = (top - 3).clamp(0, imgH - 1);
    final belowY = (bottom + 3).clamp(0, imgH - 1);
    final leftX = (left - 3).clamp(0, imgW - 1);
    final rightX = (right + 3).clamp(0, imgW - 1);

    for (var x = left; x <= right; x += ((right - left) ~/ 5).clamp(1, 50)) {
      addSample(x, aboveY);
      addSample(x, belowY);
    }
    for (var y = top; y <= bottom; y += ((bottom - top) ~/ 5).clamp(1, 50)) {
      addSample(leftX, y);
      addSample(rightX, y);
    }

    // Also sample corners outside the block
    addSample(leftX, aboveY);
    addSample(rightX, aboveY);
    addSample(leftX, belowY);
    addSample(rightX, belowY);

    if (samples.isEmpty) return Colors.white;

    // Sort by brightness (highest first) and take top 60% - these are background
    samples.sort((a, b) {
      final ba = a.$1 + a.$2 + a.$3;
      final bb = b.$1 + b.$2 + b.$3;
      return bb.compareTo(ba);
    });
    final take = (samples.length * 0.6).ceil().clamp(1, samples.length);

    int totalR = 0, totalG = 0, totalB = 0;
    for (var i = 0; i < take; i++) {
      totalR += samples[i].$1;
      totalG += samples[i].$2;
      totalB += samples[i].$3;
    }

    return Color.fromARGB(255, totalR ~/ take, totalG ~/ take, totalB ~/ take);
  }

  // -----------------------------------------------------------------------
  // Text helpers
  // -----------------------------------------------------------------------

  String get _allText {
    final buf = StringBuffer();
    for (var i = 0; i < _pages.length; i++) {
      if (i > 0) buf.writeln('\n--- Page ${i + 1} ---\n');
      final activeBlocks =
          _pages[i].blocks.where((b) => !b.isDeleted).map((b) => b.text);
      buf.writeln(activeBlocks.join('\n'));
    }
    return buf.toString().trim();
  }

  // -----------------------------------------------------------------------
  // Undo / Redo
  // -----------------------------------------------------------------------

  void _undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    switch (action) {
      case _EditAction(:final pageIndex, :final blockIndex, :final oldText):
        _pages[pageIndex].blocks[blockIndex].text = oldText;
        _redoStack.add(action);
      case _DeleteAction(:final pageIndex, :final blockIndex):
        _pages[pageIndex].blocks[blockIndex].isDeleted = false;
        _redoStack.add(action);
    }
    setState(() => _selectedBlockIndex = null);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();
    switch (action) {
      case _EditAction(:final pageIndex, :final blockIndex, :final newText):
        _pages[pageIndex].blocks[blockIndex].text = newText;
        _undoStack.add(action);
      case _DeleteAction(:final pageIndex, :final blockIndex):
        _pages[pageIndex].blocks[blockIndex].isDeleted = true;
        _undoStack.add(action);
    }
    setState(() => _selectedBlockIndex = null);
  }

  // -----------------------------------------------------------------------
  // Block actions
  // -----------------------------------------------------------------------

  void _onBlockTap(int index) {
    setState(() {
      _selectedBlockIndex = _selectedBlockIndex == index ? null : index;
    });
  }

  Future<void> _editBlock(int index) async {
    final block = _pages[_currentPage].blocks[index];
    final controller = TextEditingController(text: block.text);

    final newText = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          minLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit text...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newText != null && newText != block.text && mounted) {
      _undoStack.add(_EditAction(
        pageIndex: _currentPage,
        blockIndex: index,
        oldText: block.text,
        newText: newText,
      ));
      _redoStack.clear();
      block.text = newText;
      setState(() => _selectedBlockIndex = null);
    }
  }

  void _copyBlock(int index) {
    Clipboard.setData(
        ClipboardData(text: _pages[_currentPage].blocks[index].text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    setState(() => _selectedBlockIndex = null);
  }

  void _deleteBlock(int index) {
    _undoStack.add(
        _DeleteAction(pageIndex: _currentPage, blockIndex: index));
    _redoStack.clear();
    setState(() {
      _pages[_currentPage].blocks[index].isDeleted = true;
      _selectedBlockIndex = null;
    });
  }

  void _selectBlock(int index) {
    Clipboard.setData(
        ClipboardData(text: _pages[_currentPage].blocks[index].text));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text selected & copied')));
  }

  // -----------------------------------------------------------------------
  // Share / Save
  // -----------------------------------------------------------------------

  void _copyAll() {
    Clipboard.setData(ClipboardData(text: _allText));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _shareAll() =>
      shareText(_allText, context: context, subject: widget.documentTitle);

  Future<void> _saveAsTxt() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safe = widget.documentTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/$safe.txt');
      await file.writeAsString(_allText);
      await shareFiles([XFile(file.path)], context: context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  // -----------------------------------------------------------------------
  // Share as Image
  // -----------------------------------------------------------------------

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareAsImage() async {
    final tabIndex = _tabController.index;
    final key = tabIndex == 2 ? _photoRepaintKey : _editRepaintKey;

    // Deselect block before capture
    setState(() => _selectedBlockIndex = null);
    await Future.delayed(const Duration(milliseconds: 100));

    final bytes = await _captureWidget(key);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture image')));
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final safe = widget.documentTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/${safe}_page${_currentPage + 1}.png');
      await file.writeAsBytes(bytes);
      await shareFiles([XFile(file.path)],
          context: context, subject: widget.documentTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  Future<void> _shareAsPdf() async {
    final tabIndex = _tabController.index;
    final key = tabIndex == 2 ? _photoRepaintKey : _editRepaintKey;

    // Deselect block before capture
    setState(() => _selectedBlockIndex = null);
    await Future.delayed(const Duration(milliseconds: 100));

    final bytes = await _captureWidget(key);
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture image')));
      }
      return;
    }

    try {
      final pdf = pw.Document();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final safe = widget.documentTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/${safe}_edited.pdf');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      await shareFiles([XFile(file.path)],
          context: context, subject: widget.documentTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  Future<void> _shareAsDocx() async {
    if (_pages.isEmpty) return;
    final page = _pages[_currentPage];

    try {
      final docxBytes = DocxService.build(
        blocks: page.blocks,
        imageSize: page.imageSize,
      );

      final dir = await getTemporaryDirectory();
      final safe = widget.documentTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${dir.path}/${safe}_page${_currentPage + 1}.docx');
      await file.writeAsBytes(docxBytes);

      await shareFiles([XFile(file.path)],
          context: context, subject: widget.documentTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  // -----------------------------------------------------------------------
  // Translate (text)
  // -----------------------------------------------------------------------

  Future<void> _translate() async {
    final text = _allText.trim();
    if (text.isEmpty) return;
    setState(() {
      _isTranslating = true;
      _translatedText = null;
      _translationError = null;
    });
    try {
      final result = await TranslationService.instance
          .translate(text: text, targetLanguage: _selectedLanguage);
      if (mounted) setState(() => _translatedText = result);
    } catch (e) {
      if (mounted) setState(() => _translationError = e.toString());
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  // -----------------------------------------------------------------------
  // Photo translate
  // -----------------------------------------------------------------------

  Future<void> _translateOnPhoto() async {
    final page = _pages[_currentPage];
    final activeBlocks =
        page.blocks.where((b) => !b.isDeleted).toList();
    if (activeBlocks.isEmpty) return;

    setState(() {
      _isPhotoTranslating = true;
      _photoTranslateError = null;
      _translatedBlocks.remove(_currentPage);
    });

    try {
      final map = <int, String>{};
      // Translate each block individually for accuracy
      for (var i = 0; i < page.blocks.length; i++) {
        final block = page.blocks[i];
        if (block.isDeleted) continue;
        final result = await TranslationService.instance.translate(
          text: block.text,
          targetLanguage: _photoTranslateLang,
        );
        map[i] = result.trim();
      }
      if (mounted) setState(() => _translatedBlocks[_currentPage] = map);
    } catch (e) {
      if (mounted) setState(() => _photoTranslateError = e.toString());
    } finally {
      if (mounted) setState(() => _isPhotoTranslating = false);
    }
  }

  // -----------------------------------------------------------------------
  // Image layout helpers
  // -----------------------------------------------------------------------

  ({double offsetX, double offsetY, double scaleX, double scaleY, double w, double h})
      _imageLayout(Size imageSize, double availW, double availH) {
    final imgAspect = imageSize.width / imageSize.height;
    final availAspect = availW / availH;
    double w, h;
    if (imgAspect > availAspect) {
      w = availW;
      h = availW / imgAspect;
    } else {
      h = availH;
      w = availH * imgAspect;
    }
    return (
      offsetX: (availW - w) / 2,
      offsetY: (availH - h) / 2,
      scaleX: w / imageSize.width,
      scaleY: h / imageSize.height,
      w: w,
      h: h,
    );
  }

  // =======================================================================
  // BUILD
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Text'),
        actions: _appBarActions(tabIndex),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Edit'),
            Tab(icon: Icon(Icons.translate), text: 'Translate'),
            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Photo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditTab(),
          _buildTranslateTab(),
          _buildPhotoTranslateTab(),
        ],
      ),
    );
  }

  List<Widget> _appBarActions(int tab) {
    if (tab == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
          onPressed: _undoStack.isNotEmpty ? _undo : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
          onPressed: _redoStack.isNotEmpty ? _redo : null,
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'copy':
                _copyAll();
              case 'share':
                _shareAll();
              case 'save':
                _saveAsTxt();
              case 'share_image':
                _shareAsImage();
              case 'share_pdf':
                _shareAsPdf();
              case 'share_docx':
                _shareAsDocx();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'copy', child: Text('Copy All')),
            PopupMenuItem(value: 'share', child: Text('Share as Text')),
            PopupMenuItem(value: 'save', child: Text('Save as .txt')),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'share_image',
              child: ListTile(
                leading: Icon(Icons.image),
                title: Text('Share as Image'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'share_pdf',
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Share as PDF'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'share_docx',
              child: ListTile(
                leading: Icon(Icons.description),
                title: Text('Save as Word (.docx)'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ];
    }
    if (tab == 1) {
      final has =
          _translatedText != null && _translatedText!.isNotEmpty;
      return [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy',
          onPressed: has
              ? () {
                  Clipboard.setData(ClipboardData(text: _translatedText!));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')));
                }
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share',
          onPressed: has
              ? () => shareText(_translatedText!,
                  context: context, subject: widget.documentTitle)
              : null,
        ),
      ];
    }
    // tab == 2 (photo translate)
    return [
      PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'copy':
              _copyAll();
            case 'share':
              _shareAll();
            case 'share_image':
              _shareAsImage();
            case 'share_pdf':
              _shareAsPdf();
            case 'share_docx':
              _shareAsDocx();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'copy', child: Text('Copy All')),
          PopupMenuItem(value: 'share', child: Text('Share as Text')),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'share_image',
            child: ListTile(
              leading: Icon(Icons.image),
              title: Text('Share as Image'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'share_pdf',
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Share as PDF'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'share_docx',
            child: ListTile(
              leading: Icon(Icons.description),
              title: Text('Save as Word (.docx)'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  // -- Page selector --------------------------------------------------------

  Widget _pageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
            onPressed: _currentPage > 0
                ? () => setState(() {
                      _currentPage--;
                      _selectedBlockIndex = null;
                    })
                : null,
          ),
          Text('Page ${_currentPage + 1} of ${_pages.length}',
              style: Theme.of(context).textTheme.bodyMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
            onPressed: _currentPage < _pages.length - 1
                ? () => setState(() {
                      _currentPage++;
                      _selectedBlockIndex = null;
                    })
                : null,
          ),
        ],
      ),
    );
  }

  // ======================================================================
  // TAB 1 -- Edit
  // ======================================================================

  Widget _buildEditTab() {
    if (_isProcessing) {
      return const LoadingWidget(message: 'Recognizing text...');
    }
    if (_ocrError != null) {
      return AppErrorWidget(
        message: _ocrError!,
        onRetry: () {
          setState(() {
            _isProcessing = true;
            _ocrError = null;
            _pages.clear();
          });
          _performOcr();
        },
      );
    }
    if (_pages.isEmpty || _pages[_currentPage].blocks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_pages.length > 1) _pageSelector(),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (_, constraints) =>
                      _buildEditImage(constraints),
                ),
              ),
              if (_selectedBlockIndex != null &&
                  _selectedBlockIndex! <
                      _pages[_currentPage].blocks.length &&
                  !_pages[_currentPage].blocks[_selectedBlockIndex!].isDeleted)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomActionBar(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditImage(BoxConstraints constraints) {
    final page = _pages[_currentPage];
    final l = _imageLayout(
        page.imageSize, constraints.maxWidth, constraints.maxHeight);

    return RepaintBoundary(
      key: _editRepaintKey,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              // Image
              Positioned(
                left: l.offsetX,
                top: l.offsetY,
                width: l.w,
                height: l.h,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedBlockIndex = null);
                  },
                  child: Image.file(File(page.imagePath), fit: BoxFit.fill),
                ),
              ),
              // Block overlays
              for (var i = 0; i < page.blocks.length; i++)
                _buildBlockOverlay(
                    page.blocks[i], i, l.offsetX, l.offsetY, l.scaleX, l.scaleY),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBlockBgColor(int blockIndex) {
    return _blockBgColors[_currentPage]?[blockIndex] ?? Colors.white;
  }

  Widget _buildBlockOverlay(OcrBlock block, int index, double ox, double oy,
      double sx, double sy) {
    final r = block.boundingBox;
    final blockW = r.width * sx;
    final blockH = r.height * sy;

    final bgColor = _getBlockBgColor(index);

    // Deleted block: cover with sampled local background color
    if (block.isDeleted) {
      const pad = 4.0;
      return Positioned(
        left: ox + r.left * sx - pad,
        top: oy + r.top * sy - pad,
        width: blockW + pad * 2,
        height: blockH + pad * 2,
        child: Container(color: bgColor),
      );
    }

    // Edited block: cover original text + show new text fitted inside
    if (block.isEdited) {
      final isSelected = _selectedBlockIndex == index;
      final textColor = bgColor.computeLuminance() > 0.5
          ? Colors.black87
          : Colors.white;
      return Positioned(
        left: ox + r.left * sx,
        top: oy + r.top * sy,
        width: blockW,
        height: blockH,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onBlockTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: isSelected
                  ? Border.all(color: Colors.blue, width: 1.5)
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 1),
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                block.text,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.15,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Normal block: highlight overlay
    final isSelected = _selectedBlockIndex == index;
    return Positioned(
      left: ox + r.left * sx,
      top: oy + r.top * sy,
      width: blockW,
      height: blockH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onBlockTap(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.18)
                : Colors.blue.withValues(alpha: 0.06),
            border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : Colors.blue.withValues(alpha: 0.35),
              width: isSelected ? 2.0 : 0.8,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: isSelected
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _handle(-5, -5, null, null),
                    _handle(null, -5, -5, null),
                    _handle(-5, null, null, -5),
                    _handle(null, null, -5, -5),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _handle(double? l, double? t, double? r, double? b) {
    return Positioned(
      left: l,
      top: t,
      right: r,
      bottom: b,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final idx = _selectedBlockIndex!;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionBtn(Icons.edit, 'Edit', () => _editBlock(idx)),
            _actionBtn(Icons.select_all, 'Select', () => _selectBlock(idx)),
            _actionBtn(Icons.copy, 'Copy', () => _copyBlock(idx)),
            _actionBtn(Icons.delete_outline, 'Delete', () => _deleteBlock(idx)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.text_fields,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No text recognized',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  // ======================================================================
  // TAB 2 -- Translate (text)
  // ======================================================================

  Widget _buildTranslateTab() {
    if (_isProcessing) {
      return const LoadingWidget(message: 'Recognizing text...');
    }
    final theme = Theme.of(context);
    final langs = TranslationService.languages.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (_) => _SearchableLanguageDialog(
                title: 'Target Language',
                items: langs,
                selectedItem: _selectedLanguage,
                onSelected: (v) {
                  setState(() {
                    _selectedLanguage = v;
                    _translatedText = null;
                    _translationError = null;
                  });
                },
              ),
            ),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Target Language',
                border: OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_selectedLanguage)),
                  Icon(Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _isTranslating || _allText.trim().isEmpty ? null : _translate,
            icon: const Icon(Icons.translate),
            label: const Text('Translate'),
          ),
          const SizedBox(height: 24),
          if (_isTranslating)
            const LoadingWidget(message: 'Translating...')
          else if (_translationError != null)
            AppErrorWidget(message: _translationError!, onRetry: _translate)
          else if (_translatedText != null)
            SelectableText(_translatedText!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6))
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate,
                        size: 64,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('Select a language and tap Translate',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ======================================================================
  // TAB 3 -- Photo Translate (on-image)
  // ======================================================================

  Widget _buildPhotoTranslateTab() {
    if (_isProcessing) {
      return const LoadingWidget(message: 'Recognizing text...');
    }
    if (_ocrError != null) {
      return AppErrorWidget(
        message: _ocrError!,
        onRetry: () {
          setState(() {
            _isProcessing = true;
            _ocrError = null;
            _pages.clear();
          });
          _performOcr();
        },
      );
    }
    if (_pages.isEmpty) {
      return const Center(child: Text('No pages'));
    }

    final langs = TranslationService.languages.keys.toList();

    return Column(
      children: [
        // Language picker + translate button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _SearchableLanguageDialog(
                      title: 'Language',
                      items: langs,
                      selectedItem: _photoTranslateLang,
                      onSelected: (v) {
                        setState(() {
                          _photoTranslateLang = v;
                          _translatedBlocks.clear();
                          _photoTranslateError = null;
                        });
                      },
                    ),
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(_photoTranslateLang)),
                        Icon(Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _isPhotoTranslating ? null : _translateOnPhoto,
                child: _isPhotoTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Translate'),
              ),
            ],
          ),
        ),

        if (_photoTranslateError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_photoTranslateError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),

        if (_pages.length > 1) _pageSelector(),

        // Image with translated overlays
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) =>
                _buildPhotoTranslateImage(constraints),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTranslateImage(BoxConstraints constraints) {
    final page = _pages[_currentPage];
    final l = _imageLayout(
        page.imageSize, constraints.maxWidth, constraints.maxHeight);
    final translations = _translatedBlocks[_currentPage];

    return RepaintBoundary(
      key: _photoRepaintKey,
      child: InteractiveViewer(
        maxScale: 5.0,
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              // Original image
              Positioned(
                left: l.offsetX,
                top: l.offsetY,
                width: l.w,
                height: l.h,
                child: Image.file(File(page.imagePath), fit: BoxFit.fill),
              ),
              // Translated text overlays
              if (translations != null)
                for (var i = 0; i < page.blocks.length; i++)
                  if (translations.containsKey(i) && !page.blocks[i].isDeleted)
                    _buildTranslatedOverlay(
                        page.blocks[i], i, translations[i]!, l.offsetX,
                        l.offsetY, l.scaleX, l.scaleY),
              // Cover deleted blocks
              for (var i = 0; i < page.blocks.length; i++)
                if (page.blocks[i].isDeleted)
                  _buildDeletedOverlay(
                      page.blocks[i], i, l.offsetX, l.offsetY, l.scaleX,
                      l.scaleY),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedOverlay(OcrBlock block, int blockIndex, double ox,
      double oy, double sx, double sy) {
    final bgColor = _getBlockBgColor(blockIndex);
    final r = block.boundingBox;
    const pad = 4.0;
    return Positioned(
      left: ox + r.left * sx - pad,
      top: oy + r.top * sy - pad,
      width: r.width * sx + pad * 2,
      height: r.height * sy + pad * 2,
      child: Container(color: bgColor),
    );
  }

  Widget _buildTranslatedOverlay(OcrBlock block, int blockIndex,
      String translated, double ox, double oy, double sx, double sy) {
    final bgColor = _getBlockBgColor(blockIndex);
    final r = block.boundingBox;
    final blockW = r.width * sx;
    final blockH = r.height * sy;

    final textColor = bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    return Positioned(
      left: ox + r.left * sx,
      top: oy + r.top * sy,
      width: blockW,
      height: blockH,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            translated,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Searchable Language Dialog
// ---------------------------------------------------------------------------

class _SearchableLanguageDialog extends StatefulWidget {
  const _SearchableLanguageDialog({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
  });

  final String title;
  final List<String> items;
  final String selectedItem;
  final ValueChanged<String> onSelected;

  @override
  State<_SearchableLanguageDialog> createState() =>
      _SearchableLanguageDialogState();
}

class _SearchableLanguageDialogState extends State<_SearchableLanguageDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) => item.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Flexible(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No results found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final isSelected = item == widget.selectedItem;

                        return ListTile(
                          selected: isSelected,
                          title: Text(item),
                          trailing: isSelected
                              ? Icon(Icons.check,
                                  color: theme.colorScheme.primary)
                              : null,
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
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