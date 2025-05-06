import 'package:flutter/material.dart';
import '../models/insect_card.dart';
import 'card_selection_page.dart';
import '../socket/socket_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<InsectCard> playerCards = [];
  InsectCard? selectedCard;

  @override
  void initState() {
    super.initState();
    SocketService.connect(); // 서버 연결
    _goToCardSelection(); // 시작 시 카드 선택
  }

  Future<void> _goToCardSelection() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CardSelectionPage()),
    );

    if (selected != null && selected is List<InsectCard>) {
      setState(() {
        playerCards = selected;
      });
    }
  }

  void _selectCard(InsectCard card) {
    setState(() {
      selectedCard = card;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("곤충 카드 배틀")),
      body: playerCards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 16),
          const Text("내 카드 중 하나를 선택하세요"),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: playerCards.map((card) {
              final isSelected = card == selectedCard;
              return GestureDetector(
                onTap: () => _selectCard(card),
                child: Card(
                  color: isSelected ? Colors.amber[100] : null,
                  margin: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Image.asset(card.image, width: 80, height: 80),// **이미지 추가
                          const SizedBox(height: 8), //**이미지 추가
                          Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("타입: ${card.type}"),
                          Text("공: ${card.attack}, 방: ${card.defense}"),
                          Text("체: ${card.health}, 속: ${card.speed}"),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: selectedCard == null
                ? null
                : () {
              SocketService.sendSingleCard(selectedCard!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("카드 전송 완료")),
              );
            },
            child: const Text("선택 완료"),
          ),
        ],
      ),
    );
  }
}
