import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/coach_marks/coach_mark_keys.dart';
import '../../../../core/coach_marks/pdf_reader_coach_marks.dart';
import '../../../../core/services/coach_mark_service.dart';
import '../providers/pdf_reader_provider.dart';
import '../widgets/pdf_card.dart';

class PdfListScreen extends StatefulWidget {
  const PdfListScreen({super.key});

  @override
  State<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends State<PdfListScreen> {
  final _searchController = TextEditingController();
  bool _isImporting = false;
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
          screenKey: 'coach_mark_pdf_reader_shown',
          targets: pdfReaderCoachTargets(),
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Import PDF',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('From device'),
              subtitle: const Text('Pick a PDF from your files'),
              onTap: () {
                Navigator.pop(ctx);
                _importFromDevice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined),
              title: const Text('From URL'),
              subtitle: const Text('Download a PDF from a web link'),
              onTap: () {
                Navigator.pop(ctx);
                _showUrlDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    setState(() => _isImporting = true);
    try {
      final cubit = context.read<PdfReaderCubit>();
      final doc = await cubit.importPdf(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${doc.title}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download PDF'),
        content: TextField(
          controller: urlController,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'PDF URL',
            hintText: 'https://example.com/file.pdf',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              Navigator.pop(ctx);
              if (url.isNotEmpty) _importFromUrl(url);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromUrl(String url) async {
    // Basic URL validation
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL')),
        );
      }
      return;
    }

    setState(() => _isImporting = true);
    try {
      final cubit = context.read<PdfReaderCubit>();
      final doc = await cubit.importPdfFromUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded "${doc.title}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _triggerCoachMark();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('PDF Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: CoachMarkKeys.pdfImport,
        onPressed: _isImporting ? null : _showImportOptions,
        child: _isImporting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            key: CoachMarkKeys.pdfSearch,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search PDFs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<PdfReaderCubit>().setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<PdfReaderCubit>().setSearchQuery(value);
                setState(() {}); // update clear button visibility
              },
            ),
          ),
          // Document list
          Expanded(
            child: BlocBuilder<PdfReaderCubit, PdfReaderState>(
              builder: (context, state) {
                if (state.isLoading && state.documents.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = state.filteredDocuments;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.searchQuery.isNotEmpty
                              ? 'No PDFs match your search'
                              : 'No PDFs imported yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (state.searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to import or download a PDF',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<PdfReaderCubit>().loadDocuments(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PdfCard(
                          document: doc,
                          onTap: () {
                            context.go('/pdf-reader/view/${doc.id}');
                          },
                          onDelete: () {
                            context.read<PdfReaderCubit>().deleteDocument(doc.id);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
