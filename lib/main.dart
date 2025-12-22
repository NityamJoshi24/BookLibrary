import 'package:book_library/providers/book_provider.dart';
import 'package:book_library/providers/filter_providers.dart';
import 'package:book_library/screens/book_details_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/book.dart';

void main() {
  runApp(
    ProviderScope(child: MyApp(),)
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Library',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BookListScreen(),
    );
  }
}

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final booksAsync = ref.watch(filteredBooksProvider);
    final currentFilter = ref.watch(bookFilterProvider);


    return Scaffold(
      appBar: AppBar(
        title: Text('My Books'),
        actions: [
          PopupMenuButton<FilterOption>(
            icon: Icon(
              currentFilter == FilterOption.all ? Icons.filter_list : Icons.filter_list_alt,
              color: currentFilter == FilterOption.all ? null : Colors.blue,
            ),
            onSelected: (filter) {
              ref.read(bookFilterProvider.notifier).state = filter;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FilterOption.all,
                child: Text('All Books'),
              ),
              PopupMenuItem(
                value: FilterOption.wantToRead,
                child: Text('Want to Read'),
              ),
              PopupMenuItem(
                value: FilterOption.reading,
                child: Text('Reading'),
              ),
              PopupMenuItem(
                value: FilterOption.completed,
                child: Text('Completed'),
              ),
            ],
          ),
          booksAsync.when(
            data: (books) => Center(
              child: Padding(padding: EdgeInsets.only(right: 16),
                child: Text(
                  '${books.length} books',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            loading: () => SizedBox.shrink(),
            error: (err, stack) => SizedBox.shrink()
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Text(
                'No Books Found',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
              ),
            );
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(book.title),
                  subtitle: Text('by ${book.author} - ${book.totalPages} pages'),
                  trailing: _buildStatusChip(book.status),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(context, ref),
        child: Icon(Icons.add),
      ),
    );
  }
}

Widget _buildStatusChip(BookStatus status) {
  Color color;
  String label;

  switch(status) {
    case BookStatus.reading:
      color = Colors.blue;
      label = 'Reading';
      break;
    case BookStatus.completed:
      color = Colors.green;
      label = 'Completed';
      break;
    case BookStatus.wantToRead:
      color = Colors.orange;
      label = 'Want to Read';
      break;
  }

  return Chip(label: Text(label, style: TextStyle(fontSize: 22),),
  backgroundColor: color.withOpacity(0.2),
    side: BorderSide(color: color),
  );
}

void _showAddBookDialog(BuildContext context, WidgetRef ref){
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final pagesController = TextEditingController();

  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text('Add New Book'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: 'Book Title',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: authorController,
          decoration: InputDecoration(
            labelText: 'Author Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: pagesController,
          decoration: InputDecoration(
            labelText: 'Total Pages',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        )
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      FilledButton(onPressed: () {
        if(titleController.text.isNotEmpty && authorController.text.isNotEmpty && pagesController.text.isNotEmpty) {
          ref.read(bookProvider.notifier).addBook(
            title: titleController.text,
            author: authorController.text,
            totalPages: int.parse(pagesController.text),
          );
          Navigator.pop(context);
        }
      }, child: Text('Add Book'))
    ],
  ));
}