import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/preventivo_model.dart';
import '../utils/web_download.dart';

// ─── Colori brand BioChem ─────────────────────────────────────────────────────
final _verde = PdfColor.fromHex('00A843');
final _verdeDark = PdfColor.fromHex('003D1E');
final _verdeLight = PdfColor.fromHex('C8F5DC');
final _blu = PdfColor.fromHex('1565C0');
final _grigio = PdfColor.fromHex('555555');
final _grigioChi = PdfColor.fromHex('F5F5F5');
final _bordo = PdfColor.fromHex('E0E0E0');
final _bordoVerde = PdfColor.fromHex('C8F5DC');
const _bianco = PdfColors.white;
const _nero = PdfColors.black;

/// Genera e condivide il PDF di un preventivo BioChem.
/// Replica fedelmente il layout del documento cartaceo.
class PreventivoPdfService {
  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);
  final _dateFmt = DateFormat('dd/MM/yyyy');

  late pw.Font _f; // Roboto Regular
  late pw.Font _fb; // Roboto Bold
  late pw.Font _fi; // Roboto Italic

  // ─── Entry point pubblici ─────────────────────────────────────────────────

  Future<void> stampaPreventivo(PreventivoModel p) async {
    final bytes = await buildPdfBytes(p);
    if (kIsWeb) {
      await downloadBytes(
        bytes: bytes,
        mimeType: 'application/pdf',
        fileName: 'preventivo_${p.numeroFormattato}.pdf',
      );
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'preventivo_${p.numeroFormattato}.pdf',
      );
    }
  }

  Future<Uint8List> buildPdfBytes(PreventivoModel p) => _buildPdfBytes(p);

  // ─── Costruzione documento ────────────────────────────────────────────────

  Future<Uint8List> _buildPdfBytes(PreventivoModel p) async {
    _f = await PdfGoogleFonts.robotoRegular();
    _fb = await PdfGoogleFonts.robotoBold();
    _fi = await PdfGoogleFonts.robotoItalic();

    // Carica logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final doc = pw.Document(
      title: p.numeroFormattato,
      author: 'Biochem',
      subject: 'Preventivo',
    );

    final theme = pw.ThemeData.withFont(base: _f, bold: _fb);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 44),
          theme: theme,
        ),
        footer: (ctx) => _buildFooter(ctx, p),
        build: (ctx) => [
          _buildHeader(p, logoImage),
          pw.SizedBox(height: 10),
          _buildTagline(),
          pw.SizedBox(height: 10),
          _buildDatiCliente(p),
          pw.SizedBox(height: 10),
          _buildIndirizzoServizio(p),
          pw.SizedBox(height: 6),
          _buildOggetto(p),
          pw.SizedBox(height: 12),
          _buildDettaglioServizi(p),
          pw.SizedBox(height: 10),
          _buildTotale(p),
          pw.SizedBox(height: 10),
          _buildCondizioni(p),
          if (p.note.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildNote(p),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            'Tutte le altre prestazioni professionali saranno eseguite secondo quanto previsto da metodi, norme tecniche in vigore all’atto della fornitura, su tutti gli interventi viene rilasciato attestato/certificato in funzione dell\'attività svolta. PER ULTERIORI INFO SI VEDANO ANCHE CONDIZIONI GENERALI DEI SERVIZI',
            style: pw.TextStyle(fontSize: 7, color: _grigio),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Tutti i prezzi sono da considerarsi IVA esclusa secondo le disposizioni di legge in vigore a quel momento e validi per la durata dell’appalto.',
            style: pw.TextStyle(fontSize: 7, color: _grigio),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 10),
          _buildIban(p),
          pw.SizedBox(height: 8),
          _buildDisclaimer(),
          pw.SizedBox(height: 24),
          _buildFirme(p),
        ],
      ),
    );

    return doc.save();
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  // Logo | sito | QR-like box || pvr off n° | ora | data | mod: preventivo

  pw.Widget _buildHeader(PreventivoModel p, pw.MemoryImage? logo) {
    final numeroTesto = p.numeroFormattato;
    final oraTesto = p.ora.isNotEmpty ? p.ora : '';
    final dataTesto = _dateFmt.format(p.data);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo + sito
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Container(
                width: 110,
                height: 44,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            else
              pw.Text('BioChem',
                  style: pw.TextStyle(font: _fb, fontSize: 20, color: _verde)),
            pw.SizedBox(height: 3),
            pw.Text('www.biochemlabs.it',
                style: pw.TextStyle(fontSize: 7, color: _blu)),
          ],
        ),
        pw.Spacer(),
        // pvr off n° | ora | data | mod
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(children: [
              _headerMetaLabel('pvr off n°'),
              pw.SizedBox(width: 4),
              _headerMetaValue(numeroTesto),
              pw.SizedBox(width: 12),
              _headerMetaLabel('ora'),
              pw.SizedBox(width: 4),
              _headerMetaValue(oraTesto),
            ]),
            pw.SizedBox(height: 3),
            pw.Row(children: [
              _headerMetaLabel('data:'),
              pw.SizedBox(width: 4),
              _headerMetaValue(dataTesto),
            ]),
            pw.SizedBox(height: 3),
            pw.Row(children: [
              _headerMetaLabel('mod'),
              pw.SizedBox(width: 4),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _blu,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text('preventivo',
                    style:
                        pw.TextStyle(font: _fb, fontSize: 9, color: _bianco)),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _headerMetaLabel(String t) =>
      pw.Text(t, style: pw.TextStyle(fontSize: 8, color: _grigio));

  pw.Widget _headerMetaValue(String t) =>
      pw.Text(t, style: pw.TextStyle(font: _fb, fontSize: 9, color: _nero));

  // ─── TAGLINE ──────────────────────────────────────────────────────────────

  pw.Widget _buildTagline() {
    return pw.Text(
      'Analisi chimiche disinfestazioni, piani di monitoraggio per ambienti più sicuri e salubri',
      style: pw.TextStyle(
          fontSize: 7, color: _grigio, fontStyle: pw.FontStyle.italic),
    );
  }

  // ─── DATI CLIENTE — griglia 2 colonne ────────────────────────────────────
  // Sinistra: dati azienda | Destra: Spett. / alla cortese att.

  pw.Widget _buildDatiCliente(PreventivoModel p) {
    return pw.Table(
      border: pw.TableBorder.all(color: _bordo, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          // Colonna sinistra: dati azienda
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(p.committente,
                    style: pw.TextStyle(font: _fb, fontSize: 11, color: _nero)),
                pw.SizedBox(height: 3),
                pw.Text(p.indirizzoCommittente,
                    style: pw.TextStyle(fontSize: 9, color: _grigio)),
                pw.Text(
                    '${p.cap} ${p.citta}${p.provincia.isNotEmpty ? " (${p.provincia})" : ""}',
                    style: pw.TextStyle(fontSize: 9, color: _grigio)),
                pw.SizedBox(height: 4),
                _rigaInfo('P.I.', p.codiceFiscale),
                _rigaInfo('CU', p.codiceUnivoco),
              ],
            ),
          ),
          // Colonna destra: Spett.
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _rigaInfoLinea('Spett.', p.spett.isNotEmpty ? p.spett : '#N/A'),
                _rigaInfoLinea('alla cortese att. D',
                    p.allaCorteseDi.isNotEmpty ? p.allaCorteseDi : '#N/A'),
                _rigaInfoLinea('indirizzo',
                    p.indirizzoSpett.isNotEmpty ? p.indirizzoSpett : '#N/A'),
                _rigaInfoLinea(
                    'città', p.cittaSpett.isNotEmpty ? p.cittaSpett : '#N/A'),
                _rigaInfoLinea('PI', p.piSpett.isNotEmpty ? p.piSpett : '#N/A'),
                _rigaInfoLinea('CU', p.cuSpett.isNotEmpty ? p.cuSpett : '#N/A'),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  pw.Widget _rigaInfo(String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 30,
          child:
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _grigio)),
        ),
        pw.Text(val.isNotEmpty ? val : '—',
            style: pw.TextStyle(font: _fb, fontSize: 8, color: _nero)),
      ]),
    );
  }

  pw.Widget _rigaInfoLinea(String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 90,
          child:
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: _grigio)),
        ),
        pw.Expanded(
          child: pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            child: pw.Text(val, style: pw.TextStyle(fontSize: 8, color: _nero)),
          ),
        ),
      ]),
    );
  }

  // ─── INDIRIZZO SERVIZIO ───────────────────────────────────────────────────

  pw.Widget _buildIndirizzoServizio(PreventivoModel p) {
    return pw.Row(children: [
      pw.Text('indirizzo servizio:',
          style: pw.TextStyle(fontSize: 8, color: _grigio)),
      pw.SizedBox(width: 6),
      pw.Expanded(
        child: pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
          ),
          child: pw.Text(
            p.indirizzoServizio.isNotEmpty ? p.indirizzoServizio : '#N/A',
            style: pw.TextStyle(fontSize: 8, color: _nero),
          ),
        ),
      ),
    ]);
  }

  // ─── OGGETTO ──────────────────────────────────────────────────────────────

  pw.Widget _buildOggetto(PreventivoModel p) {
    if (p.oggetto.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Oggetto:', style: pw.TextStyle(fontSize: 8, color: _grigio)),
        pw.SizedBox(height: 2),
        pw.Text(p.oggetto, style: pw.TextStyle(fontSize: 9, color: _nero)),
      ],
    );
  }

  // ─── DETTAGLIO SERVIZI ────────────────────────────────────────────────────
  // Giornata/esecuzione | Tipologia Servizi — sopra la tabella

  pw.Widget _buildDettaglioServizi(PreventivoModel p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Riga giornata + tipologia
        pw.Row(children: [
          pw.Expanded(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _bordo, width: 0.5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Row(children: [
                pw.Text('Giornata/esecuzione  ',
                    style: pw.TextStyle(fontSize: 8, color: _grigio)),
                pw.Text(
                  p.giornataEsecuzione.isNotEmpty
                      ? p.giornataEsecuzione
                      : 'FERIALE',
                  style: pw.TextStyle(font: _fb, fontSize: 9, color: _verde),
                ),
              ]),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _bordo, width: 0.5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Row(children: [
                pw.Text('Tipologia Servizi  ',
                    style: pw.TextStyle(fontSize: 8, color: _grigio)),
                pw.Text(
                  p.tipologiaServizi.isNotEmpty ? p.tipologiaServizi : '—',
                  style: pw.TextStyle(font: _fb, fontSize: 9, color: _verde),
                ),
              ]),
            ),
          ),
        ]),
        pw.SizedBox(height: 6),
        // Tabella righe
        _buildTabellaRighe(p),
      ],
    );
  }

  pw.Widget _buildTabellaRighe(PreventivoModel p) {
    // Header tabella — sfondo verde scuro
    final header = pw.TableRow(
      decoration: pw.BoxDecoration(color: _verdeDark),
      children: [
        _thCell('cod'),
        _thCell('parametro/servizio', flex: true),
        _thCell('cad'),
        _thCell('num'),
        _thCell('sct %'),
        _thCell('cst an/ser'),
        _thCell('tot'),
      ],
    );

    final righe = p.righe.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      final prezzoScontato =
          r.prezzoUnitario - r.prezzoUnitario * r.scontoPerc / 100;
      final costoAnnoSer = prezzoScontato * r.quantita;
      final bg = i.isOdd ? PdfColor.fromHex('F5FBF5') : _bianco;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          _tdCell(r.codice, small: true, color: _blu),
          _tdCell(r.descrizione, flex: true),
          _tdCell(_moneyFmt.format(r.prezzoUnitario),
              align: pw.TextAlign.right),
          _tdCell('${r.quantita}', align: pw.TextAlign.center),
          _tdCell(r.scontoPerc > 0 ? '${r.scontoPerc.toStringAsFixed(1)}' : '—',
              align: pw.TextAlign.center),
          _tdCell(_moneyFmt.format(costoAnnoSer), align: pw.TextAlign.right),
          _tdCell(_moneyFmt.format(r.importo),
              align: pw.TextAlign.right, bold: true),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _bordo, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(48), // cod
        1: const pw.FlexColumnWidth(3), // parametro/servizio
        2: const pw.FixedColumnWidth(58), // cad
        3: const pw.FixedColumnWidth(28), // num
        4: const pw.FixedColumnWidth(38), // sct %
        5: const pw.FixedColumnWidth(68), // cst an/ser
        6: const pw.FixedColumnWidth(68), // tot
      },
      children: [header, ...righe],
    );
  }

  pw.Widget _thCell(String t, {bool flex = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t,
            textAlign: flex ? pw.TextAlign.left : pw.TextAlign.center,
            style: pw.TextStyle(font: _fb, fontSize: 8, color: _bianco)),
      );

  pw.Widget _tdCell(
    String t, {
    bool flex = false,
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    bool small = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(t,
            textAlign: align,
            style: pw.TextStyle(
              font: bold ? _fb : _f,
              fontSize: small ? 7 : 8,
              color: color ?? _nero,
            )),
      );

  // ─── TOTALE ───────────────────────────────────────────────────────────────

  pw.Widget _buildTotale(PreventivoModel p) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _bordoVerde, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(children: [
            pw.Text('Totale',
                style:
                    pw.TextStyle(font: _fb, fontSize: 11, color: _verdeDark)),
            pw.SizedBox(width: 24),
            pw.Text(_moneyFmt.format(p.totale),
                style:
                    pw.TextStyle(font: _fb, fontSize: 13, color: _verdeDark)),
          ]),
        ),
      ],
    );
  }

  // ─── CONDIZIONI ───────────────────────────────────────────────────────────

  pw.Widget _buildCondizioni(PreventivoModel p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // PAGAMENTO — riga intera
        if (p.pagamento.isNotEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _bordo, width: 0.5),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(children: [
              pw.Text('PAGAMENTO: ',
                  style: pw.TextStyle(font: _fb, fontSize: 8, color: _nero)),
              pw.Text(p.pagamento,
                  style: pw.TextStyle(fontSize: 8, color: _grigio)),
            ]),
          ),
        pw.SizedBox(height: 4),
        // Durata contratto | Rinnovo a scadenza
        pw.Row(children: [
          pw.Expanded(
            child: _buildCondizioneBox(
              'durata contratto:',
              p.durataContratto.isNotEmpty
                  ? p.durataContratto
                  : 'non specificata',
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _buildCondizioneBox(
              'rinnovo a scadenza:',
              p.rinnovoScadenza.isNotEmpty ? p.rinnovoScadenza : '—',
            ),
          ),
        ]),
        pw.SizedBox(height: 4),
        // Periodo intervento | Validità offerta
        pw.Row(children: [
          pw.Expanded(
            child: _buildCondizioneBox(
              'Periodo intervento',
              p.periodoIntervento.isNotEmpty ? p.periodoIntervento : '—',
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _buildCondizioneBox(
              'validità offerta:',
              p.validita.isNotEmpty ? p.validita : '30 giorni',
            ),
          ),
        ]),
      ],
    );
  }

  pw.Widget _buildCondizioneBox(String label, String val) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _bordo, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(children: [
        pw.Text('$label  ', style: pw.TextStyle(fontSize: 7, color: _grigio)),
        pw.Expanded(
          child: pw.Text(val,
              style: pw.TextStyle(font: _fb, fontSize: 8, color: _nero)),
        ),
      ]),
    );
  }

  // ─── NOTE ─────────────────────────────────────────────────────────────────

  pw.Widget _buildNote(PreventivoModel p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grigioChi,
        border: pw.Border.all(color: _bordo, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'NOTE VARIE SERVIZI CONDIZIONI OFFERTA',
            style: pw.TextStyle(font: _fb, fontSize: 8, color: _nero),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            p.note,
            style: pw.TextStyle(
              fontSize: 8,
              color: _grigio,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── IBAN ─────────────────────────────────────────────────────────────────

  pw.Widget _buildIban(PreventivoModel p) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grigioChi,
        border: pw.Border.all(color: _bordo, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (p.intestatoA.isNotEmpty)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Intestato a: ',
                        style: pw.TextStyle(fontSize: 8, color: _grigio),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          p.intestatoA,
                          style: pw.TextStyle(
                            font: _fb,
                            fontSize: 8,
                            color: _nero,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (p.causale.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Causale: ',
                        style: pw.TextStyle(fontSize: 8, color: _grigio),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          p.causale,
                          style: pw.TextStyle(
                            font: _fb,
                            fontSize: 8,
                            color: _nero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 40),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Biochemlabs',
                  style: pw.TextStyle(font: _fb, fontSize: 10, color: _verde),
                ),
                pw.Text(
                  'il chimico',
                  style: pw.TextStyle(font: _fi, fontSize: 9, color: _nero),
                ),
                pw.Text(
                  'Dr. Leonardo Daga',
                  style: pw.TextStyle(fontSize: 9, color: _nero),
                ),
                pw.Text(
                  'iscr. Ord. Pur Chimici n° 219A',
                  style: pw.TextStyle(fontSize: 7, color: _grigio),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── FIRME ────────────────────────────────────────────────────────────────

  pw.Widget _buildFirme(PreventivoModel p) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DATA, LUOGO',
                style: pw.TextStyle(fontSize: 8, color: _grigio),
              ),
              pw.SizedBox(height: 28),
              pw.Divider(color: _nero, height: 1),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FIRMA CLIENTE',
                style: pw.TextStyle(fontSize: 8, color: _grigio),
              ),
              pw.SizedBox(height: 28),
              pw.Divider(color: _nero, height: 1),
            ],
          ),
        ),
      ],
    );
  }

  // ─── DISCLAIMER ───────────────────────────────────────────────────────────

  pw.Widget _buildDisclaimer() {
    return pw.Text(
      'si accettano per presa visione le condizioni generali della fornitura, '
      'e determinazioni come da contratto o accordo di vendita.',
      style: pw.TextStyle(fontSize: 7, color: _grigio),
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx, PreventivoModel p) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${p.numeroFormattato} — ${p.committente}',
            style: pw.TextStyle(fontSize: 7, color: _grigio),
          ),
          pw.Text(
            'Pagina ${ctx.pageNumber} di ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: _grigio),
          ),
        ],
      ),
    );
  }
}
