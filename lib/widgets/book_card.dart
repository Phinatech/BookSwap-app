import 'dart:convert';
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

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return Colors.green.shade800; // Dark green
      case 'like new':
        return Colors.green.shade400; // Light green
      case 'good':
        return Colors.orange;
      case 'used':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = imageUrl ?? '';
    final isHttp = u.startsWith('http://') || u.startsWith('https://');
    final isBase64 = u.startsWith('data:image/');

    Widget thumb;
    if (isBase64) {
      try {
        final base64String = u.split(',')[1];
        final bytes = base64Decode(base64String);
        thumb = Image.memory(
          bytes,
          width: 52,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 52,
            height: 68,
            child: Icon(Icons.menu_book, color: Color(0xFFFFC107)),
          ),
        );
      } catch (e) {
        thumb = const SizedBox(
          width: 52,
          height: 68,
          child: Icon(Icons.menu_book, color: Color(0xFFFFC107)),
        );
      }
    } else if (isHttp) {
      thumb = Image.network(
        u,
        width: 52,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: 52,
          height: 68,
          child: Icon(Icons.menu_book, color: Color(0xFFFFC107)),
        ),
      );
    } else if (imageAsset != null) {
      thumb = Image.asset(imageAsset!, width: 52, height: 68, fit: BoxFit.cover);
    } else {
      thumb = const SizedBox(
        width: 52,
        height: 68,
        child: Icon(Icons.menu_book, color: Color(0xFFFFC107)),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: thumb),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Author: $author',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    'Condition: $condition',
                    style: TextStyle(
                      color: _getConditionColor(condition),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (secondary != null) Text(
                    secondary!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (status != null && status!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status!.toLowerCase().contains('pending') 
                              ? Colors.orange.withOpacity(0.2)
                              : const Color(0xFFFFC107).withOpacity(.2),
                          borderRadius: BorderRadius.circular(12),
                          border: status!.toLowerCase().contains('pending')
                              ? Border.all(color: Colors.orange, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          status!,
                          style: TextStyle(
                            color: status!.toLowerCase().contains('pending')
                                ? Colors.orange.shade800
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ownerActions ??
                ElevatedButton(
                  onPressed: onSwap,
                  style: onSwap == null ? ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade600,
                  ) : null,
                  child: Text(
                    onSwap == null ? 'Unavailable' : 'Swap',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
