import 'package:flutter/foundation.dart';
import 'package:studentsupportsystem/models/complaint_model.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;

  void listenToComplaints({String? studentId}) {
    _firestoreService.getComplaints(studentId: studentId).listen((complaints) {
      _complaints = complaints;
      notifyListeners();
    });
  }

  Future<void> createComplaint(ComplaintModel complaint) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.createComplaint(complaint);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.updateComplaintStatus(id, status);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
