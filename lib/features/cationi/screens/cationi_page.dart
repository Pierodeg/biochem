import 'package:flutter/material.dart';
import '../../laboratorio/famiglie_analisi.dart';
import '../../laboratorio/screens/risultati_page.dart';

/// Sezione Cationi Metalli — risultati analisi (task 5).
class CationiPage extends StatelessWidget {
  const CationiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RisultatiPage(famiglia: FamigliaAnalisi.cationi);
  }
}
