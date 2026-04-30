import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:turn_page_transition/turn_page_transition.dart';

import '../../../scanner/domain/annotation_model.dart';
import '../../../scanner/presentation/widgets/annotation_painter.dart';
import '../../../translator/data/tts_service.dart';
import '../../domain/pdf_document_model.dart';
import '../providers/pdf_reader_provider.dart';
import '../providers/pdf_viewer_provider.dart';
import '../widgets/pdf_annotation_toolbar.dart';
import '../widgets/pdf_tools_sheet.dart';
import '../widgets/pdf_tts_controls.dart';
import '../widgets/tts_highlight_painter.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with WidgetsBindingObserver {
  PdfDocumentModel? _document;
  PdfViewerCubit? _viewerCubit;
  TurnPageController? _turnPageController;
  bool _loading = true;
  bool _initialSyncDone = false;

  // Annotation drawing state
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDocument();
  }

  @override
  void didUpdateWidget(PdfViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentId != widget.documentId) {
      // Widget reused for a different document — save old & reinitialize.
      _saveCurrentPosition();
      _viewerCubit?.close();
      _viewerCubit = null;
      _turnPageController = null;
      _document = null;
      setState(() => _loading = true);
      _loadDocument();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background — persist TTS position in case process is killed
      _viewerCubit?.saveTtsPositionIfActive();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When the user switches to another tab, this branch goes offstage
    // and TickerMode becomes false — stop TTS so it doesn't keep reading.
    if (!TickerMode.of(context) && _viewerCubit != null) {
      _stopTtsIfActive();
    }
  }

  void _stopTtsIfActive() {
    final cubit = _viewerCubit!;
    if (cubit.state.ttsStatus == PdfTtsStatus.idle) return;
    cubit.stopTtsAndRememberPage();
    TtsService.instance.stop();
    TtsService.instance.setProgressHandler(null);
    cubit.clearTtsHighlight();
  }

  Future<void> _loadDocument() async {
    final doc = await context
        .read<PdfReaderCubit>()
        .repository
        .getDocumentById(widget.documentId);
    if (doc == null) {
      if (mounted) context.pop();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final cubit = PdfViewerCubit(
      documentId: doc.id,
      filePath: doc.filePath,
      uid: uid,
      initialPage: doc.lastPage,
      pageCount: doc.pageCount,
    );
    await cubit.loadAnnotations();

    _turnPageController = TurnPageController(
      initialPage: max(0, doc.lastPage - 1),
    );

    if (mounted) {
      setState(() {
        _document = doc;
        _viewerCubit = cubit;
        _loading = false;
      });
    }
  }

  /// Called by onSwipe / onTap after the controller already moved.
  /// Always reads the controller's actual position (source of truth).
  void _onPageTurned(bool isTurnForward) {
    final page = _turnPageController!.currentIndex + 1; // 0-based → 1-based
    _viewerCubit!.setCurrentPage(page);
  }

  /// Persist the current page position for the loaded document.
  /// Reads the actual visual page from the controller (source of truth).
  void _saveCurrentPosition() {
    if (_document == null || _viewerCubit == null) return;

    // 1. Sync cubit page with controller so every subsequent read is correct.
    final page = _turnPageController != null
        ? _turnPageController!.currentIndex + 1
        : _viewerCubit!.state.currentPage;
    _viewerCubit!.setCurrentPage(page);

    // 2. If TTS is active, stop it and remember the position (uses cubit
    //    state.currentPage which we just synced above).
    if (_viewerCubit!.state.ttsStatus != PdfTtsStatus.idle) {
      _viewerCubit!.stopTtsAndRememberPage();
    }
    TtsService.instance.stop();
    TtsService.instance.setProgressHandler(null);

    // 3. Save the page position to Hive.
    context.read<PdfReaderCubit>().updateLastOpened(
      _document!.id,
      lastPage: page,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentPosition();
    // Do NOT dispose _turnPageController here — TurnPageView already
    // disposes it in its own dispose(), and double-disposing a
    // ChangeNotifier throws, which can silently corrupt the save flow.
    _viewerCubit?.close();
    super.dispose();
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _document!.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename PDF'),
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
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != _document!.title) {
                final updated = await context
                    .read<PdfReaderCubit>()
                    .renameDocument(id: _document!.id, newTitle: newTitle);
                if (mounted) {
                  setState(() => _document = updated);
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Delete "${_document!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<PdfReaderCubit>()
                  .deleteDocument(_document!.id);
              if (mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showToolsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => PdfToolsSheet(
        title: _document!.title,
        filePath: _document!.filePath,
        onRename: _showRenameDialog,
        onDelete: _showDeleteDialog,
      ),
    );
  }

  // --- TTS with resume support ---

  void _onListenTap() {
    final cubit = _viewerCubit!;
    final state = cubit.state;

    // If already playing, stop and remember position
    if (state.ttsStatus != PdfTtsStatus.idle) {
      TtsService.instance.stop();
      TtsService.instance.setProgressHandler(null);
      // Save position BEFORE clearing highlight (needs highlight index for offset)
      cubit.stopTtsAndRememberPage();
      cubit.clearTtsHighlight();
      return;
    }

    // Use the controller's actual page (source of truth for visual position)
    final visualPage = _turnPageController != null
        ? _turnPageController!.currentIndex + 1
        : state.currentPage;

    // If there's a saved resume point, offer to resume from it
    if (state.hasTtsResumePoint) {
      _showTtsResumeDialog(
        state.ttsLastStoppedPage!,
        state.ttsLastStoppedOffset,
      );
    } else {
      _playFromPage(visualPage);
    }
  }

  void _showTtsResumeDialog(int lastStoppedPage, int lastStoppedOffset) {
    // Use the controller's actual page — never trust the cubit alone.
    final visualPage = _turnPageController != null
        ? _turnPageController!.currentIndex + 1
        : _viewerCubit!.state.currentPage;
    final isSamePage = lastStoppedPage == visualPage;
    final description = isSamePage
        ? 'You paused on this page. Resume from where you left off or start over?'
        : 'You paused on page $lastStoppedPage. '
            'Resume from there or start from the current page?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resume listening?'),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _viewerCubit!.clearTtsResumePoint();
              // Start over = page 1, first word
              _turnPageController?.jumpToPage(0);
              _viewerCubit!.setCurrentPage(1);
              _playFromPage(1);
            },
            child: const Text('Start over'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!isSamePage) {
                _turnPageController?.animateToPage(lastStoppedPage - 1);
                _viewerCubit!.setCurrentPage(lastStoppedPage);
              }
              _viewerCubit!.clearTtsResumePoint();
              _playFromPage(lastStoppedPage, offset: lastStoppedOffset);
            },
            child: Text(isSamePage
                ? 'Resume'
                : 'Resume (page $lastStoppedPage)'),
          ),
        ],
      ),
    );
  }

  Future<void> _playFromPage(int page, {int offset = 0}) async {
    final cubit = _viewerCubit;
    if (cubit == null) return;

    cubit.setTtsStatus(PdfTtsStatus.playing);
    // Always extract from the explicitly requested page — prevents using a
    // stale currentPage that might belong to a different document.
    final result = await cubit.extractCurrentPageTextWithPositions(page: page);
    if (result.fullText.isEmpty) {
      cubit.clearTtsHighlight();
      cubit.stopTtsAndRememberPage();
      return;
    }

    // Determine text to speak — skip to offset if resuming mid-page
    final resumeOffset =
        (offset > 0 && result.fullText.length > offset) ? offset : 0;
    final textToSpeak = resumeOffset > 0
        ? result.fullText.substring(resumeOffset)
        : result.fullText;

    if (textToSpeak.isEmpty) {
      cubit.clearTtsHighlight();
      cubit.stopTtsAndRememberPage();
      return;
    }

    final lang = cubit.state.ttsLanguage;

    // Set up progress handler — add resumeOffset so highlight maps to the full text
    TtsService.instance.setProgressHandler((text, start, end, word) {
      cubit.setTtsHighlightFromOffset(start + resumeOffset);
    });

    // Speak original text (no preprocessNumbersForTts) to keep offsets consistent
    final spoke = await TtsService.instance.speak(textToSpeak, lang);
    if (mounted) {
      if (!spoke) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No TTS voice available for ${kTtsLanguages[lang] ?? lang}',
            ),
          ),
        );
      }
      TtsService.instance.setProgressHandler(null);
      // Only clean up if still playing — if user paused, keep positions for resume
      if (cubit.state.ttsStatus == PdfTtsStatus.playing) {
        cubit.clearTtsHighlight();
        cubit.setTtsStatus(PdfTtsStatus.idle);
      }
    }
  }

  void _showLanguageSelector() {
    final cubit = _viewerCubit!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final currentLang = cubit.state.ttsLanguage;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reading Language',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Divider(height: 24),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: kTtsLanguages.entries.map((entry) {
                    final isSelected = entry.key == currentLang;
                    return ListTile(
                      title: Text(entry.value),
                      trailing: isSelected
                          ? Icon(Icons.check,
                              color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        cubit.setTtsLanguage(entry.key);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTextAnnotationDialog(int pageIndex, Offset normalizedPosition) {
    final controller = TextEditingController();
    final annotationColor = _viewerCubit!.state.annotationColor;
    showDialog(
      context: context,
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
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _viewerCubit!.addAnnotation(
                  pageIndex,
                  TextAnnotation(
                    position: normalizedPosition,
                    text: text,
                    color: annotationColor,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_document == null || _viewerCubit == null) {
      return const Scaffold(
        body: Center(child: Text('PDF not found')),
      );
    }

    return BlocProvider<PdfViewerCubit>.value(
      value: _viewerCubit!,
      child: BlocBuilder<PdfViewerCubit, PdfViewerState>(
        buildWhen: (prev, curr) =>
            prev.pageCount != curr.pageCount ||
            prev.ttsStatus != curr.ttsStatus ||
            prev.ttsLanguage != curr.ttsLanguage ||
            prev.isAnnotating != curr.isAnnotating ||
            prev.annotationTool != curr.annotationTool ||
            prev.annotationColor != curr.annotationColor ||
            prev.annotations != curr.annotations ||
            prev.isLoading != curr.isLoading,
        builder: (context, viewerState) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                _document!.title,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Language selector
                TextButton.icon(
                  icon: const Icon(Icons.translate, size: 18),
                  label: Text(
                    kTtsLanguages[viewerState.ttsLanguage]
                            ?.split(' ')
                            .first ??
                        'EN',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: _showLanguageSelector,
                ),
                // Listen button
                IconButton(
                  icon: Icon(
                    viewerState.ttsStatus != PdfTtsStatus.idle
                        ? Icons.volume_up
                        : Icons.volume_up_outlined,
                  ),
                  tooltip: 'Listen',
                  onPressed: _onListenTap,
                ),
                // Annotate button
                IconButton(
                  icon: Icon(
                    viewerState.isAnnotating
                        ? Icons.draw
                        : Icons.draw_outlined,
                  ),
                  tooltip: 'Annotate',
                  onPressed: () => _viewerCubit!.toggleAnnotationMode(),
                ),
                // Tools button
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _showToolsSheet,
                ),
              ],
            ),
            body: Column(
              children: [
                // Annotation toolbar
                const PdfAnnotationToolbar(),
                // PDF viewer
                Expanded(
                  child: _buildPdfViewer(viewerState),
                ),
                // TTS controls
                const PdfTtsControls(),
                // Page indicator — own BlocSelector so it doesn't rebuild TurnPageView
                _buildPageIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPdfViewer(PdfViewerState viewerState) {
    return PdfDocumentViewBuilder.file(
      _document!.filePath,
      builder: (context, document) {
        if (document == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final pageCount = document.pages.length;
        if (pageCount != _viewerCubit!.state.pageCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _viewerCubit!.setPageCount(pageCount);
          });
        }

        // After the TurnPageView first renders, sync the cubit with the
        // controller's actual position to prevent any initial desync.
        if (!_initialSyncDone) {
          _initialSyncDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_turnPageController != null && _viewerCubit != null) {
              final visualPage = _turnPageController!.currentIndex + 1;
              if (visualPage != _viewerCubit!.state.currentPage) {
                // The controller's initialPage didn't match — force jump
                // to the saved page so the visual and cubit agree.
                final savedPage = _viewerCubit!.state.currentPage;
                final targetIndex = (savedPage - 1)
                    .clamp(0, pageCount - 1);
                _turnPageController!.jumpToPage(targetIndex);
                _viewerCubit!.setCurrentPage(targetIndex + 1);
              }
            }
          });
        }

        return TurnPageView.builder(
          controller: _turnPageController!,
          itemCount: pageCount,
          useOnSwipe: !viewerState.isAnnotating,
          useOnTap: !viewerState.isAnnotating,
          overleafColorBuilder: (_) =>
              Theme.of(context).colorScheme.surfaceContainerHighest,
          animationTransitionPoint: 0.5,
          onSwipe: _onPageTurned,
          onTap: _onPageTurned,
          itemBuilder: (context, index) {
            return _buildPageWithAnnotations(document, index, viewerState);
          },
        );
      },
    );
  }

  Widget _buildPageWithAnnotations(
    PdfDocument document,
    int index,
    PdfViewerState viewerState,
  ) {
    final pageNumber = index + 1;
    final annotations = viewerState.annotationsForPage(index);
    final isCurrentPage = index == viewerState.currentPage - 1;

    // PDF page aspect ratio for highlight positioning
    final pdfPage = document.pages[index];
    final pdfPageAspectRatio = pdfPage.width / pdfPage.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // PDF page rendering
            PdfPageView(
              document: document,
              pageNumber: pageNumber,
            ),
            // TTS word highlight overlay — own BlocSelector to avoid full page rebuilds
            Positioned.fill(
              child: BlocSelector<PdfViewerCubit, PdfViewerState, Rect?>(
                selector: (state) {
                  if (index != state.currentPage - 1) return null;
                  final hi = state.ttsHighlightIndex;
                  if (hi == null || hi >= state.ttsWordPositions.length) {
                    return null;
                  }
                  return state.ttsWordPositions[hi].normalizedBounds;
                },
                builder: (context, bounds) {
                  if (bounds == null) return const SizedBox.shrink();
                  return IgnorePointer(
                    child: CustomPaint(
                      painter: TtsHighlightPainter(
                        normalizedBounds: bounds,
                        widgetSize: pageSize,
                        pdfPageAspectRatio: pdfPageAspectRatio,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Annotation paint overlay
            if (annotations.isNotEmpty ||
                (_currentStroke.isNotEmpty && isCurrentPage))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      annotations: [
                        ...annotations,
                        if (_currentStroke.length > 1 && isCurrentPage)
                          StrokeAnnotation(
                            points: _currentStroke,
                            color: viewerState.annotationColor,
                          ),
                      ],
                      imageRect: Offset.zero & pageSize,
                    ),
                  ),
                ),
              ),
            // Gesture detector for drawing annotations
            if (viewerState.isAnnotating && isCurrentPage)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (details) {
                    if (viewerState.annotationTool == AnnotationTool.text) {
                      final normalized = Offset(
                        details.localPosition.dx / pageSize.width,
                        details.localPosition.dy / pageSize.height,
                      );
                      _showTextAnnotationDialog(index, normalized);
                      return;
                    }
                    setState(() {
                      _currentStroke = [
                        Offset(
                          details.localPosition.dx / pageSize.width,
                          details.localPosition.dy / pageSize.height,
                        ),
                      ];
                    });
                  },
                  onPanUpdate: (details) {
                    if (viewerState.annotationTool == AnnotationTool.text) {
                      return;
                    }
                    setState(() {
                      _currentStroke = [
                        ..._currentStroke,
                        Offset(
                          details.localPosition.dx / pageSize.width,
                          details.localPosition.dy / pageSize.height,
                        ),
                      ];
                    });
                  },
                  onPanEnd: (_) {
                    if (_currentStroke.length > 1) {
                      if (viewerState.annotationTool ==
                          AnnotationTool.rectangle) {
                        _viewerCubit!.addAnnotation(
                          index,
                          RectAnnotation(
                            topLeft: _currentStroke.first,
                            bottomRight: _currentStroke.last,
                            color: viewerState.annotationColor,
                          ),
                        );
                      } else {
                        _viewerCubit!.addAnnotation(
                          index,
                          StrokeAnnotation(
                            points: _currentStroke,
                            color: viewerState.annotationColor,
                          ),
                        );
                      }
                    }
                    setState(() => _currentStroke = []);
                  },
                  onTapUp: (details) {
                    if (viewerState.annotationTool == AnnotationTool.text) {
                      final normalized = Offset(
                        details.localPosition.dx / pageSize.width,
                        details.localPosition.dy / pageSize.height,
                      );
                      _showTextAnnotationDialog(index, normalized);
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    final theme = Theme.of(context);
    return BlocSelector<PdfViewerCubit, PdfViewerState, (int, int)>(
      selector: (state) => (state.currentPage, state.pageCount),
      builder: (context, record) {
        final (currentPage, pageCount) = record;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 20,
                  onPressed: currentPage > 1
                      ? () {
                          _turnPageController?.previousPage();
                          final page =
                              _turnPageController!.currentIndex + 1;
                          _viewerCubit!.setCurrentPage(page);
                        }
                      : null,
                ),
                Text(
                  '$currentPage / $pageCount',
                  style: theme.textTheme.bodyMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 20,
                  onPressed: currentPage < pageCount
                      ? () {
                          _turnPageController?.nextPage();
                          final page =
                              _turnPageController!.currentIndex + 1;
                          _viewerCubit!.setCurrentPage(page);
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
