import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';

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
      opponentCards = data;
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

  Widget _buildCard(dynamic cardData, bool isSelected) {
    final name = cardData.name ?? cardData['name'];
    final image = cardData.image ?? cardData['image'];
    final order = cardData.order ?? cardData['order'];
    final attack = cardData.attack ?? cardData['attack'];
    final defense = cardData.defense ?? cardData['defense'];
    final health = cardData.health ?? cardData['health'];
    final speed = cardData.speed ?? cardData['speed'];

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.lightBlue[50] : Colors.white,
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null) Image.asset(image, height: 60),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            Text("목: $order", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text("공: $attack", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text("방: $defense", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text("체: $health", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text("속: $speed", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (battleLog.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(battleLog, style: const TextStyle(fontSize: 16)),
            ),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text("상대방 카드", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(
            height: 170,
            child: opponentCards.isEmpty
                ? const Center(
                child: Text("상대방 카드 정보를 기다리는 중...",
                    style: TextStyle(color: Colors.white)))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: opponentCards.length,
              itemBuilder: (context, index) {
                return _buildCard(opponentCards[index], false);
              },
            ),
          ),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text("내 카드", style: TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.5, // 세로 길이 확보
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
    );
  }
}
