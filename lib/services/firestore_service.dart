import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studentsupportsystem/models/announcement_model.dart';
import 'package:studentsupportsystem/models/attendance_model.dart';
import 'package:studentsupportsystem/models/complaint_model.dart';
import 'package:studentsupportsystem/models/schedule_model.dart';
import 'package:studentsupportsystem/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> initializeActualStudents() async {
    final usersCollection = _firestore.collection('users');
    final existingStudentsQuery = await usersCollection.where('role', isEqualTo: 'student').get();
    
    final batch = _firestore.batch();
    for (final doc in existingStudentsQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    final now = DateTime.now();
    final List<UserModel> actualStudents = [];

    // Sem 6 Div A (30 students)
    final sem6DivANames = [
      'Aaditya Joshi', 'Aarav Patel', 'Abhishek Sharma', 'Aditi Mehta', 'Alok Mishra',
      'Amit Trivedi', 'Ananya Sen', 'Aniket Kumar', 'Anjali Verma', 'Ankit Dwivedi',
      'Anshul Gupta', 'Anushka Shah', 'Archana Nair', 'Arjun Rao', 'Ayesha Khan',
      'Bhavin Patel', 'Deepa Iyer', 'Devansh Rajput', 'Divya Saxena', 'Gaurav Chaudhari',
      'Harish Solanki', 'Isha Bhatia', 'Jayesh Panchal', 'Kavya Pillai', 'Keni Patel',
      'Kunal Deshmukh', 'Manisha Gokhale', 'Manoj Kulkarni', 'Mayur Chawla', 'Meera Sen'
    ];

    for (int i = 0; i < sem6DivANames.length; i++) {
      final name = sem6DivANames[i];
      final enrollment = '230280116${(i + 1).toString().padLeft(3, '0')}';
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@itsem6a.edu';
      actualStudents.add(UserModel(
        uid: 'it_sem6_a_${i + 1}',
        name: name,
        email: email,
        role: 'student',
        classGroup: 'IT Sem-6 Div A',
        enrollmentNumber: enrollment,
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Sem 6 Div B (30 students)
    final sem6DivBNames = [
      'Neha Verma', 'Nidhi Joshi', 'Nikhil Pandey', 'Nimesh Vyas', 'Pooja Singh',
      'Pranav Iyer', 'Pratik Bhatt', 'Priyanka Das', 'Rahul Patel', 'Rhea Nair',
      'Rohit Mehta', 'Rohan Deshmukh', 'Sameer Khan', 'Sana Ali', 'Sandeep Yadav',
      'Sanjay Chauhan', 'Savitri Gamit', 'Shweta Thakur', 'Siddharth Roy', 'Simran Gupta',
      'Sneha Reddy', 'Sunil Shetty', 'Tanvi Desai', 'Tarun Saxena', 'Uday Kirpal',
      'Varun Dhawan', 'Vijay Sharma', 'Vikas Rao', 'Vikram Malhotra', 'Yashwardhan Birla'
    ];

    for (int i = 0; i < sem6DivBNames.length; i++) {
      final name = sem6DivBNames[i];
      final enrollment = '230280116${(i + 31).toString().padLeft(3, '0')}';
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@itsem6b.edu';
      actualStudents.add(UserModel(
        uid: 'it_sem6_b_${i + 1}',
        name: name,
        email: email,
        role: 'student',
        classGroup: 'IT Sem-6 Div B',
        enrollmentNumber: enrollment,
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Sem 4 Div A (15 students)
    final sem4DivANames = [
      'Abhay Charan', 'Aman Varma', 'Anita Desai', 'Brijesh Solanki', 'Chirag Shah',
      'Deepak Malhotra', 'Ekta Kapoor', 'Farhan Akhtar', 'Gopal Krishna', 'Hema Malini',
      'Inder Kumar', 'Jyoti Basu', 'Kiran Kher', 'Lalit Modi', 'Madhuri Dixit'
    ];

    for (int i = 0; i < sem4DivANames.length; i++) {
      final name = sem4DivANames[i];
      final enrollment = '240280116${(i + 1).toString().padLeft(3, '0')}';
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@itsem4a.edu';
      actualStudents.add(UserModel(
        uid: 'it_sem4_a_${i + 1}',
        name: name,
        email: email,
        role: 'student',
        classGroup: 'IT Sem-4 Div A',
        enrollmentNumber: enrollment,
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Sem 4 Div B (15 students)
    final sem4DivBNames = [
      'Naveen Patnaik', 'Omprakash Valmiki', 'Padmini Kolhapure', 'Rajesh Khanna', 'Rekha Ganesan',
      'Salman Khan', 'Sheetal Patel', 'Shashi Kapoor', 'Sunil Gavaskar', 'Tabu Hashmi',
      'Udit Narayan', 'Vinod Khanna', 'Waheeda Rehman', 'Yash Chopra', 'Zoya Akhtar'
    ];

    for (int i = 0; i < sem4DivBNames.length; i++) {
      final name = sem4DivBNames[i];
      final enrollment = '240280116${(i + 16).toString().padLeft(3, '0')}';
      final email = '${name.toLowerCase().replaceAll(' ', '.')}@itsem4b.edu';
      actualStudents.add(UserModel(
        uid: 'it_sem4_b_${i + 1}',
        name: name,
        email: email,
        role: 'student',
        classGroup: 'IT Sem-4 Div B',
        enrollmentNumber: enrollment,
        password: '123456',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Write all of them to Firestore in batches
    final List<List<UserModel>> chunks = [];
    int chunkSize = 25; // 25 is safe for Batch set writes
    for (var i = 0; i < actualStudents.length; i += chunkSize) {
      chunks.add(actualStudents.sublist(i, i + chunkSize > actualStudents.length ? actualStudents.length : i + chunkSize));
    }

    for (final chunk in chunks) {
      final writeBatch = _firestore.batch();
      for (final student in chunk) {
        writeBatch.set(usersCollection.doc(student.uid), student.toJson());
      }
      await writeBatch.commit();
    }
  }

  Future<void> ensureDefaultClassGroups() async {
    final defaultSubjects = [
      'Advanced Web Development',
      'Artificial Intelligence',
      'Software Engineering',
      'Data Analysis and Visualization',
    ];

    await createClassGroup(
      branch: 'IT',
      semester: 6,
      division: 'A',
      subjects: List<String>.from(defaultSubjects),
    );
    await createClassGroup(
      branch: 'IT',
      semester: 6,
      division: 'B',
      subjects: List<String>.from(defaultSubjects),
    );
    await createClassGroup(
      branch: 'IT',
      semester: 4,
      division: 'A',
      subjects: List<String>.from(defaultSubjects),
    );
    await createClassGroup(
      branch: 'IT',
      semester: 4,
      division: 'B',
      subjects: List<String>.from(defaultSubjects),
    );

    await initializeActualStudents();
  }

  Future<void> seedDemoStudentUsers() async {
    await initializeActualStudents();
  }

  Stream<List<String>> getClassGroups() {
    return _firestore
        .collection('class_groups')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => (doc.data()['displayName'] as String?) ?? '')
            .where((name) => name.isNotEmpty)
            .toList());
  }

  Future<void> createClassGroup({
    required String branch,
    required int semester,
    required String division,
    List<String>? subjects,
  }) async {
    final normalizedBranch = branch.trim().toUpperCase();
    final normalizedDivision = division.trim().toUpperCase();

    if (normalizedBranch.isEmpty || normalizedDivision.isEmpty) {
      throw Exception('Branch and division are required');
    }

    final displayName = '$normalizedBranch Sem-$semester Div $normalizedDivision';
    final docRef = _firestore.collection('class_groups').doc(displayName);
    final docSnap = await docRef.get();

    final Map<String, dynamic> classData = {
      'branch': normalizedBranch,
      'semester': semester,
      'division': normalizedDivision,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!docSnap.exists) {
      classData['subjects'] = (subjects ?? ['General Subject'])
          .map((subject) => subject.trim())
          .where((subject) => subject.isNotEmpty)
          .toList();
      classData['createdAt'] = FieldValue.serverTimestamp();
    } else if (subjects != null) {
      classData['subjects'] = subjects
          .map((subject) => subject.trim())
          .where((subject) => subject.isNotEmpty)
          .toList();
    }

    await docRef.set(classData, SetOptions(merge: true));
  }

  Future<List<String>> getSubjectsForClass(String classGroup) async {
    final doc = await _firestore.collection('class_groups').doc(classGroup).get();
    if (!doc.exists || doc.data() == null) {
      return [];
    }

    final subjects = doc.data()?['subjects'];
    if (subjects is List) {
      return subjects
          .map((subject) => subject.toString().trim())
          .where((subject) => subject.isNotEmpty)
          .toList();
    }

    return [];
  }

  Stream<List<String>> getSubjectsStreamForClass(String classGroup) {
    return _firestore
        .collection('class_groups')
        .doc(classGroup)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return ['General Subject'];
          final subjects = doc.data()?['subjects'];
          if (subjects is List) {
            final list = subjects
                .map((subject) => subject.toString().trim())
                .where((subject) => subject.isNotEmpty)
                .toList();
            return list.isEmpty ? ['General Subject'] : list;
          }
          return ['General Subject'];
        });
  }

  Future<void> addSubjectToClass(String classGroup, String subject) async {
    final trimmedSubject = subject.trim();
    if (trimmedSubject.isEmpty) {
      return;
    }

    await _firestore.collection('class_groups').doc(classGroup).set({
      'subjects': FieldValue.arrayUnion([trimmedSubject]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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


Stream<QuerySnapshot<Map<String, dynamic>>> getTeacherAssignments() {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return const Stream.empty();
  }
  return _firestore
      .collection('assignments')
      .where('uploadedBy', isEqualTo: currentUser.uid)
      .snapshots();
}

Stream<QuerySnapshot<Map<String, dynamic>>> getStudentAssignments({
  required String branch,
  required String semester,
  required String division,
}) {
  return _firestore
      .collection('assignments')
      .where('branch', isEqualTo: branch)
      .where('semester', isEqualTo: semester)
      .where('division', isEqualTo: division)
      .snapshots();
}

Future<void> submitAssignment({
  required String assignmentId,
  required String studentId,
  required String fileUrl,
  required String fileName,
}) async {
  if (assignmentId.trim().isEmpty) {
    throw Exception("Assignment ID is empty");
  }

  if (studentId.trim().isEmpty) {
    throw Exception("Student ID is empty");
  }

  if (fileUrl.trim().isEmpty) {
    throw Exception("File URL is empty");
  }

  if (fileName.trim().isEmpty) {
    throw Exception("File name is empty");
  }

  await _firestore.collection('submissions').add({
    'assignmentId': assignmentId,
    'studentId': studentId,
    'fileUrl': fileUrl,
    'fileName': fileName,
    'submittedAt': Timestamp.now(),
  });
}

Stream<QuerySnapshot<Map<String, dynamic>>> checkSubmission(
  String assignmentId,
  String studentId,
) {
  return _firestore
      .collection('submissions')
      .where('assignmentId', isEqualTo: assignmentId)
      .where('studentId', isEqualTo: studentId)
      .snapshots();
}

Stream<QuerySnapshot<Map<String, dynamic>>> getSubmissions(String assignmentId) {
  return FirebaseFirestore.instance
      .collection('submissions')
      .where('assignmentId', isEqualTo: assignmentId)
      .snapshots();
}

Future<Map<String, dynamic>?> getFileData(String fileId) async {
  try {
    final doc = await _firestore.collection('files').doc(fileId).get();
    return doc.exists ? doc.data() : null;
  } catch (e) {
    print("Error fetching file data: $e");
    return null;
  }
}
}
