import 'package:biochem/services/impostazioni_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/service_providers.dart';
import '../models/categoria_model.dart';

/// Dropdown riutilizzabile che si adatta automaticamente in base a [hasSottocategorie].
///
/// Legge il documento `impostazioni/{categoriaId}` da Firestore e mostra:
///
/// - [hasSottocategorie] == false →
///   UN solo [DropdownButtonFormField] con tutti gli items
///
/// - [hasSottocategorie] == true →
///   DUE [DropdownButtonFormField] in sequenza:
///     1. Sottocategoria
///     2. Elemento della sottocategoria (appare dopo la selezione del primo)
///   Il valore finale restituito da [onChanged] è "Sottocategoria / Elemento"
class CategoriaDropdown extends ConsumerStatefulWidget {
  /// ID del documento Firestore nella collection 'impostazioni'
  final String categoriaId;

  /// Label del campo principale (es. "Tipo committente")
  final String label;

  /// Valore iniziale per la modalità modifica.
  /// - Lista semplice: stringa semplice es. "Analisi acqua"
  /// - Con sottocategorie: formato "Sotto / Elemento" es. "Privato / Persona fisica"
  final String? initialValue;

  /// Callback invocato con il valore selezionato quando la selezione è completa
  final void Function(String) onChanged;

  /// Validatore opzionale per il dropdown (es. campo obbligatorio)
  final String? Function(String?)? validator;

  const CategoriaDropdown({
    super.key,
    required this.categoriaId,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  ConsumerState<CategoriaDropdown> createState() => _CategoriaDropdownState();
}

class _CategoriaDropdownState extends ConsumerState<CategoriaDropdown> {
  late final ImpostazioniService _service;

  // Stato per selezione semplice
  String? _valoreSelezionato;

  // Stato per selezione con sottocategorie
  String? _sottocategoriaSelezionata;
  String? _elementoSelezionato;

  @override
  void initState() {
    super.initState();
    // Legge il service una volta sola: è un singleton stabile
    _service = ref.read(impostazioniServiceProvider);
    _parseValoreIniziale(widget.initialValue);
  }

  /// Parsa il valore iniziale impostando lo stato interno appropriato
  void _parseValoreIniziale(String? valore) {
    if (valore == null || valore.isEmpty) return;
    if (valore.contains(' / ')) {
      // Formato con sottocategorie: "Sotto / Elemento"
      final parti = valore.split(' / ');
      _sottocategoriaSelezionata = parti[0];
      _elementoSelezionato = parti.length > 1 ? parti[1] : null;
    } else {
      // Lista semplice
      _valoreSelezionato = valore;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CategoriaModel?>(
      stream: _service.getCategoriaStream(widget.categoriaId),
      builder: (context, snap) {
        // Caricamento in corso
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildScheletro();
        }

        final categoria = snap.data;

        // Documento non trovato (categoria non ancora creata su Firestore)
        if (categoria == null) {
          return _buildScheletro(hintText: 'Categoria non trovata su Firestore');
        }

        if (!categoria.hasSottocategorie) {
          return _buildDropdownSemplice(categoria.items);
        } else {
          return _buildDropdownConSottocategorie(categoria.sottocategorie);
        }
      },
    );
  }

  // ─── Lista semplice ────────────────────────────────────────────────────────

  Widget _buildDropdownSemplice(List<String> items) {
    // Se il valore corrente non è nella lista, resettalo
    final valoreValido =
        items.contains(_valoreSelezionato) ? _valoreSelezionato : null;

    return DropdownButtonFormField<String>(
      initialValue: valoreValido,
      decoration: _dec(widget.label),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: (v) {
        setState(() => _valoreSelezionato = v);
        if (v != null) widget.onChanged(v);
      },
      isExpanded: true,
      validator: widget.validator,
    );
  }

  // ─── Con sottocategorie ────────────────────────────────────────────────────

  Widget _buildDropdownConSottocategorie(
      Map<String, List<String>> sottocategorie) {
    final chiavi = sottocategorie.keys.toList()..sort();

    // Valida la sottocategoria corrente
    final sottoValida =
        chiavi.contains(_sottocategoriaSelezionata) ? _sottocategoriaSelezionata : null;

    // Elementi disponibili per la sottocategoria selezionata
    final elementiDisponibili =
        sottoValida != null ? (sottocategorie[sottoValida] ?? []) : <String>[];

    // Valida l'elemento corrente
    final elemValido = elementiDisponibili.contains(_elementoSelezionato)
        ? _elementoSelezionato
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1° dropdown: sottocategoria
        DropdownButtonFormField<String>(
          initialValue: sottoValida,
          decoration: _dec(widget.label),
          items: chiavi
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => setState(() {
            _sottocategoriaSelezionata = v;
            _elementoSelezionato = null; // reset elemento al cambio sotto
          }),
          isExpanded: true,
        ),

        // 2° dropdown: elemento (visibile solo dopo aver scelto la sottocategoria)
        if (sottoValida != null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: elemValido,
            decoration: _dec('${widget.label} — dettaglio'),
            items: elementiDisponibili
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              setState(() => _elementoSelezionato = v);
              if (v != null && _sottocategoriaSelezionata != null) {
                // Restituisce il valore nel formato "Sotto / Elemento"
                widget.onChanged('$_sottocategoriaSelezionata / $v');
              }
            },
            isExpanded: true,
          ),
        ],
      ],
    );
  }

  // ─── Scheletro di caricamento / errore ────────────────────────────────────

  Widget _buildScheletro({String? hintText}) {
    return TextFormField(
      enabled: false,
      decoration: _dec(widget.label).copyWith(
        hintText: hintText ?? 'Caricamento...',
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
        suffixIcon: hintText == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              )
            : const Icon(Icons.warning_amber_outlined,
                color: AppColors.warning, size: 18),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
