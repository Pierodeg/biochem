import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

/// Pannello laterale del profilo utente
///
/// Implementato come [Drawer] su [Scaffold.endDrawer] → scorre da destra
/// Si chiude swipando verso destra o toccando fuori
class ProfilePanel extends ConsumerWidget {
  const ProfilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    // 85% della larghezza schermo, max 420px (evita pannelli enormi su desktop widescreen)
    final panelWidth = (MediaQuery.of(context).size.width * 0.85).clamp(0.0, 420.0);

    return Drawer(
      width: panelWidth,
      backgroundColor: AppColors.profileBackground,
      child: userAsync.when(
        data: (user) => user != null
            ? _PanelContent(
                displayName: user.displayName,
                email: user.email,
                isAdmin: user.isAdmin,
                roleLabel: user.roleLabel,
                createdAt: user.createdAt,
                isActive: user.isActive,
                initials: user.initials,
                onLogout: () => _handleLogout(context, ref),
                onImpostazioni: () => _handleImpostazioni(context),
                onCalendario: () => _handleCalendario(context),
              )
            : _PanelContent.empty(
                onLogout: () => _handleLogout(context, ref),
                onImpostazioni: () => _handleImpostazioni(context),
                onCalendario: () => _handleCalendario(context),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _PanelContent.empty(
          onLogout: () => _handleLogout(context, ref),
          onImpostazioni: () => _handleImpostazioni(context),
          onCalendario: () => _handleCalendario(context),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Chiude il drawer prima del logout
    Navigator.of(context).pop();
    await ref.read(authServiceProvider).signOut();
    // Il router gestisce automaticamente il redirect a /login
  }

  void _handleImpostazioni(BuildContext context) {
    // Chiude il drawer poi naviga alle impostazioni admin
    Navigator.of(context).pop();
    context.push('/admin/impostazioni');
  }

  void _handleCalendario(BuildContext context) {
    // Chiude il drawer poi naviga al calendario
    Navigator.of(context).pop();
    context.go('/calendario');
  }
}

// ─── Contenuto del pannello ───────────────────────────────────────────────────

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.displayName,
    required this.email,
    required this.isAdmin,
    required this.roleLabel,
    required this.createdAt,
    required this.isActive,
    required this.initials,
    required this.onLogout,
    required this.onImpostazioni,
    required this.onCalendario,
  });

  /// Costruttore per stato vuoto / errore
  factory _PanelContent.empty({
    required VoidCallback onLogout,
    required VoidCallback onImpostazioni,
    required VoidCallback onCalendario,
  }) {
    return _PanelContent(
      displayName: 'Utente',
      email: '',
      isAdmin: false,
      roleLabel: 'Dipendente',
      createdAt: DateTime.now(),
      isActive: true,
      initials: '?',
      onLogout: onLogout,
      onImpostazioni: onImpostazioni,
      onCalendario: onCalendario,
    );
  }

  final String displayName;
  final String email;
  final bool isAdmin;
  final String roleLabel;
  final DateTime createdAt;
  final bool isActive;
  final String initials;
  final VoidCallback onLogout;
  final VoidCallback onImpostazioni;
  final VoidCallback onCalendario;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con avatar
        _buildHeader(),

        // Corpo scrollabile
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Informazioni account
                _buildSectionTitle('Informazioni account'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Membro dal',
                  value: _formatDate(createdAt),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  label: 'Stato account',
                  value: isActive ? 'Attivo' : 'Disabilitato',
                  valueColor: isActive ? AppColors.success : AppColors.error,
                ),

                // Sezione Amministrazione — visibile solo agli admin
                if (isAdmin) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Amministrazione'),
                  const SizedBox(height: 12),
                  // Voce Calendario (su mobile non è in bottom nav)
                  _buildVoceMenu(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    label: 'Calendario',
                    onTap: onCalendario,
                  ),
                  const SizedBox(height: 8),
                  _buildVoceImpostazioni(context),
                ],

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Placeholder per info future
                _buildSectionTitle('Altre informazioni'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.textDisabled),
                      SizedBox(width: 10),
                      Text(
                        'Altre informazioni in arrivo...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textDisabled,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Pulsante logout in fondo
        _buildLogoutButton(),
      ],
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.appBarBackground,
      ),
      child: Column(
        children: [
          // Avatar grande con iniziali
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surface.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nome completo
          Text(
            displayName,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            email,
            style: TextStyle(
              color: AppColors.textOnPrimary.withValues(alpha: 0.75),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Badge ruolo
          _buildRoleBadge(),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.roleAdminBackground
            : AppColors.roleDipendenteBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        roleLabel,
        style: TextStyle(
          color: isAdmin ? AppColors.roleAdminText : AppColors.roleDipendenteText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ─── Voce generica menu admin ─────────────────────────────────────────────

  Widget _buildVoceMenu({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  // ─── Voce Impostazioni Admin ──────────────────────────────────────────────

  Widget _buildVoceImpostazioni(BuildContext context) {
    return _buildVoceMenu(
      context: context,
      icon: Icons.settings_outlined,
      label: 'Impostazioni',
      onTap: onImpostazioni,
    );
  }

  // ─── Sezioni info ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textDisabled,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: TextButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: const Text(
          'Esci',
          style: TextStyle(
            color: AppColors.error,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.error.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── Utility ──────────────────────────────────────────────────────────────

  /// Formatta la data in italiano: "12 gennaio 2024"
  String _formatDate(DateTime date) {
    return DateFormat('d MMMM y', 'it').format(date);
  }
}
