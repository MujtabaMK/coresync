import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/scanner_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../../../../core/widgets/main_shell_drawer.dart';
import '../providers/scanner_provider.dart';
import '../widgets/document_card.dart';

class ScannerListScreen extends StatefulWidget {
  const ScannerListScreen({super.key});

  @override
  State<ScannerListScreen> createState() => _ScannerListScreenState();
}

class _ScannerListScreenState extends State<ScannerListScreen> {
  bool _isSelectionMode = false;
  final _selectedIds = <String>{};
  int _coachMarkVersion = -1;

  @override
  void initState() {
    super.initState();
  }

  void _triggerCoachMark() {
    final v = CoachMarkService.resetVersion;
    if (_coachMarkVersion == v) return;
    _coachMarkVersion = v;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        CoachMarkService.showIfNeeded(
          context: context,
          screenKey: 'coach_mark_scanner_shown',
          targets: scannerCoachTargets(),
        );
      });
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _combineSelected() async {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 documents to combine')),
      );
      return;
    }

    final controller = TextEditingController(text: 'Combined Document');
    final title = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Combine Documents'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title for combined document',
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
            child: const Text('Combine'),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty || !mounted) return;

    try {
      final cubit = context.read<ScannerCubit>();
      final newDoc = await cubit.combineDocuments(
        documentIds: _selectedIds.toList(),
        newTitle: title,
      );
      _exitSelectionMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Combined into "${newDoc.title}"')),
        );
        context.go('/scanner/detail/${newDoc.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Combine error: $e')),
        );
      }
    }
  }

  Future<void> _showAddOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text('Scan Document'),
                subtitle: const Text('Camera with auto edge detection'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanDocument(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Import from Gallery'),
                subtitle: const Text('Select images from your gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importFromGallery(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanDocument(BuildContext context) async {
    // Request camera permission before scanning
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (!context.mounted) return;

    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission is required. Please enable it in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    if (!status.isGranted && !status.isLimited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required for document scanning')),
      );
      return;
    }

    try {
      final result =
          await FlutterDocScanner().getScannedDocumentAsImages(page: 20);
      if (result == null || !context.mounted) return;

      final images = result.images
          .where((p) => p.isNotEmpty)
          .map((p) => p.startsWith('file://') ? Uri.parse(p).toFilePath() : p)
          .toList();
      if (images.isNotEmpty && context.mounted) {
        context.go('/scanner/preview', extra: images);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: $e')),
        );
      }
    }
  }

  Future<void> _importFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty && context.mounted) {
        final paths = images.map((f) => f.path).toList();
        context.go('/scanner/preview', extra: paths);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} selected')
            : const Text('Scanner'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: MainShellDrawer.of(context),
              ),
        actions: _isSelectionMode
            ? [
                TextButton(
                  onPressed: _combineSelected,
                  child: const Text('Combine'),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () => context.push('/profile'),
                ),
              ],
      ),
      body: Column(
        children: [
          if (!_isSelectionMode)
            Padding(
              key: CoachMarkKeys.scannerSearch,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  context.read<ScannerCubit>().setSearchQuery(value);
                },
              ),
            ),
          Expanded(
            child: BlocBuilder<ScannerCubit, ScannerState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(child: Text('Error: ${state.error}'));
                }

                final documents = state.filteredDocuments;

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.document_scanner_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No scanned documents yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to scan or import a document',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final isSelected = _selectedIds.contains(doc.id);

                    if (_isSelectionMode) {
                      return Container(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1)
                            : null,
                        child: DocumentCard(
                          document: doc,
                          onTap: () => _toggleSelection(doc.id),
                          onLongPress: () {},
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(doc.id),
                          ),
                        ),
                      );
                    }

                    return DocumentCard(
                      document: doc,
                      onTap: () =>
                          context.go('/scanner/detail/${doc.id}'),
                      onLongPress: () => _enterSelectionMode(doc.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              key: CoachMarkKeys.scannerFab,
              heroTag: 'scannerFab',
              onPressed: () => _showAddOptions(context),
              child: const Icon(Icons.add),
            ),
    );
  }

}
