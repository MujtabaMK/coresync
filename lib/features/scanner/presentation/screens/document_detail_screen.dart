import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/share_utils.dart';
import '../../domain/scanned_document_model.dart';
import '../providers/scanner_provider.dart';
import '../widgets/more_tools_sheet.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late ScannerCubit _cubit;
  ScannedDocumentModel? _document;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<ScannerCubit>();
    _document = _cubit.state.documents
        .where((d) => d.id == widget.documentId)
        .firstOrNull;
  }

  Future<void> _rename() async {
    final doc = _document;
    if (doc == null) return;

    final controller = TextEditingController(text: doc.title);
    final newTitle = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && mounted) {
      final updated = await _cubit.renameDocument(
        documentId: doc.id,
        newTitle: newTitle,
      );
      if (mounted) setState(() => _document = updated);
    }
  }

  Future<void> _delete() async {
    final doc = _document;
    if (doc == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
            'Are you sure you want to delete this document? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cubit.deleteDocument(doc.id);
      if (mounted) context.go('/scanner');
    }
  }

  Future<void> _sharePdf() async {
    final doc = _document;
    if (doc == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );
      final pdfPath = await _cubit.generatePdf(doc.id);
      messenger.clearSnackBars();
      await shareFiles([XFile(pdfPath)], context: context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _shareImages() async {
    final doc = _document;
    if (doc == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final files = doc.pageImagePaths.map((p) => XFile(p)).toList();
      await shareFiles(files, context: context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error sharing images: $e')),
      );
    }
  }

  Future<void> _addPages() async {
    final doc = _document;
    if (doc == null) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner),
              title: const Text('Scan more pages'),
              subtitle: const Text('Camera with edge detection'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromScanner(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Import from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromGallery(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFromScanner(ScannedDocumentModel document) async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (!mounted) return;
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission required. Please enable in Settings.'),
          action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        ),
      );
      return;
    }
    if (!status.isGranted && !status.isLimited) return;

    try {
      final result =
          await FlutterDocScanner().getScannedDocumentAsImages(page: 20);
      if (result == null) return;

      final images = result.images.where((p) => p.isNotEmpty).toList();
      if (images.isNotEmpty) {
        final updated = await _cubit.addPages(
          documentId: document.id,
          sourceImagePaths: images,
        );
        if (mounted) setState(() => _document = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _addFromGallery(ScannedDocumentModel document) async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        final updated = await _cubit.addPages(
          documentId: document.id,
          sourceImagePaths: images.map((f) => f.path).toList(),
        );
        if (mounted) setState(() => _document = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  void _showFullPage(String path, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Page ${index + 1}')),
          body: InteractiveViewer(
            child: Center(
              child: File(path).existsSync()
                  ? Image.file(File(path))
                  : const Icon(Icons.broken_image_outlined, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _modifyScan() async {
    final doc = _document;
    if (doc == null || doc.pageImagePaths.isEmpty) return;

    if (doc.pageCount == 1) {
      await _openPageEditor(0, doc.pageImagePaths[0]);
    } else {
      _showPagePicker(
        title: 'Select a page to edit',
        onPageSelected: (index, path) => _openPageEditor(index, path),
      );
    }
  }

  Future<void> _fillAndSign() async {
    final doc = _document;
    if (doc == null || doc.pageImagePaths.isEmpty) return;

    if (doc.pageCount == 1) {
      await _openFillSign(0, doc.pageImagePaths[0]);
    } else {
      _showPagePicker(
        title: 'Select a page to fill & sign',
        onPageSelected: (index, path) => _openFillSign(index, path),
      );
    }
  }

  Future<void> _openFillSign(int pageIndex, String imagePath) async {
    final result = await context.push<bool>(
      '/scanner/detail/${widget.documentId}/fill-sign',
      extra: {'pageIndex': pageIndex, 'imagePath': imagePath},
    );
    if (result == true && mounted) {
      imageCache.clear();
      imageCache.clearLiveImages();
      final updated = await _cubit.getDocumentById(widget.documentId);
      if (updated != null && mounted) {
        setState(() => _document = updated);
      }
    }
  }

  Future<void> _openPageEditor(int pageIndex, String imagePath) async {
    final result = await context.push<bool>(
      '/scanner/detail/${widget.documentId}/edit-page',
      extra: {'pageIndex': pageIndex, 'imagePath': imagePath},
    );
    if (result == true && mounted) {
      // Refresh document state after editing
      imageCache.clear();
      imageCache.clearLiveImages();
      final updated = await _cubit.getDocumentById(widget.documentId);
      if (updated != null && mounted) {
        setState(() => _document = updated);
      }
    }
  }

  void _showPagePicker({
    required String title,
    required void Function(int index, String path) onPageSelected,
  }) {
    final doc = _document;
    if (doc == null) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: doc.pageImagePaths.length,
                itemBuilder: (_, index) {
                  final path = doc.pageImagePaths[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onPageSelected(index, path);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 0.75,
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: File(path).existsSync()
                                    ? Image.file(File(path),
                                        fit: BoxFit.cover)
                                    : const Icon(
                                        Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          Text('Page ${index + 1}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _extractPages() {
    final doc = _document;
    if (doc == null) return;
    context.push('/scanner/detail/${doc.id}/extract');
  }

  Future<void> _compressPdf() async {
    final doc = _document;
    if (doc == null) return;

    final quality = await showDialog<int>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => SimpleDialog(
        title: const Text('Compression Quality'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 30),
            child: const Text('High compression (smaller file)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 50),
            child: const Text('Medium compression'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 70),
            child: const Text('Low compression (better quality)'),
          ),
        ],
      ),
    );

    if (quality == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Compressing PDF...')),
      );
      final path = await _cubit.generateCompressedPdf(
        doc.id,
        quality: quality,
      );
      messenger.clearSnackBars();
      await shareFiles([XFile(path)], context: context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Compress error: $e')),
      );
    }
  }

  Future<void> _setPassword() async {
    final doc = _document;
    if (doc == null) return;

    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Set PDF Password'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Creating protected PDF...')),
      );
      final path = await _cubit.generateProtectedPdf(doc.id, password);
      messenger.clearSnackBars();
      await shareFiles([XFile(path)], context: context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Encryption error: $e')),
      );
    }
  }

  Future<void> _printDocument() async {
    final doc = _document;
    if (doc == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Preparing to print...')),
      );
      await _cubit.printDocument(doc.id);
      messenger.clearSnackBars();
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(content: Text('Print error: $e')),
      );
    }
  }

  Future<void> _editText() async {
    final doc = _document;
    if (doc == null) return;

    if (mounted) {
      context.push(
        '/scanner/detail/${doc.id}/ocr',
        extra: {
          'imagePaths': doc.pageImagePaths,
          'title': doc.title,
        },
      );
    }
  }

  Future<void> _combineFiles() async {
    final doc = _document;
    if (doc == null) return;

    final allDocs = _cubit.state.documents.where((d) => d.id != doc.id).toList();
    if (allDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other documents to combine with')),
      );
      return;
    }

    final selected = <String>{doc.id};
    final titleController = TextEditingController(text: '${doc.title} (Combined)');

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Combine Files'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Combined document title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Select documents to combine:'),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allDocs.length,
                    itemBuilder: (_, i) {
                      final d = allDocs[i];
                      final isSelected = selected.contains(d.id);
                      return CheckboxListTile(
                        title: Text(d.title),
                        subtitle: Text('${d.pageCount} pages'),
                        value: isSelected,
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(d.id);
                            } else {
                              selected.remove(d.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Combine'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final title = titleController.text.trim();
      if (title.isEmpty) return;
      final newDoc = await _cubit.combineDocuments(
        documentIds: selected.toList(),
        newTitle: title,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Combined into "${newDoc.title}"')),
        );
        context.go('/scanner/detail/${newDoc.id}');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Combine error: $e')),
      );
    }
  }

  void _showMoreTools() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      builder: (_) => MoreToolsSheet(
        onModifyScan: _modifyScan,
        onSaveAsJpeg: _shareImages,
        onEditText: _editText,
        onExportPdf: _sharePdf,
        onCombineFiles: _combineFiles,
        onExtractPages: _extractPages,
        onCompressPdf: _compressPdf,
        onSetPassword: _setPassword,
        onFillSign: _fillAndSign,
        onPrint: _printDocument,
        onAddPages: _addPages,
        onDelete: _delete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document')),
        body: const Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename',
            onPressed: _rename,
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'More Tools',
            onPressed: _showMoreTools,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: doc.pageImagePaths.length,
        itemBuilder: (context, index) {
          final path = doc.pageImagePaths[index];
          return GestureDetector(
            onTap: () => _showFullPage(path, index),
            onLongPress: () => _openPageEditor(index, path),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: File(path).existsSync()
                        ? Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Page ${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
