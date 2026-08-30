import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../data/repositories/emergency_repository.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';
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
  Incident? _incident;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadIncident();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
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
                  IncidentHeader(incident: _incident!).staggerChild(0),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDescription().staggerChild(1),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLocationCard().staggerChild(2),
                  const SizedBox(height: AppSpacing.lg),
                  _buildEvidenceSection().staggerChild(3),
                  const SizedBox(height: AppSpacing.lg),
                  IncidentTimeline(incident: _incident!).staggerChild(4),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActions().staggerChild(5),
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
    if (_incident!.evidenceUrls.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
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
                  Text('Este reporte no tiene fotos o videos adjuntos', style: AppTextStyles.bodySmallSecondary),
                ],
              ),
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
                '${_incident!.evidenceUrls.length} archivo(s)',
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
            itemCount: _incident!.evidenceUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
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
                      imageUrl: _incident!.evidenceUrls[index],
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

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            label: 'Confirmar aviso',
            onPressed: _confirmAlert,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            label: 'Ver ruta',
            onPressed: _viewRoute,
            icon: Icons.navigation,
          ),
        ),
      ],
    );
  }

  void _confirmAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gracias por confirmar el aviso'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.resolvedGreen,
      ),
    );
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