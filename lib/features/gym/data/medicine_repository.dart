import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineRepository {
  MedicineRepository({required this.uid});

  final String uid;

  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _medicinesCol =>
      _firestore.collection('users').doc(uid).collection('medicines');

  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    final snapshot = await _medicinesCol.get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map);
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>?> getMedicine(String id) async {
    final doc = await _medicinesCol.doc(id).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() as Map);
    data['id'] = doc.id;
    return data;
  }

  Future<void> saveMedicine(Map<String, dynamic> medicine) async {
    final id = medicine['id'] as String;
    final data = Map<String, dynamic>.from(medicine);
    data.remove('id'); // don't store id inside the document
    await _medicinesCol.doc(id).set(data);
  }

  Future<void> deleteMedicine(String id) async {
    await _medicinesCol.doc(id).delete();
  }
}