import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello per un appuntamento nel calendario aziendale.
/// Corrisponde al documento `appuntamenti/{id}` in Firestore.
class AppuntamentoModel {
  final String id;
  final String titolo;
  final String descrizione;
  final DateTime dataInizio;
  final DateTime dataFine;

  /// Tipo appuntamento: 'reg_lab' | 'pest' | 'generico' | 'lettura_piastre' | 'richiamo'
  final String tipo;

  /// ID Firestore del cliente collegato (opzionale)
  final String? clienteId;

  /// Snapshot nome cliente per display rapido senza query extra
  final String? clienteNome;

  /// ID del servizio lab o pest collegato (opzionale)
  final String? servizioCid;

  /// Tecnico assegnato all'appuntamento
  final String? tecnico;

  /// Se true, verrà generata una notifica in-app prima della scadenza
  final bool notificaAbilitata;

  /// Giorni di anticipo per la notifica (0 = stesso giorno, 1 = 1 giorno prima...)
  final int notificaGiorniPrima;

  /// Anticipo in minuti per la notifica oraria (es. 15, 30, 60, 120)
  /// 0 = notifica all'ora esatta dell'appuntamento
  final int notificaMinutiPrima;

  /// Se true, l'appuntamento è stato completato/archiviato
  final bool completato;

  /// Colore hex per la visualizzazione nel calendario (es. '#1565C0')
  final String colore;

  /// UID dell'utente che ha creato l'appuntamento
  final String creadaDa;

  final DateTime createdAt;

  const AppuntamentoModel({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.dataInizio,
    required this.dataFine,
    required this.tipo,
    this.clienteId,
    this.clienteNome,
    this.servizioCid,
    this.tecnico,
    required this.notificaAbilitata,
    required this.notificaGiorniPrima,
    this.notificaMinutiPrima = 0,
    required this.completato,
    required this.colore,
    required this.creadaDa,
    required this.createdAt,
  });

  /// Crea un [AppuntamentoModel] da un documento Firestore
  factory AppuntamentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppuntamentoModel(
      id: doc.id,
      titolo: data['titolo'] as String? ?? '',
      descrizione: data['descrizione'] as String? ?? '',
      dataInizio:
          (data['dataInizio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataFine: (data['dataFine'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipo: data['tipo'] as String? ?? 'generico',
      clienteId: data['clienteId'] as String?,
      clienteNome: data['clienteNome'] as String?,
      servizioCid: data['servizioCid'] as String?,
      tecnico: data['tecnico'] as String?,
      notificaAbilitata: data['notificaAbilitata'] as bool? ?? false,
      notificaGiorniPrima: (data['notificaGiorniPrima'] as num?)?.toInt() ?? 1,
      notificaMinutiPrima: data['notificaMinutiPrima'] as int? ?? 0,
      completato: data['completato'] as bool? ?? false,
      colore: data['colore'] as String? ?? '#5F5E5A',
      creadaDa: data['creadaDa'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'titolo': titolo,
      'descrizione': descrizione,
      'dataInizio': Timestamp.fromDate(dataInizio),
      'dataFine': Timestamp.fromDate(dataFine),
      'tipo': tipo,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'servizioCid': servizioCid,
      'tecnico': tecnico,
      'notificaAbilitata': notificaAbilitata,
      'notificaGiorniPrima': notificaGiorniPrima,
      'notificaMinutiPrima': notificaMinutiPrima,
      'completato': completato,
      'colore': colore,
      'creadaDa': creadaDa,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Colore hex standard associato al tipo di appuntamento
  static String coloreHexDaTipo(String tipo) {
    switch (tipo) {
      case 'reg_lab':
        return '#1565C0'; // blu
      case 'pest':
        return '#00A843'; // verde
      case 'lettura_piastre':
        return '#E65100'; // arancio
      case 'richiamo':
        return '#BA7517'; // ambra
      case 'generico':
      default:
        return '#5F5E5A'; // grigio
    }
  }

  /// Etichetta leggibile per il tipo appuntamento
  static String labelTipo(String tipo) {
    switch (tipo) {
      case 'reg_lab':
        return 'Reg Lab';
      case 'pest':
        return 'Pest';
      case 'lettura_piastre':
        return 'Lettura piastre';
      case 'richiamo':
        return 'Richiamo';
      case 'generico':
      default:
        return 'Generico';
    }
  }

  @override
  String toString() =>
      'AppuntamentoModel(id: $id, titolo: $titolo, tipo: $tipo, dataInizio: $dataInizio)';
}
