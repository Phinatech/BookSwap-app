import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;


  // ---------- Books ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> books() =>
      _db.collection('books').orderBy('createdAt', descending: true).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> booksByOwner(String ownerId) =>
      _db.collection('books')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  Future<String> uploadCover(XFile file, String ownerId) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      print('✅ Image converted to base64 (${base64String.length} chars)');
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('❌ Image conversion failed: $e');
      return '';
    }
  }

  Future<String> createBook(Map<String, dynamic> data) async {
    print('💾 FirestoreService: Creating book with data: $data');
    
    try {
      final bookData = Map<String, dynamic>.from(data);
      bookData['createdAt'] = FieldValue.serverTimestamp();
      
      print('💾 Adding to Firestore collection "books"...');
      
      final ref = await _db.collection('books').add(bookData);
      print('✅ Book document created with ID: ${ref.id}');
      
      return ref.id;
    } catch (e, stackTrace) {
      print('❌ FirestoreService: Failed to create book: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('books').doc(id).update(data);
  }

  Future<void> deleteBook(String id) => _db.collection('books').doc(id).delete();

  // ---------- Swaps ----------
  Stream<QuerySnapshot<Map<String, dynamic>>> myOffers(String uid) =>
      _db.collection('swaps')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> incomingOffers(String uid) =>
      _db.collection('swaps')
          .snapshots();

  Future<Map<String, dynamic>?> getBookDetails(String bookId) async {
    final doc = await _db.collection('books').doc(bookId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<String> createSwap({
    required String bookId,
    required String senderId,
    required String receiverId,
  }) async {
    final ref = _db.collection('swaps').doc();
    await ref.set({
      'authorBookId': bookId,
      'authorId': receiverId,
      'userBookId': '',
      'userId': senderId,
      'preferredDate': null,
      'returningDate': null,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
      'approvedAt': null,
      'rejectedAt': null,
      'returnedAt': null,
    });
    return ref.id;
  }

  Future<String> createDetailedSwap({
    required String targetBookId,
    required String offeredBookId,
    required String senderId,
    required String receiverId,
    required DateTime preferredDate,
  }) async {
    final ref = _db.collection('swaps').doc();
    await ref.set({
      'authorBookId': targetBookId,
      'authorId': receiverId,
      'userBookId': offeredBookId,
      'userId': senderId,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'returningDate': null,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
      'approvedAt': null,
      'rejectedAt': null,
      'returnedAt': null,
    });
    return ref.id;
  }

  Future<void> updateOfferStatus(String offerId, String status) async {
    // Get the swap data first to find the book
    final swapRef = _db.collection('swaps').doc(offerId);
    final swapDoc = await swapRef.get();
    
    if (!swapDoc.exists) {
      throw Exception('Swap not found');
    }
    
    final swapData = swapDoc.data()!;
    final bookId = swapData['authorBookId'] as String;
    
    final batch = _db.batch();
    
    // Update the swap status with timestamp
    final updateData = <String, dynamic>{'status': status};
    
    if (status == 'accepted') {
      updateData['approvedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'rejected') {
      updateData['rejectedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'returned') {
      updateData['returnedAt'] = FieldValue.serverTimestamp();
    }
    
    batch.update(swapRef, updateData);
    
    // Update book status based on swap decision
    final bookRef = _db.collection('books').doc(bookId);
    String bookStatus;
    
    if (status == 'accepted') {
      bookStatus = 'Swap Accepted';
    } else if (status == 'rejected') {
      bookStatus = 'Available';
    } else if (status == 'returned') {
      bookStatus = 'Available';
    } else {
      bookStatus = 'Swap Pending';
    }
    
    batch.update(bookRef, {
      'status': bookStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  Future<bool> checkExistingSwap(String bookId, String senderId) async {
    final query = await _db.collection('swaps')
        .where('bookId', isEqualTo: bookId)
        .where('senderId', isEqualTo: senderId)
        .where('status', isEqualTo: 'Pending')
        .get();
    return query.docs.isNotEmpty;
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
      'lastMessageFrom': from,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> markAsRead(String chatId, String userId) async {
    await _db.collection('threads').doc(chatId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> setReturningDate(String swapId, DateTime returningDate) async {
    await _db.collection('swaps').doc(swapId).update({
      'returningDate': Timestamp.fromDate(returningDate),
    });
  }

  Future<void> markSwapAsReturned(String swapId) async {
    await _db.collection('swaps').doc(swapId).update({
      'status': 'returned',
      'returnedAt': FieldValue.serverTimestamp(),
    });
  }
}
