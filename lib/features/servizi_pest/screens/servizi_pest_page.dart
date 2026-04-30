import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/servizio_pest_model.dart';
import '../../../widgets/filtri/filtro_servizi_pest.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _serviziPestStreamProvider =
    StreamProvider<List<ServizioPestModel>>((ref) {
  // Dipende dall'auth: si ricrea con token fresco dopo ogni sign-in
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(serviziPestServiceProvider).getServiziPest();
});

// ─── Pagina lista servizi pest ────────────────────────────────────────────────

class ServiziPestPage extends ConsumerStatefulWidget {
  const ServiziPestPage({super.key});

  @override
  ConsumerState<ServiziPestPage> createState() => _ServiziPestPageState();
}

class _ServiziPestPageState extends ConsumerState<ServiziPestPage> {
  final _cercaController = TextEditingController();
  String _queryRicerca = '';

  bool _filtroAperto = false;
  FiltroServiziPestStato _filtro = const FiltroServiziPestStato();

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  List<ServizioPestModel> _filtra(List<ServizioPestModel> lista) {
    List<ServizioPestModel> risultato = lista;
    if (_queryRicerca.isNotEmpty) {
      final q = _queryRicerca.toLowerCase();
      risultato = lista.where((s) {
        return s.committente.toLowerCase().contains(q) ||
            s.tipoIntervento.toLowerCase().contains(q) ||
            s.tecnico.toLowerCase().contains(q);
      }).toList();
    }
    return applicaFiltroServiziPest(risultato, _filtro);
  }

  String _formatCodiceData(String codice) {
    if (codice.length != 6) return codice;
    return '${codice.substring(4, 6)}/${codice.substring(2, 4)}/${codice.substring(0, 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final serviziAsync = ref.watch(_serviziPestStreamProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        return serviziAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Text('Errore: $err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (servizi) {
            final filtrati = _filtra(servizi);
            if (isDesktop) {
              return _buildDesktopLayout(servizi, filtrati, isAdmin);
            }
            return _buildMobileLayout(servizi, filtrati, isAdmin);
          },
        );
      },
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      List<ServizioPestModel> tutti,
      List<ServizioPestModel> filtrati,
      bool isAdmin) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            FiltroServiziPest(
              aperto: _filtroAperto,
              statoFiltro: _filtro,
              servizi: tutti,
              onFiltroApplicato: (nuovoFiltro) {
                setState(() {
                  _filtro = nuovoFiltro;
                  _filtroAperto = false;
                });
              },
            ),
            FiltriAttiviRowPest(
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
                      itemBuilder: (context, index) =>
                          _buildCardServizio(filtrati[index], isAdmin),
                    ),
            ),
          ],
        ),
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_servizi_pest',
              onPressed: () => context.push('/servizi-pest/nuovo'),
              backgroundColor: AppColors.primary.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildCardServizio(ServizioPestModel s, bool isAdmin) {
    final moneyFmt =
        NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

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
          onTap: isAdmin ? () => context.push('/servizi-pest/${s.id}') : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (s.isDraft) ...[
                      _buildBadgeBozza(),
                      const SizedBox(width: 8),
                    ],
                    if (s.tipoIntervento.isNotEmpty)
                      _buildBadgeTipo(s.tipoIntervento),
                    if (s.tipoIntervento.isNotEmpty &&
                        s.numeroIntervento.isNotEmpty)
                      const SizedBox(width: 8),
                    if (s.numeroIntervento.isNotEmpty)
                      Text(
                        s.numeroIntervento,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textOnDarkSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const Spacer(),
                    if (isAdmin)
                      const Icon(Icons.chevron_right,
                          color: AppColors.textOnDarkMuted, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.committente,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (s.codiceData.isNotEmpty) ...[
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textOnDarkSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatCodiceData(s.codiceData),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textOnDarkSecondary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (s.totaleDovuto > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF00A843).withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00A843)
                                  .withValues(alpha: 0.35),
                              width: 0.5),
                        ),
                        child: Text(
                          moneyFmt.format(s.totaleDovuto),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accentGreenDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
      List<ServizioPestModel> tutti,
      List<ServizioPestModel> filtrati,
      bool isAdmin) {
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
                  onPressed: () => context.push('/servizi-pest/nuovo'),
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
        FiltroServiziPest(
          aperto: _filtroAperto,
          statoFiltro: _filtro,
          servizi: tutti,
          onFiltroApplicato: (nuovoFiltro) {
            setState(() {
              _filtro = nuovoFiltro;
              _filtroAperto = false;
            });
          },
        ),
        FiltriAttiviRowPest(
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

  Widget _buildListaDesktop(List<ServizioPestModel> lista, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      itemCount: lista.length,
      itemBuilder: (_, i) => _buildCardPestDesktop(lista[i], isAdmin),
    );
  }

  Widget _buildCardPestDesktop(ServizioPestModel s, bool isAdmin) {
    final moneyFmt =
        NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);
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
            onTap: isAdmin ? () => context.push('/servizi-pest/${s.id}') : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.20),
                    child: Text(
                      _initials(s.committente),
                      style: const TextStyle(
                        color: AppColors.accentGreenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tipo + bozza badge + Committente
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (s.isDraft) ...[
                            _buildBadgeBozza(),
                            const SizedBox(width: 6),
                          ],
                          if (s.tipoIntervento.isNotEmpty)
                            Flexible(child: _buildBadgeTipo(s.tipoIntervento)),
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          s.committente,
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

                  // Data + Tecnico
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.calendar_today_outlined,
                            _formatCodiceData(s.codiceData)),
                        const SizedBox(height: 4),
                        _infoRow(Icons.person_outline,
                            s.tecnico.isNotEmpty ? s.tecnico : '—'),
                      ],
                    ),
                  ),

                  _separatoreV(),

                  // N° intervento + Totale
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.numeroIntervento.isNotEmpty)
                          _infoRow(Icons.tag_outlined, s.numeroIntervento,
                              label: 'N°'),
                        if (s.totaleDovuto > 0) ...[
                          const SizedBox(height: 4),
                          Container(
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
                              moneyFmt.format(s.totaleDovuto),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.accentGreenDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ] else
                          const Text('—',
                              style: TextStyle(
                                  color: AppColors.textOnDarkMuted,
                                  fontSize: 12)),
                      ],
                    ),
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

  // ─── WIDGET CONDIVISI ─────────────────────────────────────────────────────

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
              hintText: 'Cerca per committente, tipo, tecnico...',
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
                _filtroAperto ? Icons.filter_list_off : Icons.filter_list,
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

  Widget _buildBadgeTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00A843).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF00A843).withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        tipo,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.accentGreenDark,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
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
          const Icon(Icons.pest_control_outlined,
              size: 64, color: AppColors.textOnDarkMuted),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun servizio pest ancora'
                : 'Nessun risultato trovato',
            style: const TextStyle(
                fontSize: 15,
                color: AppColors.textOnDarkSecondary,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
