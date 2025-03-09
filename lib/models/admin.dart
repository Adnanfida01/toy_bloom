import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String id;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;

  Admin({
    required this.id,
    required this.email,
    this.isAdmin = true,
    required this.createdAt,
  });

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
