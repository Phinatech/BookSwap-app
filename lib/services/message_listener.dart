import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class MessageListener {
  static final MessageListener _instance = MessageListener._internal();
  factory MessageListener() => _instance;
  MessageListener._internal();

  StreamSubscription? _subscription;
  final Set<String> _processedMessages = {};

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription?.cancel();
    
    _subscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('to', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      
      if (snapshot.docs.isEmpty) return;
      
      final doc = snapshot.docs.first;
      final messageId = doc.id;
      
      // Skip if already processed
      if (_processedMessages.contains(messageId)) return;
      
      _processedMessages.add(messageId);
      
      final data = doc.data();
      final text = data['text'] ?? 'New message';
      
      NotificationService().showLocalNotification(
        title: 'New Message Received',
        body: text,
      );
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _processedMessages.clear();
  }
}