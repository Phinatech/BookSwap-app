import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Manages book CRUD operations, swap functionality, and real-time data sync
/// Uses Firestore streams for reactive UI updates
class BookProvider with ChangeNotifier {
  final _svc = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _browse = [];
  List<Map<String, dynamic>> _mine = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get browse => _browse;
  List<Map<String, dynamic>> get mine => _mine;
  bool get loading => _loading;
  String? get error => _error;

  StreamSubscription? _allSub;
  StreamSubscription? _mineSub;
  StreamSubscription? _authSub;

  BookProvider() {
    _bind();
    _authSub = _auth.authStateChanges().listen((_) => _bind());
  }

  void _bind() {
    _allSub?.cancel();
    _mineSub?.cancel();
    
    _allSub = _svc.books().listen((s) {
      _browse = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      notifyListeners();
    });

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _mineSub = _svc.booksByOwner(uid).listen((s) {
        _mine = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        notifyListeners();
      });
    } else {
      _mine = [];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _allSub?.cancel();
    _mineSub?.cancel();
    _authSub?.cancel();
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
    _setLoading(true);
    _clearError();
    
    try {
      final user = _auth.currentUser;
      print('🔍 Creating book - User: ${user?.uid} (${user?.email})');
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
    
    String imageUrl = '';
    if (imageFile != null) {
      print('📸 Uploading image...');
      try {
        imageUrl = await _svc.uploadCover(imageFile, user.uid).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⏰ Image upload timeout');
            return '';
          },
        );
        print('✅ Image uploaded: $imageUrl');
      } catch (e) {
        print('❌ Image upload failed: $e');
        imageUrl = '';
      }
    }

    final bookData = {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'imageUrl': imageUrl,
      'ownerId': user.uid,
      'ownerEmail': user.email ?? '',
      'status': '',
    };
    
    print('📝 Creating book with data: $bookData');
    
      try {
        final bookId = await _svc.createBook(bookData);
        print('✅ Book created successfully with ID: $bookId');
      } catch (e) {
        print('❌ Failed to create book: $e');
        rethrow;
      }
    } catch (e) {
      _setError('Failed to create book: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
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
    
    // Update book status to show it has a pending swap
    await _svc.updateBook(book['id'], {'status': 'Swap Pending'});
    
    // Send notification
    await NotificationService().showLocalNotification(
      title: 'Swap Request Sent!',
      body: 'Your swap request for "${book['title']}" has been sent.',
    );
  }

  Future<void> requestSwapWithDetails({
    required Map<String, dynamic> targetBook,
    required String offeredBookId,
    required DateTime preferredDate,
  }) async {
    final me = _auth.currentUser!;
    if (me.uid == targetBook['ownerId']) return;
    
    // Check if user already has a pending swap for this book
    final existingSwap = await _svc.checkExistingSwap(targetBook['id'], me.uid);
    if (existingSwap) return;
    
    await _svc.createDetailedSwap(
      targetBookId: targetBook['id'],
      offeredBookId: offeredBookId,
      senderId: me.uid,
      receiverId: targetBook['ownerId'],
      preferredDate: preferredDate,
    );
    await _svc.ensureThread(me.uid, targetBook['ownerId']);
    
    // Update book status to show it has a pending swap
    await _svc.updateBook(targetBook['id'], {'status': 'Swap Pending'});
    
    // Send notification
    await NotificationService().showLocalNotification(
      title: 'Swap Request Sent!',
      body: 'Your swap request for "${targetBook['title']}" has been sent.',
    );
  }
}
