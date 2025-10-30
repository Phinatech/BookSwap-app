import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ChatProvider with ChangeNotifier {
  final _svc = FirestoreService.instance;
  final _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> threads() =>
      _svc.threads(_auth.currentUser!.uid);

  String chatIdWith(String otherUid) => _svc.chatIdFor(_auth.currentUser!.uid, otherUid);

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String chatId) => _svc.messages(chatId);

  Future<void> send(String chatId, String to, String text) async {
    await _svc.sendMessage(chatId: chatId, from: _auth.currentUser!.uid, to: to, text: text);
  }
}