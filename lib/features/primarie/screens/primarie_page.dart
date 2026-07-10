import 'package:flutter/material.dart';
import '../../laboratorio/famiglie_analisi.dart';
import '../../laboratorio/screens/risultati_page.dart';

/// Sezione Primarie — risultati analisi chimico-fisiche (task 6).
class PrimariePage extends StatelessWidget {
  const PrimariePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RisultatiPage(famiglia: FamigliaAnalisi.primarie);
  }
}
