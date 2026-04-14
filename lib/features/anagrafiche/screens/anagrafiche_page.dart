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
  // Dipende dall'auth: quando il token cambia (login/logout) il provider
  // si ricrea con una connessione Firestore fresca, evitando permission-denied
  // dovuti alla propagazione ritardata del token dopo il sign-in.
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(clientiServiceProvider).getClienti();
});

// ─── Pagina principale ────────────────────────────────────────────────────────

/// Pagina Anagrafiche con lista/tabella clienti, ricerca e filtri avanzati
class AnagrafichePage extends ConsumerStatefulWidget {
  const AnagrafichePage({super.key});

  @override
  ConsumerState<AnagrafichePage> createState() => _AnagrafichePageState();
}

class _AnagrafichePageState extends ConsumerState<AnagrafichePage> {
  final TextEditingController _cercaController = TextEditingController();
  String _queryRicerca = '';

  // Stato del pannello filtro
  bool _filtroAperto = false;
  FiltroAnagraficaStato _filtro = const FiltroAnagraficaStato();

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  /// Filtra la lista clienti in base a testo di ricerca e filtri avanzati
  List<ClienteModel> _filtra(List<ClienteModel> clienti) {
    // Prima applica la ricerca testuale
    List<ClienteModel> risultato = clienti;
    if (_queryRicerca.isNotEmpty) {
      final q = _queryRicerca.toLowerCase();
      risultato = clienti.where((c) {
        return c.committente.toLowerCase().contains(q) ||
            c.citta.toLowerCase().contains(q) ||
            c.pivaCodiceFiscale.toLowerCase().contains(q);
      }).toList();
    }
    // Poi applica i filtri avanzati e l'ordinamento
    return applicaFiltroAnagrafica(risultato, _filtro);
  }

  @override
  Widget build(BuildContext context) {
    final clientiAsync = ref.watch(_clientiStreamProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        return clientiAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
      List<ClienteModel> tutti,
      List<ClienteModel> filtrati,
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
            // Pannello filtri animato (tra search bar e lista)
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
            // Riga chip filtri attivi
            FiltriAttiviRow(
              stato: _filtro,
              onRimosso: (nuovoFiltro) =>
                  setState(() => _filtro = nuovoFiltro),
            ),
            // Lista clienti
            Expanded(
              child: filtrati.isEmpty
                  ? _buildStatoVuoto()
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, isAdmin ? 80 : 12),
                      itemCount: filtrati.length,
                      itemBuilder: (context, index) =>
                          _buildCardCliente(filtrati[index]),
                    ),
            ),
          ],
        ),
        // FAB per aggiungere nuovo cliente (solo admin)
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => context.push('/anagrafiche/nuovo'),
              backgroundColor: AppColors.fabBackground,
              child: const Icon(Icons.add, color: AppColors.fabIcon),
            ),
          ),
      ],
    );
  }

  Widget _buildCardCliente(ClienteModel cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/anagrafiche/${cliente.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar con iniziali
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                child: Text(
                  cliente.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info cliente
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
                            color: AppColors.textDisabled,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBadgeTipo(cliente.tipoCommittente),
                        if (cliente.isDraft) ...[
                          const SizedBox(width: 6),
                          _buildBadgeBozza(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cliente.committente,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (cliente.citta.isNotEmpty)
                      Text(
                        cliente.citta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      List<ClienteModel> tutti,
      List<ClienteModel> filtrati,
      bool isAdmin) {
    return Column(
      children: [
        // Barra azioni: ricerca, filtri e bottone nuovo cliente
        Container(
          color: AppColors.surface,
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
                    backgroundColor: AppColors.buttonPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
        // Pannello filtri animato
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
        // Riga chip filtri attivi
        FiltriAttiviRow(
          stato: _filtro,
          onRimosso: (nuovoFiltro) =>
              setState(() => _filtro = nuovoFiltro),
        ),
        const Divider(height: 1, color: AppColors.divider),
        // Tabella clienti
        Expanded(
          child: filtrati.isEmpty
              ? _buildStatoVuoto()
              : _buildTabella(filtrati),
        ),
      ],
    );
  }

  Widget _buildTabella(List<ClienteModel> clienti) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('N°')),
            DataColumn(label: Text('Committente')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Indirizzo')),
            DataColumn(label: Text('Città')),
            DataColumn(label: Text('Prov.')),
            DataColumn(label: Text('P.IVA / C.F.')),
            DataColumn(label: Text('Telefono')),
            DataColumn(label: Text('')),
          ],
          rows: clienti.map((c) => _buildRigaTabella(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRigaTabella(ClienteModel cliente) {
    void apri() => context.push('/anagrafiche/${cliente.id}');
    return DataRow(
      cells: [
        DataCell(Text(cliente.numeroFormattato,
            style: const TextStyle(
                color: AppColors.textDisabled, fontWeight: FontWeight.w500)),
            onTap: apri),
        DataCell(Text(cliente.committente,
            style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: apri),
        DataCell(
          Row(children: [
            _buildBadgeTipo(cliente.tipoCommittente),
            if (cliente.isDraft) ...[
              const SizedBox(width: 6),
              _buildBadgeBozza(),
            ],
          ]),
          onTap: apri,
        ),
        DataCell(Text(cliente.indirizzo,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary)),
            onTap: apri),
        DataCell(Text(cliente.citta,
            style: const TextStyle(color: AppColors.textSecondary)),
            onTap: apri),
        DataCell(Text(cliente.provincia,
            style: const TextStyle(color: AppColors.textSecondary)),
            onTap: apri),
        DataCell(Text(cliente.pivaCodiceFiscale,
            style: const TextStyle(color: AppColors.textSecondary)),
            onTap: apri),
        DataCell(Text(cliente.telefono,
            style: const TextStyle(color: AppColors.textSecondary)),
            onTap: apri),
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

  /// Campo ricerca con bottone "Filtri" e badge filtri attivi
  Widget _buildBarraRicercaConFiltro() {
    final filtriAttivi = _filtro.filtriAttivi;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cercaController,
            onChanged: (v) => setState(() => _queryRicerca = v.trim()),
            decoration: InputDecoration(
              hintText: 'Cerca per nome, città, P.IVA...',
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textDisabled),
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
        // Bottone filtri con badge
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

  Widget _buildBadgeBozza() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Bozza',
        style: TextStyle(
          fontSize: 10,
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadgeTipo(String tipo) {
    if (tipo.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.badgeGreenBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.badgeGreenText,
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
          Icon(Icons.people_outline,
              size: 64,
              color: AppColors.textDisabled.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun cliente ancora'
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
