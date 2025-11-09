import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../providers/book_provider.dart';

/// Modal bottom sheet for creating detailed swap requests
/// Allows users to select which book to offer and set return date
class SwapBottomSheet extends StatefulWidget {
  final Map<String, dynamic> targetBook; // Book user wants to swap for

  const SwapBottomSheet({super.key, required this.targetBook});
  @override
  State<SwapBottomSheet> createState() => _SwapBottomSheetState();
}

class _SwapBottomSheetState extends State<SwapBottomSheet> {
  String? selectedBookId; // ID of book user wants to offer in exchange
  DateTime? selectedDate; // When the swapped book should be returned

  @override
  Widget build(BuildContext context) {
    // Listen to BookProvider for user's book collection
    final bookProvider = context.watch<BookProvider>();
    final myBooks = bookProvider.mine; // User's available books for swapping

    return Container(
      padding: const EdgeInsets.all(24),
      // Rounded top corners for modern bottom sheet appearance
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator for bottom sheet
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
          
          // Book Selection Dropdown - User chooses which book to offer
          Text(
            'Select your book to offer:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedBookId,
            decoration: InputDecoration(
              hintText: 'Choose a book from your collection',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            // Populate dropdown with user's available books
            items: myBooks.map((book) {
              return DropdownMenuItem<String>(
                value: book['id'],
                child: Text(
                  book['title'] ?? 'Untitled',
                  overflow: TextOverflow.ellipsis, // Prevent text overflow
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
          
          // Return Date Selection - When books should be returned
          Text(
            'Returned Swapped date:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Custom date picker with tap gesture
          InkWell(
            onTap: () async {
              // Show native date picker with constraints
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)), // Default to tomorrow
                firstDate: DateTime.now(), // Can't select past dates
                lastDate: DateTime.now().add(const Duration(days: 365)), // Max 1 year ahead
              );
              if (date != null) {
                setState(() {
                  selectedDate = date;
                });
              }
            },
            // Custom date picker UI that looks like a form field
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
                        ? DateFormat('MMM dd, yyyy').format(selectedDate!) // Format: Jan 15, 2024
                        : 'Select a date',
                    style: TextStyle(
                      // Dynamic color based on selection state
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
          
          // Action Buttons - Cancel or Send Request
          Row(
            children: [
              // Cancel button - dismisses bottom sheet
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
              // Send Request button - only enabled when both fields are selected
              Expanded(
                child: ElevatedButton(
                  // Button enabled only when both book and date are selected
                  onPressed: selectedBookId != null && selectedDate != null
                      ? () {
                          // Create detailed swap request with selected parameters
                          context.read<BookProvider>().requestSwapWithDetails(
                            targetBook: widget.targetBook,
                            offeredBookId: selectedBookId!,
                            preferredDate: selectedDate!,
                          );
                          Navigator.pop(context); // Close bottom sheet
                          // Show success feedback to user
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Swap request sent!'),
                              backgroundColor: Color(0xFFFFC107),
                            ),
                          );
                        }
                      : null, // Disabled when fields not selected
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
          // Handle keyboard appearance by adding bottom padding
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}