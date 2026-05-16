import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_parametro_model.dart';

/// Servizio per la gestione dei preset del Registro su Firestore
/// Collection: `registro_preset`
class RegistroService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<RegistroPresetModel>> getPreset() {
    return _db
        .collection('registro_preset')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map(RegistroPresetModel.fromFirestore).toList());
  }

  Future<String> salvaPreset(RegistroPresetModel preset) async {
    if (preset.id.isEmpty) {
      final doc =
          await _db.collection('registro_preset').add(preset.toMap());
      return doc.id;
    } else {
      await _db
          .collection('registro_preset')
          .doc(preset.id)
          .set(preset.toMap());
      return preset.id;
    }
  }

  Future<void> eliminaPreset(String id) async {
    await _db.collection('registro_preset').doc(id).delete();
  }

  Future<List<String>> getCampioni() async {
    final doc = await _db.collection('impostazioni').doc('campioni_riferimento').get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['items'] as List? ?? []);
  }
}
