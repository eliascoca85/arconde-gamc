import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografía minimalista – rojo & blanco.
///
/// Familias:
///   • Títulos/Headlines → Nunito   (single-story, geométrica, muy legible)
///   • Labels/UI         → Nunito   (misma, coherencia visual)
///   • Cuerpo            → Nunito   (misma, coherencia visual)
///
/// Se mantienen LibreBaskerville, LindenHill y Ovo en el proyecto pero
/// Nunito es ahora la fuente dominante para el esquema minimalista.
class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.12,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.16,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.20,
        color: AppColors.textPrimary,
      );

  // ── Headline ──────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.24,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.28,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.32,
        color: AppColors.textPrimary,
      );

  // ── Title ─────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.28,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.50,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textPrimary,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.40,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.33,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.45,
        color: AppColors.textPrimary,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.55,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.50,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.40,
        color: AppColors.textPrimary,
      );

  // ── On-Primary variants ───────────────────────────────────────────────────
  static TextStyle get displayLargeOnPrimary  => displayLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get displayMediumOnPrimary => displayMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get displaySmallOnPrimary  => displaySmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get headlineLargeOnPrimary  => headlineLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get headlineMediumOnPrimary => headlineMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get headlineSmallOnPrimary  => headlineSmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get titleLargeOnPrimary  => titleLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get titleMediumOnPrimary => titleMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get titleSmallOnPrimary  => titleSmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get labelLargeOnPrimary  => labelLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get labelMediumOnPrimary => labelMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get labelSmallOnPrimary  => labelSmall.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get bodyLargeOnPrimary  => bodyLarge.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get bodyMediumOnPrimary => bodyMedium.copyWith(color: AppColors.textOnPrimary);
  static TextStyle get bodySmallOnPrimary  => bodySmall.copyWith(color: AppColors.textOnPrimary);

  // ── Secondary (gris medio) ────────────────────────────────────────────────
  static TextStyle get displayLargeSecondary  => displayLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get displayMediumSecondary => displayMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get displaySmallSecondary  => displaySmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get headlineLargeSecondary  => headlineLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get headlineMediumSecondary => headlineMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get headlineSmallSecondary  => headlineSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get titleLargeSecondary  => titleLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get titleMediumSecondary => titleMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get titleSmallSecondary  => titleSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get labelLargeSecondary  => labelLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get labelMediumSecondary => labelMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get labelSmallSecondary  => labelSmall.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodyLargeSecondary  => bodyLarge.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodyMediumSecondary => bodyMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get bodySmallSecondary  => bodySmall.copyWith(color: AppColors.textSecondary);

  // ── Tertiary (gris claro) ─────────────────────────────────────────────────
  static TextStyle get displayLargeTertiary  => displayLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get displayMediumTertiary => displayMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get displaySmallTertiary  => displaySmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get headlineLargeTertiary  => headlineLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get headlineMediumTertiary => headlineMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get headlineSmallTertiary  => headlineSmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get titleLargeTertiary  => titleLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get titleMediumTertiary => titleMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get titleSmallTertiary  => titleSmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get labelLargeTertiary  => labelLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get labelMediumTertiary => labelMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get labelSmallTertiary  => labelSmall.copyWith(color: AppColors.textTertiary);
  static TextStyle get bodyLargeTertiary  => bodyLarge.copyWith(color: AppColors.textTertiary);
  static TextStyle get bodyMediumTertiary => bodyMedium.copyWith(color: AppColors.textTertiary);
  static TextStyle get bodySmallTertiary  => bodySmall.copyWith(color: AppColors.textTertiary);
}
