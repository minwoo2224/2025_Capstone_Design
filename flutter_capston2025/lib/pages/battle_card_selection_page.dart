import 'dart:io';
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
  State<BattleCardSelectionPage> createState() =>
      _BattleCardSelectionPageState();
}

class _BattleCardSelectionPageState extends State<BattleCardSelectionPage> {
  int? selectedIndex;
  late List<InsectCard> remainingCards;

  Offset _tapPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    remainingCards = widget.playerCards.sublist(widget.round - 1);

    SocketService.socket.on('startBattle', (data) {
      if (selectedIndex != null) {
        final sel = remainingCards[selectedIndex!];
        final opp = InsectCard.fromJson(data);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GamePage(
              userUid: widget.userUid,
              playerCards: [sel],
              opponentCards: [opp],
              round: widget.round,
              themeColor: widget.themeColor,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    SocketService.socket.off('startBattle');
    super.dispose();
  }

  void _startBattle() {
    if (selectedIndex != null) {
      final sel = remainingCards[selectedIndex!];
      SocketService.selectCard(selectedIndex!);
      SocketService.sendSelectedCard(sel);
    }
  }

  void _showDetails(InsectCard card, Offset pos) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        pos & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(card.order),
              Text('HP: ${card.health}'),
              Text('ATK: ${card.attack}'),
              Text('DEF: ${card.defense}'),
              Text('SPD: ${card.speed}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardWidget(InsectCard card,
      {bool isSelf = false, bool selected = false}) {
    final icon = {
      '가위': 'assets/icons/scissors.png',
      '바위': 'assets/icons/rock.png',
      '보': 'assets/icons/paper.png'
    }[card.type];

    return GestureDetector(
      onTapDown: (e) => _tapPos = e.globalPosition,
      onTap: isSelf
          ? () {
        setState(() {
          selectedIndex = remainingCards.indexOf(card);
        });
      }
          : null,
      onLongPress: isSelf ? () => _showDetails(card, _tapPos) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: selected ? Colors.red : Colors.transparent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(card.image),
                    width: 100,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                ),
                if (icon != null)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Image.asset(icon, width: 24, height: 24),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Round ${widget.round}',
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 16),
            const Text('상대 카드', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: widget.opponentCards
                      .map((c) => _cardWidget(c, isSelf: false))
                      .toList()),
            ),
            const SizedBox(height: 16),
            const Text('내 카드 선택', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: remainingCards
                    .map((c) => _cardWidget(
                  c,
                  isSelf: true,
                  selected: selectedIndex != null &&
                      remainingCards[selectedIndex!] == c,
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startBattle,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('배틀 시작'),
            ),
          ]),
        ),
      ),
    );
  }
}