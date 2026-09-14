import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/network/nominatim_service.dart';

enum _SearchStatus { idle, loading, results, empty, error }

/// Professional geographic search bar for the map: looks up zones, streets
/// and addresses via [NominatimService], and — once a zone is selected —
/// shows it as an active filter chip with a result count and a clear
/// action. The suggestions dropdown is rendered through the app's
/// [Overlay] (via [CompositedTransformFollower]) so it always paints above
/// everything else on screen, including floating map controls.
class MapZoneSearchField extends StatefulWidget {
  final GeoSearchResult? selectedZone;
  final int? filteredCount;
  final ValueChanged<GeoSearchResult> onZoneSelected;
  final VoidCallback onZoneCleared;
  final VoidCallback? onFilterPressed;

  const MapZoneSearchField({
    super.key,
    required this.onZoneSelected,
    required this.onZoneCleared,
    this.selectedZone,
    this.filteredCount,
    this.onFilterPressed,
  });

  @override
  State<MapZoneSearchField> createState() => _MapZoneSearchFieldState();
}

class _MapZoneSearchFieldState extends State<MapZoneSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  Timer? _debounce;
  int _searchGeneration = 0;
  OverlayEntry? _overlayEntry;

  _SearchStatus _status = _SearchStatus.idle;
  List<GeoSearchResult> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _overlayEntry?.remove();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _status = _SearchStatus.idle;
        _results = const [];
      });
      _syncOverlay();
      return;
    }

    setState(() => _status = _SearchStatus.loading);
    _syncOverlay();
    _debounce = Timer(const Duration(milliseconds: 450), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final generation = ++_searchGeneration;
    try {
      final results = await NominatimService.search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results;
        _status = results.isEmpty ? _SearchStatus.empty : _SearchStatus.results;
      });
      _syncOverlay();
    } on NominatimException {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = const [];
        _status = _SearchStatus.error;
      });
      _syncOverlay();
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = const [];
        _status = _SearchStatus.error;
      });
      _syncOverlay();
    }
  }

  void _selectResult(GeoSearchResult result) {
    _debounce?.cancel();
    _searchGeneration++;
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _status = _SearchStatus.idle;
      _results = const [];
    });
    _syncOverlay();
    widget.onZoneSelected(result);
  }

  void _clearZone() {
    widget.onZoneCleared();
  }

  /// Clears both the typed text and any pending/shown suggestions —
  /// unlike a plain query reset, this is a full "start over" action.
  void _clearQuery() {
    _debounce?.cancel();
    _searchGeneration++;
    _controller.clear();
    setState(() {
      _status = _SearchStatus.idle;
      _results = const [];
    });
    _syncOverlay();
  }

  void _editZone() {
    widget.onZoneCleared();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedZone != null) {
      return _buildActiveZoneChip(widget.selectedZone!);
    }

    // The dropdown is shown via an OverlayEntry (see _syncOverlay) instead
    // of being laid out inline below the field, so it always paints above
    // the rest of the screen — including the floating map buttons — no
    // matter where this widget sits in the page's own Stack.
    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(key: _fieldKey, child: _buildSearchInput()),
    );
  }

  void _syncOverlay() {
    if (!mounted) return;
    final shouldShow = _status != _SearchStatus.idle;
    if (shouldShow) {
      if (_overlayEntry == null) {
        _overlayEntry = _buildOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        _overlayEntry!.markNeedsBuild();
      }
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? MediaQuery.sizeOf(context).width;
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            child: Material(
              type: MaterialType.transparency,
              child: _buildDropdown(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onQueryChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Buscar zona o dirección',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
          prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: AppSpacing.iconMd),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_status == _SearchStatus.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryTeal),
                    ),
                  ),
                )
              else if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textTertiary, size: AppSpacing.iconSm),
                  onPressed: _clearQuery,
                ),
              IconButton(
                icon: Icon(Icons.tune, color: AppColors.textTertiary, size: AppSpacing.iconMd),
                onPressed: widget.onFilterPressed,
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildDropdownContent(),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildDropdownContent() {
    switch (_status) {
      case _SearchStatus.results:
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: _results.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) => _buildResultTile(_results[index]),
        );
      case _SearchStatus.empty:
        return _buildDropdownMessage(Icons.search_off, 'No encontramos esa zona.');
      case _SearchStatus.error:
        return _buildDropdownMessage(Icons.wifi_off, 'No se pudo realizar la búsqueda. Intenta nuevamente.');
      case _SearchStatus.loading:
      case _SearchStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDropdownMessage(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconMd, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyMediumSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(GeoSearchResult result) {
    final icon = switch (result.kind) {
      GeoResultKind.area => Icons.location_city,
      GeoResultKind.street => Icons.route,
      GeoResultKind.place => Icons.place_outlined,
    };

    return InkWell(
      onTap: () => _selectResult(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSpacing.iconMd, color: AppColors.secondaryTeal),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.primaryLabel,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.secondaryLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.secondaryLabel,
                      style: AppTextStyles.bodySmallSecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveZoneChip(GeoSearchResult zone) {
    // Only an area result actually filters incidents — showing a count for
    // a street/place selection would imply filtering that never happened.
    final count = zone.kind == GeoResultKind.area ? widget.filteredCount : null;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.secondaryTeal, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: AppSpacing.elevationMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _editZone,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: Row(
          children: [
            Icon(Icons.place, color: AppColors.secondaryTeal, size: AppSpacing.iconMd),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zone.primaryLabel,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count != null)
                    Text(
                      '$count ${count == 1 ? 'reporte encontrado' : 'reportes encontrados'}',
                      style: AppTextStyles.bodySmallSecondary,
                    ),
                ],
              ),
            ),
            InkWell(
              onTap: _clearZone,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(Icons.close, color: AppColors.textTertiary, size: AppSpacing.iconSm),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }
}
