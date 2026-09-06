import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../data/repositories/emergency_repository.dart'
    show cloudinaryVideoThumbnailUrl, inferEvidenceFileType;
import '../../../../../shared/widgets/basic_widgets.dart';

class EvidenceStep extends StatefulWidget {
  final List<String> evidenceUrls;
  final Function(List<String>) onEvidenceChanged;

  const EvidenceStep({
    super.key,
    required this.evidenceUrls,
    required this.onEvidenceChanged,
  });

  @override
  State<EvidenceStep> createState() => _EvidenceStepState();
}

class _EvidenceStepState extends State<EvidenceStep> {
  final ImagePicker _picker = ImagePicker();
  List<String> _localEvidence = [];

  @override
  void initState() {
    super.initState();
    _localEvidence = List.from(widget.evidenceUrls);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidencia', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Agrega fotos o videos para respaldar tu reporte (opcional)',
            style: AppTextStyles.bodyMediumSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildEvidenceGrid().staggerChild(0),
          const SizedBox(height: AppSpacing.lg),
          _buildAddEvidenceButtons().staggerChild(1),
          const SizedBox(height: AppSpacing.lg),
          _buildEvidenceInfo().staggerChild(2),
        ],
      ),
    );
  }

  Widget _buildEvidenceGrid() {
    if (_localEvidence.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_localEvidence.length} archivo(s) agregado(s)', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: _localEvidence.length + 1,
          itemBuilder: (context, index) {
            final item = index == _localEvidence.length ? _buildAddButton() : _buildEvidenceItem(index);
            return item.staggerChild(index, distance: 0.12);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: AppSpacing.iconXl, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('Sin evidencia agregada', style: AppTextStyles.bodyMediumSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text('Toca el botón de abajo para agregar', style: AppTextStyles.bodySmallTertiary),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(int index) {
    final url = _localEvidence[index];
    final isLocal = !url.startsWith('http');
    final isVideo = inferEvidenceFileType(url) == 'VIDEO';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          child: isVideo
              ? _buildVideoThumbnail(url)
              : isLocal
                  ? Image.asset(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceSecondary,
                        child: Icon(Icons.broken_image_outlined, size: AppSpacing.iconLg, color: AppColors.textTertiary),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceSecondary,
                        child: Center(child: AppLoadingIndicator(color: AppColors.primaryBlue)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceSecondary,
                        child: Icon(Icons.broken_image_outlined, size: AppSpacing.iconLg, color: AppColors.textTertiary),
                      ),
                    ),
        ),
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: GestureDetector(
            onTap: () => _removeEvidence(index),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: AppSpacing.iconXs, color: AppColors.textOnPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail(String url) {
    final thumbnailUrl = cloudinaryVideoThumbnailUrl(url);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null)
          CachedNetworkImage(
            imageUrl: thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: AppColors.surfaceSecondary),
            errorWidget: (context, url, error) => Container(color: AppColors.surfaceSecondary),
          )
        else
          Container(color: AppColors.surfaceSecondary),
        Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Icon(Icons.play_circle_fill, size: 32, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddOptions,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          border: Border.all(color: AppColors.secondaryTeal.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondaryTeal.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: AppSpacing.iconLg, color: AppColors.secondaryTeal),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Agregar', style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondaryTeal)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEvidenceButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Tomar foto',
                onPressed: () => _pickImage(ImageSource.camera),
                icon: Icons.camera_alt,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppOutlinedButton(
                label: 'Seleccionar de galería',
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icons.photo_library,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppOutlinedButton(
                label: 'Grabar video',
                onPressed: () => _pickVideo(ImageSource.camera),
                icon: Icons.videocam,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppOutlinedButton(
                label: 'Video de galería',
                onPressed: () => _pickVideo(ImageSource.gallery),
                icon: Icons.video_library,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvidenceInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primaryBlue, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Máximo 5 archivos. Formatos: JPG, PNG, MP4. Video máx: 60s. Tamaño máx: 10MB c/u.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _localEvidence.add(image.path);
          widget.onEvidenceChanged(_localEvidence);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        setState(() {
          _localEvidence.add(video.path);
          widget.onEvidenceChanged(_localEvidence);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar video'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _removeEvidence(int index) {
    setState(() {
      _localEvidence.removeAt(index);
      widget.onEvidenceChanged(_localEvidence);
    });
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
              ),
            ),
            Text('Agregar evidencia', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Foto: cámara',
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    icon: Icons.camera_alt,
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Foto: galería',
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    icon: Icons.photo_library,
                    isExpanded: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Video: cámara',
                    onPressed: () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.camera);
                    },
                    icon: Icons.videocam,
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Video: galería',
                    onPressed: () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.gallery);
                    },
                    icon: Icons.video_library,
                    isExpanded: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}