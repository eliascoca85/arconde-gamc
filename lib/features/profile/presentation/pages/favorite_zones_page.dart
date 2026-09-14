import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/animations/motion.dart';
import '../../../../core/network/nominatim_service.dart';
import '../../../../core/services/settings_events.dart';
import '../../../../core/services/settings_store.dart';
import '../../../../shared/widgets/basic_widgets.dart';

/// Zonas reales (buscadas por dirección/barrio vía [NominatimService], la
/// misma fuente que el buscador del mapa en Inicio) que el ciudadano guarda
/// como favoritas — solo en este dispositivo. Se muestran como accesos
/// rápidos sobre el buscador de Inicio: al tocar una, se aplica como filtro
/// real de incidentes (mismo mecanismo que buscarla a mano), no es una
/// lista decorativa desconectada del resto de la app.
class FavoriteZonesPage extends StatefulWidget {
  const FavoriteZonesPage({super.key});

  @override
  State<FavoriteZonesPage> createState() => _FavoriteZonesPageState();
}

class _FavoriteZonesPageState extends State<FavoriteZonesPage> {
  List<FavoriteZone>? _favorites;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  int _searchGeneration = 0;
  bool _searching = false;
  String? _searchError;
  List<GeoSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    SettingsStore.loadFavoriteZones().then((zones) {
      if (!mounted) return;
      setState(() => _favorites = zones);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final generation = ++_searchGeneration;
    try {
      final results = await NominatimService.search(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results;
        _searching = false;
        _searchError = null;
      });
    } on NominatimException catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = e.message;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = 'No se pudo realizar la búsqueda. Intenta nuevamente.';
      });
    }
  }

  bool _isSaved(GeoSearchResult result) =>
      (_favorites ?? const []).any((f) => f.osmType == result.osmType && f.osmId == result.osmId);

  Future<void> _addFavorite(GeoSearchResult result) async {
    final favorites = _favorites;
    if (favorites == null || _isSaved(result)) return;
    final zone = FavoriteZone(
      osmType: result.osmType,
      osmId: result.osmId,
      primaryLabel: result.primaryLabel,
      secondaryLabel: result.secondaryLabel,
      lat: result.center.latitude,
      lon: result.center.longitude,
    );
    setState(() => favorites.add(zone));
    await SettingsStore.setFavoriteZones(favorites);
    SettingsEvents.notifyFavoriteZonesChanged();
    _debounce?.cancel();
    _searchGeneration++;
    _controller.clear();
    _focusNode.unfocus();
    if (!mounted) return;
    setState(() {
      _results = const [];
      _searching = false;
    });
  }

  Future<void> _removeFavorite(FavoriteZone zone) async {
    final favorites = _favorites;
    if (favorites == null) return;
    setState(() => favorites.removeWhere((f) => f.key == zone.key));
    await SettingsStore.setFavoriteZones(favorites);
    SettingsEvents.notifyFavoriteZonesChanged();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favorites;
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Zonas favoritas', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: favorites == null
          ? const Center(child: AppLoadingIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Busca tu barrio o una zona y guárdala para tenerla como acceso rápido en el buscador de Inicio.',
                  style: AppTextStyles.bodyMediumSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSearchField(),
                if (_searching || _results.isNotEmpty || _searchError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildSearchStatus(),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('Tus zonas favoritas', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),
                if (favorites.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(
                      'Aún no tienes zonas favoritas. Búscalas arriba y toca "Guardar".',
                      style: AppTextStyles.bodySmallTertiary,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary,
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                      border: Border.all(color: AppColors.borderPrimary, width: 0.5),
                    ),
                    child: Column(
                      children: favorites.asMap().entries.map((entry) {
                        final index = entry.key;
                        final zone = entry.value;
                        return ListTile(
                          leading: AppIconBadge(
                            icon: Icons.place_outlined,
                            gradient: AppColors.primaryGradient,
                            size: 40,
                            iconSize: AppSpacing.iconMd,
                          ),
                          title: Text(zone.primaryLabel, style: AppTextStyles.bodyLarge),
                          subtitle: zone.secondaryLabel.isNotEmpty
                              ? Text(zone.secondaryLabel, style: AppTextStyles.bodySmallSecondary, maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: AppColors.textTertiary),
                            onPressed: () => _removeFavorite(zone),
                          ),
                          shape: Border(
                            bottom: index == favorites.length - 1
                                ? BorderSide.none
                                : BorderSide(color: AppColors.divider, width: 0.5),
                          ),
                        ).staggerChild(index, step: const Duration(milliseconds: 40));
                      }).toList(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
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
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: AppColors.textTertiary, size: AppSpacing.iconSm),
                  onPressed: () {
                    _debounce?.cancel();
                    _searchGeneration++;
                    _controller.clear();
                    setState(() {
                      _results = const [];
                      _searching = false;
                      _searchError = null;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),
      ),
    );
  }

  Widget _buildSearchStatus() {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: AppLoadingIndicator(size: 24)),
      );
    }
    if (_searchError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(_searchError!, style: AppTextStyles.bodySmallSecondary),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: Column(
        children: _results.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          final saved = _isSaved(result);
          final icon = switch (result.kind) {
            GeoResultKind.area => Icons.location_city,
            GeoResultKind.street => Icons.route,
            GeoResultKind.place => Icons.place_outlined,
          };
          return ListTile(
            leading: Icon(icon, color: AppColors.secondaryTeal, size: AppSpacing.iconMd),
            title: Text(result.primaryLabel, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: result.secondaryLabel.isNotEmpty
                ? Text(result.secondaryLabel, style: AppTextStyles.bodySmallSecondary, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: saved
                ? Icon(Icons.check_circle, color: AppColors.resolvedGreen, size: AppSpacing.iconMd)
                : TextButton(
                    onPressed: () => _addFavorite(result),
                    child: Text('Guardar', style: AppTextStyles.labelMedium),
                  ),
            shape: Border(
              bottom: index == _results.length - 1 ? BorderSide.none : BorderSide(color: AppColors.divider, width: 0.5),
            ),
          );
        }).toList(),
      ),
    );
  }
}
