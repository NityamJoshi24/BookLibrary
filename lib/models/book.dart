enum BookStatus{
  reading,
  completed,
  wantToRead,
}

class Book{
  final String id;
  final String title;
  final String author;
  final int totalPages;
  final int currentPage;
  final BookStatus status;

  Book({
    required this.title,
    required this.author,
    required this.currentPage,
    required this.id,
    required this.status,
    required this.totalPages,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    BookStatus? status,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
    );
  }

  double get progressPercentage{
    if(totalPages == 0) return 0;
    return (currentPage/totalPages*100).clamp(0, 100);
  }
}