import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Animates between two exercise images (start/end position) from free-exercise-db.
///
/// Uses ImageKit CDN with resizing for fast loading and 1-year cache.
class ExerciseAnimationWidget extends StatefulWidget {
  final String imageSlug;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const ExerciseAnimationWidget({
    super.key,
    required this.imageSlug,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
  });

  @override
  State<ExerciseAnimationWidget> createState() =>
      _ExerciseAnimationWidgetState();
}

class _ExerciseAnimationWidgetState extends State<ExerciseAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  String get _url0 =>
      'https://ik.imagekit.io/yuhonas/tr:w-400,h-400/${widget.imageSlug}/0.jpg';
  String get _url1 =>
      'https://ik.imagekit.io/yuhonas/tr:w-400,h-400/${widget.imageSlug}/1.jpg';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      color: Colors.white,
      child: _ImageCrossfade(
        url0: _url0,
        url1: _url1,
        animation: _animation,
        fit: widget.fit,
        errorWidget: widget.errorWidget,
      ),
    );
  }
}

class _ImageCrossfade extends AnimatedWidget {
  final String url0;
  final String url1;
  final BoxFit fit;
  final Widget? errorWidget;

  const _ImageCrossfade({
    required this.url0,
    required this.url1,
    required Animation<double> animation,
    required this.fit,
    this.errorWidget,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final opacity = (listenable as Animation<double>).value;
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url0,
          fit: fit,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) =>
              errorWidget ?? const SizedBox.shrink(),
        ),
        Opacity(
          opacity: opacity,
          child: CachedNetworkImage(
            imageUrl: url1,
            fit: fit,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}