import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThreadsScreen extends StatelessWidget {
  const ThreadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ChatProvider>();
    final me = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: prov.threads(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No chats yet'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i].data();
              final members = List<String>.from(d['members']);
              final other = members.firstWhere((x) => x != me.uid, orElse: () => me.uid);
              final chatId = FirestoreService.instance.chatIdFor(me.uid, other);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('Chat with ${other.substring(0, 6)}...'),
                subtitle: Text(d['lastText'] ?? ''),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUid: other))),
              );
            },
          );
        },
      ),
    );
  }
}