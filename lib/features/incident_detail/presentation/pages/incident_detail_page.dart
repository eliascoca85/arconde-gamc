import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/auth_service.dart';
import '../../../../../data/dtos/emergency_message_dto.dart';
import '../../../../../data/dtos/evidence_dto.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/auth_gate.dart';
import '../../../../../shared/widgets/basic_widgets.dart';
import '../widgets/incident_comments_section.dart';
import '../widgets/incident_timeline.dart';
import '../widgets/incident_header.dart';

class IncidentDetailPage extends StatefulWidget {
  final String incidentId;

  const IncidentDetailPage({super.key, required this.incidentId});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  final _emergencyRepository = EmergencyRepository();
  final _picker = ImagePicker();
  final _commentController = TextEditingController();
  Incident? _incident;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isTogglingLike = false;
  final List<EmergencyMessageDto> _messages = [];
  final List<EvidenceDto> _evidences = [];
  bool _isSendingComment = false;
  bool _isUploadingEvidence = false;

  @override
  void initState() {
    super.initState();
    _loadIncident();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadIncident() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final id = int.tryParse(widget.incidentId);
    if (id == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      final incident = await _emergencyRepository.getDetailIncident(id);
      if (!mounted) return;
      setState(() {
        _incident = incident;
        _isLoading = false;
      });
      if (AuthService.isLoggedIn.value) {
        _registerView(id);
      }
      _loadMessages(id);
      _loadEvidence(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _registerView(int id) async {
    try {
      final viewsCount = await _emergencyRepository.registerView(id);
      if (!mounted || _incident == null) return;
      setState(() {
        _incident = _incident!.copyWith(viewsCount: viewsCount);
      });
    } catch (_) {
      // La vista es informativa; si falla, no interrumpimos la carga del reporte.
    }
  }

  Future<void> _loadMessages(int id) async {
    try {
      final messages = await _emergencyRepository.listMessages(id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
      });
    } catch (_) {
      // Los comentarios son un complemento; si fallan, no bloqueamos el reporte.
    }
  }

  Future<void> _loadEvidence(int id) async {
    try {
      final evidences = await _emergencyRepository.listEvidence(id);
      if (!mounted) return;
      setState(() {
        _evidences
          ..clear()
          ..addAll(evidences);
      });
    } catch (_) {
      // La evidencia es un complemento; si falla, no bloqueamos el reporte.
    }
  }

  Future<void> _sendComment() async {
    final id = int.tryParse(widget.incidentId);
    final text = _commentController.text.trim();
    if (id == null || text.isEmpty) return;
    if (!await ensureAuthenticated(context, action: 'comentar en este reporte')) return;
    if (!mounted) return;

    setState(() => _isSendingComment = true);
    try {
      final sent = await _emergencyRepository.sendMessage(id, text);
      if (!mounted) return;
      setState(() {
        _messages.add(sent);
        _commentController.clear();
        _isSendingComment = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo enviar el comentario. Intenta nuevamente.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addEvidence(ImageSource source) async {
    final id = int.tryParse(widget.incidentId);
    if (id == null) return;
    if (!await ensureAuthenticated(context, action: 'agregar evidencia a este reporte')) return;
    if (!mounted) return;

    XFile? image;
    try {
      image = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('No se pudo abrir la cámara/galería.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (image == null) return;

    setState(() => _isUploadingEvidence = true);
    try {
      final evidence = await _emergencyRepository.uploadEvidence(id, File(image.path));
      if (!mounted) return;
      setState(() {
        _evidences.insert(0, evidence);
        _isUploadingEvidence = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingEvidence = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo subir la evidencia. Intenta nuevamente.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddEvidenceOptions() {
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
                    label: 'Cámara',
                    onPressed: () {
                      Navigator.pop(context);
                      _addEvidence(ImageSource.camera);
                    },
                    icon: Icons.camera_alt,
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppOutlinedButton(
                    label: 'Galería',
                    onPressed: () {
                      Navigator.pop(context);
                      _addEvidence(ImageSource.gallery);
                    },
                    icon: Icons.photo_library,
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

  String _resolveMediaUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${ApiClient.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(child: AppLoadingIndicator()),
      );
    }

    if (_hasError || _incident == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Incidente no encontrado',
            subtitle: 'No pudimos cargar este reporte. Revisa tu conexión e intenta nuevamente.',
            action: AppButton(
              label: 'Reintentar',
              isExpanded: false,
              onPressed: _loadIncident,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IncidentHeader(
                    incident: _incident!,
                    onLikeTap: _toggleLike,
                    isTogglingLike: _isTogglingLike,
                  ).staggerChild(0),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDescription().staggerChild(1),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLocationCard().staggerChild(2),
                  const SizedBox(height: AppSpacing.lg),
                  _buildEvidenceSection().staggerChild(3),
                  const SizedBox(height: AppSpacing.lg),
                  IncidentCommentsSection(
                    messages: _messages,
                    controller: _commentController,
                    isSending: _isSendingComment,
                    onSend: _sendComment,
                  ).staggerChild(4),
                  const SizedBox(height: AppSpacing.lg),
                  IncidentTimeline(incident: _incident!).staggerChild(5),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActions().staggerChild(6),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfacePrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ),
        Container(
          margin: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: _showMoreOptions,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Hero(
          tag: 'incident_${_incident!.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _incident!.statusColor.withValues(alpha: 0.4),
                  AppColors.backgroundPrimary,
                ],
              ),
            ),
            child: Stack(
              children: [
                AppBackgroundPattern(color: _incident!.statusColor),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: _incident!.statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _incident!.statusColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(_incident!.typeIcon, size: AppSpacing.iconXl, color: AppColors.textOnPrimary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(_incident!.title, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.description_outlined,
                gradient: AppColors.primaryGradient,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Descripción', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(_incident!.description, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.location_on_outlined,
                gradient: AppColors.primaryGradient,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Ubicación', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const AppIconBadge(
                icon: Icons.place_outlined,
                gradient: AppColors.primaryGradient,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_incident!.location.address, style: AppTextStyles.bodyMedium),
                    Text(_incident!.location.zone, style: AppTextStyles.bodySmallSecondary),
                    if (_incident!.location.reference.isNotEmpty)
                      Text('Ref: ${_incident!.location.reference}', style: AppTextStyles.bodySmallTertiary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  label: 'Compartir ubicación',
                  onPressed: () {},
                  icon: Icons.share_location,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Ver ruta',
                  onPressed: () {},
                  icon: Icons.directions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    if (_evidences.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  ),
                  child: Icon(Icons.photo_library_outlined, size: AppSpacing.iconLg, color: AppColors.textTertiary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sin evidencia', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Este reporte no tiene fotos adjuntas', style: AppTextStyles.bodySmallSecondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppOutlinedButton(
              label: _isUploadingEvidence ? 'Subiendo...' : 'Agregar evidencia',
              onPressed: _isUploadingEvidence ? null : _showAddEvidenceOptions,
              icon: Icons.add_a_photo_outlined,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Evidencia', style: AppTextStyles.titleMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
              ),
              child: Text(
                '${_evidences.length} archivo(s)',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _evidences.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == _evidences.length) {
                return _buildAddEvidenceCard().staggerChild(index, distance: 0.15);
              }
              final evidence = _evidences[index];
              return Hero(
                tag: 'evidence_${_incident!.id}_$index',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                  child: Container(
                    width: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderPrimary, width: 0.5),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: _resolveMediaUrl(evidence.fileUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceSecondary,
                        child: Center(
                          child: AppLoadingIndicator(color: AppColors.primaryBlue),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceSecondary,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, size: AppSpacing.iconXl, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                ),
              ).staggerChild(index, distance: 0.15);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddEvidenceCard() {
    return GestureDetector(
      onTap: _isUploadingEvidence ? null : _showAddEvidenceOptions,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: _isUploadingEvidence
              ? AppLoadingIndicator(color: AppColors.primaryBlue)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue, size: AppSpacing.iconLg),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Agregar', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlue)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return AppButton(
      label: 'Ver ruta',
      onPressed: _viewRoute,
      icon: Icons.navigation,
    );
  }

  Future<void> _toggleLike() async {
    final id = int.tryParse(widget.incidentId);
    if (id == null || _incident == null) return;
    if (!await ensureAuthenticated(context, action: 'confirmar este aviso')) return;
    if (!mounted) return;

    setState(() => _isTogglingLike = true);
    try {
      final result = await _emergencyRepository.toggleLike(id);
      if (!mounted) return;
      setState(() {
        _incident = _incident!.copyWith(
          isLikedByMe: result.liked,
          confirmationsCount: result.likesCount,
        );
        _isTogglingLike = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.liked ? 'Gracias por confirmar el aviso' : 'Confirmación retirada'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.liked ? AppColors.resolvedGreen : AppColors.textTertiary,
        ),
      );
    } catch (e) {
      debugPrint('toggleLike failed for emergency $id: $e');
      if (!mounted) return;
      setState(() => _isTogglingLike = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la confirmación: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _viewRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo navegación...'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(incident: _incident!),
    );
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final Incident incident;

  const _MoreOptionsSheet({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              ),
              child: Icon(Icons.flag_outlined, color: AppColors.error, size: AppSpacing.iconMd),
            ),
            title: Text('Reportar falso', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
            subtitle: Text('Marcar como reporte falso o spam', style: AppTextStyles.bodySmallSecondary),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reporte enviado'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              ),
              child: Icon(Icons.share_outlined, color: AppColors.primaryBlue, size: AppSpacing.iconMd),
            ),
            title: Text('Compartir', style: AppTextStyles.bodyLarge),
            subtitle: Text('Enviar a contactos o redes sociales', style: AppTextStyles.bodySmallSecondary),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              ),
              child: Icon(Icons.bookmark_outline, color: AppColors.textTertiary, size: AppSpacing.iconMd),
            ),
            title: Text('Guardar', style: AppTextStyles.bodyLarge),
            subtitle: Text('Agregar a tus incidentes guardados', style: AppTextStyles.bodySmallSecondary),
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}