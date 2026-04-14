import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

/// Schermata di accesso all'applicazione
///
/// Solo email + password. Nessuna opzione di registrazione:
/// gli account vengono creati esclusivamente dall'amministratore.
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
    // Nasconde la tastiera
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    ref.read(loginProvider.notifier).clearError();

    try {
      await ref.read(loginProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      // Il router gestisce automaticamente la navigazione
      // tramite il redirect sull'authStateProvider
    } catch (_) {
      // L'errore è già memorizzato nello state del loginProvider
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              // Larghezza massima per schermi desktop / tablet
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildForm(loginState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header con logo e titolo ──────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo aziendale
        Image.asset(
          'assets/images/logo.png',
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'Gestionale Aziendale',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─── Form email + password ─────────────────────────────────────────────────

  Widget _buildForm(LoginState loginState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Email aziendale',
              hintText: 'nome@azienda.it',
              prefixIcon: Icon(Icons.email_outlined),
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
          const SizedBox(height: 16),

          // Campo password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostra password'
                    : 'Nascondi password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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

          // Messaggio di errore (visibile solo in caso di fallimento)
          if (loginState.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(loginState.errorMessage!),
          ],

          const SizedBox(height: 28),

          // Pulsante accedi
          ElevatedButton(
            onPressed: loginState.isLoading ? null : _handleLogin,
            child: loginState.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.buttonPrimaryText,
                    ),
                  )
                : const Text('Accedi'),
          ),

          // Nota: nessun link per registrazione o recupero password.
          // Tutte le operazioni sugli account avvengono tramite l'admin.
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
