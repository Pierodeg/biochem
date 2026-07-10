import 'package:flutter/material.dart';
import '../../laboratorio/famiglie_analisi.dart';
import '../../laboratorio/screens/risultati_page.dart';

/// Sezione Microbiologia — risultati analisi microbiologiche (task 9).
class MicrobioPage extends StatelessWidget {
  const MicrobioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RisultatiPage(famiglia: FamigliaAnalisi.microbio);
  }
}
