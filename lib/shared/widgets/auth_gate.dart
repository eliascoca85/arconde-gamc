import 'package:flutter/material.dart';
import '../../app/theme/index.dart';
import '../../core/network/auth_service.dart';
import 'basic_widgets.dart';

/// Gate for actions that require an account (reporting an emergency, in
/// particular — viewing the map stays open to everyone). Returns `true` if
/// the user is already logged in; otherwise shows an explanatory dialog and
/// sends them back to the login/register screen, returning `false` so the
/// caller can bail out of whatever it was about to do.
Future<bool> ensureAuthenticated(BuildContext context, {String action = 'reportar una emergencia'}) async {
  if (AuthService.isLoggedIn.value) return true;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg)),
      title: Text('Necesitas una cuenta', style: AppTextStyles.headlineSmall),
      content: Text(
        'Para $action tenés que iniciar sesión o registrarte. Ver el mapa de incidentes no requiere cuenta.',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: AppTextStyles.labelMedium),
        ),
        AppButton(
          label: 'Iniciar sesión',
          isExpanded: false,
          onPressed: () {
            Navigator.pop(context);
            AuthService.requestLogin();
          },
        ),
      ],
    ),
  );

  return false;
}
