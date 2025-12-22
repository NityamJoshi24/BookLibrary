import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../providers/book_provider.dart';

class BookDetailsScreen extends ConsumerWidget{
  final Book book;

  BookDetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bookProvider);

    return booksAsync.when(
      data: (books) {
        // Find the current version of this book
        final currentBook = books.firstWhere(
              (b) => b.id == book.id,
          orElse: () => book,
        );

        return _buildDetailScreen(context, ref, currentBook);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Book Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Book Details')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDetailScreen(BuildContext context, WidgetRef ref, Book currentBook) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details'),
        actions: [
          IconButton(onPressed: () {
            _showDeleteConfirmation(context, ref);
          }, icon: Icon(Icons.delete))
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentBook.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 8,),
            Text('by ${currentBook.author}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey[300]
              ),
            ),
            SizedBox(height: 24,),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book Status',
                        style: Theme.of(context).textTheme.titleMedium
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    _buildStatusButton(context, ref, currentBook),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16,),
            Card(
              child: Padding(padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reading Progress',
                        style: Theme.of(context).textTheme.titleMedium
                    ),
                    SizedBox(height: 16,),

                    LinearProgressIndicator(
                      value: currentBook.progressPercentage / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    SizedBox(height: 8,),
                    Text('${currentBook.currentPage} / ${currentBook.totalPages} pages (${currentBook.progressPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16,),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: () => _showUpdateProgressDialog(context, ref, currentBook),
                          icon: Icon(Icons.edit),
                          label: Text('Update Progress')),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(bookProvider.notifier).deleteBook(book.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatusButton(BuildContext context, WidgetRef ref, Book currentBook) {
  return Wrap(
    spacing: 8,
    children: [
      ChoiceChip(label: Text('Want to Read'),
        selected: currentBook.status == BookStatus.wantToRead,
        onSelected: (selected) {
          if(selected) {
            ref.read(bookProvider.notifier).updateStatus(currentBook.id, BookStatus.wantToRead);
          }
        },
        selectedColor: Colors.orange.withOpacity(0.3),
      ),
      ChoiceChip(label: Text('Reading'),
        selected: currentBook.status == BookStatus.reading,
        onSelected: (selected) {
          if(selected) {
            ref.read(bookProvider.notifier).updateStatus(currentBook.id, BookStatus.reading);
          }
        },
        selectedColor: Colors.blue.withOpacity(0.3),
      ),
      ChoiceChip(label: Text('Completed'),
        selected: currentBook.status == BookStatus.completed,
        onSelected: (selected) {
          if(selected) {
            ref.read(bookProvider.notifier).updateStatus(currentBook.id, BookStatus.completed);
          }
        },
        selectedColor: Colors.green.withOpacity(0.3),
      ),
    ],
  );
}

void _showUpdateProgressDialog(BuildContext context, WidgetRef ref, Book currentBook) {
  final controller = TextEditingController(text: currentBook.currentPage.toString());

  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text('Update Reading Progress'),
    content: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Current Page',
        border: OutlineInputBorder(),
        helperText: 'Total Pages: ${currentBook.totalPages}',
      ),
      keyboardType: TextInputType.number,
      autofocus: true,
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      FilledButton(onPressed: () {
        final newPage = int.tryParse(controller.text);
        if(newPage != null && newPage >= 0 && newPage <= currentBook.totalPages) {
          ref.read(bookProvider.notifier).updateProgress(currentBook.id, newPage);
          Navigator.pop(context);
        }
      }, child: Text('Update'),
      ),
    ],
  ));
}