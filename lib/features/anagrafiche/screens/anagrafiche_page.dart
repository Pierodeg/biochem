import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/cliente_model.dart';
import '../../../widgets/filtri/filtro_anagrafica.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _clientiStreamProvider = StreamProvider<List<ClienteModel>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(clientiServiceProvider).getClienti();
});

// ─── Pagina principale ────────────────────────────────────────────────────────

class AnagrafichePage extends ConsumerStatefulWidget {
  const AnagrafichePage({super.key});

  @override
  ConsumerState<AnagrafichePage> createState() => _AnagrafichePageState();
}

class _AnagrafichePageState extends ConsumerState<AnagrafichePage> {
  final TextEditingController _cercaController = TextEditingController();
  String _queryRicerca = '';
  bool _filtroAperto = false;
  FiltroAnagraficaStato _filtro = const FiltroAnagraficaStato();

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  List<ClienteModel> _filtra(List<ClienteModel> clienti) {
    List<ClienteModel> risultato = clienti;
    if (_queryRicerca.isNotEmpty) {
      final q = _queryRicerca.toLowerCase();
      risultato = clienti.where((c) {
        return c.committente.toLowerCase().contains(q) ||
            c.citta.toLowerCase().contains(q) ||
            c.pivaCodiceFiscale.toLowerCase().contains(q);
      }).toList();
    }
    return applicaFiltroAnagrafica(risultato, _filtro);
  }

  @override
  Widget build(BuildContext context) {
    final clientiAsync = ref.watch(_clientiStreamProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        return clientiAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Text('Errore: $err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (clienti) {
            final filtrati = _filtra(clienti);
            final isAdmin =
                ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
            if (isDesktop) {
              return _buildDesktopLayout(clienti, filtrati, isAdmin);
            }
            return _buildMobileLayout(clienti, filtrati, isAdmin);
          },
        );
      },
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      List<ClienteModel> tutti, List<ClienteModel> filtrati, bool isAdmin) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            FiltroAnagrafica(
              aperto: _filtroAperto,
              statoFiltro: _filtro,
              clienti: tutti,
              onFiltroApplicato: (nuovoFiltro) {
                setState(() {
                  _filtro = nuovoFiltro;
                  _filtroAperto = false;
                });
              },
            ),
            FiltriAttiviRow(
              stato: _filtro,
              onRimosso: (nuovoFiltro) => setState(() => _filtro = nuovoFiltro),
            ),
            // Separatore sottile
            Container(
              height: 1,
              color: AppColors.glassBorder,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(
              child: filtrati.isEmpty
                  ? _buildStatoVuoto()
                  : ListView.builder(
                      padding:
                          EdgeInsets.fromLTRB(12, 12, 12, isAdmin ? 80 : 12),
                      itemCount: filtrati.length,
                      itemBuilder: (context, index) =>
                          _buildCardClienteMobile(filtrati[index]),
                    ),
            ),
          ],
        ),
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_anagrafiche',
              onPressed: () => context.push('/anagrafiche/nuovo'),
              backgroundColor: AppColors.primary.withValues(alpha: 0.85),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildCardClienteMobile(ClienteModel cliente) {
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
          onTap: () => context.push('/anagrafiche/${cliente.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.20),
                  child: Text(
                    cliente.initials,
                    style: const TextStyle(
                      color: AppColors.accentGreenDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cliente.numeroFormattato,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildBadgeTipo(cliente.tipoCommittente),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cliente.committente,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      if (cliente.citta.isNotEmpty)
                        Text(
                          cliente.citta,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textOnDarkSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      List<ClienteModel> tutti, List<ClienteModel> filtrati, bool isAdmin) {
    return Column(
      children: [
        // Barra ricerca — trasparente
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              SizedBox(width: 320, child: _buildBarraRicercaConFiltro()),
              const Spacer(),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push('/anagrafiche/nuovo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuovo cliente'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.30),
                    foregroundColor: AppColors.accentGreenDark,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.50),
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
        // Filtro — trasparente
        FiltroAnagrafica(
          aperto: _filtroAperto,
          statoFiltro: _filtro,
          clienti: tutti,
          onFiltroApplicato: (nuovoFiltro) {
            setState(() {
              _filtro = nuovoFiltro;
              _filtroAperto = false;
            });
          },
        ),
        FiltriAttiviRow(
          stato: _filtro,
          onRimosso: (nuovoFiltro) => setState(() => _filtro = nuovoFiltro),
        ),
        // Separatore sottile
        Container(
          height: 1,
          color: AppColors.glassBorder,
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        Expanded(
          child: filtrati.isEmpty
              ? _buildStatoVuoto()
              : _buildListaDesktop(filtrati),
        ),
      ],
    );
  }

  Widget _buildListaDesktop(List<ClienteModel> clienti) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      itemCount: clienti.length,
      itemBuilder: (_, i) => _buildCardClienteDesktop(clienti[i]),
    );
  }

  Widget _buildCardClienteDesktop(ClienteModel cliente) {
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
            onTap: () => context.push('/anagrafiche/${cliente.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.20),
                    child: Text(
                      cliente.initials,
                      style: const TextStyle(
                        color: AppColors.accentGreenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Numero + Nome + Badge
                  SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            cliente.numeroFormattato,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textOnDarkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildBadgeTipo(cliente.tipoCommittente),
                        ]),
                        const SizedBox(height: 3),
                        Text(
                          cliente.committente,
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

                  // Indirizzo + Città
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                            Icons.location_on_outlined,
                            cliente.indirizzo.isNotEmpty
                                ? cliente.indirizzo
                                : '—'),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.place_outlined,
                          '${cliente.citta.isNotEmpty ? cliente.citta : '—'}'
                          '${cliente.provincia.isNotEmpty ? ' (${cliente.provincia})' : ''}',
                        ),
                      ],
                    ),
                  ),

                  _separatoreV(),

                  // P.IVA + Codice univoco
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          Icons.badge_outlined,
                          cliente.pivaCodiceFiscale.isNotEmpty
                              ? cliente.pivaCodiceFiscale
                              : '—',
                          label: 'P.IVA',
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.tag_outlined,
                          cliente.codiceUnivoco.isNotEmpty
                              ? cliente.codiceUnivoco
                              : '—',
                          label: 'CU',
                        ),
                      ],
                    ),
                  ),

                  _separatoreV(),

                  // Telefono + Referente
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          Icons.phone_outlined,
                          cliente.telefono.isNotEmpty ? cliente.telefono : '—',
                        ),
                        const SizedBox(height: 4),
                        _infoRow(
                          Icons.person_outline,
                          cliente.referente.isNotEmpty
                              ? cliente.referente
                              : '—',
                        ),
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
              fontSize: 10,
              color: AppColors.textOnDarkMuted,
            ),
          ),
        Expanded(
          child: Text(
            testo,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textOnDarkSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
              hintText: 'Cerca per nome, città, P.IVA...',
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
              onPressed: () => setState(() => _filtroAperto = !_filtroAperto),
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
    if (tipo.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF00A843).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00A843).withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Text(
        tipo,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.accentGreenDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline,
              size: 64, color: AppColors.textOnDarkMuted),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun cliente ancora'
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
