import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/book_provider.dart';

class SwapBottomSheet extends StatefulWidget {
  final Map<String, dynamic> targetBook;

  const SwapBottomSheet({super.key, required this.targetBook});

  @override
  State<SwapBottomSheet> createState() => _SwapBottomSheetState();
}

class _SwapBottomSheetState extends State<SwapBottomSheet> {
  String? selectedBookId;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final myBooks = bookProvider.mine;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Swap Request',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Request to swap "${widget.targetBook['title']}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // My Books Dropdown
          Text(
            'Select your book to offer:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedBookId,
            decoration: InputDecoration(
              hintText: 'Choose a book from your collection',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: myBooks.map((book) {
              return DropdownMenuItem<String>(
                value: book['id'],
                child: Text(
                  book['title'] ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedBookId = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Date Picker
          Text(
            'Preferred swap date:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  selectedDate = date;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                        : 'Select a date',
                    style: TextStyle(
                      color: selectedDate != null 
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedBookId != null && selectedDate != null
                      ? () {
                          // Process swap request with selected book and date
                          context.read<BookProvider>().requestSwapWithDetails(
                            targetBook: widget.targetBook,
                            offeredBookId: selectedBookId!,
                            preferredDate: selectedDate!,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Swap request sent!'),
                              backgroundColor: Color(0xFFFFC107),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Send Request'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}