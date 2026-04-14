import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello per una notifica in-app dell'utente.
///
/// Struttura Firestore: notifiche/{uid}/items/{notificaId}
/// Ogni utente ha la propria sotto-collezione di notifiche.
class NotificaModel {
  final String id;
  final String titolo;
  final String corpo;

  /// Tipo notifica (stesso tipo di AppuntamentoModel):
  /// 'reg_lab' | 'pest' | 'generico' | 'lettura_piastre' | 'richiamo'
  final String tipo;

  /// ID dell'appuntamento collegato (opzionale)
  final String? appuntamentoId;

  /// Se true, la notifica è stata letta dall'utente
  final bool letta;

  final DateTime createdAt;

  /// Data di scadenza della notifica (opzionale, usata per l'ordinamento)
  final DateTime? scadenza;

  const NotificaModel({
    required this.id,
    required this.titolo,
    required this.corpo,
    required this.tipo,
    this.appuntamentoId,
    required this.letta,
    required this.createdAt,
    this.scadenza,
  });

  /// Crea un [NotificaModel] da un documento Firestore
  factory NotificaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificaModel(
      id: doc.id,
      titolo: data['titolo'] as String? ?? '',
      corpo: data['corpo'] as String? ?? '',
      tipo: data['tipo'] as String? ?? 'generico',
      appuntamentoId: data['appuntamentoId'] as String?,
      letta: data['letta'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scadenza: (data['scadenza'] as Timestamp?)?.toDate(),
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'titolo': titolo,
      'corpo': corpo,
      'tipo': tipo,
      'appuntamentoId': appuntamentoId,
      'letta': letta,
      'createdAt': Timestamp.fromDate(createdAt),
      'scadenza': scadenza != null ? Timestamp.fromDate(scadenza!) : null,
    };
  }

  /// Restituisce una copia della notifica con [letta] = true
  NotificaModel copyWithLetta() {
    return NotificaModel(
      id: id,
      titolo: titolo,
      corpo: corpo,
      tipo: tipo,
      appuntamentoId: appuntamentoId,
      letta: true,
      createdAt: createdAt,
      scadenza: scadenza,
    );
  }

  @override
  String toString() =>
      'NotificaModel(id: $id, titolo: $titolo, letta: $letta)';
}
