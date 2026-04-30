import 'package:flutter/material.dart';

/// Palette 3 modificata — Verde brillante (#00C853) + Blu logo (#1565C0)
/// Sidebar bicolore: header blu, voci su verde scuro.
/// Verde acceso come palette 4, struttura sidebar come palette 3.
/// Per cambiare tema modificare solo questo file.

class AppColors {
  AppColors._();

  // ─── Colori brand dal logo ─────────────────────────────────────────────────

  static const Color primary = Color(0xFF00A843);
  static const Color primaryBright = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF007830);
  static const Color primaryDarkest = Color(0xFF003D1E);
  static const Color primaryLight = Color(0xFFC8F5DC);
  static const Color primaryLightest = Color(0xFFE8FFF2);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueMedium = Color(0xFF1976D2);
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color blueDark = Color(0xFF0D3B7A);

  // ─── Sfondo pagina ────────────────────────────────────────────────────────

  static const Color background = Color(0xFFF5F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF2F7F2);

  // ─── Sidebar desktop ──────────────────────────────────────────────────────

  static const Color sidebarBackground = Color(0xFF003D1E);
  static const Color sidebarHeaderBackground = Color(0xFF1565C0);
  static const Color sidebarLogoText = Color(0xFFFFFFFF);
  static const Color sidebarTextInactive = Color(0xFF4CAF50);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarItemActive = Color(0xFF00A843);
  static const Color sidebarAccent = Color(0xFF00C853);

  // ─── AppBar mobile ────────────────────────────────────────────────────────

  static const Color appBarBackground = Color(0xFF1565C0);
  static const Color appBarForeground = Color(0xFFFFFFFF);

  // ─── Bottom navigation mobile ─────────────────────────────────────────────

  static const Color navSelected = Color(0xFF00A843);
  static const Color navUnselected = Color(0xFFAAAAAA);
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navIndicator = Color(0xFF00C853);

  // ─── Bottoni ──────────────────────────────────────────────────────────────

  static const Color buttonPrimary = Color(0xFF00A843);
  static const Color buttonPrimaryText = Color(0xFFFFFFFF);
  static const Color buttonPrimaryHover = Color(0xFF007830);
  static const Color buttonSecondary = Color(0xFFC8F5DC);
  static const Color buttonSecondaryText = Color(0xFF005C2A);
  static const Color buttonBlue = Color(0xFF1565C0);
  static const Color buttonBlueText = Color(0xFFFFFFFF);
  static const Color buttonDanger = Color(0xFFD32F2F);
  static const Color buttonDangerText = Color(0xFFFFFFFF);
  static const Color buttonDisabled = Color(0xFFE0E0E0);
  static const Color buttonDisabledText = Color(0xFFAAAAAA);

  // ─── FAB ──────────────────────────────────────────────────────────────────

  static const Color fabBackground = Color(0xFF00A843);
  static const Color fabIcon = Color(0xFFFFFFFF);

  // ─── Tabelle ──────────────────────────────────────────────────────────────

  static const Color tableHeader = Color(0xFFE8F5E9);
  static const Color tableHeaderText = Color(0xFF005C2A);
  static const Color tableRowEven = Color(0xFFFFFFFF);
  static const Color tableRowOdd = Color(0xFFFAFAFA);
  static const Color tableRowHover = Color(0xFFC8F5DC);
  static const Color tableBorder = Color(0xFFE0E0E0);

  // ─── Badge e chip ─────────────────────────────────────────────────────────

  static const Color badgeGreenBackground = Color(0xFFC8F5DC);
  static const Color badgeGreenText = Color(0xFF005C2A);
  static const Color badgeBlueBackground = Color(0xFFE3F2FD);
  static const Color badgeBlueText = Color(0xFF1565C0);
  static const Color badgeGreyBackground = Color(0xFFEEEEEE);
  static const Color badgeGreyText = Color(0xFF555555);
  static const Color badgeRedBackground = Color(0xFFFFEBEE);
  static const Color badgeRedText = Color(0xFFD32F2F);
  static const Color badgeAmberBackground = Color(0xFFFFF8E1);
  static const Color badgeAmberText = Color(0xFFB7770D);

  // ─── Stato e feedback ─────────────────────────────────────────────────────

  static const Color success = Color(0xFF00A843);
  static const Color successLight = Color(0xFFC8F5DC);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── Toggle / Switch ──────────────────────────────────────────────────────

  static const Color switchActive = Color(0xFF00A843);
  static const Color switchActiveTrack = Color(0xFF80D8A0);
  static const Color switchInactive = Color(0xFFBDBDBD);

  // ─── Form e input ─────────────────────────────────────────────────────────

  static const Color inputBorder = Color(0xFFCCCCCC);
  static const Color inputBorderFocus = Color(0xFF00A843);
  static const Color inputBorderError = Color(0xFFD32F2F);
  static const Color inputLabel = Color(0xFF005C2A);

  // ─── Divider e bordi ──────────────────────────────────────────────────────

  static const Color divider = Color(0xFFE0E0E0);
  static const Color cardBorder = Color(0xFFE0E0E0);

  // ─── Profilo panel ────────────────────────────────────────────────────────

  static const Color profileBackground = Color(0xFFFFFFFF);
  static const Color avatarAdminBackground = Color(0xFF00A843);
  static const Color avatarAdminText = Color(0xFFFFFFFF);
  static const Color avatarDipendenteBackground = Color(0xFF1565C0);
  static const Color avatarDipendenteText = Color(0xFFFFFFFF);
  static const Color roleAdminBackground = Color(0xFFC8F5DC);
  static const Color roleAdminText = Color(0xFF005C2A);
  static const Color roleDipendenteBackground = Color(0xFFE3F2FD);
  static const Color roleDipendenteText = Color(0xFF1565C0);

  // ─── Testo generico ───────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textDisabled = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnBlue = Color(0xFFFFFFFF);

  // ─── Glass / Sfondo scuro ─────────────────────────────────────────────────

  /// Sfondo gradiente
  static const Color gradientStart = Color(0xFF003D1E);
  static const Color gradientMid1 = Color(0xFF005C2A);
  static const Color gradientMid2 = Color(0xFF0C447C);
  static const Color gradientEnd = Color(0xFF042C53);

  /// Card glass — scala di intensità
  /// Usa questi valori per controllare quanto è visibile la card
  /// sullo sfondo scuro del gradiente.

  /// ~7% — quasi invisibile (default attuale)
  static const Color glassCard = Color(0x12FFFFFF);

  /// ~10% — leggero (hover default)
  static const Color glassCardHover = Color(0x1AFFFFFF);

  /// ~13% — medio (card espandibili aperte)
  static const Color glassCardMedium = Color(0x21FFFFFF);

  /// ~18% — visibile (card in evidenza)
  static const Color glassCardHigh = Color(0x2EFFFFFF);

  /// ~24% — forte (card selezionate/attive)
  static const Color glassCardStrong = Color(0x3DFFFFFF);

  /// Sfondo glass scuro — form e tabelle
  static const Color glassDark = Color(0x33000000);

  /// Sfondo glass molto scuro — header tabelle, navbar
  static const Color glassDarkest = Color(0x4D000000);

  /// Bordi glass — scala di intensità

  /// ~6% — sottile (separatori interni)
  static const Color glassBorderSubtle = Color(0x0FFFFFFF);

  /// ~15% — standard (bordi card default)
  static const Color glassBorder = Color(0x26FFFFFF);

  /// ~22% — medio (bordi card espandibili)
  static const Color glassBorderMedium = Color(0x38FFFFFF);

  /// ~30% — marcato (bordi card in evidenza)
  static const Color glassBorderStrong = Color(0x4DFFFFFF);

  /// Testo su sfondo scuro

  /// 100% — bianco puro (valori campi input)
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// ~60% — label campi input su sfondo scuro
  static const Color glassFieldLabel = Color(0x99FFFFFF);

  /// ~55% — label leggermente più scura (alternativa)
  static const Color glassFieldLabelDim = Color(0x8CFFFFFF);

  /// ~40% — testo disabilitato/muted su sfondo scuro
  static const Color textOnDarkMuted = Color(0x66FFFFFF);

  /// ~60% — testo secondario su sfondo scuro (alias di glassFieldLabel)
  static const Color textOnDarkSecondary = Color(0x99FFFFFF);

  /// Verde accent su sfondo scuro
  static const Color accentGreenDark = Color(0xFF4AE883);

  /// Blu accent su sfondo scuro
  static const Color accentBlueDark = Color(0xFF7DB8F4);

  /// Amber accent su sfondo scuro
  static const Color accentAmberDark = Color(0xFFF4C875);

  // ─── MaterialColor per ThemeData ──────────────────────────────────────────

  static const MaterialColor primarySwatch = MaterialColor(
    0xFF00A843,
    <int, Color>{
      50:  Color(0xFFE8FFF2),
      100: Color(0xFFC8F5DC),
      200: Color(0xFF8AE8B4),
      300: Color(0xFF4CD98C),
      400: Color(0xFF00C853),
      500: Color(0xFF00A843),
      600: Color(0xFF007830),
      700: Color(0xFF005C2A),
      800: Color(0xFF003D1E),
      900: Color(0xFF002010),
    },
  );

  // ─── Helper colori per ruolo ──────────────────────────────────────────────

  static Color roleBadgeBackground(String role) =>
      role == 'admin' ? roleAdminBackground : roleDipendenteBackground;

  static Color roleBadgeText(String role) =>
      role == 'admin' ? roleAdminText : roleDipendenteText;

  static Color avatarBackground(String role) =>
      role == 'admin' ? avatarAdminBackground : avatarDipendenteBackground;

  static Color avatarText(String role) =>
      role == 'admin' ? avatarAdminText : avatarDipendenteText;
}
