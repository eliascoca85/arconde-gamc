import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/index.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/basic_widgets.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _faqs = [
    (
      question: '¿Cómo creo un reporte?',
      answer: 'Toca el botón "Reportar" en el mapa. Puedes narrar lo que ocurre por voz o llenar el formulario manualmente, adjuntando fotos como evidencia si lo necesitas.',
    ),
    (
      question: '¿Cómo veo el estado de mis reportes?',
      answer: 'Ve a "Mis reportes" desde la barra inferior. Ahí puedes filtrar entre reportes en revisión y atendidos.',
    ),
    (
      question: '¿Por qué no me llegan notificaciones?',
      answer: 'Revisa que hayas iniciado sesión y que las notificaciones estén activadas en Perfil → Configuración.',
    ),
    (
      question: '¿Puedo reportar de forma anónima?',
      answer: 'Necesitas una cuenta para crear reportes, pero tus datos solo se comparten con las autoridades a cargo de atenderlos — ver Perfil → Privacidad.',
    ),
    (
      question: '¿Qué hago si es una emergencia real y necesito ayuda inmediata?',
      answer: 'Arconte no reemplaza a la línea de emergencias. Si tu vida o la de alguien más está en riesgo, llama primero al 110 (Policía) o al 119 (Bomberos).',
    ),
  ];

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    context.showSuccessSnackBar('$label copiado.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text('Ayuda y soporte', style: AppTextStyles.titleLarge),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Preguntas frecuentes', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.borderPrimary, width: 0.5),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: _faqs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final faq = entry.value;
                  return ExpansionTile(
                    title: Text(faq.question, style: AppTextStyles.bodyLarge),
                    iconColor: AppColors.secondaryTeal,
                    collapsedIconColor: AppColors.textTertiary,
                    shape: Border(
                      bottom: index == _faqs.length - 1
                          ? BorderSide.none
                          : BorderSide(color: AppColors.divider, width: 0.5),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(faq.answer, style: AppTextStyles.bodyMediumSecondary),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Contáctanos', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.borderPrimary, width: 0.5),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: AppIconBadge(icon: Icons.mail_outline, gradient: AppColors.primaryGradient, size: 40, iconSize: AppSpacing.iconMd),
                  title: Text('soporte@arconte.app', style: AppTextStyles.bodyLarge),
                  subtitle: Text('Toca para copiar', style: AppTextStyles.bodySmallSecondary),
                  trailing: Icon(Icons.copy_outlined, color: AppColors.textTertiary),
                  onTap: () => _copy(context, 'Correo', 'soporte@arconte.app'),
                  shape: Border.all(color: Colors.transparent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
