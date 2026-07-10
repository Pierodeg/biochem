import 'package:flutter/material.dart';
import '../../home/widgets/sezione_placeholder.dart';

/// Sezione Anioni — risultati analisi anioni (task 7).
/// Placeholder: implementazione nell'AREA C del PIANO_GENERALE.md.
class AnioniPage extends StatelessWidget {
  const AnioniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SezionePlaceholder(
      titolo: 'Anioni',
      icona: Icons.bubble_chart_outlined,
    );
  }
}
