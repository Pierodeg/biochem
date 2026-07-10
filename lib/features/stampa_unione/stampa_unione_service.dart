import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/risultato_analisi_model.dart';
import '../../models/servizio_lab_model.dart';
import '../laboratorio/famiglie_analisi.dart';

/// Una riga aggregata della Stampa unione: un certificato con i risultati
/// di tutte le famiglie collegate (per `certNumb`).
class RigaStampaUnione {
  final String certNumb;
  final String codA;
  final String committente;

  /// Risultati per famiglia (`famiglia.id` → risultato), assenti se non caricati.
  final Map<String, RisultatoAnalisi> perFamiglia;

  const RigaStampaUnione({
    required this.certNumb,
    required this.codA,
    required this.committente,
    required this.perFamiglia,
  });

  int get famiglieCompilate => perFamiglia.length;
}

/// Aggrega Reg Lab (`servizi_lab`) + le collection di risultati in righe
/// per certificato. Sola lettura — base dati del certificato PDF (AREA E).
class StampaUnioneService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<FamigliaAnalisi> famiglie = [
    FamigliaAnalisi.primarie,
    FamigliaAnalisi.cationi,
    FamigliaAnalisi.anioni,
    FamigliaAnalisi.microbio,
  ];

  Future<List<RigaStampaUnione>> caricaRighe() async {
    // 1. Campioni da Reg Lab.
    final serviziSnap = await _db.collection('servizi_lab').get();
    final campioni = <String, ServizioLabModel>{};
    for (final doc in serviziSnap.docs) {
      final s = ServizioLabModel.fromFirestore(doc);
      if (s.certificazioneNumerica.isNotEmpty) {
        campioni[s.certificazioneNumerica] = s;
      }
    }

    // 2. Risultati per famiglia, indicizzati per certNumb.
    final risultatiPerFamiglia = <String, Map<String, RisultatoAnalisi>>{};
    for (final fam in famiglie) {
      final snap = await _db.collection(fam.collection).get();
      final map = <String, RisultatoAnalisi>{};
      for (final doc in snap.docs) {
        final r = RisultatoAnalisi.fromFirestore(doc);
        if (r.certNumb.isNotEmpty) map[r.certNumb] = r;
      }
      risultatiPerFamiglia[fam.id] = map;
    }

    // 3. Unione delle chiavi (campioni + tutte le famiglie).
    final chiavi = <String>{
      ...campioni.keys,
      for (final m in risultatiPerFamiglia.values) ...m.keys,
    };

    final righe = <RigaStampaUnione>[];
    for (final cert in chiavi) {
      final campione = campioni[cert];
      final perFamiglia = <String, RisultatoAnalisi>{};
      String codA = campione?.codiceA ?? '';
      String committente = campione?.committente ?? '';
      for (final fam in famiglie) {
        final r = risultatiPerFamiglia[fam.id]?[cert];
        if (r != null) {
          perFamiglia[fam.id] = r;
          if (codA.isEmpty) codA = r.codA;
          if (committente.isEmpty) committente = r.committente;
        }
      }
      righe.add(RigaStampaUnione(
        certNumb: cert,
        codA: codA,
        committente: committente,
        perFamiglia: perFamiglia,
      ));
    }

    // Ordina per certificato (numerico se possibile).
    righe.sort((a, b) {
      final na = int.tryParse(a.certNumb);
      final nb = int.tryParse(b.certNumb);
      if (na != null && nb != null) return nb.compareTo(na);
      return b.certNumb.compareTo(a.certNumb);
    });
    return righe;
  }
}
