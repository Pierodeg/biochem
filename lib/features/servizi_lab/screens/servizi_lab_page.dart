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

/// Pagina Reg Lab — lista con ricerca, filtri avanzati e accesso al form (solo admin)
///
/// Questa pagina è incorporata nell'IndexedStack di [MainScreen] (tab 2)
/// e NON ha un proprio Scaffold.
class ServiziLabPage extends ConsumerStatefulWidget {
  const ServiziLabPage({super.key});

  @override
  ConsumerState<ServiziLabPage> createState() => _ServiziLabPageState();
}

class _ServiziLabPageState extends ConsumerState<ServiziLabPage> {
  final _cercaController = TextEditingController();
  String _queryRicerca = '';

  // Stato filtro
  bool _filtroAperto = false;
  FiltroRegLabStato _filtro = const FiltroRegLabStato();

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  /// Applica ricerca testuale + filtri avanzati
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
            // Barra di ricerca con bottone filtri
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            // Pannello filtri animato
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
            // Riga chip filtri attivi
            FiltriAttiviRowRegLab(
              stato: _filtro,
              onRimosso: (f) => setState(() => _filtro = f),
            ),
            // Lista servizi
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
        // FAB visibile solo agli admin
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_servizi_lab',
              onPressed: () => context.push('/servizi-lab/nuovo'),
              backgroundColor: AppColors.fabBackground,
              child: const Icon(Icons.add, color: AppColors.fabIcon),
            ),
          ),
      ],
    );
  }

  Widget _buildCardServizio(ServizioLabModel s, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isAdmin
            ? () => context.push('/servizi-lab/${s.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prima riga: certificazione + badge analisi
              Row(
                children: [
                  Text(
                    s.certificazioneNumerica,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary,
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
                        color: AppColors.textDisabled, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              // Committente
              Text(
                s.committente,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // Data + badge FT + badge pagata
              Row(
                children: [
                  if (s.dataEmissione != null) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textDisabled),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(s.dataEmissione!),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
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
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      List<ServizioLabModel> tutti,
      List<ServizioLabModel> filtrati,
      bool isAdmin) {
    return Column(
      children: [
        // Barra azioni
        Container(
          color: AppColors.surface,
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
                    backgroundColor: AppColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
        // Pannello filtri
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
        // Riga chip filtri attivi
        FiltriAttiviRowRegLab(
          stato: _filtro,
          onRimosso: (f) => setState(() => _filtro = f),
        ),
        const Divider(height: 1, color: AppColors.divider),
        // Tabella
        Expanded(
          child: filtrati.isEmpty
              ? _buildStatoVuoto()
              : _buildTabella(filtrati, isAdmin),
        ),
      ],
    );
  }

  Widget _buildTabella(List<ServizioLabModel> servizi, bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppColors.tableHeader),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          columnSpacing: 20,
          columns: [
            const DataColumn(label: Text('Certificazione')),
            const DataColumn(label: Text('Committente')),
            const DataColumn(label: Text('Analisi')),
            const DataColumn(label: Text('Inizio prove')),
            const DataColumn(label: Text('Emissione')),
            const DataColumn(label: Text('FT')),
            const DataColumn(label: Text('Pagata')),
            if (isAdmin) const DataColumn(label: Text('')),
          ],
          rows: servizi.map((s) => _buildRigaTabella(s, isAdmin)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRigaTabella(ServizioLabModel s, bool isAdmin) {
    void apri() => context.push('/servizi-lab/${s.id}');
    final formatter = DateFormat('dd/MM/yy');

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Text(
                s.certificazioneNumerica,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (s.isDraft) ...[
                const SizedBox(width: 8),
                _buildBadgeBozza(),
              ],
            ],
          ),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(s.committente,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          s.tipoAnalisi.isNotEmpty
              ? _buildBadgeAnalisi(s.tipoAnalisi)
              : const SizedBox.shrink(),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(formatter.format(s.inizioProveGenerali),
              style: const TextStyle(color: AppColors.textSecondary)),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(
            s.dataEmissione != null
                ? formatter.format(s.dataEmissione!)
                : '—',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(_buildBadgeFt(s.ft), onTap: isAdmin ? apri : null),
        DataCell(_buildBadgePagata(s.fatturaPagata),
            onTap: isAdmin ? apri : null),
        if (isAdmin)
          DataCell(
            TextButton(
              onPressed: apri,
              child: const Text('Apri'),
            ),
          ),
      ],
    );
  }

  // ─── WIDGET CONDIVISI ─────────────────────────────────────────────────────

  /// Campo ricerca con bottone filtri e badge contatore
  Widget _buildBarraRicercaConFiltro() {
    final filtriAttivi = _filtro.filtriAttivi;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cercaController,
            onChanged: (v) => setState(() => _queryRicerca = v.trim()),
            decoration: InputDecoration(
              hintText: 'Cerca per committente, analisi, cert...',
              prefixIcon:
                  const Icon(Icons.search, size: 20, color: AppColors.textDisabled),
              suffixIcon: _queryRicerca.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _cercaController.clear();
                        setState(() => _queryRicerca = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
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
                    ? AppColors.primary
                    : AppColors.textSecondary,
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
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipoAnalisi,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
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
        color: AppColors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
        ),
      ),
      child: const Text(
        'Bozza',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBadgeFt(bool ft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ft
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: ft ? AppColors.success : AppColors.divider),
      ),
      child: Text(
        'FT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ft ? AppColors.success : AppColors.textDisabled,
        ),
      ),
    );
  }

  Widget _buildBadgePagata(bool pagata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: pagata
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: pagata ? AppColors.success : AppColors.error),
      ),
      child: Text(
        pagata ? 'Pagata' : 'Non pagata',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: pagata ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_outlined,
              size: 64,
              color: AppColors.textDisabled.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun servizio lab ancora'
                : 'Nessun risultato trovato',
            style: const TextStyle(
                fontSize: 15,
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
