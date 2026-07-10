import 'package:flutter/material.dart';
import '../../home/widgets/sezione_placeholder.dart';

/// Sezione Stampa unione — vista aggregata per certificato (task 8).
/// Placeholder: implementazione nell'AREA D del PIANO_GENERALE.md.
class StampaUnionePage extends StatelessWidget {
  const StampaUnionePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SezionePlaceholder(
      titolo: 'Stampa unione',
      icona: Icons.table_view_outlined,
    );
  }
}
