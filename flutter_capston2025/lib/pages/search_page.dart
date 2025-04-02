import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final Color themeColor;

  const SearchPage({super.key, required this.themeColor});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _insects = [
    "사슴벌레",
    "장수풍뎅이",
    "나비",
    "잠자리",
    "메뚜기",
    "개미",
    "벌",
    "매미",
    "딱정벌레",
    "방아깃과",
  ];
  List<String> _filteredInsects = [];

  @override
  void initState() {
    super.initState();
    _filteredInsects = _insects;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredInsects = _insects
          .where((insect) => insect.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("검색")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "곤충 이름을 검색하세요",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: _filteredInsects.isEmpty
                ? const Center(
              child: Text(
                "검색 결과가 없습니다.",
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredInsects.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      _filteredInsects[index],
                      style: const TextStyle(fontSize: 18),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${_filteredInsects[index]} 선택됨"),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}