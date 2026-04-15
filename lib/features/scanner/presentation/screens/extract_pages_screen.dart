import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/scanned_document_model.dart';
import '../providers/scanner_provider.dart';

class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesScreenState();
}

class _ExtractPagesScreenState extends State<ExtractPagesScreen> {
  final _titleController = TextEditingController();
  final _selectedIndices = <int>{};

  ScannedDocumentModel? get _document {
    return context
        .read<ScannerCubit>()
        .state
        .documents
        .where((d) => d.id == widget.documentId)
        .firstOrNull;
  }

  Future<void> _extract() async {
    final doc = _document;
    if (doc == null) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one page')),
      );
      return;
    }

    try {
      final cubit = context.read<ScannerCubit>();
      final newDoc = await cubit.extractPages(
        documentId: doc.id,
        pageIndices: _selectedIndices.toList()..sort(),
        newTitle: title,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Extracted ${_selectedIndices.length} pages to "${newDoc.title}"',
            ),
          ),
        );
        // Pop back from the root overlay, then navigate within the shell
        Navigator.of(context).pop();
        context.go('/scanner/detail/${newDoc.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extract error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = _document;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Extract Pages')),
        body: const Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Pages'),
        actions: [
          TextButton(
            onPressed: _selectedIndices.isEmpty ? null : _extract,
            child: const Text('Extract'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'New document title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_selectedIndices.length} of ${doc.pageCount} pages selected',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: doc.pageImagePaths.length,
              itemBuilder: (context, index) {
                final path = doc.pageImagePaths[index];
                final isSelected = _selectedIndices.contains(index);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIndices.remove(index);
                      } else {
                        _selectedIndices.add(index);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
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
                                      child:
                                          Icon(Icons.broken_image_outlined),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                'Page ${index + 1}',
                                style:
                                    Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
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
