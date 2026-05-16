import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentsupportsystem/models/announcement_model.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/models/complaint_model.dart';
import 'package:studentsupportsystem/models/schedule_model.dart';
import 'package:studentsupportsystem/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= ANNOUNCEMENTS =================

  Stream<List<AnnouncementModel>> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => AnnouncementModel.fromJson(doc.data()))
                .toList());
  }

  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore
        .collection('announcements')
        .doc(announcement.id)
        .set(announcement.toJson());
  }

  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    await _firestore
        .collection('announcements')
        .doc(announcement.id)
        .update(announcement.toJson());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }

  // ================= COMPLAINTS =================

  Stream<List<ComplaintModel>> getComplaints({String? studentId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('complaints');

    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromJson(doc.data()))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> createComplaint(ComplaintModel complaint) async {
    await _firestore
        .collection('complaints')
        .doc(complaint.id)
        .set(complaint.toJson());
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    await _firestore.collection('complaints').doc(id).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // ================= SCHEDULE =================

  Stream<List<ScheduleModel>> getSchedule() {
    return _firestore
        .collection('timetable')
        .orderBy('day')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => ScheduleModel.fromJson(doc.data()))
                .toList());
  }

  Future<void> createSchedule(ScheduleModel schedule) async {
    await _firestore
        .collection('timetable')
        .doc(schedule.id)
        .set(schedule.toJson());
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _firestore
        .collection('timetable')
        .doc(schedule.id)
        .update(schedule.toJson());
  }

  Future<void> deleteSchedule(String id) async {
    await _firestore.collection('timetable').doc(id).delete();
  }

  // ================= USERS =================

  Stream<List<UserModel>> getStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => UserModel.fromJson(doc.data()))
                .toList());
  }

  Stream<List<UserModel>> getStudentsByClass(String classGroup) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classGroup', isEqualTo: classGroup)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => UserModel.fromJson(doc.data()))
                .toList());
  }

  Future<void> createStudent(UserModel student) async {
    await _firestore.collection('users').doc(student.uid).set(student.toJson());
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> saveAttendanceRecord(AttendanceModel attendance) async {
    await _firestore
        .collection('attendance_records')
        .doc(attendance.id)
        .set(attendance.toJson(), SetOptions(merge: true));
  }

  Stream<List<AttendanceModel>> getAttendanceForStudent(String studentId) {
    return _firestore
        .collection('attendance_records')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceModel.fromJson(doc.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> seedDemoStudentUsers() async {
    final now = DateTime.now();
    final demoStudents = [
      // Sem 6
      UserModel(
        uid: 'it-semi6-a-1',
        name: 'Ayesha Khan',
        email: 'ayesha.khan@itsem6a.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div A',
        enrollmentNumber: '230280116001',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-a-2',
        name: 'Rahul Patel',
        email: 'rahul.patel@itsem6a.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div A',
        enrollmentNumber: '230280116002',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-a-3',
        name: 'Meera Sen',
        email: 'meera.sen@itsem6a.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div A',
        enrollmentNumber: '230280116003',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-a-4',
        name: 'Arjun Nair',
        email: 'arjun.nair@itsem6a.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div A',
        enrollmentNumber: '230280116004',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-a-5',
        name: 'Simran Gupta',
        email: 'simran.gupta@itsem6a.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div A',
        enrollmentNumber: '230280116005',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-b-1',
        name: 'Sana Ali',
        email: 'sana.ali@itsem6b.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div B',
        enrollmentNumber: '230280116006',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-b-2',
        name: 'Vijay Sharma',
        email: 'vijay.sharma@itsem6b.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div B',
        enrollmentNumber: '230280116007',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-b-3',
        name: 'Tanvi Desai',
        email: 'tanvi.desai@itsem6b.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div B',
        enrollmentNumber: '230280116008',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-b-4',
        name: 'Karan Singh',
        email: 'karan.singh@itsem6b.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div B',
        enrollmentNumber: '230280116009',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-semi6-b-5',
        name: 'Neha Verma',
        email: 'neha.verma@itsem6b.edu',
        role: 'student',
        classGroup: 'IT Sem-6 Div B',
        enrollmentNumber: '230280116010',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      // Sem 4
      UserModel(
        uid: 'it-sem4-a-1',
        name: 'Rohit Mehta',
        email: 'rohit.mehta@itsem4a.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div A',
        enrollmentNumber: '240280116001',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-a-2',
        name: 'Nidhi Joshi',
        email: 'nidhi.joshi@itsem4a.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div A',
        enrollmentNumber: '240280116002',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-a-3',
        name: 'Pranav Iyer',
        email: 'pranav.iyer@itsem4a.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div A',
        enrollmentNumber: '240280116003',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-a-4',
        name: 'Riya Shah',
        email: 'riya.shah@itsem4a.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div A',
        enrollmentNumber: '240280116004',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-a-5',
        name: 'Amit Joshi',
        email: 'amit.joshi@itsem4a.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div A',
        enrollmentNumber: '240280116005',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-b-1',
        name: 'Pooja Singh',
        email: 'pooja.singh@itsem4b.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div B',
        enrollmentNumber: '240280116006',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-b-2',
        name: 'Vikas Rao',
        email: 'vikas.rao@itsem4b.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div B',
        enrollmentNumber: '240280116007',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-b-3',
        name: 'Sheetal Patel',
        email: 'sheetal.patel@itsem4b.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div B',
        enrollmentNumber: '240280116008',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-b-4',
        name: 'Devansh Kumar',
        email: 'devansh.kumar@itsem4b.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div B',
        enrollmentNumber: '240280116009',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem4-b-5',
        name: 'Anjali Mathur',
        email: 'anjali.mathur@itsem4b.edu',
        role: 'student',
        classGroup: 'IT Sem-4 Div B',
        enrollmentNumber: '240280116010',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      // Sem 2
      UserModel(
        uid: 'it-sem2-a-1',
        name: 'Kavya Menon',
        email: 'kavya.menon@itsem2a.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div A',
        enrollmentNumber: '250280116001',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-a-2',
        name: 'Sameer Khan',
        email: 'sameer.khan@itsem2a.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div A',
        enrollmentNumber: '250280116002',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-a-3',
        name: 'Isha Verma',
        email: 'isha.verma@itsem2a.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div A',
        enrollmentNumber: '250280116003',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-a-4',
        name: 'Harish Gupta',
        email: 'harish.gupta@itsem2a.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div A',
        enrollmentNumber: '250280116004',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-a-5',
        name: 'Rhea Nair',
        email: 'rhea.nair@itsem2a.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div A',
        enrollmentNumber: '250280116005',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-b-1',
        name: 'Ankit Sharma',
        email: 'ankit.sharma@itsem2b.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div B',
        enrollmentNumber: '250280116006',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-b-2',
        name: 'Priya Joshi',
        email: 'priya.joshi@itsem2b.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div B',
        enrollmentNumber: '250280116007',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-b-3',
        name: 'Naveen Patel',
        email: 'naveen.patel@itsem2b.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div B',
        enrollmentNumber: '250280116008',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-b-4',
        name: 'Smita Rao',
        email: 'smita.rao@itsem2b.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div B',
        enrollmentNumber: '250280116009',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        uid: 'it-sem2-b-5',
        name: 'Aman Verma',
        email: 'aman.verma@itsem2b.edu',
        role: 'student',
        classGroup: 'IT Sem-2 Div B',
        enrollmentNumber: '250280116010',
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final student in demoStudents) {
      await createStudent(student);
    }
  }

  Future<void> migrateOldClassNames() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        String? classGroup = data['classGroup'] as String?;
        
        if (classGroup == 'IT Division A') {
          await doc.reference.update({'classGroup': 'IT Sem-6 Div A'});
        } else if (classGroup == 'IT Division B') {
          await doc.reference.update({'classGroup': 'IT Sem-6 Div B'});
        }
      }

      final attendanceSnapshot = await _firestore.collection('attendance_records').get();
      for (final doc in attendanceSnapshot.docs) {
        final data = doc.data();
        String? classGroup = data['classGroup'] as String?;
        
        if (classGroup == 'IT Division A') {
          await doc.reference.update({'classGroup': 'IT Sem-6 Div A'});
        } else if (classGroup == 'IT Division B') {
          await doc.reference.update({'classGroup': 'IT Sem-6 Div B'});
        }
      }
    } catch (e) {
      print('Migration error: $e');
    }
  }

  Future<void> migrateEnrollmentNumbers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').where('role', isEqualTo: 'student').get();
      
      int sem6Count = 1;
      int sem4Count = 1;
      int sem2Count = 1;

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        String classGroup = data['classGroup'] ?? '';
        
        String newEnrollment = '';
        String semester = '';
        String branch = 'IT';
        
        if (classGroup.contains('Sem-6')) {
          newEnrollment = '230280116${sem6Count.toString().padLeft(3, '0')}';
          semester = '6';
          sem6Count++;
        } else if (classGroup.contains('Sem-4')) {
          newEnrollment = '240280116${sem4Count.toString().padLeft(3, '0')}';
          semester = '4';
          sem4Count++;
        } else if (classGroup.contains('Sem-2')) {
          newEnrollment = '250280116${sem2Count.toString().padLeft(3, '0')}';
          semester = '2';
          sem2Count++;
        } else {
          // Default to sem 6 if unknown
          newEnrollment = '230280116${sem6Count.toString().padLeft(3, '0')}';
          semester = '6';
          sem6Count++;
        }

        await doc.reference.update({
          'enrollmentNumber': newEnrollment,
          'semester': semester,
          'branch': branch,
        });
      }
      print('Enrollment migration complete');
    } catch (e) {
      print('Migration error: $e');
    }
  }

  Stream<List<AttendanceModel>> getAttendanceRecordsForClass(String classGroup) {
    return _firestore
        .collection('attendance_records')
        .where('classGroup', isEqualTo: classGroup)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceModel.fromJson(doc.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Stream<List<AttendanceModel>> getAttendanceRecordsForClassAndSubject(String classGroup, String subject) {
    return _firestore
        .collection('attendance_records')
        .where('classGroup', isEqualTo: classGroup)
        .where('subject', isEqualTo: subject)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AttendanceModel.fromJson(doc.data()))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  // ================= ASSIGNMENTS =================

  Future<void> addAssignment({
    required String title,
    required String description,
    required String fileUrl,
    required DateTime deadline,
  }) async {
    await _firestore.collection('assignments').add({
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAssignments() {
    return _firestore.collection('assignments')
    .orderBy('createdAt', descending: true)
    .snapshots();
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String fileUrl,
  }) async {
    await _firestore.collection('submissions').add({
      'assignmentId': assignmentId,
      'studentId': studentId,
      'fileUrl': fileUrl,
      'submittedAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> checkSubmission(
    String assignmentId, String studentId) {
  return _firestore
      .collection('submissions')
      .where('assignmentId', isEqualTo: assignmentId)
      .where('studentId', isEqualTo: studentId)
      .snapshots();
}

 Stream<QuerySnapshot<Map<String, dynamic>>> getSubmissions(String assignmentId) {
  return _firestore
      .collection('submissions')
      .where('assignmentId', isEqualTo: assignmentId)
      .snapshots();
}
}