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
                final b = prov.mine[i]; // Map<String, dynamic>
                final title = (b['title'] ?? '') as String;                 // NEW
                final author = (b['author'] ?? '') as String;               // NEW
                final condition = (b['condition'] ?? 'New') as String;      // NEW
                final imageUrl = (b['imageUrl'] ?? '') as String;           // NEW
                final status = (b['status'] ?? '') as String;               // NEW

                return BookCard(
                  // book: b,                                          // REMOVED
                  title: title,                                         // CHANGED
                  author: author,                                       // CHANGED
                  condition: condition,                                 // CHANGED
                  imageUrl: imageUrl,                                   // CHANGED (BookCard handles empty/non-http)
                  secondary: 'By $author · $condition',                 // CHANGED (was: subtitle2)
                  status: status,                                       // NEW (shows "Pending" chip when set)
                  ownerActions: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostBookScreen(editing: b), // CHANGED (PostBookScreen takes a Map)
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => prov.delete(b['id'] as String), // CHANGED (id from Map)
                      ),
                    ],
                  ),
                );
              },
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
}
