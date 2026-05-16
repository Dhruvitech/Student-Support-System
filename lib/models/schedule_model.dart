import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String id;
  final String day;
  final String subject;
  final String time;
  final String instructor;
  final String room;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.day,
    required this.subject,
    required this.time,
    required this.instructor,
    required this.room,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    id: json['id'] as String,
    day: json['day'] as String,
    subject: json['subject'] as String,
    time: json['time'] as String,
    instructor: json['instructor'] as String,
    room: json['room'] as String,
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    updatedAt: (json['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'subject': subject,
    'time': time,
    'instructor': instructor,
    'room': room,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  ScheduleModel copyWith({
    String? id,
    String? day,
    String? subject,
    String? time,
    String? instructor,
    String? room,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ScheduleModel(
    id: id ?? this.id,
    day: day ?? this.day,
    subject: subject ?? this.subject,
    time: time ?? this.time,
    instructor: instructor ?? this.instructor,
    room: room ?? this.room,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
