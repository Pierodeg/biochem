import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifiche/widgets/notifiche_panel.dart';
import '../../profile/widgets/profile_panel.dart';

/// Schermata principale con layout responsive.
///
/// Riceve il [StatefulNavigationShell] da go_router: la navigazione tra tab
/// è gestita dal router (URL aggiornato, stato branch preservato).
///
/// MOBILE (< 600px):
///   - AppBar globale con titolo + avatar profilo (apre endDrawer)
///   - Body: navigationShell (go_router gestisce lo stato per branch)
///   - BottomNavigationBar con 5 voci
///   - EndDrawer: [ProfilePanel]
///
/// DESKTOP (>= 600px):
///   - Sidebar fissa 220px con logo, nav e avatar utente
///   - Header con titolo pagina corrente
///   - Body: navigationShell
///   - EndDrawer: [ProfilePanel]
class MainScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  /// Chiave globale per aprire l'endDrawer da widget annidati (sidebar/avatar)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ─── Configurazione statica ────────────────────────────────────────────────

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.people_outline, label: 'Anagrafiche'),
    _NavItem(icon: Icons.description_outlined, label: 'Preventivo'),
    _NavItem(icon: Icons.biotech_outlined, label: 'Reg Lab'),
    _NavItem(icon: Icons.pest_control, label: 'Servizi Pest'),
    _NavItem(icon: Icons.receipt_long_outlined, label: 'Fatture'),
    _NavItem(icon: Icons.calendar_month_outlined, label: 'Calendario'),
  ];

  static const List<String> _titles = [
    'Anagrafiche',
    'Preventivo',
    'Reg Lab',
    'Servizi Pest',
    'Fatture',
    'Calendario',
  ];

  /// Cambia tab tramite go_router: aggiorna URL e preserva lo stato del branch
  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      // initialLocation: true riporta alla root del branch se già selezionato
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  int get _currentIndex => widget.navigationShell.currentIndex;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Mostra notifiche pendenti inviate dal redirect del router
    ref.listen<String?>(pendingNotificationProvider, (_, message) {
      if (message == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(pendingNotificationProvider.notifier).state = null;
      });
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return _buildDesktopLayout();
        }
        return _buildMobileLayout();
      },
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 50,
          fit: BoxFit.contain,
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Badge notifiche campanella
          _NotificaBadgeButton(scaffoldKey: _scaffoldKey),
          _AppBarAvatarButton(scaffoldKey: _scaffoldKey),
        ],
      ),

      // navigationShell gestisce lo stato di ogni branch separatamente
      body: widget.navigationShell,

      // Drawer start: pannello notifiche
      drawer: const NotifichePanel(),
      // Drawer end: profilo utente
      endDrawer: const ProfilePanel(),

      // Bottom nav mobile: solo le prime 5 voci (Calendario è nel pannello profilo)
      bottomNavigationBar: BottomNavigationBar(
        // Quando si è sul tab Calendario (index 5) nessuna voce risulta attiva
        currentIndex: _currentIndex < 5 ? _currentIndex : 0,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: _navItems
            .take(5) // esclude Calendario dalla bottom nav
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const NotifichePanel(),
      endDrawer: const ProfilePanel(),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: AppColors.sidebarBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo aziendale nella sidebar desktop
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 60,
                fit: BoxFit.contain,
              ),
            ),

            const Divider(
                color: Colors.white24, height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _navItems.length,
                itemBuilder: (context, index) => _buildSidebarItem(index),
              ),
            ),

            const Divider(
                color: Colors.white24, height: 1, indent: 12, endIndent: 12),
            _SidebarUserFooter(scaffoldKey: _scaffoldKey),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.sidebarItemActive
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected
              ? AppColors.sidebarTextActive
              : AppColors.sidebarTextInactive,
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected
                ? AppColors.sidebarTextActive
                : AppColors.sidebarTextInactive,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        onTap: () => _onTabSelected(index),
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Badge notifiche campanella (desktop)
          _NotificaBadgeButton(scaffoldKey: _scaffoldKey),
        ],
      ),
    );
  }
}

// ─── Badge notifiche campanella (ConsumerWidget isolato) ─────────────────────

/// Icona campanella con badge rosso che mostra il numero di notifiche non lette.
/// Tap → apre il pannello notifiche (drawer start).
class _NotificaBadgeButton extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _NotificaBadgeButton({required this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();

    // Conta notifiche non lette in real-time
    final conteggio = ref.watch(
      _nonLetteCountProvider(uid),
    );

    return IconButton(
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
      icon: Badge(
        isLabelVisible: conteggio.valueOrNull != null &&
            conteggio.valueOrNull! > 0,
        label: Text(
          '${conteggio.valueOrNull ?? 0}',
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.notifications_outlined),
      ),
      color: AppColors.appBarForeground,
      tooltip: 'Notifiche',
    );
  }
}

/// Provider per il conteggio notifiche non lette (ottimizzato per il badge)
final _nonLetteCountProvider =
    StreamProvider.family<int, String>((ref, uid) {
  return ref.watch(notificheServiceProvider).getNotificheNonLette(uid);
});

// ─── Dati di una voce della nav ───────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Avatar AppBar mobile (ConsumerWidget isolato) ───────────────────────────

/// Avatar circolare nell'AppBar mobile che apre il profilo.
/// ConsumerWidget isolato: si ricostruisce solo quando cambia [currentUserProvider].
class _AppBarAvatarButton extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _AppBarAvatarButton({required this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => scaffoldKey.currentState?.openEndDrawer(),
        child: userAsync.when(
          data: (user) => CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.appBarForeground.withValues(alpha: 0.22),
            child: Text(
              user?.initials ?? '?',
              style: const TextStyle(
                color: AppColors.appBarForeground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          loading: () => const SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.appBarForeground),
              ),
            ),
          ),
          error: (_, __) => const CircleAvatar(
            radius: 18,
            child: Icon(Icons.person, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar footer sidebar desktop (ConsumerWidget isolato) ──────────────────

/// Sezione in fondo alla sidebar desktop con avatar, nome e ruolo.
/// ConsumerWidget isolato: si ricostruisce solo quando cambia [currentUserProvider].
class _SidebarUserFooter extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _SidebarUserFooter({required this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => scaffoldKey.currentState?.openEndDrawer(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: userAsync.when(
            data: (user) => Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.sidebarLogoText.withValues(alpha: 0.22),
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      color: AppColors.sidebarLogoText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName ?? '',
                        style: const TextStyle(
                          color: AppColors.sidebarLogoText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roleLabel ?? '',
                        style: const TextStyle(
                          color: AppColors.sidebarTextInactive,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.settings_outlined,
                  color: AppColors.sidebarLogoText.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
            loading: () => const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.sidebarLogoText),
                ),
              ),
            ),
            error: (_, __) =>
                const Icon(Icons.person, color: AppColors.sidebarLogoText, size: 24),
          ),
        ),
      ),
    );
  }
}
