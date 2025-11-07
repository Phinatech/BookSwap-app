import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/book_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/book_card.dart';
import 'post_book_screen.dart';


class MyListings extends StatefulWidget {
  const MyListings({super.key});

  @override
  State<MyListings> createState() => _MyListingsState();
}

class _MyListingsState extends State<MyListings> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [

          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _debugListBooks,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFC107)
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          tabs: const [
            Tab(text: 'My Books'),
            Tab(text: 'My Offers'),
            Tab(text: 'Incoming'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyBooks(),
          _buildMyOffers(),
          _buildIncoming(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostBookScreen()),
        ),
        label: const Text('Post'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyBooks() {
    final prov = context.watch<BookProvider>();
    return prov.mine.isEmpty
        ? const Center(child: Text('You have not posted any books yet'))
        : ListView.builder(
            itemCount: prov.mine.length,
            itemBuilder: (c, i) {
              final b = prov.mine[i];
              return BookCard(
                title: b['title'] ?? '',
                author: b['author'] ?? '',
                condition: b['condition'] ?? 'New',
                imageUrl: b['imageUrl'] ?? '',
                status: b['status'] ?? '',
                ownerActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostBookScreen(editing: b),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color.fromARGB(255, 137, 136, 136)),
                      onPressed: () => _confirmDelete(context, prov, b),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildMyOffers() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder(
      stream: FirestoreService.instance.myOffers(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No offers sent'));
        }
        final allOffers = snapshot.data!.docs;
        final pendingOffers = allOffers.where((doc) {
          final data = doc.data();
          final hasUserId = data['userId'] == uid;
          final hasSenderId = data['senderId'] == uid;
          return (hasUserId || hasSenderId);
        }).toList();
        pendingOffers.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        final offers = pendingOffers;
        if (offers.isEmpty) return const Center(child: Text('No offers sent'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (c, i) {
            final offerDoc = offers[i];
            final offer = offerDoc.data();
            final status = offer['status'] ?? 'Unknown';
            final date = offer['createdAt']?.toDate();
            final authorBookId = offer['authorBookId'] ?? '';
            
            return FutureBuilder<Map<String, dynamic>?>(
              future: FirestoreService.instance.getBookDetails(authorBookId),
              builder: (context, bookSnapshot) {
                final bookName = bookSnapshot.data?['title'] ?? 'Unknown Book';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC107),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.swap_horiz, color: Color(0xFF0A0A23)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bookName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'User ID: ${offer['userId'] ?? offer['senderId'] ?? 'Unknown'}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildIncoming() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder(
      stream: FirestoreService.instance.incomingOffers(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No incoming offers'));
        }
        final allOffers = snapshot.data!.docs;
        final pendingOffers = allOffers.where((doc) {
          final data = doc.data();
          final status = data['status'];
          final hasAuthorId = data['authorId'] == uid;
          final hasReceiverId = data['receiverId'] == uid;
          return status == 'Pending' && (hasAuthorId || hasReceiverId);
        }).toList();
        pendingOffers.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        final offers = pendingOffers;
        if (offers.isEmpty) return const Center(child: Text('No incoming offers'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (c, i) {
            final offerDoc = offers[i];
            final offer = offerDoc.data();
            final status = offer['status'] ?? 'Unknown';
            final date = offer['createdAt']?.toDate();
            final authorBookId = offer['authorBookId'] ?? '';
            
            return FutureBuilder<Map<String, dynamic>?>(
              future: FirestoreService.instance.getBookDetails(authorBookId),
              builder: (context, bookSnapshot) {
                final bookName = bookSnapshot.data?['title'] ?? 'Unknown Book';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0A0A23),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Color(0xFFFFC107)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bookName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Author ID: ${offer['authorId'] ?? offer['receiverId'] ?? 'Unknown'}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (status.toLowerCase() == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateOfferStatus(offerDoc.id, 'accepted'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _updateOfferStatus(offerDoc.id, 'rejected'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _updateOfferStatus(String offerId, String status) async {
    await FirestoreService.instance.updateOfferStatus(offerId, status);
  }

  Future<void> _debugListBooks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('🔍 Debug: Current user: ${user?.uid} (${user?.email})');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .get();
      
      print('📚 Debug: Total books in database: ${snapshot.docs.length}');
      
      if (user != null) {
        final myBooks = snapshot.docs.where((doc) => 
          doc.data()['ownerId'] == user.uid
        ).toList();
        print('📖 Debug: My books count: ${myBooks.length}');
        
        for (final doc in myBooks) {
          print('Book ${doc.id}: ${doc.data()}');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${snapshot.docs.length} books total. Check console for details.')),
        );
      }
    } catch (e) {
      print('❌ Debug error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, BookProvider prov, Map<String, dynamic> book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      prov.delete(book['id'] as String);
    }
  }
}