import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String studentId;
  final String studentName;
  final String title;
  final String description;
  final String status;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) => ComplaintModel(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    status: json['status'] as String,
    timestamp: (json['timestamp'] as Timestamp).toDate(),
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    updatedAt: (json['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'title': title,
    'description': description,
    'status': status,
    'timestamp': Timestamp.fromDate(timestamp),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  ComplaintModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? title,
    String? description,
    String? status,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ComplaintModel(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    studentName: studentName ?? this.studentName,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
