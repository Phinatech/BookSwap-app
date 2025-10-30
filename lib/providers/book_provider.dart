import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/book.dart';

class BookProvider with ChangeNotifier {
  final _svc = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  List<Book> _browse = [];
  List<Book> _mine = [];

  List<Book> get browse => _browse;
  List<Book> get mine => _mine;

  StreamSubscription? _allSub;
  StreamSubscription? _mineSub;

  BookProvider() {
    _bind();
  }

  void _bind() {
    _allSub?.cancel();
    _allSub = _svc.books().listen((s) {
      _browse = s.docs.map((d) => Book.fromDoc(d)).toList();
      notifyListeners();
    });

    _mineSub?.cancel();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _mineSub = _svc.booksByOwner(uid).listen((s) {
        _mine = s.docs.map((d) => Book.fromDoc(d)).toList();
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

  // ------------ CRUD ------------
  Future<void> create({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    File? cover,
  }) async {
    final user = _auth.currentUser!;
    String imageUrl = '';
    if (cover != null) {
      imageUrl = await _svc.uploadCover(cover, user.uid);
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

  Future<void> update({
    required String id,
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    File? cover,
    String? currentImageUrl,
  }) async {
    String imageUrl = currentImageUrl ?? '';
    if (cover != null) {
      imageUrl = await _svc.uploadCover(cover, _auth.currentUser!.uid);
    }
    await _svc.updateBook(id, {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
    });
  }

  Future<void> delete(String id) => _svc.deleteBook(id);

  // ------------ Swap ------------
  Future<void> requestSwap(Book book) async {
    final me = _auth.currentUser!;
    if (me.uid == book.ownerId) return;
    await _svc.createSwap(bookId: book.id, senderId: me.uid, receiverId: book.ownerId);
    // Ensure chat thread exists
    await _svc.ensureThread(me.uid, book.ownerId);
  }
}