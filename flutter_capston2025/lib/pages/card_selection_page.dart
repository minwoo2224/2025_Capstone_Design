import 'package:flutter/material.dart';
import '../models/insect_card.dart';

class CardSelectionPage extends StatefulWidget {
  const CardSelectionPage({super.key});

  @override
  State<CardSelectionPage> createState() => _CardSelectionPageState();
}

class _CardSelectionPageState extends State<CardSelectionPage> {
  List<InsectCard> _cards = [];
  List<InsectCard> _selected = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final loaded = await loadInsectCards();
    setState(() {
      _cards = loaded;
    });
  }

  void _toggleSelect(InsectCard card) {
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else {
        if (_selected.length < 3) _selected.add(card);
      }
    });
  }

  void _submitSelection() {
    if (_selected.length == 3) {
      Navigator.pop(context, _selected);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("3장의 카드를 선택하세요")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("카드 선택")),
      body: _cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              children: _cards.map((card) {
                final isSelected = _selected.contains(card);
                return GestureDetector(
                  onTap: () => _toggleSelect(card),
                  child: Card(
                    color: isSelected ? Colors.green[100] : null,
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(card.image, width: 60, height: 60),
                          const SizedBox(height: 4), //**이미지 추가
                          Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("타입: ${card.type}, 목: ${card.order}"),
                          Text("공: ${card.attack}, 방: ${card.defense}"),
                          Text("체: ${card.health}, 속도: ${card.speed}"),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitSelection,
        label: const Text("선택 완료"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
