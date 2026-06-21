/// Dati anagrafici e bancari dell'azienda fornitrice (DaMo).
///
/// Documento Firestore: `impostazioni/dati_azienda`.
/// Compaiono di **default** nel preventivo (colonna fornitore + coordinate
/// bancarie) e sono modificabili **solo dall'amministratore**.
/// I valori di default [damo] derivano dalla carta intestata di riferimento.
class DatiAzienda {
  final String ragioneSociale;
  final String indirizzo;
  final String cap;
  final String citta;
  final String provincia;
  final String piva;
  final String codiceUnivoco;
  final String rea;
  final String telefono;
  final String telefonoLab;
  final String email;
  final String web;
  final String iban;
  final String banca;
  final String intestatarioIban;
  final String firmaTitolo; // es. "il chimico"
  final String firmaNome; // es. "Dr. Leonardo Daga"
  final String firmaIscrizione; // es. "iscr. Ord. Naz. Chimici n° 219A"

  const DatiAzienda({
    required this.ragioneSociale,
    required this.indirizzo,
    required this.cap,
    required this.citta,
    required this.provincia,
    required this.piva,
    required this.codiceUnivoco,
    required this.rea,
    required this.telefono,
    required this.telefonoLab,
    required this.email,
    required this.web,
    required this.iban,
    required this.banca,
    required this.intestatarioIban,
    required this.firmaTitolo,
    required this.firmaNome,
    required this.firmaIscrizione,
  });

  /// Valori di default DaMo (dalla carta intestata `2026_MOD_PREV_GENER`).
  static const DatiAzienda damo = DatiAzienda(
    ragioneSociale: 'DaMo Srls',
    indirizzo: 'via Nazionale, 198',
    cap: '07019',
    citta: 'Villanova Monteleone',
    provincia: 'SS',
    piva: '02776870905',
    codiceUnivoco: 'T9K4ZHO',
    rea: 'SS - 203775',
    telefono: '+39 349 7644010',
    telefonoLab: '+39 375 8622574',
    email: 'info@biochemlabs.it',
    web: 'www.biochemlabs.it',
    iban: 'IT13U0101585100000070694786',
    banca: 'Banco di Sardegna',
    intestatarioIban: 'DaMo Srls',
    firmaTitolo: 'il chimico',
    firmaNome: 'Dr. Leonardo Daga',
    firmaIscrizione: 'iscr. Ord. Naz. Chimici n° 219A',
  );

  /// Costruisce dai dati Firestore, con fallback ai default DaMo per i campi
  /// mancanti (così il documento può anche essere parziale).
  factory DatiAzienda.fromMap(Map<String, dynamic> d) => DatiAzienda(
        ragioneSociale: d['ragioneSociale'] as String? ?? damo.ragioneSociale,
        indirizzo: d['indirizzo'] as String? ?? damo.indirizzo,
        cap: d['cap'] as String? ?? damo.cap,
        citta: d['citta'] as String? ?? damo.citta,
        provincia: d['provincia'] as String? ?? damo.provincia,
        piva: d['piva'] as String? ?? damo.piva,
        codiceUnivoco: d['codiceUnivoco'] as String? ?? damo.codiceUnivoco,
        rea: d['rea'] as String? ?? damo.rea,
        telefono: d['telefono'] as String? ?? damo.telefono,
        telefonoLab: d['telefonoLab'] as String? ?? damo.telefonoLab,
        email: d['email'] as String? ?? damo.email,
        web: d['web'] as String? ?? damo.web,
        iban: d['iban'] as String? ?? damo.iban,
        banca: d['banca'] as String? ?? damo.banca,
        intestatarioIban:
            d['intestatarioIban'] as String? ?? damo.intestatarioIban,
        firmaTitolo: d['firmaTitolo'] as String? ?? damo.firmaTitolo,
        firmaNome: d['firmaNome'] as String? ?? damo.firmaNome,
        firmaIscrizione: d['firmaIscrizione'] as String? ?? damo.firmaIscrizione,
      );

  Map<String, dynamic> toMap() => {
        'ragioneSociale': ragioneSociale,
        'indirizzo': indirizzo,
        'cap': cap,
        'citta': citta,
        'provincia': provincia,
        'piva': piva,
        'codiceUnivoco': codiceUnivoco,
        'rea': rea,
        'telefono': telefono,
        'telefonoLab': telefonoLab,
        'email': email,
        'web': web,
        'iban': iban,
        'banca': banca,
        'intestatarioIban': intestatarioIban,
        'firmaTitolo': firmaTitolo,
        'firmaNome': firmaNome,
        'firmaIscrizione': firmaIscrizione,
      };

  DatiAzienda copyWith({
    String? ragioneSociale,
    String? indirizzo,
    String? cap,
    String? citta,
    String? provincia,
    String? piva,
    String? codiceUnivoco,
    String? rea,
    String? telefono,
    String? telefonoLab,
    String? email,
    String? web,
    String? iban,
    String? banca,
    String? intestatarioIban,
    String? firmaTitolo,
    String? firmaNome,
    String? firmaIscrizione,
  }) =>
      DatiAzienda(
        ragioneSociale: ragioneSociale ?? this.ragioneSociale,
        indirizzo: indirizzo ?? this.indirizzo,
        cap: cap ?? this.cap,
        citta: citta ?? this.citta,
        provincia: provincia ?? this.provincia,
        piva: piva ?? this.piva,
        codiceUnivoco: codiceUnivoco ?? this.codiceUnivoco,
        rea: rea ?? this.rea,
        telefono: telefono ?? this.telefono,
        telefonoLab: telefonoLab ?? this.telefonoLab,
        email: email ?? this.email,
        web: web ?? this.web,
        iban: iban ?? this.iban,
        banca: banca ?? this.banca,
        intestatarioIban: intestatarioIban ?? this.intestatarioIban,
        firmaTitolo: firmaTitolo ?? this.firmaTitolo,
        firmaNome: firmaNome ?? this.firmaNome,
        firmaIscrizione: firmaIscrizione ?? this.firmaIscrizione,
      );
}
