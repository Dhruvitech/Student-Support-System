import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_and_found_model.dart';

class LostAndFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'lost_and_found';

  // બધા items get કરો
  Stream<List<LostAndFoundModel>> getAllItems() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LostAndFoundModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // નવો item add કરો
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
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Item added successfully!');
  } catch (e) {
    print('Error adding item: $e');
    rethrow;
  }
}

  // Item delete કરો (admin)
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection(_collection).doc(itemId).delete();
  }

  // Status update કરો (admin)
  Future<void> updateStatus(String itemId, String status) async {
    await _firestore.collection(_collection).doc(itemId).update({
      'status': status,
    });
  }
}