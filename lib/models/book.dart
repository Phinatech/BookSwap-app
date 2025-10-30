import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String swapFor;
  final String imageUrl;
  final String ownerId;
  final String ownerEmail;
  final String status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapFor,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerEmail,
    required this.status,
  });

  factory Book.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Book(
      id: doc.id,
      title: d['title'] ?? '',
      author: d['author'] ?? '',
      condition: d['condition'] ?? 'New',
      swapFor: d['swapFor'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      ownerId: d['ownerId'] ?? '',
      ownerEmail: d['ownerEmail'] ?? '',
      status: d['status'] ?? '',
    );
  }
}