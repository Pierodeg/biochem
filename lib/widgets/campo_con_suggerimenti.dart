import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/service_providers.dart';

/// Campo di testo libero con suggerimenti caricabili da un elenco
/// (`impostazioni/{categoriaId}` → `items`).
///
/// L'utente può **scegliere un valore dall'elenco** (icona a tendina nel campo)
/// oppure **digitarlo manualmente**. Se l'elenco è vuoto, il campo resta un
/// normale campo di testo libero.
class CampoConSuggerimenti extends ConsumerWidget {
  final String categoriaId;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator;

  const CampoConSuggerimenti({
    super.key,
    required this.categoriaId,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(impostazioniServiceProvider);
    return StreamBuilder<List<String>>(
      stream: service.getItems(categoriaId),
      builder: (context, snap) {
        final items = snap.data ?? const <String>[];
        return TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          validator: validator,
          decoration: _dec(label).copyWith(
            suffixIcon: items.isEmpty
                ? null
                : PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.textOnDarkSecondary),
                    color: const Color(0xFF0A2A1A),
                    tooltip: 'Scegli da elenco',
                    onSelected: (v) {
                      controller.text = v;
                      controller.selection = TextSelection.collapsed(
                          offset: controller.text.length);
                    },
                    itemBuilder: (_) => items
                        .map((e) => PopupMenuItem<String>(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(
                                      color: AppColors.textOnDark,
                                      fontSize: 13)),
                            ))
                        .toList(),
                  ),
          ),
        );
      },
    );
  }

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
