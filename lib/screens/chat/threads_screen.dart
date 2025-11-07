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
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardColor,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: prov.threads(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No chats yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation by browsing books!',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
          
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnread ? const Color(0xFFFFC107).withOpacity(0.1) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isUnread ? Border.all(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    width: 1,
                  ) : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0A0A23),
                              const Color(0xFF0A0A23).withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A0A23).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            avatarChar,
                            style: const TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shortId,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          color: isUnread ? const Color(0xFFFFC107) : Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      lastText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread ? Theme.of(context).textTheme.bodyMedium?.color : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                        height: 1.3,
                      ),
                    ),
                  ),
                  onTap: () {
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
      ),
    );
  }
}