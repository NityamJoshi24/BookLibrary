enum BookStatus{
  reading,
  completed,
  wantToRead,
}

class Book{
  // Sentinel object to distinguish between "no change" and "explicit null"
  static const Object _audioPathSentinel = Object();
  final String id;
  final String title;
  final String author;
  final int totalPages;
  final int currentPage;
  final BookStatus status;
  final String? audioNotePath;

  Book({
    required this.title,
    required this.author,
    required this.currentPage,
    required this.id,
    required this.status,
    required this.totalPages,
    this.audioNotePath,
  });

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? totalPages,
    int? currentPage,
    BookStatus? status,
    Object? audioNotePath = _audioPathSentinel,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      audioNotePath: identical(audioNotePath, _audioPathSentinel)
          ? this.audioNotePath
          : audioNotePath as String?,
    );
  }

  double get progressPercentage{
    if(totalPages == 0) return 0;
    return (currentPage/totalPages*100).clamp(0, 100);
  }

  bool get hasAudioNote => audioNotePath != null && audioNotePath!.isNotEmpty;
}