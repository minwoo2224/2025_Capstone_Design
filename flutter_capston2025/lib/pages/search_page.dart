// lib/pages/search_page.dart

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  // [수정됨] "Enter"를 누르거나 검색 기록을 탭했을 때 호출되는 함수
  void _performSearch(String query) {
    if (query.isEmpty) return;

    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    setState(() {
      _controller.text = query; // 텍스트 필드에 검색어 반영
      _searchFuture = _apiService.searchInsects(query);
      _saveSearchHistory(query); // 검색 시 기록 저장
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
    setState(() {});
  }

  Future<void> _deleteHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(item);
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  // [삭제됨] Timer와 _onSearchChanged 함수는 더 이상 필요 없으므로 삭제합니다.

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
              // [수정됨] onChanged -> onSubmitted
              // 키보드에서 '완료' 또는 'Enter'를 누르면 _performSearch 함수 호출
              onSubmitted: (query) => _performSearch(query),
              decoration: InputDecoration(
                hintText: "곤충 이름으로 검색 후 Enter...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          Expanded(
            child: _controller.text.isEmpty
                ? _buildHistoryList()
                : _buildResultList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    // (이 부분 코드는 변경 없음)
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
    // (이 부분 코드는 변경 없음)
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
                  ? Image.network(insect.imageUrl, width: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.bug_report))
                  : const Icon(Icons.bug_report, size: 40),
              title: Text(insect.commonName),
              subtitle: Text(insect.sciName),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(insect: insect)),
                );
              },
            );
          },
        );
      },
    );
  }
}