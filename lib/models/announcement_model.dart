import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) => AnnouncementModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    createdBy: json['createdBy'] as String,
    createdByName: json['createdByName'] as String,
    timestamp: (json['timestamp'] as Timestamp).toDate(),
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    updatedAt: (json['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'timestamp': Timestamp.fromDate(timestamp),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    String? createdByName,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AnnouncementModel(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    createdBy: createdBy ?? this.createdBy,
    createdByName: createdByName ?? this.createdByName,
    timestamp: timestamp ?? this.timestamp,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
