import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/certificato_pdf_service.dart';
import '../../laboratorio/famiglie_analisi.dart';
import '../stampa_unione_service.dart';

/// Sezione Stampa unione — vista aggregata per certificato (task 8, AREA D).
///
/// Sola lettura: unisce Reg Lab + le famiglie di risultati per `certNumb`.
/// Base dati del certificato PDF (AREA E).
class StampaUnionePage extends StatefulWidget {
  const StampaUnionePage({super.key});

  @override
  State<StampaUnionePage> createState() => _StampaUnionePageState();
}

class _StampaUnionePageState extends State<StampaUnionePage> {
  final _service = StampaUnioneService();
  late Future<List<RigaStampaUnione>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _service.caricaRighe();
  }

  void _ricarica() {
    setState(() => _future = _service.caricaRighe());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: FutureBuilder<List<RigaStampaUnione>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentGreenDark));
              }
              if (snap.hasError) {
                return Center(
                  child: Text('Errore: ${snap.error}',
                      style: const TextStyle(color: AppColors.error)),
                );
              }
              final righe = (snap.data ?? []).where((r) {
                if (_query.isEmpty) return true;
                final q = _query.toLowerCase();
                return r.committente.toLowerCase().contains(q) ||
                    r.certNumb.toLowerCase().contains(q);
              }).toList();
              if (righe.isEmpty) {
                return const Center(
                  child: Text(
                    'Nessun dato aggregato. Registra campioni e risultati.',
                    style: TextStyle(color: AppColors.textOnDarkMuted),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: righe.length,
                itemBuilder: (context, i) => _RigaUnione(riga: righe[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: AppColors.textOnDark),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cerca committente o n° certificato…',
                hintStyle: const TextStyle(color: AppColors.textOnDarkMuted),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textOnDarkSecondary, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.glassDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _ricarica,
            tooltip: 'Ricarica',
            icon: const Icon(Icons.refresh,
                color: AppColors.accentGreenDark),
          ),
        ],
      ),
    );
  }
}

class _RigaUnione extends StatelessWidget {
  final RigaStampaUnione riga;
  const _RigaUnione({required this.riga});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.glassCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.accentGreenDark,
          collapsedIconColor: AppColors.textOnDarkMuted,
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              riga.certNumb.isNotEmpty ? riga.certNumb : '—',
              style: const TextStyle(
                color: AppColors.accentGreenDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          title: Text(
            riga.committente.isNotEmpty
                ? riga.committente
                : '(senza committente)',
            style: const TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Cod A ${riga.codA.isNotEmpty ? riga.codA : "—"} · ${riga.famiglieCompilate}/${StampaUnioneService.famiglie.length} analisi',
            style: const TextStyle(
                color: AppColors.textOnDarkSecondary, fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            for (final fam in StampaUnioneService.famiglie)
              _buildFamiglia(fam),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () =>
                    CertificatoPdfService().stampaCertificato(riga),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Certificato (bozza)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentGreenDark,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamiglia(FamigliaAnalisi fam) {
    final r = riga.perFamiglia[fam.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(fam.icona, size: 15, color: AppColors.accentGreenDark),
            const SizedBox(width: 6),
            Text(
              fam.titolo,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (r == null)
          const Padding(
            padding: EdgeInsets.only(left: 21, bottom: 4),
            child: Text('— non compilata',
                style: TextStyle(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                for (final col in fam.colonne)
                  if ((r.valori[col.key] ?? '').isNotEmpty)
                    Text(
                      '${col.label}: ${r.valori[col.key]}',
                      style: const TextStyle(
                          color: AppColors.textOnDarkSecondary, fontSize: 12),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}
