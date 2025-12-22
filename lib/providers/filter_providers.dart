import 'package:book_library/providers/book_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';

// Use a special "all" status
enum FilterOption {
  all,
  wantToRead,
  reading,
  completed,
}

final bookFilterProvider = StateProvider<FilterOption>((ref) {
  return FilterOption.all;
});

final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(bookProvider);
  final filter = ref.watch(bookFilterProvider);

  return booksAsync.when(
    data: (books) {
      if (filter == FilterOption.all) {
        return AsyncValue.data(books);
      }

      BookStatus? targetStatus;
      switch (filter) {
        case FilterOption.wantToRead:
          targetStatus = BookStatus.wantToRead;
          break;
        case FilterOption.reading:
          targetStatus = BookStatus.reading;
          break;
        case FilterOption.completed:
          targetStatus = BookStatus.completed;
          break;
        default:
          return AsyncValue.data(books);
      }

      final filtered = books.where((book) => book.status == targetStatus).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});