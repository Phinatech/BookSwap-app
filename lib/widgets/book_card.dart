import 'package:flutter/material.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onSwap;
  final Widget? ownerActions;
  final String? subtitle2;

  const BookCard({
    super.key,
    required this.book,
    this.onSwap,
    this.ownerActions,
    this.subtitle2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: book.imageUrl.isEmpty
              ? const SizedBox(width: 48, height: 64, child: Icon(Icons.menu_book, color: Colors.amber))
              : Image.network(book.imageUrl, width: 48, height: 64, fit: BoxFit.cover),
        ),
        title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${subtitle2 ?? 'By ${book.author}'}${book.status.isNotEmpty ? '  ·  ${book.status}' : ''}'),
        trailing: ownerActions ??
            ElevatedButton(
              onPressed: onSwap,
              child: const Text('Swap'),
            ),
      ),
    );
  }
}