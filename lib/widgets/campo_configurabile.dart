import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/service_providers.dart';
import '../features/auth/providers/auth_provider.dart';
import '../models/categoria_model.dart';
import '../services/impostazioni_service.dart';

/// Macro-sezioni dell'app → categorie (documenti `impostazioni/`) che contengono.
/// Rispecchia l'organizzazione del pannello Impostazioni.
const Map<String, List<String>> _macroSezioni = {
  'ANAGRAFICHE': ['tipi_committente'],
  'REG LAB': [
    'categorie_analisi',
    'lab_tecnici',
    'campioni_riferimento',
    'prelevato_da',
    'modalita_prelievo',
    'rif_normativa',
  ],
  'SERVIZI PEST': [
    'pest_tipi_intervento',
    'pest_numero_intervento',
    'pest_tecnici',
    'pest_prodotti',
    'pest_ulteriori_interventi',
    'pest_voci_economiche',
  ],
  'PREVENTIVO': [
    'preventivo_giornata',
    'preventivo_pagamento',
    'preventivo_validita',
    'preventivo_rinnovo',
    'preventivo_oggetti',
    'preventivo_durata',
    'preventivo_periodo',
    'preventivo_note',
  ],
  'FATTURE': [],
};

/// Etichetta della macro "catch-all" per categorie non mappate altrove.
const _macroAltre = 'ALTRE';

/// Campo "configurabile": l'admin lo aggancia con una cascata
/// **sezione → categoria → (sottocategoria) → suggerimenti**, dove ogni scelta
/// **apre automaticamente** il menu successivo (nessun click aggiuntivo).
///
/// Una volta agganciato, la categoria **resta** (persistita in
/// `impostazioni/field_bindings`). L'admin può ri-cambiarla con ↺ (con conferma).
/// Da configurato, toccando l'intera casella compaiono i suggerimenti.
class CampoConfigurabile extends ConsumerStatefulWidget {
  /// Chiave stabile del campo (es. 'preventivo_oggetto') per salvare il binding.
  final String fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLines;

  /// Categoria predefinita: se non c'è un binding salvato, il campo risulta
  /// **già configurato** su questa categoria (i campi già a lista restano tali).
  /// L'admin può comunque ri-agganciarlo con ↺.
  final String? defaultCategoriaId;
  final String defaultSottocategoria;

  const CampoConfigurabile({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.defaultCategoriaId,
    this.defaultSottocategoria = '',
  });

  @override
  ConsumerState<CampoConfigurabile> createState() => _CampoConfigurabileState();
}

class _CampoConfigurabileState extends ConsumerState<CampoConfigurabile> {
  /// Documenti `impostazioni/` che non sono "categorie" selezionabili.
  static const _nonCategorie = {
    'dati_azienda',
    'field_bindings',
    'preventivo_listino',
    'preventivo_listino_v2',
  };

  /// Ancora per posizionare i menu a catena sotto la casella.
  final GlobalKey _ancora = GlobalKey();

  ImpostazioniService get _service => ref.read(impostazioniServiceProvider);

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    return StreamBuilder<FieldBinding?>(
      stream: _service.getFieldBinding(widget.fieldKey),
      builder: (context, snap) {
        final salvato = snap.data;
        // Binding effettivo: quello salvato, altrimenti il default (se previsto).
        final effettivo = salvato ??
            (widget.defaultCategoriaId != null
                ? FieldBinding(
                    categoriaId: widget.defaultCategoriaId!,
                    sottocategoria: widget.defaultSottocategoria)
                : null);
        if (effettivo != null) {
          return _buildCampoBound(effettivo, isAdmin, override: salvato != null);
        }
        if (!isAdmin) {
          return _buildTestoLibero(hint: 'Campo non ancora configurato');
        }
        return _buildTriggerConfigurazione();
      },
    );
  }

  // ─── Stato CONFIGURATO — tap sull'intera casella apre i suggerimenti ─────────

  Widget _buildCampoBound(FieldBinding binding, bool isAdmin,
      {bool override = false}) {
    final Stream<List<String>> stream = binding.haSottocategoria
        ? _service
            .getSottocategorie(binding.categoriaId)
            .map((m) => m[binding.sottocategoria] ?? const <String>[])
        : _service.getItems(binding.categoriaId);

    return StreamBuilder<List<String>>(
      stream: stream,
      builder: (context, snap) {
        final items = snap.data ?? const <String>[];
        final valore = widget.controller.text;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PopupMenuButton<String>(
                enabled: items.isNotEmpty,
                tooltip: 'Scegli un suggerimento',
                color: const Color(0xFF0A2A1A),
                position: PopupMenuPosition.under,
                constraints: const BoxConstraints(minWidth: 240),
                onSelected: (v) {
                  setState(() {
                    widget.controller.text = v;
                    widget.controller.selection =
                        TextSelection.collapsed(offset: v.length);
                  });
                },
                itemBuilder: (_) => items
                    .map((e) => PopupMenuItem<String>(
                          value: e,
                          child: Text(e,
                              style: const TextStyle(
                                  color: AppColors.textOnDark, fontSize: 13)),
                        ))
                    .toList(),
                child: InputDecorator(
                  isEmpty: valore.isEmpty,
                  decoration: _dec(widget.label).copyWith(
                    helperText: _helperLabel(binding, items.isEmpty, override),
                    helperStyle: const TextStyle(
                        fontSize: 10, color: AppColors.textOnDarkMuted),
                    suffixIcon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.textOnDarkSecondary),
                  ),
                  child: Text(
                    valore,
                    maxLines: widget.maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.restart_alt,
                    size: 20, color: AppColors.textOnDarkSecondary),
                tooltip: 'Cambia categoria (admin)',
                onPressed: _cambiaCategoria,
              ),
          ],
        );
      },
    );
  }

  String _helperLabel(FieldBinding b, bool senzaSuggerimenti, bool override) {
    final base = b.haSottocategoria
        ? 'Categoria: ${b.categoriaId} → ${b.sottocategoria}'
        : 'Categoria: ${b.categoriaId}';
    final tag = (!override && widget.defaultCategoriaId != null)
        ? ' (predefinita)'
        : '';
    final sugg = senzaSuggerimenti ? ' · nessun suggerimento' : '';
    return '$base$tag$sugg';
  }

  Future<void> _cambiaCategoria() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        title: const Text('Cambia categoria',
            style: TextStyle(color: AppColors.textOnDark)),
        content: const Text(
          'Vuoi cambiare la categoria collegata a questo campo?',
          style: TextStyle(color: AppColors.textOnDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continua',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _apriMenuSezioni();
  }

  // ─── Stato NON configurato (admin): casella che avvia la cascata di menu ─────

  Widget _buildTriggerConfigurazione() {
    return InkWell(
      key: _ancora,
      borderRadius: BorderRadius.circular(8),
      onTap: _apriMenuSezioni,
      child: InputDecorator(
        // isEmpty:false → la label flotta in alto e non si sovrappone al
        // placeholder "Scegli sezione".
        isEmpty: false,
        decoration: _dec(widget.label).copyWith(
          helperText: 'Tocca per configurare: sezione → categoria',
          helperStyle:
              const TextStyle(fontSize: 10, color: AppColors.textOnDarkMuted),
          prefixIcon: const Icon(Icons.folder_outlined,
              size: 18, color: AppColors.textOnDarkMuted),
          suffixIcon: const Icon(Icons.arrow_drop_down,
              color: AppColors.textOnDarkSecondary),
        ),
        child: const Text('Scegli sezione',
            style: TextStyle(color: AppColors.textOnDarkMuted)),
      ),
    );
  }

  // ─── Cascata di menu (ogni scelta apre automaticamente il successivo) ────────

  Future<void> _apriMenuSezioni() async {
    final tutte = await _service.getCategorie().first;
    if (!mounted) return;
    final haAltre = tutte
        .any((c) => !_nonCategorie.contains(c.id) && _macroDi(c.id) == null);
    final sezioni = [..._macroSezioni.keys, if (haAltre) _macroAltre];
    const revert = '__default__';
    final opzioni = <(String, String)>[
      if (widget.defaultCategoriaId != null)
        (revert, '↩ Ripristina predefinita'),
      ...sezioni.map((s) => (s, s)),
    ];
    final scelta = await _mostraMenu(opzioni);
    if (scelta == null || !mounted) return;
    if (scelta == revert) {
      await _service.rimuoviFieldBinding(widget.fieldKey);
      return;
    }
    await _apriMenuCategorie(scelta);
  }

  Future<void> _apriMenuCategorie(String macro) async {
    final tutte = await _service.getCategorie().first;
    if (!mounted) return;
    final categorie = tutte
        .where((c) => !_nonCategorie.contains(c.id))
        .where((c) => macro == _macroAltre
            ? _macroDi(c.id) == null
            : _macroDi(c.id) == macro)
        .toList();
    if (categorie.isEmpty) {
      _avviso('Nessuna categoria in «$macro». Creane una in Impostazioni.');
      return;
    }
    final id = await _mostraMenu(categorie
        .map((c) =>
            (c.id, c.hasSottocategorie ? '${c.nome}  (sottocat.)' : c.nome))
        .toList());
    if (id == null || !mounted) return;
    final cat = categorie.firstWhere((c) => c.id == id);
    if (cat.hasSottocategorie) {
      await _apriMenuSottocategorie(cat);
    } else {
      await _service.salvaFieldBinding(widget.fieldKey, cat.id);
    }
  }

  Future<void> _apriMenuSottocategorie(CategoriaModel cat) async {
    final sub = cat.sottocategorie.keys.toList()..sort();
    if (sub.isEmpty) {
      _avviso('«${cat.nome}» non ha sottocategorie. Creane in Impostazioni.');
      return;
    }
    final s = await _mostraMenu(sub.map((x) => (x, x)).toList());
    if (s == null || !mounted) return;
    await _service.salvaFieldBinding(widget.fieldKey, cat.id,
        sottocategoria: s);
  }

  /// Mostra un menu ancorato sotto la casella. Ogni voce è `(value, label)`.
  Future<String?> _mostraMenu(List<(String, String)> opzioni) {
    final box = _ancora.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return Future.value(null);
    final pos = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    return showMenu<String>(
      context: context,
      position: pos,
      color: const Color(0xFF0A2A1A),
      constraints: const BoxConstraints(minWidth: 240),
      items: opzioni
          .map((o) => PopupMenuItem<String>(
                value: o.$1,
                child: Text(o.$2,
                    style: const TextStyle(
                        color: AppColors.textOnDark, fontSize: 13)),
              ))
          .toList(),
    );
  }

  void _avviso(String testo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(testo, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.textOnDarkSecondary.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Macro-sezione a cui appartiene la categoria [id], o `null` se non mappata.
  String? _macroDi(String id) {
    for (final e in _macroSezioni.entries) {
      if (e.value.contains(id)) return e.key;
    }
    return null;
  }

  // ─── Testo libero (non admin, campo non configurato) ─────────────────────────

  Widget _buildTestoLibero({required String hint}) {
    return TextFormField(
      controller: widget.controller,
      style: const TextStyle(color: Colors.white),
      maxLines: widget.maxLines,
      decoration: _dec(widget.label).copyWith(
        helperText: hint,
        helperStyle:
            const TextStyle(fontSize: 10, color: AppColors.textOnDarkMuted),
      ),
    );
  }

  // ─── Decorazione (coerente con CampoConSuggerimenti) ─────────────────────────

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13),
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
