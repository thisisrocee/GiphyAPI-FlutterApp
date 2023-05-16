import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
      ),
      home: GiphySearchPage(),
    );
  }
}

class GiphySearchPage extends StatefulWidget {
  @override
  _GiphySearchPageState createState() => _GiphySearchPageState();
}

class _GiphySearchPageState extends State<GiphySearchPage> {
  List<dynamic> _gifs = [];
  TextEditingController _searchController = TextEditingController();
  bool _loading = false;
  int _offset = 0;
  int _limit = 25;
  ScrollController _scrollController = ScrollController();
  bool _isInitialLoad = true;
  int preLoadTreshold = 10;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadTrendingGifs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.maxScrollExtent == _scrollController.offset) {
      _isSearching ? _loadMoreGifsSearch() : _loadMoreGifs();
    }
  }

  void _handleApiResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _gifs = data['data'];
        _loading = false;
        _offset = _limit;
        _isInitialLoad = false;
      });
    } else {
      setState(() {
        _gifs.clear();
        _loading = false;
        _isInitialLoad = false;
      });
    }
  }

  void _loadTrendingGifs() async {
    setState(() {
      _loading = true;
      _isInitialLoad = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://api.giphy.com/v1/gifs/trending?api_key=QjThAIEG3AtzcVpSWnUL9mRY7pYA1ufr&limit=$_limit&offset=$_offset',
      ),
    );

    _handleApiResponse(response);
  }

  void _searchGifs(String query) async {
    if (query.isEmpty) {
      _loadTrendingGifs();
      _isSearching = false;
      return;
    }

    setState(() {
      _loading = true;
    });

    final response = await http.get(
      Uri.parse(
        'https://api.giphy.com/v1/gifs/search?q=${_searchController.text}&api_key=QjThAIEG3AtzcVpSWnUL9mRY7pYA1ufr&limit=$_limit&offset=$_offset',
      ),
    );

    _handleApiResponse(response);
  }

  void _loadMoreGifs() async {
    if (_loading) return;

    final response = await http.get(
      Uri.parse(
        'https://api.giphy.com/v1/gifs/trending?api_key=QjThAIEG3AtzcVpSWnUL9mRY7pYA1ufr&limit=$_limit&offset=$_offset',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _gifs.addAll(data['data']);
        _offset += _limit;
      });
    }
  }

  void _loadMoreGifsSearch() async {
    if (_loading) return;

    final response = await http.get(
      Uri.parse(
        'https://api.giphy.com/v1/gifs/search?q=${_searchController.text}&api_key=QjThAIEG3AtzcVpSWnUL9mRY7pYA1ufr&limit=$_limit&offset=$_offset',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _gifs.addAll(data['data']);
        _offset += _limit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _offset = 0;
                _isSearching = true;
              });
              Future.delayed(const Duration(milliseconds: 300), () {
                _searchGifs(value);
              });
            },
            decoration: const InputDecoration(
              labelText: 'Search A GIF',
            ),
          ),
        ),
        _loading
            ? const CircularProgressIndicator()
            : Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  itemCount: _gifs.length + 1,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth >= 600 ? 4 : 2,
                    crossAxisSpacing: 0.0,
                    mainAxisSpacing: 0.0,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    if (index < _gifs.length) {
                      final gif = _gifs[index];
                      return Image.network(
                          gif['images']['fixed_height']['url']);
                    } else {
                      return _buildLoaderIndicator();
                    }
                  },
                ),
              ),
      ]),
    );
  }

  Widget _buildLoaderIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}
