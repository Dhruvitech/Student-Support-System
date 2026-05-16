import 'package:flutter/foundation.dart';
import 'package:studentsupportsystem/models/announcement_model.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  void listenToAnnouncements() {
    _firestoreService.getAnnouncements().listen((announcements) {
      _announcements = announcements;
      notifyListeners();
    });
  }

  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.createAnnouncement(announcement);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.updateAnnouncement(announcement);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.deleteAnnouncement(id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
