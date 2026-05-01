import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/preventivo_model.dart';
import '../../../widgets/filtri/filtro_preventivi.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _preventiviStreamProvider = StreamProvider<List<PreventivoModel>>((ref) {
  // Dipende dall'auth: si ricrea con token fresco dopo ogni sign-in
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(preventiviServiceProvider).getPreventivi();
});

// ─── Pagina lista preventivi ──────────────────────────────────────────────────

class PreventiviPage extends ConsumerStatefulWidget {
  const PreventiviPage({super.key});

  @override
  ConsumerState<PreventiviPage> createState() => _PreventiviPageState();
}

class _PreventiviPageState extends ConsumerState<PreventiviPage> {
  final _cercaController = TextEditingController();
  String _queryRicerca = '';
  bool _filtroAperto = false;
  FiltroPreventiviStato _filtro = const FiltroPreventiviStato();

  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  List<PreventivoModel> _filtra(List<PreventivoModel> lista) {
    List<PreventivoModel> risultato = lista;
    if (_queryRicerca.isNotEmpty) {
      final q = _queryRicerca.toLowerCase();
      risultato = lista
          .where((p) =>
              p.committente.toLowerCase().contains(q) ||
              p.numeroFormattato.toLowerCase().contains(q))
          .toList();
    }
    return applicaFiltroPreventivi(risultato, _filtro);
  }

  @override
  Widget build(BuildContext context) {
    final preventiviAsync = ref.watch(_preventiviStreamProvider);
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        return preventiviAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Text('Errore: $err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (preventivi) {
            final filtrati = _filtra(preventivi);
            return isDesktop
                ? _buildDesktopLayout(preventivi, filtrati, isAdmin)
                : _buildMobileLayout(preventivi, filtrati, isAdmin);
          },
        );
      },
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    List<PreventivoModel> tutti,
    List<PreventivoModel> filtrati,
    bool isAdmin,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            FiltroPreventivi(
              aperto: _filtroAperto,
              statoFiltro: _filtro,
              onFiltroApplicato: (f) =>
                  setState(() { _filtro = f; _filtroAperto = false; }),
            ),
            FiltriAttiviRowPreventivi(
              stato: _filtro,
              onRimosso: (f) => setState(() => _filtro = f),
            ),
            Container(
              height: 0.5,
              color: AppColors.glassBorder,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(
              child: filtrati.isEmpty
                  ? _buildStatoVuoto()
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          12, 12, 12, isAdmin ? 80 : 16),
                      itemCount: filtrati.length,
                      itemBuilder: (_, i) => _buildCard(filtrati[i], isAdmin),
                    ),
            ),
          ],
        ),
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_preventivi',
              onPressed: () => context.push('/preventivo/nuovo'),
              backgroundColor: AppColors.primary.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(PreventivoModel p, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.glassCardHover,
          onTap: isAdmin ? () => context.push('/preventivo/${p.id}') : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (p.isDraft) ...[
                      _buildBadgeBozza(),
                      const SizedBox(width: 8),
                    ],
                    _buildBadgeNumero(p),
                    const Spacer(),
                    if (isAdmin) ...[
                      const Icon(Icons.chevron_right,
                          color: AppColors.textOnDarkMuted, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  p.committente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textOnDarkMuted),
                    const SizedBox(width: 5),
                    Text(
                      _dateFmt.format(p.data),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textOnDarkSecondary),
                    ),
                    if (p.totale > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A843).withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00A843)
                                  .withValues(alpha: 0.35),
                              width: 0.5),
                        ),
                        child: Text(
                          _moneyFmt.format(p.totale),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentGreenDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (p.righe.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${p.righe.length} ${p.righe.length == 1 ? 'servizio' : 'servizi'}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textOnDarkSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    List<PreventivoModel> tutti,
    List<PreventivoModel> filtrati,
    bool isAdmin,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              SizedBox(width: 340, child: _buildBarraRicercaConFiltro()),
              const Spacer(),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push('/preventivo/nuovo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuovo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.30),
                    foregroundColor: AppColors.accentGreenDark,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.50),
                        width: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
        FiltroPreventivi(
          aperto: _filtroAperto,
          statoFiltro: _filtro,
          onFiltroApplicato: (f) =>
              setState(() { _filtro = f; _filtroAperto = false; }),
        ),
        FiltriAttiviRowPreventivi(
          stato: _filtro,
          onRimosso: (f) => setState(() => _filtro = f),
        ),
        const Divider(height: 1, color: AppColors.glassBorderSubtle),
        Expanded(
          child: filtrati.isEmpty
              ? _buildStatoVuoto()
              : _buildListaDesktop(filtrati, isAdmin),
        ),
      ],
    );
  }

  Widget _buildListaDesktop(List<PreventivoModel> lista, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      itemCount: lista.length,
      itemBuilder: (_, i) => _buildCardPreventivoDesktop(lista[i], isAdmin),
    );
  }

  Widget _buildCardPreventivoDesktop(PreventivoModel p, bool isAdmin) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1000),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.glassCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            hoverColor: AppColors.glassCardHover,
            onTap: isAdmin ? () => context.push('/preventivo/${p.id}') : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.20),
                    child: Text(
                      _initials(p.committente),
                      style: const TextStyle(
                        color: AppColors.accentGreenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Numero + Badge bozza + Committente
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _buildBadgeNumero(p),
                          if (p.isDraft) ...[
                            const SizedBox(width: 6),
                            _buildBadgeBozza(),
                          ],
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          p.committente,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textOnDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  _separatoreV(),

                  // Data + servizi
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.calendar_today_outlined,
                            _dateFmt.format(p.data)),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.list_outlined,
                          '${p.righe.length} ${p.righe.length == 1 ? 'servizio' : 'servizi'}',
                        ),
                      ],
                    ),
                  ),

                  _separatoreV(),

                  // Totale
                  Expanded(
                    flex: 2,
                    child: p.totale > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A843)
                                  .withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF00A843)
                                      .withValues(alpha: 0.35),
                                  width: 0.5),
                            ),
                            child: Text(
                              _moneyFmt.format(p.totale),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.accentGreenDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Text('—',
                            style:
                                TextStyle(color: AppColors.textOnDarkMuted)),
                  ),

                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textOnDarkMuted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _separatoreV() {
    return Container(
      width: 0.5,
      height: 40,
      color: AppColors.glassBorder,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _infoRow(IconData icon, String testo, {String? label}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textOnDarkMuted),
        const SizedBox(width: 5),
        if (label != null)
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 10, color: AppColors.textOnDarkMuted),
          ),
        Expanded(
          child: Text(
            testo,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textOnDarkSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _initials(String nome) {
    final parts =
        nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ─── Widget condivisi ─────────────────────────────────────────────────────

  Widget _buildBarraRicercaConFiltro() {
    final filtriAttivi = _filtro.filtriAttivi;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cercaController,
            style: const TextStyle(color: AppColors.textOnDark),
            onChanged: (v) => setState(() => _queryRicerca = v.trim()),
            decoration: InputDecoration(
              hintText: 'Cerca per committente o numero...',
              hintStyle: const TextStyle(color: AppColors.textOnDarkMuted),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textOnDarkSecondary),
              suffixIcon: _queryRicerca.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 18, color: AppColors.textOnDarkSecondary),
                      onPressed: () {
                        _cercaController.clear();
                        setState(() => _queryRicerca = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0x1A000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.glassBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.glassBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () =>
                  setState(() => _filtroAperto = !_filtroAperto),
              icon: Icon(
                _filtroAperto
                    ? Icons.filter_list_off
                    : Icons.filter_list,
                color: _filtroAperto || filtriAttivi > 0
                    ? AppColors.accentGreenDark
                    : AppColors.textOnDarkSecondary,
              ),
              tooltip: 'Filtri',
            ),
            if (filtriAttivi > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$filtriAttivi',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeNumero(PreventivoModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.40), width: 0.5),
      ),
      child: Text(
        p.numeroFormattato,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.accentBlueDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadgeBozza() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFBA7517).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFBA7517).withValues(alpha: 0.40), width: 0.5),
      ),
      child: const Text(
        'Bozza',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.accentAmberDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined,
              size: 64, color: AppColors.textOnDarkMuted),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun preventivo ancora'
                : 'Nessun risultato trovato',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textOnDarkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
