import 'package:flutter/material.dart';
import '../../home/widgets/sezione_placeholder.dart';

/// Sezione Primarie — risultati analisi chimico-fisiche (task 6).
/// Placeholder: implementazione nell'AREA C del PIANO_GENERALE.md.
class PrimariePage extends StatelessWidget {
  const PrimariePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SezionePlaceholder(
      titolo: 'Primarie',
      icona: Icons.opacity_outlined,
    );
  }
}
