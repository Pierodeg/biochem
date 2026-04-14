import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../models/cliente_model.dart';

/// Opzioni di ordinamento per la lista clienti
enum OrdinamentoAnagrafica {
  numeroCliente('↑ N° cliente'),
  nomeAZ('A→Z Nome'),
  cittaAZ('A→Z Città'),
  tipoAZ('A→Z Tipo committente');

  final String etichetta;
  const OrdinamentoAnagrafica(this.etichetta);
}

/// Stato immutabile del filtro anagrafica
class FiltroAnagraficaStato {
  final List<String> tipiSelezionati;
  final List<String> cittaSelezionate;
  final List<String> provinceSelezionate;
  final OrdinamentoAnagrafica ordinamento;

  const FiltroAnagraficaStato({
    this.tipiSelezionati = const [],
    this.cittaSelezionate = const [],
    this.provinceSelezionate = const [],
    this.ordinamento = OrdinamentoAnagrafica.numeroCliente,
  });

  /// Numero totale di filtri attivi (esclude ordinamento default)
  int get filtriAttivi =>
      tipiSelezionati.length +
      cittaSelezionate.length +
      provinceSelezionate.length +
      (ordinamento != OrdinamentoAnagrafica.numeroCliente ? 1 : 0);

  bool get hasFiltri => filtriAttivi > 0;

  FiltroAnagraficaStato copyWith({
    List<String>? tipiSelezionati,
    List<String>? cittaSelezionate,
    List<String>? provinceSelezionate,
    OrdinamentoAnagrafica? ordinamento,
  }) {
    return FiltroAnagraficaStato(
      tipiSelezionati: tipiSelezionati ?? this.tipiSelezionati,
      cittaSelezionate: cittaSelezionate ?? this.cittaSelezionate,
      provinceSelezionate: provinceSelezionate ?? this.provinceSelezionate,
      ordinamento: ordinamento ?? this.ordinamento,
    );
  }

  FiltroAnagraficaStato reset() => const FiltroAnagraficaStato();
}

/// Province sarde disponibili come filtro
const _provinceSarde = ['SS', 'CA', 'NU', 'OR', 'SU', 'OT', 'OG', 'VS'];

/// Widget filtro per la pagina Anagrafiche.
///
/// Si apre/chiude con animazione verticale (altezza 0 → altezza contenuto).
/// Posizionato tra la search bar e la lista clienti come AnimatedContainer
/// nel layout Column — non usa overlay.
///
/// Uso:
/// ```dart
/// FiltroAnagrafica(
///   statoFiltro: _filtro,
///   clienti: clienti,
///   onFiltroApplicato: (nuovoStato) => setState(() => _filtro = nuovoStato),
/// )
/// ```
class FiltroAnagrafica extends ConsumerStatefulWidget {
  /// Stato corrente del filtro (controllato dall'esterno)
  final FiltroAnagraficaStato statoFiltro;

  /// Lista completa dei clienti (per estrarre le città distinte)
  final List<ClienteModel> clienti;

  /// Callback chiamato quando l'utente preme "Applica"
  final ValueChanged<FiltroAnagraficaStato> onFiltroApplicato;

  /// Se true il pannello è aperto
  final bool aperto;

  const FiltroAnagrafica({
    super.key,
    required this.statoFiltro,
    required this.clienti,
    required this.onFiltroApplicato,
    required this.aperto,
  });

  @override
  ConsumerState<FiltroAnagrafica> createState() => _FiltroAnagraficaState();
}

class _FiltroAnagraficaState extends ConsumerState<FiltroAnagrafica>
    with SingleTickerProviderStateMixin {
  // Stato locale (bozza) — viene applicato solo al pressione di "Applica"
  late FiltroAnagraficaStato _bozza;

  // Se le città sono espanse (oltre le prime 6)
  bool _cittaEspanse = false;

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
  }

  @override
  void didUpdateWidget(FiltroAnagrafica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statoFiltro != widget.statoFiltro) {
      _bozza = widget.statoFiltro;
    }
  }

  // ─── Calcoli derivati ──────────────────────────────────────────────────────

  /// Lista dei tipi committente distinti caricati da Firestore
  Future<List<String>> _getTipiCommittente() async {
    final service = ref.read(impostazioniServiceProvider);
    final items = await service.getItems('tipi_committente').first;
    return items;
  }

  /// Città distinte presenti nei clienti, ordinate A→Z
  List<String> get _cittaDisponibili {
    final citta = widget.clienti
        .map((c) => c.citta.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return citta;
  }

  // ─── Toggle chip ──────────────────────────────────────────────────────────

  void _toggleTipo(String tipo) {
    final lista = List<String>.from(_bozza.tipiSelezionati);
    lista.contains(tipo) ? lista.remove(tipo) : lista.add(tipo);
    setState(() => _bozza = _bozza.copyWith(tipiSelezionati: lista));
  }

  void _toggleCitta(String citta) {
    final lista = List<String>.from(_bozza.cittaSelezionate);
    lista.contains(citta) ? lista.remove(citta) : lista.add(citta);
    setState(() => _bozza = _bozza.copyWith(cittaSelezionate: lista));
  }

  void _toggleProvincia(String prov) {
    final lista = List<String>.from(_bozza.provinceSelezionate);
    lista.contains(prov) ? lista.remove(prov) : lista.add(prov);
    setState(() => _bozza = _bozza.copyWith(provinceSelezionate: lista));
  }

  void _azzera() {
    setState(() {
      _bozza = const FiltroAnagraficaStato();
      _cittaEspanse = false;
    });
    widget.onFiltroApplicato(const FiltroAnagraficaStato());
  }

  void _applica() => widget.onFiltroApplicato(_bozza);

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.aperto ? null : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: widget.aperto ? _buildContenuto() : const SizedBox.shrink(),
    );
  }

  Widget _buildContenuto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tipi committente
          _buildSezioneTitolo('Tipo committente'),
          const SizedBox(height: 6),
          FutureBuilder<List<String>>(
            future: _getTipiCommittente(),
            builder: (context, snap) {
              final tipi = snap.data ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tipi
                    .map((t) => _buildChip(
                          label: t,
                          selezionato: _bozza.tipiSelezionati.contains(t),
                          onTap: () => _toggleTipo(t),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Città
          _buildSezioneTitolo('Città'),
          const SizedBox(height: 6),
          _buildChipCitta(),
          const SizedBox(height: 12),

          // Province
          _buildSezioneTitolo('Provincia'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _provinceSarde
                .map((p) => _buildChip(
                      label: p,
                      selezionato: _bozza.provinceSelezionate.contains(p),
                      onTap: () => _toggleProvincia(p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Ordina per
          _buildSezioneTitolo('Ordina per'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: OrdinamentoAnagrafica.values
                .map((o) => _buildChip(
                      label: o.etichetta,
                      selezionato: _bozza.ordinamento == o,
                      onTap: () => setState(
                          () => _bozza = _bozza.copyWith(ordinamento: o)),
                      monoSelezione: true,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Riga bottoni
          Row(
            children: [
              // Azzera
              TextButton.icon(
                onPressed: _azzera,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('✕ Azzera tutto'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
              const Spacer(),
              // Contatore filtri attivi
              if (_bozza.filtriAttivi > 0)
                Text(
                  '${_bozza.filtriAttivi} ${_bozza.filtriAttivi == 1 ? 'filtro attivo' : 'filtri attivi'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 12),
              // Applica
              FilledButton(
                onPressed: _applica,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: const Text('Applica'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildChipCitta() {
    final tutte = _cittaDisponibili;
    final visibili = _cittaEspanse || tutte.length <= 6
        ? tutte
        : tutte.take(6).toList();
    final rimanenti = tutte.length - 6;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...visibili.map((c) => _buildChip(
              label: c,
              selezionato: _bozza.cittaSelezionate.contains(c),
              onTap: () => _toggleCitta(c),
            )),
        if (!_cittaEspanse && rimanenti > 0)
          ActionChip(
            label: Text('+ altre $rimanenti',
                style: const TextStyle(fontSize: 12)),
            backgroundColor: AppColors.inputBackground,
            onPressed: () => setState(() => _cittaEspanse = true),
          ),
      ],
    );
  }

  Widget _buildSezioneTitolo(String titolo) {
    return Text(
      titolo,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selezionato,
    required VoidCallback onTap,
    bool monoSelezione = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selezionato
              ? AppColors.primary
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selezionato ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selezionato
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Riga chip filtri attivi ───────────────────────────────────────────────────

/// Riga di chip verdi che mostra i filtri attivi con bottone di rimozione.
/// Visibile solo quando ci sono filtri attivi.
class FiltriAttiviRow extends StatelessWidget {
  final FiltroAnagraficaStato stato;
  final ValueChanged<FiltroAnagraficaStato> onRimosso;

  const FiltriAttiviRow({
    super.key,
    required this.stato,
    required this.onRimosso,
  });

  @override
  Widget build(BuildContext context) {
    if (!stato.hasFiltri) return const SizedBox.shrink();

    final chips = <_ChipAttivo>[];

    for (final tipo in stato.tipiSelezionati) {
      chips.add(_ChipAttivo(
        label: tipo,
        onRimovi: () => onRimosso(stato.copyWith(
            tipiSelezionati: stato.tipiSelezionati
                .where((t) => t != tipo)
                .toList())),
      ));
    }
    for (final citta in stato.cittaSelezionate) {
      chips.add(_ChipAttivo(
        label: citta,
        onRimovi: () => onRimosso(stato.copyWith(
            cittaSelezionate: stato.cittaSelezionate
                .where((c) => c != citta)
                .toList())),
      ));
    }
    for (final prov in stato.provinceSelezionate) {
      chips.add(_ChipAttivo(
        label: prov,
        onRimovi: () => onRimosso(stato.copyWith(
            provinceSelezionate: stato.provinceSelezionate
                .where((p) => p != prov)
                .toList())),
      ));
    }
    if (stato.ordinamento != OrdinamentoAnagrafica.numeroCliente) {
      chips.add(_ChipAttivo(
        label: stato.ordinamento.etichetta,
        onRimovi: () =>
            onRimosso(stato.copyWith(
                ordinamento: OrdinamentoAnagrafica.numeroCliente)),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.successLight,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips,
      ),
    );
  }
}

class _ChipAttivo extends StatelessWidget {
  final String label;
  final VoidCallback onRimovi;

  const _ChipAttivo({required this.label, required this.onRimovi});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.badgeGreenText,
              fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.badgeGreenBackground,
      side: const BorderSide(color: AppColors.success),
      deleteIcon:
          const Icon(Icons.close, size: 14, color: AppColors.badgeGreenText),
      onDeleted: onRimovi,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Utility: applica filtro e ordinamento a una lista clienti ────────────────

/// Applica [filtro] a [clienti] e restituisce la lista ordinata.
List<ClienteModel> applicaFiltroAnagrafica(
    List<ClienteModel> clienti, FiltroAnagraficaStato filtro) {
  var risultato = clienti.where((c) {
    // Filtro tipo committente
    if (filtro.tipiSelezionati.isNotEmpty &&
        !filtro.tipiSelezionati.contains(c.tipoCommittente)) {
      return false;
    }
    // Filtro città
    if (filtro.cittaSelezionate.isNotEmpty &&
        !filtro.cittaSelezionate.contains(c.citta.trim())) {
      return false;
    }
    // Filtro provincia
    if (filtro.provinceSelezionate.isNotEmpty &&
        !filtro.provinceSelezionate.contains(c.provincia.trim().toUpperCase())) {
      return false;
    }
    return true;
  }).toList();

  // Ordinamento
  switch (filtro.ordinamento) {
    case OrdinamentoAnagrafica.numeroCliente:
      risultato.sort((a, b) => a.numeroCliente.compareTo(b.numeroCliente));
    case OrdinamentoAnagrafica.nomeAZ:
      risultato.sort((a, b) =>
          a.committente.toLowerCase().compareTo(b.committente.toLowerCase()));
    case OrdinamentoAnagrafica.cittaAZ:
      risultato.sort(
          (a, b) => a.citta.toLowerCase().compareTo(b.citta.toLowerCase()));
    case OrdinamentoAnagrafica.tipoAZ:
      risultato.sort((a, b) => a.tipoCommittente
          .toLowerCase()
          .compareTo(b.tipoCommittente.toLowerCase()));
  }

  return risultato;
}
