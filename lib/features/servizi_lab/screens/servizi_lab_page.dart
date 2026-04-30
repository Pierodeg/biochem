import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/servizio_lab_model.dart';
import '../../../widgets/filtri/filtro_reg_lab.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _serviziLabStreamProvider =
    StreamProvider<List<ServizioLabModel>>((ref) {
  // Dipende dall'auth: si ricrea con token fresco dopo ogni sign-in
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(serviziLabServiceProvider).getServiziLab();
});

// ─── Pagina lista Reg Lab ─────────────────────────────────────────────────────

class ServiziLabPage extends ConsumerStatefulWidget {
  const ServiziLabPage({super.key});

  @override
  ConsumerState<ServiziLabPage> createState() => _ServiziLabPageState();
}

class _ServiziLabPageState extends ConsumerState<ServiziLabPage> {
  final _cercaController = TextEditingController();
  String _queryRicerca = '';

  bool _filtroAperto = false;
  FiltroRegLabStato _filtro = const FiltroRegLabStato();

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  List<ServizioLabModel> _filtra(List<ServizioLabModel> lista) {
    List<ServizioLabModel> risultato = lista;
    if (_queryRicerca.isNotEmpty) {
      final q = _queryRicerca.toLowerCase();
      risultato = lista.where((s) {
        return s.committente.toLowerCase().contains(q) ||
            s.tipoAnalisi.toLowerCase().contains(q) ||
            s.certificazioneNumerica.toLowerCase().contains(q);
      }).toList();
    }
    return applicaFiltroRegLab(risultato, _filtro);
  }

  @override
  Widget build(BuildContext context) {
    final serviziAsync = ref.watch(_serviziLabStreamProvider);
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
      List<ServizioLabModel> tutti,
      List<ServizioLabModel> filtrati,
      bool isAdmin) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            FiltroRegLab(
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
            FiltriAttiviRowRegLab(
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
              heroTag: 'fab_servizi_lab',
              onPressed: () => context.push('/servizi-lab/nuovo'),
              backgroundColor: AppColors.primary.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildCardServizio(ServizioLabModel s, bool isAdmin) {
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
          onTap: isAdmin ? () => context.push('/servizi-lab/${s.id}') : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.certificazioneNumerica,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.accentGreenDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (s.isDraft) ...[
                      _buildBadgeBozza(),
                      const SizedBox(width: 8),
                    ],
                    if (s.tipoAnalisi.isNotEmpty)
                      _buildBadgeAnalisi(s.tipoAnalisi),
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
                    if (s.dataEmissione != null) ...[
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textOnDarkSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(s.dataEmissione!),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textOnDarkSecondary),
                      ),
                      const SizedBox(width: 10),
                    ],
                    _buildBadgeFt(s.ft),
                    const SizedBox(width: 6),
                    _buildBadgePagata(s.fatturaPagata),
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
      List<ServizioLabModel> tutti,
      List<ServizioLabModel> filtrati,
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
                  onPressed: () => context.push('/servizi-lab/nuovo'),
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
        FiltroRegLab(
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
        FiltriAttiviRowRegLab(
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

  Widget _buildListaDesktop(List<ServizioLabModel> lista, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      itemCount: lista.length,
      itemBuilder: (_, i) => _buildCardLabDesktop(lista[i], isAdmin),
    );
  }

  Widget _buildCardLabDesktop(ServizioLabModel s, bool isAdmin) {
    final formatter = DateFormat('dd/MM/yy');
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
            onTap: isAdmin ? () => context.push('/servizi-lab/${s.id}') : null,
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

                  // Certificazione + bozza + Committente
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            s.certificazioneNumerica,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreenDark,
                            ),
                          ),
                          if (s.isDraft) ...[
                            const SizedBox(width: 6),
                            _buildBadgeBozza(),
                          ],
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

                  // Analisi + inizio prove
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.tipoAnalisi.isNotEmpty)
                          _buildBadgeAnalisi(s.tipoAnalisi),
                        const SizedBox(height: 4),
                        _infoRow(Icons.science_outlined,
                            formatter.format(s.inizioProveGenerali),
                            label: 'Inizio'),
                      ],
                    ),
                  ),

                  _separatoreV(),

                  // Emissione + FT + Pagata
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          Icons.calendar_today_outlined,
                          s.dataEmissione != null
                              ? formatter.format(s.dataEmissione!)
                              : '—',
                          label: 'Emiss.',
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          _buildBadgeFt(s.ft),
                          const SizedBox(width: 6),
                          _buildBadgePagata(s.fatturaPagata),
                        ]),
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
              hintText: 'Cerca per committente, analisi, cert...',
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

  Widget _buildBadgeAnalisi(String tipoAnalisi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00A843).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF00A843).withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        tipoAnalisi,
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

  Widget _buildBadgeFt(bool ft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ft
            ? const Color(0xFF00A843).withValues(alpha: 0.20)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ft
              ? const Color(0xFF00A843).withValues(alpha: 0.35)
              : AppColors.glassBorderSubtle,
          width: 0.5,
        ),
      ),
      child: Text(
        'FT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ft ? AppColors.accentGreenDark : AppColors.textOnDarkMuted,
        ),
      ),
    );
  }

  Widget _buildBadgePagata(bool pagata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pagata
            ? const Color(0xFF00A843).withValues(alpha: 0.20)
            : const Color(0xFFD32F2F).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pagata
              ? const Color(0xFF00A843).withValues(alpha: 0.35)
              : const Color(0xFFD32F2F).withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Text(
        pagata ? 'Pagata' : 'Non pagata',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: pagata ? AppColors.accentGreenDark : const Color(0xFFFF7070),
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.biotech_outlined,
              size: 64, color: AppColors.textOnDarkMuted),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun servizio lab ancora'
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
