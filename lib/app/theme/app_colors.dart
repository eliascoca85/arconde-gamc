import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background          = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFFFF9D6);
  static const Color backgroundTertiary  = Color(0xFFFFF0A8);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surfacePrimary   = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFFFF9E6);
  static const Color surfaceTertiary  = Color(0xFFFFF0B3);
  static const Color surfaceElevated  = Color(0xFFFFFFFF);

  // ── Primary – Rojo principal ──────────────────────────────────────────────
  static const Color primary              = Color(0xFFD32F2F); // Rojo sólido
  static const Color primaryLight         = Color(0xFFEF5350); // Rojo claro
  static const Color primaryDark          = Color(0xFFB71C1C); // Rojo oscuro
  static const Color primaryContainer     = Color(0xFFFFEBEE); // Fondo rojo muy suave
  static const Color primaryContainerDark = Color(0xFFFFCDD2); // Fondo rojo suave

  // ── Secondary – Amarillo de apoyo ─────────────────────────────────────────
  static const Color secondary              = Color(0xFFF4C400);
  static const Color secondaryLight         = Color(0xFFFFD84D);
  static const Color secondaryDark          = Color(0xFF9A7900);
  static const Color secondaryContainer     = Color(0xFFFFF4BF);
  static const Color secondaryContainerDark = Color(0xFFFFE98A);

  // ── Accent – Rojo más suave ───────────────────────────────────────────────
  static const Color accent              = Color(0xFFC62828);
  static const Color accentLight         = Color(0xFFE57373);
  static const Color accentDark          = Color(0xFF7F0000);
  static const Color accentContainer     = Color(0xFFFFEBEE);

  // ── Accent Soft (usado en gradients) ─────────────────────────────────────
  static const Color accentSoft              = Color(0xFFEF9A9A);
  static const Color accentSoftLight         = Color(0xFFFFCDD2);
  static const Color accentSoftDark          = Color(0xFFE57373);
  static const Color accentSoftContainer     = Color(0xFFFFF3F3);
  static const Color accentSoftContainerDark = Color(0xFFFFEBEE);

  // ── Textos ────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A); // Negro muy suave
  static const Color textSecondary = Color(0xFF3D3200); // Amarillo oscuro legible
  static const Color textTertiary  = Color(0xFF806600); // Amarillo apagado
  static const Color textDisabled  = Color(0xFFC7A900);
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Blanco sobre rojo
  static const Color textOnSurface = Color(0xFF1A1A1A);
  static const Color textOnAccent  = Color(0xFFFFFFFF);

  // ── Bordes ────────────────────────────────────────────────────────────────
  static const Color borderPrimary   = Color(0xFFF0D24A);
  static const Color borderSecondary = Color(0xFFD9B400);
  static const Color borderFocus     = Color(0xFFD32F2F);

  // ── Sombras y overlays ────────────────────────────────────────────────────
  static const Color shadowColor   = Color(0x14000000);
  static const Color overlayColor  = Color(0xB3000000);

  // ── Estados semánticos ────────────────────────────────────────────────────
  static const Color urgentRed              = Color(0xFFD32F2F);
  static const Color urgentRedLight         = Color(0xFFEF5350);
  static const Color urgentRedDark          = Color(0xFFB71C1C);
  static const Color urgentRedContainer     = Color(0xFFFFEBEE);

  static const Color moderateOrange          = Color(0xFFF57C00);
  static const Color moderateOrangeLight     = Color(0xFFFFB74D);
  static const Color moderateOrangeDark      = Color(0xFFE65100);
  static const Color moderateOrangeContainer = Color(0xFFFFF3E0);

  static const Color resolvedGreen          = Color(0xFF388E3C);
  static const Color resolvedGreenLight     = Color(0xFF66BB6A);
  static const Color resolvedGreenDark      = Color(0xFF1B5E20);
  static const Color resolvedGreenContainer = Color(0xFFE8F5E9);

  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color error   = Color(0xFFD32F2F);
  static const Color info    = Color(0xFF1565C0);

  static const Color divider = Color(0xFFF0D24A);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientReverse = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentSoftGradient = LinearGradient(
    colors: [accentSoft, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient urgentGradient = LinearGradient(
    colors: [urgentRed, urgentRedLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient moderateGradient = LinearGradient(
    colors: [moderateOrange, moderateOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient resolvedGradient = LinearGradient(
    colors: [resolvedGreen, resolvedGreenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surfacePrimary, surfaceSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Backward compatibility aliases ────────────────────────────────────────
  static const Color primaryBlue              = primary;
  static const Color primaryBlueLight         = primaryLight;
  static const Color primaryBlueDark          = primaryDark;
  static const Color primaryBlueContainer     = primaryContainer;
  static const Color secondaryTeal            = secondary;
  static const Color secondaryTealLight       = secondaryLight;
  static const Color secondaryTealDark        = secondaryDark;
  static const Color secondaryTealContainer   = secondaryContainer;
  static const Color accentLightAlias         = accentSoftContainer;
  static const Color backgroundPrimary        = background;
}