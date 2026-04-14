import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/notifica_model.dart';

/// Pannello laterale (endDrawer / pagina) per le notifiche in-app.
///
/// Mostra le notifiche dell'utente corrente ordinate per data decrescente.
/// - Notifiche non lette in evidenza (punto blu)
/// - Tap → segna come letta e naviga all'appuntamento
/// - Bottone "Segna tutte come lette"
/// - Dismissible per eliminare su mobile
class NotifichePanel extends ConsumerWidget {
  const NotifichePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final uid = userAsync.valueOrNull?.uid;

    if (uid == null) {
      return const Drawer(
        child: Center(child: Text('Utente non autenticato')),
      );
    }

    final notificheService = ref.read(notificheServiceProvider);
    final notificheAsync = ref.watch(_notificheProvider(uid));

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Notifiche',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // Bottone "Segna tutte come lette"
                  TextButton.icon(
                    onPressed: () =>
                        notificheService.segnaLetteTutte(uid),
                    icon: const Icon(Icons.done_all,
                        size: 16, color: AppColors.primary),
                    label: const Text(
                      'Tutte lette',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                  // Bottone chiudi
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Lista notifiche ───────────────────────────────────────────
            Expanded(
              child: notificheAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                    child: Text('Errore: $e',
                        style:
                            const TextStyle(color: AppColors.error))),
                data: (notifiche) {
                  if (notifiche.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none,
                              size: 48, color: AppColors.textDisabled),
                          SizedBox(height: 8),
                          Text('Nessuna notifica',
                              style: TextStyle(
                                  color: AppColors.textDisabled,
                                  fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
                    itemCount: notifiche.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) {
                      final n = notifiche[i];
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: AppColors.error,
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        onDismissed: (_) =>
                            notificheService.eliminaNotifica(uid, n.id),
                        child:
                            _buildNotificaItem(context, ref, n, uid),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificaItem(BuildContext context, WidgetRef ref,
      NotificaModel n, String uid) {
    final notificheService = ref.read(notificheServiceProvider);
    final colore = _colorePerTipo(n.tipo);

    return InkWell(
      onTap: () async {
        // Segna come letta
        if (!n.letta) {
          await notificheService.segnaLetta(uid, n.id);
        }
        // Naviga all'appuntamento se presente
        if (n.appuntamentoId != null && context.mounted) {
          Navigator.pop(context); // chiude il drawer
          context.push('/calendario/${n.appuntamentoId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        color: n.letta ? Colors.transparent : AppColors.primaryLightest,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icona colorata per tipo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colore.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconaPerTipo(n.tipo),
                size: 18,
                color: colore,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.titolo,
                          style: TextStyle(
                            fontWeight: n.letta
                                ? FontWeight.w400
                                : FontWeight.w700,
                            fontSize: 13,
                            color: n.letta
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Punto blu se non letta
                      if (!n.letta)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (n.corpo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      n.corpo,
                      style: TextStyle(
                        fontSize: 12,
                        color: n.letta
                            ? AppColors.textDisabled
                            : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Data/ora relativa
                  Text(
                    _dataRelativa(n.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Restituisce una stringa relativa per la data (es. "2 ore fa", "Ieri")
  String _dataRelativa(DateTime data) {
    final ora = DateTime.now();
    final diff = ora.difference(data);

    if (diff.inMinutes < 1) return 'Adesso';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} ore fa';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return '${diff.inDays} giorni fa';
    return DateFormat('dd/MM/yyyy', 'it').format(data);
  }

  Color _colorePerTipo(String tipo) {
    switch (tipo) {
      case 'reg_lab':
        return const Color(0xFF1565C0);
      case 'pest':
        return const Color(0xFF00A843);
      case 'lettura_piastre':
        return const Color(0xFFE65100);
      case 'richiamo':
        return const Color(0xFFBA7517);
      case 'generico':
      default:
        return const Color(0xFF5F5E5A);
    }
  }

  IconData _iconaPerTipo(String tipo) {
    switch (tipo) {
      case 'reg_lab':
        return Icons.biotech_outlined;
      case 'pest':
        return Icons.pest_control;
      case 'lettura_piastre':
        return Icons.science_outlined;
      case 'richiamo':
        return Icons.refresh;
      case 'generico':
      default:
        return Icons.notifications_outlined;
    }
  }
}

// ─── Provider locale per le notifiche dell'utente ──────────────────────────

/// Provider che fornisce lo stream delle notifiche per l'UID passato.
final _notificheProvider = StreamProvider.family<List<NotificaModel>, String>(
  (ref, uid) => ref.watch(notificheServiceProvider).getNotifiche(uid),
);
