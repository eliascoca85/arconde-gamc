import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app/app.dart';
import 'app/theme/app_colors.dart';
import 'app/theme/app_text_styles.dart';
import 'app/theme/app_spacing.dart';
import 'app/theme/app_theme.dart';
import 'core/extensions/widget_extensions.dart';
import 'core/network/auth_service.dart';
import 'shared/widgets/basic_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArconteApp());
}

class ArconteApp extends StatefulWidget {
  const ArconteApp({super.key});

  @override
  State<ArconteApp> createState() => _ArconteAppState();
}

class _ArconteAppState extends State<ArconteApp> {
  bool _showSplash = true;
  bool _skippedAuth = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      AuthService.restoreSession(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);
    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  void _onSkip() {
    setState(() => _skippedAuth = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return _preRouterShell(const _SplashScreen());
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.isLoggedIn,
      builder: (context, loggedIn, _) {
        if (loggedIn || _skippedAuth) {
          return const App();
        }
        return _preRouterShell(_LoginScreen(onComplete: _onSkip));
      },
    );
  }

  Widget _preRouterShell(Widget child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: child,
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/LOGO_GAMC.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Arconte', style: AppTextStyles.displaySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tu comunidad, tu seguridad',
                      style: AppTextStyles.bodyLargeSecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _LoginMethod { email, phone }

enum _AuthStage { choice, login, register }

class _LoginScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const _LoginScreen({required this.onComplete});

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  _AuthStage _stage = _AuthStage.choice;
  _LoginMethod _method = _LoginMethod.phone;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _skip() => widget.onComplete();

  Future<void> _submit() async {
    if (_method == _LoginMethod.email) {
      setState(() {
        _errorMessage = 'Por ahora el ingreso con correo no está disponible. Usa tu número de celular.';
      });
      return;
    }

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Completa tu número de celular y tu contraseña.');
      return;
    }

    final isLogin = _stage == _AuthStage.login;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (!isLogin && (firstName.isEmpty || lastName.isEmpty)) {
      setState(() => _errorMessage = 'Completa tu nombre y apellido.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (isLogin) {
        await AuthService.login(phone, password);
      } else {
        await AuthService.register(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phone,
          password: password,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSubmitting = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo conectar. Revisa tu conexión e intenta nuevamente.';
        _isSubmitting = false;
      });
      return;
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  _stage == _AuthStage.choice ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
              children: [
                if (_stage != _AuthStage.choice)
                  AppIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => setState(() {
                      _stage = _AuthStage.choice;
                      _errorMessage = null;
                    }),
                  ).paddingAll(AppSpacing.xs),
                TextButton(
                  onPressed: _skip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    ),
                    textStyle: AppTextStyles.titleMedium,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Saltar', style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent)),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.arrow_forward, size: AppSpacing.iconMd, color: AppColors.accent),
                    ],
                  ),
                ).paddingAll(AppSpacing.sm),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: KeyedSubtree(
                          key: ValueKey(_stage),
                          child: _stage == _AuthStage.choice ? _buildChoice() : _buildForm(),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoice() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Image.asset(
          'assets/icons/LOGO_GAMC.png',
          width: 112,
          height: 112,
          fit: BoxFit.contain,
        ).animate().fadeIn(duration: 400.ms).scale(),
        const SizedBox(height: AppSpacing.lg),
        Text('Bienvenido a Arconte', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Inicia sesión o crea una cuenta para reportar y seguir incidentes de tu zona',
          style: AppTextStyles.bodyLargeSecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Iniciar sesión',
                onPressed: () => setState(() {
                  _stage = _AuthStage.login;
                  _errorMessage = null;
                }),
                icon: Icons.login,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppOutlinedButton(
                label: 'Crear cuenta',
                onPressed: () => setState(() {
                  _stage = _AuthStage.register;
                  _errorMessage = null;
                }),
                icon: Icons.person_add_alt_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildForm() {
    final isLogin = _stage == _AuthStage.login;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          isLogin ? 'Inicia sesión' : 'Crea tu cuenta',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isLogin
              ? 'Ingresa con tu correo o celular para continuar'
              : 'Regístrate con tu correo o celular para empezar',
          style: AppTextStyles.bodyLargeSecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildMethodToggle(),
        const SizedBox(height: AppSpacing.lg),
        if (_method == _LoginMethod.email) _buildEmailUnavailableNotice() else _buildPhoneForm(isLogin: isLogin),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: isLogin ? 'Iniciar sesión' : 'Crear cuenta',
          onPressed: _method == _LoginMethod.email ? null : _submit,
          isLoading: _isSubmitting,
          icon: Icons.login,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildMethodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
      child: Row(
        children: [
          Expanded(child: _buildMethodTab('Correo electrónico', Icons.email_outlined, _LoginMethod.email)),
          Expanded(child: _buildMethodTab('Celular', Icons.phone_android_outlined, _LoginMethod.phone)),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String label, IconData icon, _LoginMethod method) {
    final isSelected = _method == method;
    return GestureDetector(
      onTap: () => setState(() {
        _method = method;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSpacing.iconSm, color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailUnavailableNotice() {
    return AppCard(
      color: AppColors.surfaceSecondary,
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondary, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'El ingreso con correo estará disponible próximamente. Usa tu número de celular.',
              style: AppTextStyles.bodyMediumSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm({required bool isLogin}) {
    return Column(
      children: [
        if (!isLogin) ...[
          AppInput(
            label: 'Nombre',
            controller: _firstNameController,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppInput(
            label: 'Apellido',
            controller: _lastNameController,
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppInput(
          label: 'Número de celular',
          hint: '70000000',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_outlined,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppInput(
          label: 'Contraseña',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}