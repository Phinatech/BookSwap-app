import 'dart:async';
import 'dart:io';
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
    print('BookProvider.create called');
    final user = _auth.currentUser!;
    print('User: ${user.uid}');
    
    String imageUrl = '';
    if (imageFile != null) {
      print('Starting image upload...');
      imageUrl = await _svc.uploadCover(imageFile, user.uid);
      print('Image uploaded: $imageUrl');
    } else {
      print('No image provided, using empty string');
    }

    print('Creating book document...');
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
    print('Book document created');
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
    // CHANGED: if new image provided, upload; else keep existing (or empty string)
    String imageUrl = currentImageUrl ?? ''; // CHANGED
    if (imageFile != null) {
      imageUrl = await _svc.uploadCover(imageFile, _auth.currentUser!.uid); // CHANGED
    }
    await _svc.updateBook(id, {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl, // CHANGED
    });
  }

  // ------------ DELETE ------------
  Future<void> delete(String id) => _svc.deleteBook(id);

  // ------------ SWAP ------------
  Future<void> requestSwap(Map<String, dynamic> book) async {
    final me = _auth.currentUser!;
    if (me.uid == book['ownerId']) return;
    await _svc.createSwap(bookId: book['id'], senderId: me.uid, receiverId: book['ownerId']);
    await _svc.ensureThread(me.uid, book['ownerId']);
  }
}
