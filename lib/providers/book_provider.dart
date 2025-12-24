import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../repository/book_repository.dart';
import '../services/audio_service.dart';

class BookNotifier extends StateNotifier<AsyncValue<List<Book>>> {

  final BookRepository _repository;
  final AudioService _audioService = AudioService();


  BookNotifier(this._repository) : super(const AsyncValue.loading()){
    _loadBooks();
}

  Future<void> startRecordingNote(String bookId) async {
    try{
      await _audioService.startRecording(bookId);
    } catch (e) {
      print('Error start recording: $e');
      throw Exception('Failed to start recording');
    }
  }

  Future<void> stopRecordingAndSave(String bookId) async {
    try{
      final audioPath = await _audioService.stopRecording();

      if(audioPath != null) {
        state.whenData((books) async {
          final updatedBooks = [
            for(final book in books)
              if(book.id == bookId)
                book.copyWith(audioNotePath: audioPath)
              else
                book,
          ];

          state = AsyncValue.data(updatedBooks);
          await _saveBooks(updatedBooks);
        });
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  bool get isRecording => _audioService.isRecording;

  Future<void> deleteAudioNote(String bookId) async {
    state.whenData((books) async {
      final book = books.firstWhere((b) => b.id == bookId);

      if(book.audioNotePath != null) {
        await _audioService.deleteAudio(book.audioNotePath!);

        final updatedBooks = [
          for(final b in books)
            if(b.id == bookId)
              b.copyWith(audioNotePath: null)
            else
              b
        ];

        state = AsyncValue.data(updatedBooks);
        await _saveBooks(updatedBooks);
      }
    });
  }

  AudioService get audioService => _audioService;


  Future<void> _loadBooks() async {
    try{
      final books = await _repository.loadBooks();
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
}
}

  Future<void> _saveBooks(List<Book> books) async {
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
      await _saveBooks(updatedBooks);
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
      await _saveBooks(updatedBooks);
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
      await _saveBooks(updatedBooks);
    });
  }

  void deleteBook(String bookId) async {
    state.whenData((books) async {
      final updatedBooks = books.where((book) => book.id != bookId).toList();
      state = AsyncValue.data(updatedBooks);
      await _saveBooks(updatedBooks);
    });
  }
}

final bookRepositoryProvider = Provider<BookRepository>((ref) => BookRepository());

final bookProvider = StateNotifierProvider<BookNotifier, AsyncValue<List<Book>>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return BookNotifier(repository);
});