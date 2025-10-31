import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String condition;
  final String? imageAsset; // local asset (optional)
  final String? imageUrl;   // https url (optional)
  final String? secondary;  // e.g., time ago
  final String? status;     // e.g., "Pending"
  final Widget? ownerActions;
  final VoidCallback? onSwap;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.condition,
    this.imageAsset,
    this.imageUrl,
    this.secondary,
    this.status,
    this.ownerActions,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    // CHANGED: Only render network when it's a non-empty http(s) URL
    final u = imageUrl ?? '';
    final isHttp = u.startsWith('http://') || u.startsWith('https://'); // CHANGED

    final thumb = isHttp
        ? Image.network(
            u,
            width: 52,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 52,
              height: 68,
              child: Icon(Icons.menu_book, color: Color(0xFFFFC107)),
            ),
          )
        : (imageAsset != null
            ? Image.asset(imageAsset!, width: 52, height: 68, fit: BoxFit.cover)
            : const SizedBox(
                width: 52,
                height: 68,
                child: Icon(Icons.menu_book, color: Color(0xFFFFC107)),
              ));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: thumb),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By $author'),
            Text('Condition: $condition'),
            if (secondary != null) Text(secondary!, style: const TextStyle(fontSize: 12)),
            if (status != null && status!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(status!),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFFFC107).withOpacity(.2),
                ),
              ),
          ],
        ),
        trailing: ownerActions ??
            ElevatedButton(
              onPressed: onSwap,
              child: const Text('Swap'),
            ),
      ),
    );
  }
}
