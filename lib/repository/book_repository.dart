import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

class BookRepository{
  static const String _booksKey = 'books_list';

  Future<void> saveBooks(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();

    final booksJson = books.map((book) => {
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'totalPages': book.totalPages,
      'currentPage': book.currentPage,
      'status': book.status.name,
    }).toList();

    await prefs.setString(_booksKey, jsonEncode(booksJson));
    print('Saved ${books.length} books to storage');
  }

  Future<List<Book>> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final booksString = prefs.getString(_booksKey);

    if(booksString == null || booksString.isEmpty) {
      print('No saved books found');
      return [];
    }

    try{
      final List<dynamic> booksJson = jsonDecode(booksString);

      final books = booksJson.map((json) {
        BookStatus status;
        switch(json['status']) {
          case 'reading':
            status = BookStatus.reading;
            break;
            case 'completed':
            status = BookStatus.completed;
            break;
            case 'wantToRead':
            status = BookStatus.wantToRead;
            break;
            default:
            status = BookStatus.wantToRead;
        }

        return Book(title: json['title'], author: json['author'], currentPage: json['currentPage'], id: json['id'], status: status, totalPages: json['totalPages']);
      }).toList();
      
      print('Loaded ${books.length} books from storage');
      return books;
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  Future<void> clearBooks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_booksKey);
    print('Cleared books from storage');
  }
}