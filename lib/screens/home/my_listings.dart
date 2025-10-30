import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';
import 'post_book_screen.dart';

class MyListings extends StatelessWidget {
  const MyListings({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: prov.mine.isEmpty
          ? const Center(child: Text('You have not posted any books yet'))
          : ListView.builder(
              itemCount: prov.mine.length,
              itemBuilder: (c, i) {
                final b = prov.mine[i];
                return BookCard(
                  book: b,
                  subtitle2: 'By ${b.author} · ${b.condition}',
                  ownerActions: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PostBookScreen(editing: b)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => prov.delete(b.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostBookScreen())),
        label: const Text('Post'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}