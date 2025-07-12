import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/insect_info.dart';
import '../api/insect_api_service.dart';
import '../detail/detail_page.dart';


class SearchPage extends StatefulWidget {
  final Color themeColor;

  const SearchPage({
    super.key,
    required this.themeColor,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final InsectApiService _apiService = InsectApiService();
  final TextEditingController _controller = TextEditingController();
  Future<List<InsectInfo>>? _searchFuture;

  List<String> _searchHistory = [];
  List<String> _koreanInsectNames = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadKoreanInsectNames();
    _loadSearchHistory();
  }

  Future<void> _loadKoreanInsectNames() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/translation_map.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      setState(() {
        _koreanInsectNames = jsonMap.keys.toList();
      });
    } catch (e) {
      print("translation_map.json 파일 로딩 실패: $e");
    }
  }

  void _onTextChanged(String query) {
    if (_searchFuture != null) {
      setState(() {
        _searchFuture = null;
      });
    }

    if (query.isEmpty) {
      setState(() {
        _suggestions.clear();
      });
      return;
    }

    setState(() {
      _suggestions = _koreanInsectNames
          .where((name) => name.contains(query))
          .take(5)
          .toList();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _controller.text = query;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
      _searchFuture = _apiService.searchInsects(query);
      _saveSearchHistory(query);
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    await prefs.setStringList('search_history', _searchHistory);
  }

  Future<void> _deleteHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(item);
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        title: const Text("곤충 통합 검색 🦋"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: "곤충 이름으로 검색...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _controller.clear();
                      _suggestions.clear();
                      _searchFuture = null;
                    });
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchFuture != null) {
      return _buildResultList();
    } else if (_controller.text.isNotEmpty) {
      return _buildSuggestionList();
    } else {
      return _buildHistoryList();
    }
  }

  Widget _buildSuggestionList() {
    if (_suggestions.isEmpty) {
      return const Center(child: Text("추천 검색어가 없습니다."));
    }
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.saved_search),
          title: Text(suggestion),
          onTap: () {
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (_searchHistory.isEmpty) {
      return const Center(child: Text("최근 검색 기록이 없습니다."));
    }
    return ListView.builder(
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final item = _searchHistory[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(item),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _deleteHistoryItem(item),
          ),
          onTap: () {
            _performSearch(item);
          },
        );
      },
    );
  }

  Widget _buildResultList() {
    if (_searchFuture == null) {
      return const Center(child: Text("검색어를 입력하고 Enter를 누르세요."));
    }
    return FutureBuilder<List<InsectInfo>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("오류 발생: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("검색 결과가 없습니다."));
        }
        final insects = snapshot.data!;
        return ListView.builder(
          itemCount: insects.length,
          itemBuilder: (context, index) {
            final insect = insects[index];
            return ListTile(
              leading: insect.imageUrl.isNotEmpty
                  ? Image.network(insect.imageUrl,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                  const Icon(Icons.bug_report))
                  : const Icon(Icons.bug_report, size: 40),
              title: Text(insect.commonName),
              subtitle: Text(insect.sciName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DetailPage(insect: insect)),
                );
              },
            );
          },
        );
      },
    );
  }
}