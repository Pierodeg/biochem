import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/preventivo_model.dart';

// ─── Costanti colori PDF (da AppColors) ──────────────────────────────────────

final _verde = PdfColor.fromHex('00A843');
final _verdeDark = PdfColor.fromHex('003D1E');
final _verdeLightest = PdfColor.fromHex('E8FFF2');
final _verdeLight = PdfColor.fromHex('C8F5DC');
final _testoGrigio = PdfColor.fromHex('555555');
final _bordo = PdfColor.fromHex('E0E0E0');
const _bianco = PdfColors.white;

/// Service per la generazione e condivisione del PDF di un preventivo.
///
/// Uso:
/// ```dart
/// await PreventivoPdfService().stampaPreventivo(preventivo);
/// ```
class PreventivoPdfService {
  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '\u20AC', decimalDigits: 2);
  final _dateFmt = DateFormat('dd/MM/yyyy');

  // Font caricati una volta per generazione (supportano Unicode: €, —, ecc.)
  late pw.Font _f;   // regular
  late pw.Font _fb;  // bold

  // ─── Entry point pubblici ─────────────────────────────────────────────────

  /// Genera il PDF e apre la finestra di condivisione/stampa nativa.
  Future<void> stampaPreventivo(PreventivoModel p) async {
    final bytes = await buildPdfBytes(p);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${p.numeroFormattato}.pdf',
    );
  }

  /// Costruisce e restituisce i byte del PDF (usato anche per l'anteprima).
  Future<Uint8List> buildPdfBytes(PreventivoModel p) =>
      _buildPdfBytes(p);

  // ─── Costruzione documento ────────────────────────────────────────────────

  Future<Uint8List> _buildPdfBytes(PreventivoModel p) async {
    final doc = pw.Document(
      title: p.numeroFormattato,
      author: 'Biochem',
      subject: 'Preventivo',
    );

    // Carica logo da assets
    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Font Unicode (supporta €, —, caratteri italiani, ecc.)
    _f  = await PdfGoogleFonts.robotoRegular();
    _fb = await PdfGoogleFonts.robotoBold();

    final theme = pw.ThemeData.withFont(
      base: _f,
      bold: _fb,
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
          theme: theme,
        ),
        footer: (ctx) => _buildFooter(ctx, p),
        build: (ctx) => [
          _buildHeader(p, logoImage),
          pw.SizedBox(height: 18),
          _buildDatiCliente(p),
          pw.SizedBox(height: 14),
          _buildTabellaRighe(p),
          pw.SizedBox(height: 14),
          _buildTotali(p),
          pw.SizedBox(height: 14),
          _buildCondizioni(p),
          if (p.note.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _buildNote(p),
          ],
          pw.SizedBox(height: 28),
          _buildFirma(p),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Sezione header ───────────────────────────────────────────────────────

  pw.Widget _buildHeader(PreventivoModel p, pw.MemoryImage logo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _verdeDark,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo
          pw.Container(
            width: 90,
            height: 50,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            width: 1,
            height: 50,
            color: _bianco.shade(0.3),
          ),
          pw.SizedBox(width: 16),
          // Titolo PREVENTIVO
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PREVENTIVO',
                  style: pw.TextStyle(
                    font: _fb,
                    fontSize: 22,
                    color: _bianco,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  p.numeroFormattato,
                  style: pw.TextStyle(
                    font: _fb,
                    fontSize: 13,
                    color: _verdeLight,
                  ),
                ),
              ],
            ),
          ),
          // Data + stato
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Data: ${_dateFmt.format(p.data)}',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: _bianco,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: p.isDraft
                      ? PdfColor.fromHex('E65100')
                      : _verde,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  p.isDraft ? 'BOZZA' : 'CONFERMATO',
                  style: pw.TextStyle(
                    font: _fb,
                    fontSize: 9,
                    color: _bianco,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dati cliente ─────────────────────────────────────────────────────────

  pw.Widget _buildDatiCliente(PreventivoModel p) {
    return _buildSezione(
      titolo: 'DATI CLIENTE',
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          _rigaTabCliente('Tipo committente', p.tipoCommittente,
              'Committente', p.committente),
          _rigaTabCliente('Indirizzo', p.indirizzoCommittente,
              'CAP / Città / Prov.',
              '${p.cap} ${p.citta}${p.provincia.isNotEmpty ? ' (${p.provincia})' : ''}'),
          _rigaTabCliente('C.F. / P.IVA', p.codiceFiscale,
              'Codice univoco', p.codiceUnivoco),
          if (p.referente.isNotEmpty)
            _rigaTabCliente('Referente', p.referente, '', ''),
        ],
      ),
    );
  }

  pw.TableRow _rigaTabCliente(
      String lbl1, String val1, String lbl2, String val2) {
    return pw.TableRow(children: [
      _cellLabel(lbl1),
      _cellValue(val1),
      if (lbl2.isNotEmpty) _cellLabel(lbl2) else pw.SizedBox(),
      if (val2.isNotEmpty) _cellValue(val2) else pw.SizedBox(),
    ]);
  }

  // ─── Tabella righe servizi ────────────────────────────────────────────────

  pw.Widget _buildTabellaRighe(PreventivoModel p) {
    const colWidths = {
      0: pw.FixedColumnWidth(24),   // N°
      1: pw.FixedColumnWidth(54),   // Codice
      2: pw.FlexColumnWidth(3),     // Descrizione
      3: pw.FlexColumnWidth(1.2),   // Giornata
      4: pw.FixedColumnWidth(60),   // Prezzo
      5: pw.FixedColumnWidth(28),   // Qta
      6: pw.FixedColumnWidth(38),   // Sconto
      7: pw.FixedColumnWidth(64),   // Importo
    };

    final intestazione = pw.TableRow(
      decoration: pw.BoxDecoration(color: _verdeDark),
      children: [
        _headerCell('N°'),
        _headerCell('Codice'),
        _headerCell('Descrizione'),
        _headerCell('Giornata'),
        _headerCell('Prezzo\nunit.'),
        _headerCell('Qta'),
        _headerCell('Sc.%'),
        _headerCell('Importo'),
      ],
    );

    final righe = p.righe.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      final bg = i.isEven
          ? PdfColors.white
          : PdfColor.fromHex('F9FDF9');
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          _dataCell('${i + 1}', align: pw.TextAlign.center),
          _dataCell(r.codice, small: true),
          _dataCell(r.descrizione),
          _dataCell(r.giornata, small: true),
          _dataCell(_moneyFmt.format(r.prezzoUnitario),
              align: pw.TextAlign.right, small: true),
          _dataCell('${r.quantita}', align: pw.TextAlign.center),
          _dataCell(
              r.scontoPerc > 0
                  ? '${r.scontoPerc.toStringAsFixed(1)}%'
                  : '—',
              align: pw.TextAlign.center,
              small: true),
          _dataCell(_moneyFmt.format(r.importo),
              align: pw.TextAlign.right,
              bold: true,
              color: _verdeDark),
        ],
      );
    }).toList();

    return _buildSezione(
      titolo: 'RIGHE SERVIZI',
      child: pw.Table(
        columnWidths: colWidths,
        border: pw.TableBorder.all(color: _bordo, width: 0.5),
        children: [intestazione, ...righe],
      ),
    );
  }

  // ─── Totali ───────────────────────────────────────────────────────────────

  pw.Widget _buildTotali(PreventivoModel p) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.SizedBox()),
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: _verdeLightest,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _verde, width: 0.5),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _rigaTotale(
                    'Imponibile', _moneyFmt.format(p.imponibile)),
                pw.Divider(color: _bordo, height: 8),
                _rigaTotale(
                  'IVA ${p.percIva.toStringAsFixed(0)}%',
                  _moneyFmt.format(p.importoIva),
                ),
                pw.Divider(color: _verde.shade(0.5), height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: pw.BoxDecoration(
                    color: _verde,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTALE',
                        style: pw.TextStyle(
                          font: _fb,
                          fontSize: 13,
                          color: _bianco,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        _moneyFmt.format(p.totale),
                        style: pw.TextStyle(
                          font: _fb,
                          fontSize: 15,
                          color: _bianco,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _rigaTotale(String label, String valore) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10, color: _testoGrigio)),
          pw.Text(valore,
              style: pw.TextStyle(
                  font: _fb,
                  fontSize: 11,
                  color: _verdeDark)),
        ],
      ),
    );
  }

  // ─── Condizioni ───────────────────────────────────────────────────────────

  pw.Widget _buildCondizioni(PreventivoModel p) {
    final voci = <_VoceCond>[
      if (p.validita.isNotEmpty)
        _VoceCond('Validità offerta', p.validita),
      if (p.modalitaPagamento.isNotEmpty)
        _VoceCond('Modalità di pagamento', p.modalitaPagamento),
      if (p.rinnovo.isNotEmpty)
        _VoceCond('Rinnovo automatico', p.rinnovo),
    ];

    if (voci.isEmpty) return pw.SizedBox();

    return _buildSezione(
      titolo: 'CONDIZIONI',
      child: pw.Row(
        children: voci
            .asMap()
            .entries
            .expand((e) => [
                  if (e.key > 0)
                    pw.Container(
                        width: 1, height: 36, color: _bordo,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 12)),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          e.value.label,
                          style: pw.TextStyle(
                              fontSize: 9, color: _testoGrigio),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          e.value.valore,
                          style: pw.TextStyle(
                            font: _fb,
                            fontSize: 11,
                            color: _verdeDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ])
            .toList(),
      ),
    );
  }

  // ─── Note ─────────────────────────────────────────────────────────────────

  pw.Widget _buildNote(PreventivoModel p) {
    return _buildSezione(
      titolo: 'NOTE',
      child: pw.Text(
        p.note,
        style: pw.TextStyle(fontSize: 10, color: _testoGrigio),
      ),
    );
  }

  // ─── Area firma ───────────────────────────────────────────────────────────

  pw.Widget _buildFirma(PreventivoModel p) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Per accettazione — Il Cliente',
                  style: pw.TextStyle(
                      fontSize: 9, color: _testoGrigio)),
              pw.SizedBox(height: 28),
              pw.Container(
                  height: 0.5, color: _bordo),
              pw.SizedBox(height: 4),
              pw.Text('Firma e timbro',
                  style: pw.TextStyle(
                      fontSize: 8, color: _testoGrigio)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Biochem',
                  style: pw.TextStyle(
                      font: _fb,
                      fontSize: 9, color: _verdeDark)),
              pw.SizedBox(height: 28),
              pw.Container(
                  height: 0.5, color: _bordo),
              pw.SizedBox(height: 4),
              pw.Text('Firma e timbro',
                  style: pw.TextStyle(
                      fontSize: 8, color: _testoGrigio)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Footer pagina ────────────────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx, PreventivoModel p) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${p.numeroFormattato} — ${p.committente}',
            style: pw.TextStyle(fontSize: 8, color: _testoGrigio),
          ),
          pw.Text(
            'Pagina ${ctx.pageNumber} di ${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _testoGrigio),
          ),
        ],
      ),
    );
  }

  // ─── Widget helper ────────────────────────────────────────────────────────

  pw.Widget _buildSezione({required String titolo, required pw.Widget child}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Intestazione sezione
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 5, 10, 5),
          decoration: pw.BoxDecoration(
            color: _verdeDark,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(5),
              topRight: pw.Radius.circular(5),
            ),
          ),
          child: pw.Text(
            titolo,
            style: pw.TextStyle(
              font: _fb,
              fontSize: 9,
              color: _bianco,
              letterSpacing: 1,
            ),
          ),
        ),
        // Contenuto
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _bordo, width: 0.5),
            borderRadius: const pw.BorderRadius.only(
              bottomLeft: pw.Radius.circular(5),
              bottomRight: pw.Radius.circular(5),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  pw.Widget _headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: _fb,
            fontSize: 8,
            color: _bianco,
          ),
        ),
      );

  pw.Widget _dataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    bool small = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            font: bold ? _fb : _f,
            fontSize: small ? 8 : 9,
            color: color ?? PdfColors.black,
          ),
        ),
      );

  pw.Widget _cellLabel(String text) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(0, 4, 8, 4),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, color: _testoGrigio),
        ),
      );

  pw.Widget _cellValue(String text) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(0, 4, 8, 4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: _fb,
            fontSize: 9,
            color: PdfColors.black,
          ),
        ),
      );
}

// ─── Helper interno ───────────────────────────────────────────────────────────

class _VoceCond {
  final String label;
  final String valore;
  const _VoceCond(this.label, this.valore);
}
