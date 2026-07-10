import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/fcm_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePanel extends ConsumerWidget {
  const ProfilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final panelWidth =
        (MediaQuery.of(context).size.width * 0.85).clamp(0.0, 420.0);

    return Drawer(
      width: panelWidth,
      backgroundColor: Colors.transparent,
      child: Container(
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
                )
              : _PanelContent.empty(
                  onLogout: () => _handleLogout(context, ref),
                ),
          loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.accentGreenDark),
          ),
          error: (_, __) => _PanelContent.empty(
            onLogout: () => _handleLogout(context, ref),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    await FcmService(ProviderScope.containerOf(context, listen: false))
        .eliminaToken();
    await ref.read(authServiceProvider).signOut();
  }
}

// ─── Contenuto pannello ───────────────────────────────────────────────────────

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
  });

  factory _PanelContent.empty({
    required VoidCallback onLogout,
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildSectionTitle('Informazioni account'),
                  const SizedBox(height: 10),
                  _buildGlassCard(children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Membro dal',
                      value: _formatDate(createdAt),
                    ),
                    _buildDividerLine(),
                    _buildInfoRow(
                      icon: isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      label: 'Stato account',
                      value: isActive ? 'Attivo' : 'Disabilitato',
                      valueColor: isActive
                          ? AppColors.accentGreenDark
                          : const Color(0xFFFF7070),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Altre informazioni'),
                  const SizedBox(height: 10),
                  _buildGlassCard(children: const [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 15, color: AppColors.textOnDarkMuted),
                        SizedBox(width: 10),
                        Text(
                          'Altre informazioni in arrivo...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textOnDarkMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.25),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.accentGreenDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.primary.withValues(alpha: 0.25)
                        : const Color(0xFF1565C0).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdmin
                          ? AppColors.primary.withValues(alpha: 0.50)
                          : const Color(0xFF1565C0).withValues(alpha: 0.50),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: isAdmin
                          ? AppColors.accentGreenDark
                          : AppColors.accentBlueDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1.5, color: AppColors.glassBorder),
          ),
        ],
      ),
    );
  }

  // ─── Componenti glass ─────────────────────────────────────────────────────

  Widget _buildGlassCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDividerLine() {
    return Container(
      height: 0.5,
      color: AppColors.glassBorderSubtle,
      margin: const EdgeInsets.symmetric(vertical: 10),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnDarkMuted,
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
        Icon(icon, size: 15, color: AppColors.textOnDarkSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textOnDarkSecondary),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textOnDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                Container(height: 1.5, color: AppColors.glassBorder),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.error),
              label: const Text(
                'Esci',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    AppColors.error.withValues(alpha: 0.20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM y', 'it').format(date);
  }
}
