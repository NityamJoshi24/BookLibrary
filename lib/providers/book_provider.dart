import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../repository/book_repository.dart';

class BookNotifier extends StateNotifier<AsyncValue<List<Book>>> {

  final BookRepository _repository;

  BookNotifier(this._repository) : super(const AsyncValue.loading()){
    _loadBooks();
}

  Future<void> _loadBooks() async {
    try{
      final books = await _repository.loadBooks();
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
}
}

  Future<void> _savedBooks(List<Book> books) async {
    await _repository.saveBooks(books);
}

  void addBook({
    required String title,
    required String author,
    required int totalPages,
}) async {
    state.whenData((books) async {
      final newBook = Book(
        id: DateTime.now().toString(),
        title: title,
        author: author,
        totalPages: totalPages,
        currentPage: 0,
        status: BookStatus.wantToRead,
      );
      final updatedBooks = [...books, newBook];
      state = AsyncValue.data(updatedBooks);
      await _savedBooks(updatedBooks);
    });
  }

  void updateProgress(String bookId, int currentPage) async {
    state.whenData((books) async {
      final updatedBooks = [
        for (final book in books)
          if (book.id == bookId)
            book.copyWith(currentPage: currentPage)
          else
            book
      ];
      state = AsyncValue.data(updatedBooks);
      await _savedBooks(updatedBooks);
    });
  }

  void updateStatus(String bookId, BookStatus status) async {
    state.whenData((books) async {
      final updatedBooks = [
        for (final book in books)
          if (book.id == bookId)
            book.copyWith(status: status)
          else
            book
      ];
      state = AsyncValue.data(updatedBooks);
      await _savedBooks(updatedBooks);
    });
  }

  void deleteBook(String bookId) async {
    state.whenData((books) async {
      final updatedBooks = books.where((book) => book.id != bookId).toList();
      state = AsyncValue.data(updatedBooks);
      await _savedBooks(updatedBooks);
    });
  }
}

final bookRepositoryProvider = Provider<BookRepository>((ref) => BookRepository());

final bookProvider = StateNotifierProvider<BookNotifier, AsyncValue<List<Book>>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return BookNotifier(repository);
});