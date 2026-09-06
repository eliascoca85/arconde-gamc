import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/index.dart';
import 'basic_widgets.dart';

/// Pantalla completa para ver una foto o reproducir un video de evidencia.
class MediaViewerPage extends StatefulWidget {
  final String url;
  final bool isVideo;
  final String heroTag;

  const MediaViewerPage({
    super.key,
    required this.url,
    required this.isVideo,
    required this.heroTag,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  VideoPlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.play();
      controller.setLooping(true);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: widget.heroTag,
          child: widget.isVideo ? _buildVideo() : _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: AppLoadingIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (_hasError) {
      return const Center(
        child: Icon(Icons.error_outline, size: 64, color: Colors.white54),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: AppLoadingIndicator(color: Colors.white));
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(controller),
          GestureDetector(
            onTap: () => setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            }),
            child: Container(color: Colors.transparent),
          ),
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: AppColors.primaryBlue,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white10,
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
          ),
        ],
      ),
    );
  }
}
