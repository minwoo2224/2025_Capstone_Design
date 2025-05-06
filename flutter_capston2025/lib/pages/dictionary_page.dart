import 'package:flutter/material.dart';
import '../models/insect_card.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  List<InsectCard> _cards = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("곤충 도감")),
      body: _cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final c = _cards[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.asset(c.image, width: 60, height: 60),
              title: Text(c.name),
              subtitle: Text("타입: ${c.type}, 곤충목: ${c.order}"),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("공: ${c.attack} / 방: ${c.defense}"),
                  Text("체: ${c.health} / 속도: ${c.speed}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
