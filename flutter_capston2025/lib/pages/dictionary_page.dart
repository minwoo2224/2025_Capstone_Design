import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/pages/card_selection_page.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({Key? key}) : super(key: key);

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  List<InsectCard> allCards = [];

  @override
  void initState() {
    super.initState();
    _loadAllCards();
  }

  Future<void> _loadAllCards() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // assets/cards/ 폴더에 있는 모든 JSON 파일 경로 추출
      final cardFiles = manifestMap.keys
          .where((path) => path.startsWith('assets/cards/') && path.endsWith('.json'))
          .toList();

      List<InsectCard> loadedCards = [];

      for (final path in cardFiles) {
        final jsonString = await rootBundle.loadString(path);
        final List<dynamic> jsonData = json.decode(jsonString);

        final cards = jsonData.map((e) => InsectCard.fromJson(e)).toList();
        loadedCards.addAll(cards);
      }

      setState(() {
        allCards = loadedCards;
      });
    } catch (e) {
      debugPrint('카드 로드 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('곤충 도감'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // 카드 선택 페이지로 이동할 때 카드 리스트 전달
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardSelectionPage(allCards: allCards),
                ),
              );
            },
          )
        ],
      ),
      body: allCards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: allCards.length,
        itemBuilder: (context, index) {
          final card = allCards[index];
          return ListTile(
            title: Text(card.name),
            subtitle: Text("공격력: ${card.attack}, 방어력: ${card.defense}, 체력: ${card.health}, 속도: ${card.speed}"),
          );
        },
      ),
    );
  }
}
