import 'package:flutter/material.dart';
import '../../home/widgets/sezione_placeholder.dart';

/// Sezione Cationi Metalli — risultati analisi (task 5).
/// Placeholder: implementazione nell'AREA C del PIANO_GENERALE.md.
class CationiPage extends StatelessWidget {
  const CationiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SezionePlaceholder(
      titolo: 'Cationi Metalli',
      icona: Icons.science_outlined,
    );
  }
}
