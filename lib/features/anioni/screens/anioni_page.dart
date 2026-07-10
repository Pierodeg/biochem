import 'package:flutter/material.dart';
import '../../laboratorio/famiglie_analisi.dart';
import '../../laboratorio/screens/risultati_page.dart';

/// Sezione Anioni — risultati analisi anioni (task 7).
class AnioniPage extends StatelessWidget {
  const AnioniPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RisultatiPage(famiglia: FamigliaAnalisi.anioni);
  }
}
