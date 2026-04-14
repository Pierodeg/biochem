import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/categoria_model.dart';
import '../../../services/impostazioni_service.dart';

// NOTA: Documenti Firestore da creare per Servizi Pest (se non esistono):
//   impostazioni/pest_tipi_intervento       → { nome: "Tipi intervento Pest", hasSottocategorie: false, items: [] }
//   impostazioni/pest_numero_intervento     → { nome: "N° intervento Pest",   hasSottocategorie: false, items: [] }
//   impostazioni/pest_tecnici              → { nome: "Tecnici Pest",          hasSottocategorie: false, items: [] }
//   impostazioni/pest_prodotti             → { nome: "Prodotti Pest",         hasSottocategorie: false, items: [] }
//   impostazioni/pest_ulteriori_interventi  → { nome: "Ulteriori interventi Pest", hasSottocategorie: false, items: [] }
//   impostazioni/pest_voci_economiche       → { nome: "Voci economiche Pest", hasSottocategorie: false, items: [] }
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
    categorieId: ['categorie_preventivo'],
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
              '+ Nuova categoria',
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
    nomeCtrl.dispose();
    idCtrl.dispose();
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

class _CategoriaTile extends StatefulWidget {
  final CategoriaModel categoria;
  final ImpostazioniService service;

  const _CategoriaTile({required this.categoria, required this.service});

  @override
  State<_CategoriaTile> createState() => _CategoriaTileState();
}

class _CategoriaTileState extends State<_CategoriaTile> {
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
            child: categoria.hasSottocategorie
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
