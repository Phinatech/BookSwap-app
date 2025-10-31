import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        bottom: TabBar(
          controller: _tabController,
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
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => prov.delete(b['id'] as String),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final offers = snapshot.data!.docs;
        if (offers.isEmpty) return const Center(child: Text('No offers sent'));
        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (c, i) {
            final offer = offers[i].data();
            return ListTile(
              title: Text('Offer for book: ${offer['bookId']}'),
              subtitle: Text('Status: ${offer['status']}'),
              trailing: Text('${offer['createdAt']?.toDate().toString().split(' ')[0] ?? ''}'),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final offers = snapshot.data!.docs;
        if (offers.isEmpty) return const Center(child: Text('No incoming offers'));
        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (c, i) {
            final offer = offers[i].data();
            return ListTile(
              title: Text('Offer from: ${offer['senderId']}'),
              subtitle: Text('Book: ${offer['bookId']}'),
              trailing: Text('Status: ${offer['status']}'),
            );
          },
        );
      },
    );
  }
}
