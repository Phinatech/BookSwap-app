import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThreadsScreen extends StatelessWidget {
  const ThreadsScreen({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }

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
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No chats yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Start a conversation by browsing books!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          // Sort by timestamp (most recent first)
          docs.sort((a, b) {
            final aTime = a.data()['lastTimestamp'] as Timestamp?;
            final bTime = b.data()['lastTimestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
            itemBuilder: (c, i) {
              final d = docs[i].data();
              final members = List<String>.from(d['members']);
              final other = members.firstWhere((x) => x != me.uid, orElse: () => me.uid);
              final chatId = FirestoreService.instance.chatIdFor(me.uid, other);
              final lastText = d['lastText'] ?? 'No messages yet';
              final timestamp = d['lastTimestamp'] as Timestamp?;
              
              // Create avatar from first character and short ID
              final avatarChar = other.isNotEmpty ? other[0].toUpperCase() : '?';
              final shortId = '${other.substring(0, 4)}...${other.substring(other.length - 4)}';
              
              // Check if message is unread
              final lastMessageFrom = d['lastMessageFrom'] ?? '';
              final readBy = List<String>.from(d['readBy'] ?? []);
              final isUnread = lastMessageFrom != me.uid && 
                              lastMessageFrom.isNotEmpty && 
                              !readBy.contains(me.uid);
              
              return Container(
                color: isUnread ? const Color(0xFFFFC107).withOpacity(0.1) : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF0A0A23),
                    child: Text(
                      avatarChar,
                      style: const TextStyle(
                        color: Color(0xFFFFC107),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    shortId,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      lastText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFFFC107),
                        size: 20,
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mark as read by updating lastMessageFrom to current user
                    if (isUnread) {
                      FirestoreService.instance.markAsRead(chatId, me.uid);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: chatId, 
                          otherUserEmail: '${other.substring(0, 8)}...',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}