import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';

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
                return BookCard(
                  book: b,
                  subtitle2: 'By ${b.author} · ${b.condition}\n${DateFormat.yMMMd().format(DateTime.now())}',
                  onSwap: () => prov.requestSwap(b),
                );
              },
            ),
    );
  }
}
