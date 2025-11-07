import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserEmail;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _lastMessageId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkForNewMessages(List messages) {
    if (messages.isEmpty) return;
    
    final currentUser = FirebaseAuth.instance.currentUser!;
    final latestMessage = messages.first.data();
    final messageId = messages.first.id;
    
    // Check if this is a new message from someone else
    if (_lastMessageId != null && 
        _lastMessageId != messageId && 
        latestMessage['from'] != currentUser.uid) {
      
      NotificationService().showLocalNotification(
        title: 'New Message',
        body: latestMessage['text'] ?? 'You have a new message',
      );
    }
    
    _lastMessageId = messageId;
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    final otherUserId = widget.chatId.replaceAll(currentUser.uid, '').replaceAll('_', '');

    context.read<ChatProvider>().sendMessage(
      chatId: widget.chatId,
      from: currentUser.uid,
      to: otherUserId,
      text: text,
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final time = DateFormat('HH:mm').format(timestamp);
    
    if (messageDate == today) {
      return time; // Today: just show time
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $time'; // Yesterday
    } else if (now.difference(messageDate).inDays < 7) {
      return '${DateFormat('EEEE').format(timestamp)} $time'; // This week: show day name
    } else {
      return '${DateFormat('dd/MM/yyyy').format(timestamp)} $time'; // Older: show date
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFC107),
              child: Text(
                widget.otherUserEmail[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF0A0A23),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserEmail,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0A0A23),
        foregroundColor: const Color(0xFFFFC107),
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardColor.withOpacity(0.5),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirestoreService.instance.messages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;
                  _checkForNewMessages(messages);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index].data();
                      final isMe = message['from'] == currentUser.uid;
                      final timestamp = message['createdAt']?.toDate();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF0A0A23),
                                child: Text(
                                  widget.otherUserEmail[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFFFC107),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe 
                                    ? const Color(0xFFFFC107)
                                    : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? const Color(0xFF0A0A23) : Theme.of(context).textTheme.bodyLarge?.color,
                                        fontSize: 16,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (timestamp != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTimestamp(timestamp),
                                            style: TextStyle(
                                              color: isMe 
                                                ? const Color(0xFF0A0A23).withOpacity(0.6)
                                                : Theme.of(context).textTheme.bodySmall?.color,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.done_all,
                                              size: 14,
                                              color: const Color(0xFF0A0A23).withOpacity(0.6),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFFFC107),
                                child: Text(
                                  currentUser.email?[0].toUpperCase() ?? 'M',
                                  style: const TextStyle(
                                    color: Color(0xFF0A0A23),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            hintStyle: TextStyle(color: Theme.of(context).hintColor),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF0A0A23),
                          size: 22,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}