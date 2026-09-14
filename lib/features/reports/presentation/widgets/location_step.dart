import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../app/theme/index.dart';
import '../../../../../core/animations/motion.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../mock/models.dart';
import '../../../../../shared/widgets/basic_widgets.dart';
import '../../../../../shared/widgets/app_map.dart';

class LocationStep extends StatefulWidget {
  final Location? selectedLocation;
  final Function(Location) onLocationSelected;
  final Location userLocation;

  const LocationStep({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
    required this.userLocation,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  LatLng? _selectedPosition;
  bool _useCurrentLocation = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedLocation != null) {
      _selectedPosition = LatLng(widget.selectedLocation!.latitude, widget.selectedLocation!.longitude);
      _useCurrentLocation = true;
    } else {
      _selectedPosition = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Dónde ocurrió?', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Selecciona la ubicación exacta en el mapa',
            style: AppTextStyles.bodyMediumSecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildMapPicker().staggerChild(0),
          const SizedBox(height: AppSpacing.lg),
          _buildLocationCard().staggerChild(1),
          const SizedBox(height: AppSpacing.md),
          _buildUseLocationButton().staggerChild(2),
        ],
      ),
    );
  }

  Widget _buildMapPicker() {
    return Container(
      height: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
      child: AppMapPicker(
        initialPosition: _selectedPosition!,
        onLocationSelected: _onMapLocationSelected,
        userLocation: LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
      ),
    );
  }

  void _onMapLocationSelected(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _useCurrentLocation = false;
    });

    widget.onLocationSelected(Location(
      latitude: position.latitude,
      longitude: position.longitude,
      address: _getApproximateAddress(position),
      zone: _getApproximateZone(position),
    ));
  }

  Widget _buildLocationCard() {
    final location = widget.selectedLocation ?? widget.userLocation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary, width: 0.5),
      ),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ubicación seleccionada', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary)),
                    Text(location.address, style: AppTextStyles.bodyMedium),
                    Text(location.zone, style: AppTextStyles.bodySmallSecondary),
                  ],
                ),
              ),
            ],
          ),
          if (location.reference.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.info_outline, size: AppSpacing.iconXs, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Text('Ref: ${location.reference}', style: AppTextStyles.bodySmallTertiary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUseLocationButton() {
    return AppButton(
      label: _useCurrentLocation ? 'Usar mi ubicación actual' : 'Detectar mi ubicación',
      onPressed: _onUseCurrentLocation,
      icon: _useCurrentLocation ? Icons.check_circle : Icons.my_location,
      backgroundColor: _useCurrentLocation ? AppColors.resolvedGreen : AppColors.secondaryTeal,
      isLoading: _isLocating,
    );
  }

  Future<void> _onUseCurrentLocation() async {
    setState(() => _isLocating = true);
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (position == null) {
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación. Revisa los permisos de ubicación.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final location = Location(
      latitude: position.latitude,
      longitude: position.longitude,
      address: _getApproximateAddress(LatLng(position.latitude, position.longitude)),
      zone: 'Ubicación actual',
    );

    setState(() {
      _isLocating = false;
      _useCurrentLocation = true;
      _selectedPosition = LatLng(position.latitude, position.longitude);
    });
    widget.onLocationSelected(location);
  }

  String _getApproximateAddress(LatLng position) {
    return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
  }

  String _getApproximateZone(LatLng position) {
    return 'Zona detectada automáticamente';
  }
}