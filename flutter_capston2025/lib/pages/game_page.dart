import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';
import 'dart:math';

class GamePage extends StatefulWidget {
  final String userUid;
  final List<InsectCard> playerCards;
  final List<dynamic> opponentCards;
  final Color themeColor;

  const GamePage({
    Key? key,
    required this.userUid,
    required this.playerCards,
    required this.opponentCards,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int? selectedCardIndex;
  String battleLog = '';
  int round = 1;
  bool waitingForOpponent = true;
  List<dynamic> opponentCards = [];

  @override
  void initState() {
    super.initState();
    opponentCards = widget.opponentCards;
    SocketService.socket.on('matchResult', _onMatchResult);
    SocketService.socket.on('nextRound', _onNextRound);
    SocketService.socket.on('cardsInfo', _onCardsInfo);
  }

  @override
  void dispose() {
    SocketService.socket.off('matchResult', _onMatchResult);
    SocketService.socket.off('nextRound', _onNextRound);
    SocketService.socket.off('cardsInfo', _onCardsInfo);
    super.dispose();
  }

  void _onMatchResult(dynamic msg) {
    setState(() {
      battleLog = msg.toString();
    });
    _showGameEndDialog(msg.toString());
  }

  void _onNextRound(dynamic data) {
    setState(() {
      battleLog = '다음 라운드 시작';
      selectedCardIndex = null;
      round += 1;
      waitingForOpponent = false;
    });
  }

  void _onCardsInfo(dynamic data) {
    setState(() {
      opponentCards = List<Map<String, dynamic>>.from(data);
      waitingForOpponent = false;
    });
  }

  void _selectCard(int index) {
    if (selectedCardIndex != null) return;

    setState(() {
      selectedCardIndex = index;
      waitingForOpponent = true;
      battleLog = '선택한 카드: ${widget.playerCards[index].name}';
    });

    SocketService.selectCard(index);
  }

  Widget _buildCard(InsectCard card, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? widget.themeColor.withOpacity(0.4) : Colors.white,
        border: Border.all(color: widget.themeColor, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: widget.themeColor.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("공격력: ${card.attack}"),
          Text("방어력: ${card.defense}"),
          Text("체력: ${card.health}"),
          Text("속도: ${card.speed}"),
        ],
      ),
    );
  }

  Widget _buildOpponentCard(Map<String, dynamic> cardData) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(cardData['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("공격력: ${cardData['attack']}"),
          Text("방어력: ${cardData['defend']}"),
          Text("체력: ${cardData['hp']}"),
          Text("속도: ${cardData['speed']}"),
        ],
      ),
    );
  }

  void _showGameEndDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("게임 종료"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("홈으로"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게임 - Round $round'),
        backgroundColor: widget.themeColor,
      ),
      body: Column(
        children: [
          if (battleLog.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(battleLog, style: const TextStyle(fontSize: 16)),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                const Text("상대방 카드", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: opponentCards.length,
                    itemBuilder: (context, index) {
                      return _buildOpponentCard(opponentCards[index]);
                    },
                  ),
                ),
                const Divider(),
                const Text("내 카드", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: widget.playerCards.length,
                    itemBuilder: (context, index) {
                      final card = widget.playerCards[index];
                      return GestureDetector(
                        onTap: waitingForOpponent ? null : () => _selectCard(index),
                        child: _buildCard(card, selectedCardIndex == index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
