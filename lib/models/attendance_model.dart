import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String classGroup;
  final String subject;
  final DateTime date;
  final bool present;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classGroup,
    required this.subject,
    required this.date,
    required this.present,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        studentName: json['studentName'] as String,
        classGroup: json['classGroup'] as String,
        subject: json['subject'] as String,
        date: (json['date'] as Timestamp).toDate(),
        present: json['present'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'classGroup': classGroup,
        'subject': subject,
        'date': Timestamp.fromDate(date),
        'present': present,
      };
}
