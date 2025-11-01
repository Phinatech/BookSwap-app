import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';

class BookProvider with ChangeNotifier {
  final _svc = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _browse = [];
  List<Map<String, dynamic>> _mine = [];

  List<Map<String, dynamic>> get browse => _browse;
  List<Map<String, dynamic>> get mine => _mine;

  StreamSubscription? _allSub;
  StreamSubscription? _mineSub;

  BookProvider() {
    _bind();
  }

  void _bind() {
    _allSub?.cancel();
    _allSub = _svc.books().listen((s) {
      _browse = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      notifyListeners();
    });

    _mineSub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _mineSub = _svc.booksByOwner(uid).listen((s) {
        _mine = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _allSub?.cancel();
    _mineSub?.cancel();
    super.dispose();
  }

  // ------------ CREATE ------------
  Future<void> create({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    XFile? imageFile,
  }) async {
    final user = _auth.currentUser!;
    
    String imageUrl = '';
    if (imageFile != null) {
      try {
        imageUrl = await _svc.uploadCover(imageFile, user.uid).timeout(
          const Duration(seconds: 15),
          onTimeout: () => '',
        );
      } catch (e) {
        imageUrl = '';
      }
    }

    await _svc.createBook({
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
      'ownerId': user.uid,
      'ownerEmail': user.email ?? '',
      'status': '',
    });
  }

  // ------------ UPDATE ------------
  Future<void> update({
    required String id,
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    XFile? imageFile,
    String? currentImageUrl,
  }) async {
    String imageUrl = currentImageUrl ?? '';
    if (imageFile != null) {
      try {
        imageUrl = await _svc.uploadCover(imageFile, _auth.currentUser!.uid).timeout(
          const Duration(seconds: 15),
          onTimeout: () => currentImageUrl ?? '',
        );
      } catch (e) {
        imageUrl = currentImageUrl ?? '';
      }
    }
    await _svc.updateBook(id, {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
    });
  }

  // ------------ DELETE ------------
  Future<void> delete(String id) => _svc.deleteBook(id);

  // ------------ SWAP ------------
  Future<void> requestSwap(Map<String, dynamic> book) async {
    final me = _auth.currentUser!;
    if (me.uid == book['ownerId']) return;
    
    // Check if user already has a pending swap for this book
    final existingSwap = await _svc.checkExistingSwap(book['id'], me.uid);
    if (existingSwap) return;
    
    await _svc.createSwap(bookId: book['id'], senderId: me.uid, receiverId: book['ownerId']);
    await _svc.ensureThread(me.uid, book['ownerId']);
  }
}
