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

/// Pagina Servizi Pest — lista con ricerca, filtri avanzati e form (solo admin)
///
/// Questa pagina è incorporata nell'IndexedStack di [MainScreen] (tab 3)
/// e NON ha un proprio Scaffold.
class ServiziPestPage extends ConsumerStatefulWidget {
  const ServiziPestPage({super.key});

  @override
  ConsumerState<ServiziPestPage> createState() => _ServiziPestPageState();
}

class _ServiziPestPageState extends ConsumerState<ServiziPestPage> {
  final _cercaController = TextEditingController();
  String _queryRicerca = '';

  // Stato filtro
  bool _filtroAperto = false;
  FiltroServiziPestStato _filtro = const FiltroServiziPestStato();

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  /// Applica ricerca testuale + filtri avanzati + ordinamento
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

  /// Formatta il codice data AAMMGG in GG/MM/AA per la visualizzazione
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
            // Barra di ricerca con bottone filtri
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            // Pannello filtri animato
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
            // Riga chip filtri attivi
            FiltriAttiviRowPest(
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
              heroTag: 'fab_servizi_pest',
              onPressed: () => context.push('/servizi-pest/nuovo'),
              backgroundColor: AppColors.fabBackground,
              child: const Icon(Icons.add, color: AppColors.fabIcon),
            ),
          ),
      ],
    );
  }

  Widget _buildCardServizio(ServizioPestModel s, bool isAdmin) {
    final moneyFmt =
        NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

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
            ? () => context.push('/servizi-pest/${s.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prima riga: tipo intervento + n° intervento
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
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
              // Data + totale
              Row(
                children: [
                  if (s.codiceData.isNotEmpty) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.textDisabled),
                    const SizedBox(width: 4),
                    Text(
                      _formatCodiceData(s.codiceData),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (s.totaleDovuto > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        moneyFmt.format(s.totaleDovuto),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
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
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      List<ServizioPestModel> tutti,
      List<ServizioPestModel> filtrati,
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
                  onPressed: () => context.push('/servizi-pest/nuovo'),
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
        // Riga chip filtri attivi
        FiltriAttiviRowPest(
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

  Widget _buildTabella(List<ServizioPestModel> servizi, bool isAdmin) {
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
            const DataColumn(label: Text('Tipo')),
            const DataColumn(label: Text('N° interv.')),
            const DataColumn(label: Text('Committente')),
            const DataColumn(label: Text('Data')),
            const DataColumn(label: Text('Tecnico')),
            const DataColumn(label: Text('Totale dovuto')),
            if (isAdmin) const DataColumn(label: Text('')),
          ],
          rows: servizi.map((s) => _buildRigaTabella(s, isAdmin)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRigaTabella(ServizioPestModel s, bool isAdmin) {
    void apri() => context.push('/servizi-pest/${s.id}');
    final moneyFmt =
        NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              if (s.isDraft) ...[
                _buildBadgeBozza(),
                const SizedBox(width: 6),
              ],
              if (s.tipoIntervento.isNotEmpty) _buildBadgeTipo(s.tipoIntervento),
            ],
          ),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(s.numeroIntervento,
              style: const TextStyle(color: AppColors.textSecondary)),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(s.committente,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(
            _formatCodiceData(s.codiceData),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(s.tecnico,
              style: const TextStyle(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis),
          onTap: isAdmin ? apri : null,
        ),
        DataCell(
          Text(
            s.totaleDovuto > 0 ? moneyFmt.format(s.totaleDovuto) : '—',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          onTap: isAdmin ? apri : null,
        ),
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
              hintText: 'Cerca per committente, tipo, tecnico...',
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

  Widget _buildBadgeTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
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

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pest_control_outlined,
              size: 64,
              color: AppColors.textDisabled.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun servizio pest ancora'
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
