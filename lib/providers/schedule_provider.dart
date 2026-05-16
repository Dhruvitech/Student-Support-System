import 'package:flutter/foundation.dart';
import 'package:studentsupportsystem/models/schedule_model.dart';
import 'package:studentsupportsystem/services/firestore_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;

  void listenToSchedules() {
    _firestoreService.getSchedule().listen((schedules) {
      _schedules = schedules;
      notifyListeners();
    });
  }

  Future<void> createSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.createSchedule(schedule);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.updateSchedule(schedule);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.deleteSchedule(id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
