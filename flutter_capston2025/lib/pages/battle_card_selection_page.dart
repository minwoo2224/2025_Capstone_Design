import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/pages/game_page.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';

class BattleCardSelectionPage extends StatefulWidget {
  final List<InsectCard> playerCards;
  final List<InsectCard> opponentCards;
  final int round;
  final String userUid;
  final Color themeColor;

  const BattleCardSelectionPage({
    Key? key,
    required this.playerCards,
    required this.opponentCards,
    required this.round,
    required this.userUid,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<BattleCardSelectionPage> createState() => _BattleCardSelectionPageState();
}

class _BattleCardSelectionPageState extends State<BattleCardSelectionPage> {
  int? selectedIndex;
  List<InsectCard> remainingCards = [];

  @override
  void initState() {
    super.initState();

    // 남은 카드 계산 (round에 따라 1장씩 사용했다고 가정)
    remainingCards = widget.playerCards.sublist(widget.round - 1);

    // 서버에서 startBattle 이벤트 수신 시 상대 카드도 함께 전달됨
    SocketService.socket.on('startBattle', (data) {
      if (selectedIndex != null) {
        final selectedCard = remainingCards[selectedIndex!];
        final opponentCard = InsectCard.fromJson(data);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GamePage(
              userUid: widget.userUid,
              playerCards: [selectedCard],
              opponentCards: [opponentCard],
              round: widget.round,
              themeColor: widget.themeColor,
            ),
          ),
        );
      }
    });
  }

  void _startBattle() {
    if (selectedIndex != null) {
      final selectedCard = remainingCards[selectedIndex!];
      SocketService.selectCard(selectedIndex!);
      SocketService.sendSelectedCard(selectedCard);
    }
  }

  Widget _buildCard(InsectCard card, {bool selected = false}) {
    return Container(
      width: 120,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: selected ? Colors.red : Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (card.image.isNotEmpty) Image.asset(card.image, height: 40),
          Text('이름: ${card.name}', style: const TextStyle(color: Colors.black)),
          Text('타입: ${card.type}', style: const TextStyle(color: Colors.black)),
          Text('공격: ${card.attack}', style: const TextStyle(color: Colors.black)),
          Text('방어: ${card.defense}', style: const TextStyle(color: Colors.black)),
          Text('체력: ${card.health}', style: const TextStyle(color: Colors.black)),
          Text('속도: ${card.speed}', style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SocketService.socket.off('startBattle');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('게임 - Round ${widget.round}',
                    style: const TextStyle(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 16),
                const Text('상대 카드',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.opponentCards.map((c) => _buildCard(c)).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('배틀에 참가할 카드 선택',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: remainingCards.asMap().entries.map((entry) {
                      int index = entry.key;
                      InsectCard card = entry.value;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIndex = index),
                        child: _buildCard(card, selected: selectedIndex == index),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startBattle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text('배틀 시작'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
