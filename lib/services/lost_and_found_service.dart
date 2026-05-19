import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_and_found_model.dart';

class LostAndFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'lost_and_found';

  Stream<List<LostAndFoundModel>> getAllItems() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LostAndFoundModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addItem(LostAndFoundModel item) async {
    try {
      await _firestore.collection(_collection).add({
        'title': item.title,
        'description': item.description,
        'category': item.category,
        'status': item.status,
        'location': item.location,
        'date': item.date,
        'postedBy': item.postedBy,
        'userId': item.userId,
        'contactNumber': item.contactNumber, // ✅ NEW
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Item added successfully!');
    } catch (e) {
      print('Error adding item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    await _firestore.collection(_collection).doc(itemId).delete();
  }

  Future<void> updateStatus(String itemId, String status) async {
    await _firestore.collection(_collection).doc(itemId).update({
      'status': status,
    });
  }
}