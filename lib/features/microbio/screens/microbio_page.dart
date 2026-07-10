import 'package:flutter/material.dart';
import '../../home/widgets/sezione_placeholder.dart';

/// Sezione Microbiologia — risultati analisi microbiologiche (task 9).
/// Placeholder: implementazione nell'AREA C del PIANO_GENERALE.md.
class MicrobioPage extends StatelessWidget {
  const MicrobioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SezionePlaceholder(
      titolo: 'Microbiologia',
      icona: Icons.coronavirus_outlined,
    );
  }
}
