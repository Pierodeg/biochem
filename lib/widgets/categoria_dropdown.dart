import 'package:biochem/services/impostazioni_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/service_providers.dart';
import '../models/categoria_model.dart';

/// Dropdown riutilizzabile che si adatta automaticamente in base a [hasSottocategorie].
class CategoriaDropdown extends ConsumerStatefulWidget {
  final String categoriaId;
  final String label;
  final String? initialValue;
  final void Function(String) onChanged;
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

  String? _valoreSelezionato;
  String? _sottocategoriaSelezionata;
  String? _elementoSelezionato;

  @override
  void initState() {
    super.initState();
    _service = ref.read(impostazioniServiceProvider);
    _parseValoreIniziale(widget.initialValue);
  }

  void _parseValoreIniziale(String? valore) {
    if (valore == null || valore.isEmpty) return;
    if (valore.contains(' / ')) {
      final parti = valore.split(' / ');
      _sottocategoriaSelezionata = parti[0];
      _elementoSelezionato = parti.length > 1 ? parti[1] : null;
    } else {
      _valoreSelezionato = valore;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CategoriaModel?>(
      stream: _service.getCategoriaStream(widget.categoriaId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildScheletro();
        }
        final categoria = snap.data;
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
    final valoreValido =
        items.contains(_valoreSelezionato) ? _valoreSelezionato : null;

    return DropdownButtonFormField<String>(
      initialValue: valoreValido,
      decoration: _dec(widget.label),
      style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
      dropdownColor: const Color(0xFF0A2A1A),
      iconEnabledColor: AppColors.textOnDarkSecondary,
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

    final sottoValida = chiavi.contains(_sottocategoriaSelezionata)
        ? _sottocategoriaSelezionata
        : null;

    final elementiDisponibili = sottoValida != null
        ? (sottocategorie[sottoValida] ?? [])
        : <String>[];

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
          style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
          dropdownColor: const Color(0xFF0A2A1A),
          iconEnabledColor: AppColors.textOnDarkSecondary,
          items: chiavi
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) => setState(() {
            _sottocategoriaSelezionata = v;
            _elementoSelezionato = null;
          }),
          isExpanded: true,
        ),

        // 2° dropdown: elemento
        if (sottoValida != null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: elemValido,
            decoration: _dec('${widget.label} — dettaglio'),
            style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
            dropdownColor: const Color(0xFF0A2A1A),
            iconEnabledColor: AppColors.textOnDarkSecondary,
            items: elementiDisponibili
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) {
              setState(() => _elementoSelezionato = v);
              if (v != null && _sottocategoriaSelezionata != null) {
                widget.onChanged('$_sottocategoriaSelezionata / $v');
              }
            },
            isExpanded: true,
          ),
        ],
      ],
    );
  }

  // ─── Scheletro ────────────────────────────────────────────────────────────

  Widget _buildScheletro({String? hintText}) {
    return TextFormField(
      enabled: false,
      decoration: _dec(widget.label).copyWith(
        hintText: hintText ?? 'Caricamento...',
        hintStyle: const TextStyle(
            color: AppColors.textOnDarkMuted, fontSize: 13),
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

  // ─── Decoration condivisa ─────────────────────────────────────────────────

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          color: AppColors.textOnDarkSecondary, fontSize: 13),
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppColors.glassBorderSubtle, width: 0.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
