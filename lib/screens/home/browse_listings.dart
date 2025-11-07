import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/book_card.dart';
import '../../widgets/swap_bottom_sheet.dart';

class BrowseListings extends StatelessWidget {
  const BrowseListings({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Listings')),
      body: prov.browse.isEmpty
          ? const Center(child: Text('No listings yet'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: prov.browse.length,
              itemBuilder: (c, i) {
                final b = prov.browse[i];
                final status = b['status'] ?? '';
                
                // Skip books with pending status
                if (status.toLowerCase() == 'pending') {
                  return const SizedBox.shrink();
                }

                final createdAt = b['createdAt']?.toDate() ?? DateTime.now();
                return BookCard(
                  title: b['title'] ?? '',
                  author: b['author'] ?? '',
                  condition: b['condition'] ?? 'New',
                  imageUrl: b['imageUrl'] ?? '',
                  secondary: DateFormat.yMMMd().format(createdAt),
                  status: b['status'] ?? '',
                  onSwap: () {
                    final currentUserId = context.read<AuthService>().currentUser?.uid;
                    if (b['ownerId'] == currentUserId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You cannot swap your own book'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SwapBottomSheet(targetBook: b),
                    );
                  },
                );
              },
            ),
    );
  }
}
