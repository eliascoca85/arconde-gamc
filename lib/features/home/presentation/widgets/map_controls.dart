import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/index.dart';

/// Single circular floating control button used over the map (zoom,
/// expand, locate-me). Kept generic so new map actions can reuse it
/// without duplicating the container/shadow styling. When [gradient] is
/// given, the button renders filled with it (icon turns white for
/// contrast); otherwise it falls back to the plain surface style.
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isLoading;
  final Gradient? gradient;

  const MapControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isLoading = false,
    this.gradient,
  });

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final iconColor = gradient != null ? AppColors.textOnPrimary : AppColors.textPrimary;

    final button = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? AppColors.surfacePrimary : null,
        shape: BoxShape.circle,
        border: gradient == null ? Border.all(color: AppColors.borderPrimary, width: 0.5) : null,
        boxShadow: [
          BoxShadow(
            color: gradient != null ? AppColors.shadowColor.withValues(alpha: 0.35) : AppColors.shadowColor,
            blurRadius: gradient != null ? AppSpacing.elevationMd : AppSpacing.elevationSm,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, size: AppSpacing.iconMd, color: iconColor),
          ),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

/// Zoom in/out pair, anchored to the top-right of the map.
class MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapControlButton(
          icon: Icons.add,
          tooltip: 'Acercar',
          onPressed: onZoomIn,
          gradient: AppColors.primaryGradient,
        ),
        const SizedBox(height: AppSpacing.sm),
        MapControlButton(
          icon: Icons.remove,
          tooltip: 'Alejar',
          onPressed: onZoomOut,
          gradient: AppColors.primaryGradient,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }
}

/// Expand-to-fullscreen and locate-me pair, anchored to the bottom-right of
/// the map (above the "Reportar" FAB, never over it).
class MapActionControls extends StatelessWidget {
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final VoidCallback onLocateMe;
  final bool isLocating;

  const MapActionControls({
    super.key,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    required this.onLocateMe,
    required this.isLocating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapControlButton(
          icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          tooltip: isFullscreen ? 'Restaurar vista' : 'Expandir mapa',
          onPressed: onToggleFullscreen,
          gradient: AppColors.accentGradient,
        ),
        const SizedBox(height: AppSpacing.sm),
        MapControlButton(
          icon: Icons.my_location,
          tooltip: 'Mi ubicación',
          onPressed: onLocateMe,
          isLoading: isLocating,
          gradient: AppColors.secondaryGradient,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }
}
