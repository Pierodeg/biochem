import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/categoria_model.dart';
import '../../../models/listino_model.dart';
import '../../../services/impostazioni_service.dart';
import '../../../services/listino_service.dart';

// NOTA: Documenti Firestore da creare per Servizi Pest (se non esistono):
//   impostazioni/pest_tipi_intervento       → { nome: "Tipi intervento Pest", hasSottocategorie: false, items: [] }
//   impostazioni/pest_numero_intervento     → { nome: "N° intervento Pest",   hasSottocategorie: false, items: [] }
//   impostazioni/pest_tecnici              → { nome: "Tecnici Pest",          hasSottocategorie: false, items: [] }
//   impostazioni/pest_prodotti             → { nome: "Prodotti Pest",         hasSottocategorie: false, items: [] }
//   impostazioni/pest_ulteriori_interventi  → { nome: "Ulteriori interventi Pest", hasSottocategorie: false, items: [] }
//   impostazioni/pest_voci_economiche       → { nome: "Voci economiche Pest", hasSottocategorie: false, items: [] }
//
// NOTA: Documenti Firestore da creare per Preventivo (se non esistono):
//   impostazioni/preventivo_listino    → { nome: "Listino servizi",          hasSottocategorie: false,
//                                         items: [ { "codice": "P_DSF2", "descrizione": "Disinfezione in ott alla L.82/94 DM 274/97", "prezzoUnitario": 150.0 } ] }
//   impostazioni/preventivo_giornata   → { nome: "Giornata/esecuzione",      hasSottocategorie: false, items: ["FERIALE","FESTIVO","NOTTURNO"] }
//   impostazioni/preventivo_pagamento  → { nome: "Modalità di pagamento",    hasSottocategorie: false,
//                                         items: ["Bonifico","Contanti","Assegno","Anticipo 30% saldo alla esecuzione","Immediato"] }
//   impostazioni/preventivo_validita   → { nome: "Validità preventivo",      hasSottocategorie: false, items: ["30 giorni","60 giorni","90 giorni"] }
//   impostazioni/preventivo_rinnovo    → { nome: "Rinnovo preventivo",       hasSottocategorie: false, items: ["Sì","No"] }
//   NOTA preventivo_listino: il campo items contiene Map, non stringhe.
//
// NOTA: Questa pagina è accessibile SOLO agli utenti con role == 'admin'

// ─── Provider ─────────────────────────────────────────────────────────────────

final _categorieStreamProvider = StreamProvider<List<CategoriaModel>>((ref) {
  return ref.watch(impostazioniServiceProvider).getCategorie();
});

// ─── Definizione macro sezioni ────────────────────────────────────────────────

/// Rappresenta una macro-sezione del pannello impostazioni
class _MacroSezione {
  final String titolo;
  final IconData icona;
  final Color colore;

  /// ID documenti Firestore delle categorie contenute in questa macro
  final List<String> categorieId;

  const _MacroSezione({
    required this.titolo,
    required this.icona,
    required this.colore,
    required this.categorieId,
  });
}

/// 5 macro sezioni dell'Admin
const _macroSezioni = [
  _MacroSezione(
    titolo: 'ANAGRAFICHE',
    icona: Icons.people_outline,
    colore: AppColors.blue,
    categorieId: ['tipi_committente'],
  ),
  _MacroSezione(
    titolo: 'REG LAB',
    icona: Icons.biotech_outlined,
    colore: AppColors.primary,
    categorieId: [
      'categorie_analisi',
      'lab_tecnici',
      'campioni_riferimento',
      'prelevato_da',
      'modalita_prelievo',
      'rif_normativa',
    ],
  ),
  _MacroSezione(
    titolo: 'SERVIZI PEST',
    icona: Icons.pest_control,
    colore: AppColors.warning,
    categorieId: [
      'pest_tipi_intervento',
      'pest_numero_intervento',
      'pest_tecnici',
      'pest_prodotti',
      'pest_ulteriori_interventi',
      'pest_voci_economiche',
    ],
  ),
  _MacroSezione(
    titolo: 'PREVENTIVO',
    icona: Icons.description_outlined,
    colore: AppColors.info,
    categorieId: [
      'preventivo_listino',  // Listino a cascata (tipologie → sotto-tipi → servizi)
      'preventivo_giornata',    // Giornata/esecuzione (FERIALE, FESTIVO, NOTTURNO)
      'preventivo_pagamento',   // Modalità di pagamento
      'preventivo_validita',    // Validità del preventivo
      'preventivo_rinnovo',     // Rinnovo automatico
    ],
  ),
  _MacroSezione(
    titolo: 'FATTURE',
    icona: Icons.receipt_long_outlined,
    colore: AppColors.textSecondary,
    categorieId: [],
  ),
];

// ─── Pagina principale ────────────────────────────────────────────────────────

/// Pagina di impostazioni amministrative — organizzata in 5 macro sezioni.
///
/// Permette di:
/// - Espandere ogni macro per vedere le categorie ad essa associata
/// - Gestire gli items / sottocategorie di ogni categoria
/// - Creare categorie libere tramite il bottone "+ Nuova categoria"
/// - Se una categoria non esiste ancora in Firestore, mostra un tasto "Crea"
class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    if (userAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final user = userAsync.valueOrNull;
    if (user == null || !user.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Accesso non autorizzato',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    final categorieAsync = ref.watch(_categorieStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Impostazioni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Bottone per creare una nuova categoria libera
          TextButton.icon(
            onPressed: () => _mostraDialogNuovaCategoria(context, ref),
            icon: const Icon(Icons.add, size: 18, color: AppColors.surface),
            label: const Text(
              'Nuova categoria',
              style: TextStyle(color: AppColors.surface, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: categorieAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Text('Errore: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (categorie) {
          // Mappa id → CategoriaModel per ricerca rapida
          final categorieMap = {for (final c in categorie) c.id: c};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 5 macro sezioni come ExpansionTile di primo livello
              ..._macroSezioni.map((macro) => _MacroExpansionTile(
                    macro: macro,
                    categorieMap: categorieMap,
                    service: ref.read(impostazioniServiceProvider),
                  )),
              const SizedBox(height: 16),
              // Categorie libere (non associate a nessuna macro)
              _buildCategorieLibere(context, categorie, ref),
            ],
          );
        },
      ),
    );
  }

  /// Mostra le categorie non incluse in nessuna macro (create dall'utente)
  Widget _buildCategorieLibere(
      BuildContext context, List<CategoriaModel> categorie, WidgetRef ref) {
    final tuttiGliId =
        _macroSezioni.expand((m) => m.categorieId).toSet();
    final libere = categorie.where((c) => !tuttiGliId.contains(c.id)).toList();
    if (libere.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'ALTRE CATEGORIE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDisabled,
              letterSpacing: 1,
            ),
          ),
        ),
        ...libere.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CategoriaTile(
                categoria: c,
                service: ref.read(impostazioniServiceProvider),
              ),
            )),
      ],
    );
  }

  /// Dialog per la creazione di una nuova categoria libera
  Future<void> _mostraDialogNuovaCategoria(
      BuildContext context, WidgetRef ref) async {
    final service = ref.read(impostazioniServiceProvider);
    final nomeCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    bool hasSottocategorie = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void aggiornaNome(String nome) {
            idCtrl.text = _generaId(nome);
          }

          return AlertDialog(
            title: const Text(
              'Nuova categoria',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome categoria *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: aggiornaNome,
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID documento Firestore *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      helperText: 'Auto-generato dal nome, modificabile',
                      helperStyle: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text(
                      'Ha sottocategorie?',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      hasSottocategorie
                          ? 'Struttura a 3 livelli (sotto → elementi)'
                          : 'Lista semplice di voci',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    value: hasSottocategorie,
                    onChanged: (v) =>
                        setDialogState(() => hasSottocategorie = v),
                    activeThumbColor: AppColors.switchActive,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final nome = nomeCtrl.text.trim();
                        final id = idCtrl.text.trim();
                        if (nome.isEmpty || id.isEmpty) return;

                        setDialogState(() => isSaving = true);
                        try {
                          await service.creaCategoria(
                              id, nome, hasSottocategorie);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Errore: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.surface, strokeWidth: 2))
                    : const Text('Crea'),
              ),
            ],
          );
        },
      ),
    );
    // I controller NON vanno disposti qui: il dialog esegue un'animazione di
    // uscita dopo il pop, e i TextField al suo interno avrebbero ancora listener
    // attivi → disporre il controller prima che l'animazione termini causa
    // "TextEditingController used after being disposed".
    // I controller verranno rilasciati dal GC quando i TextField saranno
    // effettivamente distrutti al termine dell'animazione.
  }

  String _generaId(String nome) {
    return nome
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

// ─── Macro ExpansionTile di primo livello ─────────────────────────────────────

class _MacroExpansionTile extends StatefulWidget {
  final _MacroSezione macro;
  final Map<String, CategoriaModel> categorieMap;
  final ImpostazioniService service;

  const _MacroExpansionTile({
    required this.macro,
    required this.categorieMap,
    required this.service,
  });

  @override
  State<_MacroExpansionTile> createState() => _MacroExpansionTileState();
}

class _MacroExpansionTileState extends State<_MacroExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final macro = widget.macro;
    final numCategorie = macro.categorieId.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
        color: AppColors.surface,
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _isExpanded = v),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          // Icona colorata per macro
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: macro.colore.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(macro.icona, color: macro.colore, size: 20),
          ),
          title: Row(
            children: [
              // Titolo macro in grassetto
              Text(
                macro.titolo,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              // Contatore categorie
              if (numCategorie > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.badgeGreyBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$numCategorie ${numCategorie == 1 ? 'categoria' : 'categorie'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.badgeGreyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // Freccia animata
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textSecondary),
          ),
          children: [
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildContenutioMacro(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenutioMacro() {
    // Macro FATTURE: nessuna categoria ancora
    if (widget.macro.categorieId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Nessuna categoria configurata',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textDisabled,
              fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: widget.macro.categorieId
          .map((id) => _buildCategoriaTileOPlaceholder(id))
          .toList(),
    );
  }

  Widget _buildCategoriaTileOPlaceholder(String id) {
    final categoria = widget.categorieMap[id];
    if (categoria != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _CategoriaTile(
          categoria: categoria,
          service: widget.service,
        ),
      );
    }

    // Categoria non ancora creata in Firestore → placeholder grigio con "Crea"
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline,
                size: 18, color: AppColors.textDisabled),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                id,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDisabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _creaCategoria(id),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary),
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }

  /// Crea la categoria Firestore con il nome suggerito dall'ID
  Future<void> _creaCategoria(String id) async {
    // Converte l'ID in un nome leggibile (es. "pest_tecnici" → "Pest Tecnici")
    final nome = id
        .split('_')
        .map((p) => p.isNotEmpty
            ? '${p[0].toUpperCase()}${p.substring(1)}'
            : '')
        .join(' ');
    try {
      await widget.service.creaCategoria(id, nome, false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ─── Tile per una singola categoria ──────────────────────────────────────────

class _CategoriaTile extends ConsumerStatefulWidget {
  final CategoriaModel categoria;
  final ImpostazioniService service;

  const _CategoriaTile({required this.categoria, required this.service});

  @override
  ConsumerState<_CategoriaTile> createState() => _CategoriaTileState();
}

class _CategoriaTileState extends ConsumerState<_CategoriaTile> {
  bool _isExpanded = false;

  ImpostazioniService get _service => widget.service;

  Future<void> _onToggleSottocategorie(bool nuovoValore) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attenzione'),
        content: Text(
          nuovoValore
              ? 'Passando a "Con sottocategorie" la lista attuale verrà cancellata.\nContinuare?'
              : 'Passando a "Lista semplice" le sottocategorie attuali verranno cancellate.\nContinuare?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Continua'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.toggleSottocategorie(widget.categoria.id, nuovoValore);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _eliminaCategoria() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina "${widget.categoria.nome}"?'),
        content: const Text(
            'I valori già salvati in clienti e servizi non vengono modificati. L\'azione è irreversibile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.eliminaCategoria(widget.categoria.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoria = widget.categoria;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      color: AppColors.background,
      child: ExpansionTile(
        onExpansionChanged: (v) => setState(() => _isExpanded = v),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          categoria.hasSottocategorie
              ? Icons.account_tree_outlined
              : Icons.list_alt_outlined,
          color: AppColors.primary,
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoria.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    categoria.hasSottocategorie
                        ? 'Con sottocategorie'
                        : 'Lista semplice',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: categoria.hasSottocategorie,
                onChanged: _onToggleSottocategorie,
                activeThumbColor: AppColors.switchActive,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: 'Elimina categoria',
              onPressed: _eliminaCategoria,
            ),
          ],
        ),
        trailing: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
        ),
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: categoria.id == 'preventivo_listino'
                ? _ContenutoListinoV2(listinoService: ref.read(listinoServiceProvider))
                : categoria.hasSottocategorie
                        ? _ContenutoConSottocategorie(
                            categoriaId: categoria.id, service: _service)
                        : _ContenutoListaSemplice(
                            categoriaId: categoria.id, service: _service),
          ),
        ],
      ),
    );
  }
}

// ─── Contenuto: lista semplice ────────────────────────────────────────────────

class _ContenutoListaSemplice extends StatefulWidget {
  final String categoriaId;
  final ImpostazioniService service;
  const _ContenutoListaSemplice(
      {required this.categoriaId, required this.service});

  @override
  State<_ContenutoListaSemplice> createState() =>
      _ContenutoListaSempliceState();
}

class _ContenutoListaSempliceState extends State<_ContenutoListaSemplice> {
  ImpostazioniService get _service => widget.service;
  final _ctrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _aggiungi() async {
    final voce = _ctrl.text.trim();
    if (voce.isEmpty) return;
    setState(() => _salvando = true);
    try {
      await _service.aggiungiItem(widget.categoriaId, voce);
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _elimina(String voce) async {
    try {
      await _service.eliminaItem(widget.categoriaId, voce);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<String>>(
          stream: _service.getItems(widget.categoriaId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nessuna voce presente',
                    style: TextStyle(
                        color: AppColors.textDisabled, fontSize: 13)),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map(_buildChip).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: 'Nuova voce...',
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _aggiungi(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _salvando ? null : _aggiungi,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: _salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2))
                  : const Text('Aggiungi'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String voce) {
    return Chip(
      label: Text(voce, style: const TextStyle(fontSize: 13)),
      backgroundColor: AppColors.inputBackground,
      side: const BorderSide(color: AppColors.divider),
      deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.error),
      onDeleted: () => _elimina(voce),
    );
  }
}

// ─── Contenuto: con sottocategorie ───────────────────────────────────────────

class _ContenutoConSottocategorie extends StatefulWidget {
  final String categoriaId;
  final ImpostazioniService service;
  const _ContenutoConSottocategorie(
      {required this.categoriaId, required this.service});

  @override
  State<_ContenutoConSottocategorie> createState() =>
      _ContenutoConSottocategorieState();
}

class _ContenutoConSottocategorieState
    extends State<_ContenutoConSottocategorie> {
  ImpostazioniService get _service => widget.service;
  final _nuovaSottoCtrl = TextEditingController();
  bool _aggiungendoSotto = false;

  @override
  void dispose() {
    _nuovaSottoCtrl.dispose();
    super.dispose();
  }

  Future<void> _aggiungiSottocategoria() async {
    final nome = _nuovaSottoCtrl.text.trim();
    if (nome.isEmpty) return;
    setState(() => _aggiungendoSotto = true);
    try {
      await _service.aggiungiSottocategoria(widget.categoriaId, nome);
      _nuovaSottoCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _aggiungendoSotto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, List<String>>>(
      stream: _service.getSottocategorie(widget.categoriaId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final sottocategorie = snap.data ?? {};
        final chiavi = sottocategorie.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...chiavi.map((nomeSotto) => _SottocategoriaTile(
                  categoriaId: widget.categoriaId,
                  nomeSottocategoria: nomeSotto,
                  elementi: sottocategorie[nomeSotto] ?? [],
                  service: widget.service,
                )),

            if (chiavi.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuovaSottoCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nuova sottocategoria...',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _aggiungiSottocategoria(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed:
                      _aggiungendoSotto ? null : _aggiungiSottocategoria,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: _aggiungendoSotto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppColors.surface, strokeWidth: 2))
                      : const Text('+ Sottocategoria'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── ExpansionTile per una singola sottocategoria ─────────────────────────────

class _SottocategoriaTile extends StatefulWidget {
  final String categoriaId;
  final String nomeSottocategoria;
  final List<String> elementi;
  final ImpostazioniService service;

  const _SottocategoriaTile({
    required this.categoriaId,
    required this.nomeSottocategoria,
    required this.elementi,
    required this.service,
  });

  @override
  State<_SottocategoriaTile> createState() => _SottocategoriaTileState();
}

class _SottocategoriaTileState extends State<_SottocategoriaTile> {
  final _elementoCtrl = TextEditingController();
  bool _aggiungendo = false;

  @override
  void dispose() {
    _elementoCtrl.dispose();
    super.dispose();
  }

  Future<void> _aggiungiElemento() async {
    final el = _elementoCtrl.text.trim();
    if (el.isEmpty) return;
    setState(() => _aggiungendo = true);
    try {
      await widget.service.aggiungiElemento(
          widget.categoriaId, widget.nomeSottocategoria, el);
      _elementoCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _aggiungendo = false);
    }
  }

  Future<void> _eliminaElemento(String el) async {
    await widget.service.eliminaElemento(
        widget.categoriaId, widget.nomeSottocategoria, el);
  }

  Future<void> _eliminaSottocategoria() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina "${widget.nomeSottocategoria}"?'),
        content: const Text(
            'Verranno eliminati anche tutti gli elementi al suo interno.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.service.eliminaSottocategoria(
          widget.categoriaId, widget.nomeSottocategoria);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      color: AppColors.surface,
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.nomeSottocategoria,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${widget.elementi.length} ${widget.elementi.length == 1 ? 'elemento' : 'elementi'}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: 'Elimina sottocategoria',
              onPressed: _eliminaSottocategoria,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.elementi.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nessun elemento',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 13)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.elementi
                        .map((el) => Chip(
                              label: Text(el,
                                  style: const TextStyle(fontSize: 13)),
                              backgroundColor: AppColors.inputBackground,
                              side:
                                  const BorderSide(color: AppColors.divider),
                              deleteIcon: const Icon(Icons.close,
                                  size: 16, color: AppColors.error),
                              onDeleted: () => _eliminaElemento(el),
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _elementoCtrl,
                        decoration: InputDecoration(
                          hintText: 'Nuovo elemento...',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onSubmitted: (_) => _aggiungiElemento(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _aggiungendo ? null : _aggiungiElemento,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: _aggiungendo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: AppColors.surface, strokeWidth: 2))
                          : const Text('Aggiungi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contenuto: listino voci preventivo ──────────────────────────────────────

/// Widget speciale per la categoria [preventivo_listino].
///
/// Ogni voce del listino è una Map Firestore con i campi:
///   { "codice": String, "descrizione": String, "prezzoUnitario": double }
///
/// Layout responsive: tabella su desktop (≥ 500 px), card su mobile.
class _ContenutoListino extends StatefulWidget {
  final String categoriaId;
  final ImpostazioniService service;
  const _ContenutoListino({required this.categoriaId, required this.service});

  @override
  State<_ContenutoListino> createState() => _ContenutoListinoState();
}

class _ContenutoListinoState extends State<_ContenutoListino> {
  final _codiceCtrl = TextEditingController();
  final _descrizioneCtrl = TextEditingController();
  final _prezzoCtrl = TextEditingController(text: '0.00');
  bool _salvando = false;

  // Formattatore moneta italiano
  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

  @override
  void dispose() {
    _codiceCtrl.dispose();
    _descrizioneCtrl.dispose();
    _prezzoCtrl.dispose();
    super.dispose();
  }

  /// Aggiunge la nuova voce al listino su Firestore
  Future<void> _aggiungi() async {
    final codice = _codiceCtrl.text.trim();
    final descrizione = _descrizioneCtrl.text.trim();
    if (codice.isEmpty || descrizione.isEmpty) return;
    // Arrotonda il prezzo a 2 decimali
    final prezzo = double.parse(
      (double.tryParse(_prezzoCtrl.text.replaceAll(',', '.')) ?? 0.0)
          .toStringAsFixed(2),
    );

    setState(() => _salvando = true);
    try {
      await widget.service.aggiungiVoceListino(widget.categoriaId, {
        'codice': codice,
        'descrizione': descrizione,
        'prezzoUnitario': prezzo,
      });
      _codiceCtrl.clear();
      _descrizioneCtrl.clear();
      _prezzoCtrl.text = '0.00';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// Elimina la voce all'indice indicato (read-modify-write su Firestore)
  Future<void> _elimina(int indice) async {
    try {
      await widget.service
          .eliminaVoceListinoPerIndice(widget.categoriaId, indice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 500;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista/tabella voci esistenti in real-time
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.service.getVociListino(widget.categoriaId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final voci = snap.data ?? [];
                if (voci.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nessuna voce nel listino',
                      style: TextStyle(
                          color: AppColors.textDisabled, fontSize: 13),
                    ),
                  );
                }
                return isDesktop
                    ? _buildTabellaDesktop(voci)
                    : _buildListaMobile(voci);
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            // Etichetta sezione aggiunta
            const Text(
              'Aggiungi voce al listino',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            // Form di inserimento — riga orizzontale su desktop, colonna su mobile
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _codiceCtrl,
                      decoration: _dec('Codice'),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _descrizioneCtrl,
                      decoration: _dec('Descrizione'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _prezzoCtrl,
                      decoration: _dec('Prezzo unit. (€)'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _salvando ? null : _aggiungi,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: AppColors.surface, strokeWidth: 2))
                        : const Text('Aggiungi'),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _codiceCtrl,
                    decoration: _dec('Codice'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descrizioneCtrl,
                    decoration: _dec('Descrizione'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _prezzoCtrl,
                    decoration: _dec('Prezzo unitario (€)'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _salvando ? null : _aggiungi,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: AppColors.surface, strokeWidth: 2))
                        : const Text('Aggiungi'),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  /// Tabella desktop: Codice | Descrizione | Prezzo unit. | Elimina
  Widget _buildTabellaDesktop(List<Map<String, dynamic>> voci) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 60,
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Codice')),
          DataColumn(label: Text('Descrizione')),
          DataColumn(label: Text('Prezzo unit.')),
          DataColumn(label: Text('')),
        ],
        rows: voci.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return DataRow(cells: [
            DataCell(Text(
              v['codice'] as String? ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.primary,
              ),
            )),
            DataCell(SizedBox(
              width: 300,
              child: Text(
                v['descrizione'] as String? ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
              ),
            )),
            DataCell(Text(
              _moneyFmt.format(
                  (v['prezzoUnitario'] as num?)?.toDouble() ?? 0.0),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.primaryDark,
              ),
            )),
            DataCell(IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: 'Elimina voce',
              onPressed: () => _elimina(i),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  /// Lista card mobile: badge codice + descrizione + prezzo + elimina
  Widget _buildListaMobile(List<Map<String, dynamic>> voci) {
    return Column(
      children: voci.asMap().entries.map((entry) {
        final i = entry.key;
        final v = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Badge codice colorato in verde chiaro
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v['codice'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['descrizione'] as String? ?? '',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _moneyFmt.format(
                          (v['prezzoUnitario'] as num?)?.toDouble() ?? 0.0),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 18),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () => _elimina(i),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}

// ─── Listino v2 a cascata ─────────────────────────────────────────────────────

/// Editor del listino a cascata v2.
/// Carica le tipologie tramite [getTipologie()] e mostra l'albero interattivo.
class _ContenutoListinoV2 extends StatefulWidget {
  final ListinoService listinoService;
  const _ContenutoListinoV2({required this.listinoService});

  @override
  State<_ContenutoListinoV2> createState() => _ContenutoListinoV2State();
}

class _ContenutoListinoV2State extends State<_ContenutoListinoV2> {
  List<TipologiaListino>? _tipologie;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _caricaListino();
  }

  Future<void> _caricaListino() async {
    if (mounted) setState(() => _loading = true);
    try {
      final t = await widget.listinoService.getTipologie();
      if (mounted) setState(() { _tipologie = t; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _tipologie = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ));
    }
    final tipologie = _tipologie ?? [];
    if (tipologie.isEmpty) {
      return const Center(
        child: Text('Nessun servizio configurato',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return _buildListaTipologie(tipologie);
  }

  Widget _buildListaTipologie(List<TipologiaListino> tipologie) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tipologie.length,
      itemBuilder: (_, i) {
        final tipologia = tipologie[i];
        final colore = _coloreTipologia(tipologia.id);
        return ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colore.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(tipologia.id,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 11, color: colore)),
          ),
          title: Text(tipologia.nome,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          trailing: Text('${tipologia.tuttiServizi.length} servizi',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          children:
              tipologia.sottotipi.map((st) => _buildSottotipoTile(tipologia, st)).toList(),
        );
      },
    );
  }

  Widget _buildSottotipoTile(TipologiaListino tipologia, SottotipoListino st) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 16, right: 16),
      title: Row(children: [
        SizedBox(
          width: 80,
          child: Text(st.id,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue)),
        ),
        Text(' — ${st.nome}',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
      ]),
      trailing: Text('${st.servizi.length}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      children: [
        ...st.servizi.map((s) => ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 8),
              leading: Text(s.codiceUnivoco,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue)),
              title: Text(s.descrizione,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('€ ${s.prezzoUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.blue),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _dialogModificaServizio(tipologia, st, s),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _dialogEliminaServizio(tipologia, st, s),
                ),
              ]),
            )),
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8, top: 4),
          child: OutlinedButton.icon(
            onPressed: () => _dialogAggiungiServizio(tipologia, st),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Aggiungi servizio', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Color _coloreTipologia(String id) {
    switch (id) {
      case 'P':
        return AppColors.primary;
      case 'A':
        return AppColors.blue;
      case 'V':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _dialogModificaServizio(
    TipologiaListino tipologia,
    SottotipoListino sottotipo,
    ServizioListino servizio,
  ) async {
    final nomeCtrl = TextEditingController(text: servizio.descrizione);
    final prezzoCtrl =
        TextEditingController(text: servizio.prezzoUnitario.toStringAsFixed(2));
    bool salvando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Modifica servizio',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Text('Codice: ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(servizio.codiceUnivoco,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue)),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nomeCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Nome / descrizione',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prezzoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Prezzo (€)',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      setDialog(() => salvando = true);
                      final nome = nomeCtrl.text.trim();
                      final prezzo =
                          double.tryParse(prezzoCtrl.text.replaceAll(',', '.')) ??
                              0.0;
                      try {
                        await widget.listinoService.aggiornaServizio(
                          _tipologie!,
                          tipologia.id,
                          sottotipo.id,
                          servizio.codiceUnivoco,
                          nome,
                          prezzo,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _caricaListino();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Errore: $e'),
                              backgroundColor: AppColors.error));
                        }
                      } finally {
                        if (ctx.mounted) setDialog(() => salvando = false);
                      }
                    },
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2))
                  : const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogEliminaServizio(
    TipologiaListino tipologia,
    SottotipoListino sottotipo,
    ServizioListino servizio,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina "${servizio.codiceUnivoco}"?'),
        content: Text(
            'Eliminare "${servizio.descrizione}"? Azione irreversibile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.listinoService
          .eliminaServizio(_tipologie!, tipologia.id, sottotipo.id, servizio.codiceUnivoco);
      await _caricaListino();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Errore: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _dialogAggiungiServizio(
    TipologiaListino tipologia,
    SottotipoListino sottotipo,
  ) async {
    // Numero suggerito: max numero esistente + 1
    int maxNum = 0;
    for (final s in sottotipo.servizi) {
      final n = int.tryParse(s.codiceUnivoco.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
      if (n > maxNum) maxNum = n;
    }
    final suggerito = (maxNum + 1).toString();

    final nCtrl = TextEditingController(text: suggerito);
    final nomeCtrl = TextEditingController();
    final prezzoCtrl = TextEditingController(text: '0.00');
    String anteprima = '${sottotipo.id}$suggerito';
    bool aggiungendo = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Aggiungi servizio',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Text('Codice: ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(anteprima,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ]),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Numero',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) =>
                    setDialog(() => anteprima = '${sottotipo.id}$v'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nome / descrizione *',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prezzoCtrl,
                decoration: const InputDecoration(
                    labelText: 'Prezzo (€) *',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            FilledButton(
              onPressed: aggiungendo
                  ? null
                  : () async {
                      final numero = nCtrl.text.trim();
                      final nome = nomeCtrl.text.trim();
                      final prezzo = double.tryParse(
                              prezzoCtrl.text.replaceAll(',', '.')) ??
                          0.0;
                      if (numero.isEmpty || nome.isEmpty) return;
                      setDialog(() => aggiungendo = true);
                      try {
                        final nuovo = ServizioListino(
                          codiceUnivoco: '${sottotipo.id}$numero',
                          descrizione: nome,
                          prezzoUnitario: prezzo,
                        );
                        await widget.listinoService.aggiungiServizio(
                            _tipologie!, tipologia.id, sottotipo.id, nuovo);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _caricaListino();
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text('Errore: $e'),
                              backgroundColor: AppColors.error));
                        }
                      } finally {
                        if (ctx.mounted) setDialog(() => aggiungendo = false);
                      }
                    },
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: aggiungendo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2))
                  : const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }
}

