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
                final createdAt = b['createdAt']?.toDate() ?? DateTime.now();
                final currentUserId = context.read<AuthService>().currentUser?.uid;
                final isOwnBook = b['ownerId'] == currentUserId;
                final isPending = status.toLowerCase().contains('pending');
                
                return BookCard(
                  title: b['title'] ?? '',
                  author: b['author'] ?? '',
                  condition: b['condition'] ?? 'New',
                  imageUrl: b['imageUrl'] ?? '',
                  secondary: DateFormat.yMMMd().format(createdAt),
                  status: status,
                  onSwap: isOwnBook || isPending ? null : () {
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
