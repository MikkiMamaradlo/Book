import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/book.dart';
import 'services/book_repository.dart';
import 'add_book_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BookRepository _bookRepository = BookRepository();
  List<Book> _books = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isConnected = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadBooks();
    _searchController.addListener(() {
      setState(() {}); // Triggers UI update for clear button
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _loadBooks() async {
    if (!_isConnected) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No internet connection. Please check your network.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _bookRepository.loadBooks();

    setState(() {
      _books = _bookRepository.books;
      _isLoading = false;
      if (_bookRepository.error != null) {
        _hasError = true;
        _errorMessage = _bookRepository.error!;
      }
    });
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      await _loadBooks();
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
      _searchQuery = query;
    });
    final results = await _bookRepository.searchBooks(query);
    setState(() {
      _books = results;
      _isLoading = false;
      if (_bookRepository.error != null) {
        _hasError = true;
        _errorMessage = _bookRepository.error!;
      }
    });
  }

  Future<void> _addBook(Book book) async {
    setState(() {
      _isLoading = true;
    });

    final success = await _bookRepository.addBook(book);

    setState(() {
      _isLoading = false;
      if (success) {
        _books = _bookRepository.books;
        _hasError = false;
      } else {
        _hasError = true;
        _errorMessage = _bookRepository.error ?? 'Failed to add book';
      }
    });
  }

  Future<void> _deleteBook(String id) async {
    final success = await _bookRepository.deleteBook(id);

    if (success) {
      setState(() {
        _books = _bookRepository.books;
        _hasError = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = _bookRepository.error ?? 'Failed to delete book';
      });
    }
  }

  Future<void> _editBook(String id, Book updatedBook) async {
    setState(() {
      _isLoading = true;
    });

    final success = await _bookRepository.updateBook(id, updatedBook);

    setState(() {
      _isLoading = false;
      if (success) {
        _books = _bookRepository.books;
        _hasError = false;
      } else {
        _hasError = true;
        _errorMessage = _bookRepository.error ?? 'Failed to update book';
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Library'),
        backgroundColor: Color.fromARGB(255, 5, 5, 5),
        foregroundColor: const Color.fromARGB(255, 248, 227, 2),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadBooks)],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddBookPage()),
          );
          if (result != null && result is Book) {
            await _addBook(result);
          }
        },
        backgroundColor: Color.fromARGB(255, 5, 5, 5),
        child: Icon(Icons.add, color: const Color.fromARGB(255, 255, 251, 16)),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchBooks(value.trim());
            },
            decoration: InputDecoration(
              hintText: 'Search books...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchBooks('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.brown[50],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color.fromARGB(255, 5, 5, 5)),
                      SizedBox(height: 16),
                      Text('Loading books...'),
                    ],
                  ),
                )
              : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBooks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 5, 5, 5),
                          foregroundColor: const Color.fromARGB(255, 255, 251, 16),
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No books found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first book by tapping the + button',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return GestureDetector(
                      onTap: () {},
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          margin: EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Color.fromARGB(255, 5, 5, 5),
                                      width: 2,
                                    ),
                                    image: DecorationImage(
                                      image: AssetImage(book.image),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Color(0xFF4E342E),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'by ${book.author}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.brown[300],
                                        ),
                                      ),
                                      if (book.publishedYear != null) ...[
                                        SizedBox(height: 8),
                                        Chip(
                                          label: Text(
                                            'Year: ${book.publishedYear}',
                                          ),
                                          backgroundColor: Colors.brown[50],
                                          labelStyle: TextStyle(
                                            color: Color.fromARGB(255, 5, 5, 5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Column(
                                  children: [
                                    Tooltip(
                                      message: 'Edit',
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddBookPage(
                                                initialBook: book,
                                              ),
                                            ),
                                          );
                                          if (result != null &&
                                              result is Book) {
                                            await _editBook(book.id!, result);
                                          }
                                        },
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Delete',
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Delete Book'),
                                                content: Text(
                                                  'Are you sure you want to delete "${book.title}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      _deleteBook(book.id!);
                                                    },
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
