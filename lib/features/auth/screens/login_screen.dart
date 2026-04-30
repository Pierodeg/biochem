import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginProvider.notifier).clearError();
    try {
      await ref.read(loginProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMid1,
            AppColors.gradientMid2,
            AppColors.gradientEnd,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Luce verde in alto a destra
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF00A843).withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Luce blu in basso a sinistra
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF1565C0).withValues(alpha: 0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Contenuto
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCard(loginState),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card glass con form ───────────────────────────────────────────────────

  Widget _buildCard(LoginState loginState) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo dentro la card
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 0.5,
              color: AppColors.glassBorder,
            ),
            const SizedBox(height: 20),
            // Campo email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(color: AppColors.textOnDark),
              decoration: _inputDec(
                label: 'Email aziendale',
                hint: 'nome@azienda.it',
                icon: Icons.email_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci la tua email';
                }
                final emailRegex =
                    RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Formato email non valido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Campo password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              style: const TextStyle(color: AppColors.textOnDark),
              decoration: _inputDec(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostra password'
                      : 'Nascondi password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textOnDarkSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci la tua password';
                }
                if (value.length < 6) {
                  return 'La password deve avere almeno 6 caratteri';
                }
                return null;
              },
            ),

            // Errore login
            if (loginState.errorMessage != null) ...[
              const SizedBox(height: 14),
              _buildErrorBanner(loginState.errorMessage!),
            ],

            const SizedBox(height: 24),

            // Bottone accedi
            FilledButton(
              onPressed: loginState.isLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.35),
                foregroundColor: AppColors.accentGreenDark,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.15),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: loginState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentGreenDark,
                      ),
                    )
                  : const Text(
                      'Accedi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.40),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline,
              color: AppColors.error.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input decoration ──────────────────────────────────────────────────────

  InputDecoration _inputDec({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13),
      hintStyle:
          const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textOnDarkSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 0.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: TextStyle(
          color: AppColors.error.withValues(alpha: 0.8), fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
