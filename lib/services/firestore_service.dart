import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // ---------- Books ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> books() =>
      _db.collection('books').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> booksByOwner(String ownerId) =>
      _db.collection('books')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  // Upload image and ALWAYS return an HTTPS download URL (not a path or gs://)
  Future<String> uploadCover(File file, String ownerId) async {
    final id = const Uuid().v4();
    final ref = _storage.ref().child('covers/$ownerId/$id.jpg');
    // CHANGED: add metadata, await put, then get https URL
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg')); // CHANGED
    final url = await ref.getDownloadURL(); // CHANGED
    if (url.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
        message: 'Failed to obtain download URL for uploaded image.',
      );
    }
    return url;
  }

  Future<String> createBook(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await _db.collection('books').add(data);
    return ref.id;
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('books').doc(id).update(data);
  }

  Future<void> deleteBook(String id) => _db.collection('books').doc(id).delete();

  // ---------- Swaps ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> myOffers(String uid) =>
      _db.collection('swaps').where('senderId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> incomingOffers(String uid) =>
      _db.collection('swaps').where('receiverId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();

  Future<String> createSwap({
    required String bookId,
    required String senderId,
    required String receiverId,
  }) async {
    final ref = _db.collection('swaps').doc();
    await ref.set({
      'bookId': bookId,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('books').doc(bookId).update({'status': 'Pending'});
    return ref.id;
  }

  // ---------- Chats (optional) ----------
  String chatIdFor(String a, String b) {
    final pair = [a, b]..sort();
    return pair.join('_');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> threads(String uid) =>
      _db.collection('threads').where('members', arrayContains: uid).snapshots();

  Future<void> ensureThread(String uidA, String uidB) async {
    final id = chatIdFor(uidA, uidB);
    final ref = _db.collection('threads').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'members': [uidA, uidB],
        'lastText': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String chatId) =>
      _db.collection('threads').doc(chatId).collection('messages').orderBy('createdAt').snapshots();

  Future<void> sendMessage({
    required String chatId,
    required String from,
    required String to,
    required String text,
  }) async {
    final batch = _db.batch();
    final msgRef = _db.collection('threads').doc(chatId).collection('messages').doc();
    batch.set(msgRef, {
      'from': from,
      'to': to,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('threads').doc(chatId), {
      'lastText': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
