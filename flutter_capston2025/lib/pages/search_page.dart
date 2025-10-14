import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/insect_info.dart';
import '../api/insect_api_service.dart';
import '../detail/detail_page.dart';
import '../widgets/themed_background.dart';
import '../main.dart' show themeController;

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

  // (중복 @override 하나는 삭제해 주세요)
  @override
  Widget build(BuildContext context) {
    // 1) 테마 기준(검정/종이/하양) - AppBar 색 결정용
    final bool isDarkTheme = themeController.isDark;

    // 2) 화면 밝기 기준(다크/라이트) - 입력창/텍스트 대비용
    final bool isDarkUi = Theme.of(context).brightness == Brightness.dark;

    // 입력창 배경/테두리/아이콘/텍스트 색
    final fill       = isDarkUi ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final borderColor= isDarkUi ? Colors.white24                 : Colors.black26;
    final iconColor  = isDarkUi ? Colors.white70                 : Colors.black54;
    final textColor  = isDarkUi ? Colors.white                   : Colors.black87;

    // 경고 줄이고 싶으면 언더스코어 제거
    OutlineInputBorder outlined([Color? c]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: c ?? borderColor, width: 1),
    );

    return Scaffold(
      appBar: AppBar(
        // 다크 테마만 예전 보라색 사용, 나머지는 테마(app_theme.dart) 값 사용
        backgroundColor: isDarkTheme
            ? widget.themeColor
            : Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: isDarkTheme
            ? Colors.white
            : Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
        title: const Text("곤충 통합 검색 🦋"),
        centerTitle: true,
      ),
      body: ThemedBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                onSubmitted: _performSearch,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: "곤충 이름으로 검색...",
                  hintStyle: TextStyle(color: isDarkUi ? Colors.white60 : Colors.black45),
                  prefixIcon: Icon(Icons.search, color: iconColor),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: iconColor),
                    onPressed: () {
                      setState(() {
                        _controller.clear();
                        _suggestions.clear();
                        _searchFuture = null;
                      });
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: fill,
                  enabledBorder: outlined(),
                  focusedBorder: outlined(
                    Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  ),
                  border: outlined(),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            Expanded(child: _buildContent(context, textColor, iconColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor, Color iconColor) {
    if (_searchFuture != null) {
      return _buildResultList(context, textColor, iconColor);
    } else if (_controller.text.isNotEmpty) {
      return _buildSuggestionList(context, textColor, iconColor);
    } else {
      return _buildHistoryList(context, textColor, iconColor);
    }
  }

  Widget _buildSuggestionList(BuildContext context, Color textColor, Color iconColor) {
    if (_suggestions.isEmpty) {
      return Center(child: Text("추천 검색어가 없습니다.", style: TextStyle(color: textColor)));
    }
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: Icon(Icons.saved_search, color: iconColor),
          title: Text(suggestion, style: TextStyle(color: textColor)),
          onTap: () => _performSearch(suggestion),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context, Color textColor, Color iconColor) {
    if (_searchHistory.isEmpty) {
      return Center(child: Text("최근 검색 기록이 없습니다.", style: TextStyle(color: textColor)));
    }
    return ListView.builder(
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final item = _searchHistory[index];
        return ListTile(
          leading: Icon(Icons.history, color: iconColor),
          title: Text(item, style: TextStyle(color: textColor)),
          trailing: IconButton(
            icon: Icon(Icons.close, color: iconColor),
            onPressed: () => _deleteHistoryItem(item),
          ),
          onTap: () => _performSearch(item),
        );
      },
    );
  }

  Widget _buildResultList(BuildContext context, Color textColor, Color iconColor) {
    if (_searchFuture == null) {
      return Center(child: Text("검색어를 입력하고 Enter를 누르세요.", style: TextStyle(color: textColor)));
    }
    return FutureBuilder<List<InsectInfo>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("오류 발생: ${snapshot.error}", style: TextStyle(color: textColor)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: textColor)));
        }
        final insects = snapshot.data!;
        return ListView.builder(
          itemCount: insects.length,
          itemBuilder: (context, index) {
            final insect = insects[index];
            return ListTile(
              leading: insect.imageUrl.isNotEmpty
                  ? Image.network(
                insect.imageUrl,
                width: 60,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Icon(Icons.bug_report, color: iconColor),
              )
                  : Icon(Icons.bug_report, size: 40, color: iconColor),
              title: Text(insect.commonName, style: TextStyle(color: textColor)),
              subtitle: Text(insect.sciName, style: TextStyle(color: textColor.withOpacity(0.7))),
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