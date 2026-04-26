import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifiche/widgets/notifiche_panel.dart';
import '../../profile/widgets/profile_panel.dart';

class MainScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  int get _currentIndex => widget.navigationShell.currentIndex;

  @override
  Widget build(BuildContext context) {
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
                  const Color(0xFF00A843).withValues(alpha: 0.12),
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
                  const Color(0xFF1565C0).withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Contenuto principale
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 600) {
                return _buildDesktopLayout();
              }
              return _buildMobileLayout();
            },
          ),
        ],
      ),
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.glassDarkest,
        title: Image.asset(
          'assets/images/logo.png',
          height: 50,
          fit: BoxFit.contain,
        ),
        automaticallyImplyLeading: false,
        actions: [
          _NotificaBadgeButton(
              scaffoldKey: _scaffoldKey, iconColor: AppColors.textOnDark),
          _AppBarAvatarButton(scaffoldKey: _scaffoldKey),
        ],
      ),
      body: widget.navigationShell,
      drawer: const NotifichePanel(),
      endDrawer: const ProfilePanel(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.glassDarkest,
          border: Border(
            top: BorderSide(
              color: AppColors.glassBorder,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex < 5 ? _currentIndex : 0,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.accentGreenDark,
          unselectedItemColor: AppColors.textOnDarkSecondary,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: _navItems
              .take(5)
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
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
      decoration: const BoxDecoration(
        color: AppColors.glassDarkest,
        border: Border(
          right: BorderSide(
            color: AppColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Image.asset(
                'assets/images/logo.png',
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
            Container(
              height: 0.5,
              color: AppColors.glassBorder,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const SizedBox(height: 8),
            // Voci nav
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: _navItems.length,
                itemBuilder: (context, index) => _buildSidebarItem(index),
              ),
            ),
            Container(
              height: 0.5,
              color: AppColors.glassBorder,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
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
            ? AppColors.primary.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.40),
                width: 0.5,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected
              ? AppColors.accentGreenDark
              : AppColors.textOnDarkSecondary,
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected
                ? AppColors.accentGreenDark
                : AppColors.textOnDarkSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: () => _onTabSelected(index),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        hoverColor: AppColors.glassCard,
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          _NotificaBadgeButton(
            scaffoldKey: _scaffoldKey,
            iconColor: AppColors.textOnDark,
          ),
        ],
      ),
    );
  }
}

// ─── Badge notifiche ──────────────────────────────────────────────────────────

class _NotificaBadgeButton extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Color iconColor;

  const _NotificaBadgeButton({
    required this.scaffoldKey,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return const SizedBox.shrink();

    final conteggio = ref.watch(_nonLetteCountProvider(uid));

    return IconButton(
      onPressed: () => scaffoldKey.currentState?.openDrawer(),
      icon: Badge(
        isLabelVisible:
            conteggio.valueOrNull != null && conteggio.valueOrNull! > 0,
        label: Text(
          '${conteggio.valueOrNull ?? 0}',
          style: const TextStyle(fontSize: 10),
        ),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.notifications_outlined),
      ),
      color: iconColor,
      tooltip: 'Notifiche',
    );
  }
}

final _nonLetteCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return ref.watch(notificheServiceProvider).getNotificheNonLette(uid);
});

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Avatar AppBar mobile ─────────────────────────────────────────────────────

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
            backgroundColor: AppColors.primary.withValues(alpha: 0.25),
            child: Text(
              user?.initials ?? '?',
              style: const TextStyle(
                color: AppColors.accentGreenDark,
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
                    strokeWidth: 2, color: AppColors.textOnDark),
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

// ─── Footer sidebar desktop ───────────────────────────────────────────────────

class _SidebarUserFooter extends ConsumerWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _SidebarUserFooter({required this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.glassCard,
        onTap: () => scaffoldKey.currentState?.openEndDrawer(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.glassCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 0.5,
            ),
          ),
          child: userAsync.when(
            data: (user) => Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  child: Text(
                    user?.initials ?? '?',
                    style: const TextStyle(
                      color: AppColors.accentGreenDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName ?? '',
                        style: const TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roleLabel ?? '',
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textOnDarkMuted,
                  size: 15,
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.textOnDark),
                ),
              ),
            ),
            error: (_, __) =>
                const Icon(Icons.person, color: AppColors.textOnDark, size: 24),
          ),
        ),
      ),
    );
  }
}
