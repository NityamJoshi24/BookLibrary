import 'package:book_library/providers/book_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';

class ReadingStats{
  final int totalBooks;
  final int booksReading;
  final int booksCompleted;
  final int booksWantToRead;
  final int totalPages;
  final int pagesRead;
  final int pagesRemaining;

  ReadingStats({
    required this.totalBooks,
    required this.booksReading,
    required this.booksCompleted,
    required this.booksWantToRead,
    required this.totalPages,
    required this.pagesRead,
    required this.pagesRemaining
});

  double get completePercentage {
    if(totalPages == 0) return 0;
    return (pagesRead / totalPages * 100).clamp(0, 100);
  }

  double get averagePagesPerBook {
    if(totalBooks == 0) return 0;
    return totalPages / totalBooks;
  }

  int get booksInProgress => booksReading;
}

final statisticsProvider = Provider<AsyncValue<ReadingStats>>((ref) {
  final bookAsync = ref.watch(bookProvider);

  return bookAsync.when(data: (books) {
    int totalBooks = books.length;
    int booksReading = 0;
    int booksCompleted = 0;
    int booksWantToRead = 0;
    int totalPages = 0;
    int pagesRead = 0;

    for(final book in books) {

      switch(book.status) {
        case BookStatus.reading:
          booksReading++;
          break;
        case BookStatus.completed:
          booksCompleted++;
          break;
        case BookStatus.wantToRead:
          booksWantToRead++;
          break;
      }

      totalPages += book.totalPages;
      pagesRead += book.currentPage;
    }

    final stats = ReadingStats(
        totalBooks: totalBooks,
        booksReading: booksReading,
        booksCompleted: booksCompleted,
        booksWantToRead: booksWantToRead,
        totalPages: totalPages,
        pagesRead: pagesRead,
        pagesRemaining: totalPages - pagesRead
    );

    return AsyncValue.data(stats);

  }, error: (err, stack) => AsyncValue.error(err, stack),
      loading: () => AsyncValue.loading());
});