import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../features/laboratorio/famiglie_analisi.dart';
import '../features/stampa_unione/stampa_unione_service.dart';
import '../utils/web_download.dart';
import 'impostazioni_service.dart';

final _verde = PdfColor.fromHex('00A843');
final _verdeDark = PdfColor.fromHex('003D1E');
final _grigio = PdfColor.fromHex('555555');
final _grigioChi = PdfColor.fromHex('F5F5F5');
final _bordo = PdfColor.fromHex('E0E0E0');

/// Genera il PDF del certificato di analisi a partire da una riga aggregata
/// della Stampa unione.
///
/// ⚠️ **BOZZA / layout provvisorio.** Il modello di certificato definitivo del
/// cliente (intestazione di accreditamento, diciture, ordine parametri) non è
/// ancora disponibile: questo PDF va rifinito quando arriverà (AREA E/G del
/// PIANO_GENERALE.md). Nel frattempo dà un output leggibile e stampabile.
class CertificatoPdfService {
  late pw.Font _f;
  late pw.Font _fb;

  Future<void> stampaCertificato(RigaStampaUnione riga) async {
    final bytes = await buildPdfBytes(riga);
    final nome = 'certificato_${riga.certNumb}.pdf';
    if (kIsWeb) {
      await downloadBytes(
          bytes: bytes, mimeType: 'application/pdf', fileName: nome);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: nome);
    }
  }

  Future<Uint8List> buildPdfBytes(RigaStampaUnione riga) async {
    _f = await PdfGoogleFonts.robotoRegular();
    _fb = await PdfGoogleFonts.robotoBold();

    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final dati = await ImpostazioniService().getDatiAzienda();
    final theme = pw.ThemeData.withFont(base: _f, bold: _fb);
    final doc = pw.Document(title: 'Certificato ${riga.certNumb}');

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 40),
          theme: theme,
        ),
        header: (ctx) => _intestazione(logo, dati),
        footer: (ctx) => pw.Column(children: [
          pw.Divider(color: _bordo, thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BOZZA — layout provvisorio in attesa del modello definitivo',
                style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.red,
                    fontStyle: pw.FontStyle.italic),
              ),
              pw.Text('Pag. ${ctx.pageNumber}/${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: _grigio)),
            ],
          ),
        ]),
        build: (ctx) => [
          _boxCampione(riga),
          pw.SizedBox(height: 12),
          for (final fam in StampaUnioneService.famiglie)
            if (riga.perFamiglia[fam.id] != null) ...[
              _tabellaFamiglia(fam, riga),
              pw.SizedBox(height: 10),
            ],
          pw.SizedBox(height: 16),
          _firma(dati),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _intestazione(pw.MemoryImage? logo, dynamic dati) {
    return pw.Column(children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.SizedBox(height: 46, width: 120, child: pw.Image(logo)),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(dati.ragioneSociale as String,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('${dati.indirizzo}, ${dati.cap} ${dati.citta} (${dati.provincia})',
                  style: pw.TextStyle(fontSize: 8, color: _grigio)),
              pw.Text('P.IVA ${dati.piva} · ${dati.telefonoLab}',
                  style: pw.TextStyle(fontSize: 8, color: _grigio)),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        decoration: pw.BoxDecoration(color: _verdeDark),
        alignment: pw.Alignment.center,
        child: pw.Text('RAPPORTO DI PROVA / CERTIFICATO DI ANALISI',
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      ),
      pw.SizedBox(height: 10),
    ]);
  }

  pw.Widget _boxCampione(RigaStampaUnione riga) {
    pw.Widget riga2(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                  text: '$k: ',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(
                  text: v, style: const pw.TextStyle(fontSize: 9)),
            ]),
          ),
        );
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _grigioChi,
        border: pw.Border.all(color: _bordo, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          riga2('N° certificato', riga.certNumb),
          riga2('Codice campione (Cod A)', riga.codA.isNotEmpty ? riga.codA : '—'),
          riga2('Committente',
              riga.committente.isNotEmpty ? riga.committente : '—'),
        ],
      ),
    );
  }

  pw.Widget _tabellaFamiglia(FamigliaAnalisi fam, RigaStampaUnione riga) {
    final r = riga.perFamiglia[fam.id]!;
    final righeValori = fam.colonne
        .where((c) => (r.valori[c.key] ?? '').isNotEmpty)
        .toList();
    if (righeValori.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(fam.titolo.toUpperCase(),
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _verde)),
        pw.SizedBox(height: 3),
        pw.Table(
          border: pw.TableBorder.all(color: _bordo, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
          },
          children: [
            for (final c in righeValori)
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  child: pw.Text(c.label,
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  child: pw.Text(r.valori[c.key] ?? '',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _firma(dynamic dati) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(dati.firmaTitolo as String,
                style: pw.TextStyle(fontSize: 8, color: _grigio)),
            pw.SizedBox(height: 2),
            pw.Text(dati.firmaNome as String,
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(dati.firmaIscrizione as String,
                style: pw.TextStyle(fontSize: 7, color: _grigio)),
          ],
        ),
      ],
    );
  }
}
