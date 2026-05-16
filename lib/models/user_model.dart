import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String classGroup;
  final String enrollmentNumber;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.classGroup,
    required this.enrollmentNumber,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    classGroup: json['classGroup'] as String? ?? '',
    enrollmentNumber: json['enrollmentNumber'] as String? ?? '',
    password: json['password'] as String? ?? '',
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    updatedAt: (json['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'role': role,
    'classGroup': classGroup,
    'enrollmentNumber': enrollmentNumber,
    'password': password,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? classGroup,
    String? enrollmentNumber,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    classGroup: classGroup ?? this.classGroup,
    enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
    password: password ?? this.password,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
