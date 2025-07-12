import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/pages/battle_card_selection_page.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';
import 'package:flutter_capston2025/storage/login_storage.dart';

class CardSelectionPage extends StatefulWidget {
  final List<InsectCard> allCards;

  const CardSelectionPage({Key? key, required this.allCards}) : super(key: key);

  @override
  State<CardSelectionPage> createState() => _CardSelectionPageState();
}

class _CardSelectionPageState extends State<CardSelectionPage> {
  List<InsectCard> selectedCards = [];
  String? userUid;

  @override
  void initState() {
    super.initState();
    _loadUserUid();
  }

  Future<void> _loadUserUid() async {
    final loginInfo = await readLoginInfo(guest: false);
    setState(() {
      userUid = loginInfo['uid'];
    });
  }

  void _toggleCardSelection(InsectCard card) {
    setState(() {
      if (selectedCards.contains(card)) {
        selectedCards.remove(card);
      } else {
        if (selectedCards.length < 3) {
          selectedCards.add(card);
        }
      }
    });
  }

  void _submitSelection() async {
    final guestInfo = await readLoginInfo(guest: true);
    if (userUid == null || guestInfo.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("로그인이 필요합니다."),
          content: const Text("게임을 진행하려면 로그인이 필요합니다."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedCards.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("카드를 3장 선택해주세요.")),
      );
      return;
    }

    SocketService.connect(
      onConnected: () {
        SocketService.sendCardData(userUid!, selectedCards);
      },
      onMatched: () {},
      onCardsReceived: (opponentCards) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BattleCardSelectionPage(
              userUid: userUid!,
              playerCards: selectedCards,
              opponentCards: opponentCards,
              round: 1,
              themeColor: Colors.blue,
            ),
          ),
        );
      },
    );
  }

  void _showCardDetails(BuildContext context, InsectCard card, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  String _getIconPath(String type) {
    switch (type) {
      case '가위':
        return 'assets/icons/scissors.png';
      case '바위':
        return 'assets/icons/rock.png';
      case '보':
        return 'assets/icons/paper.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCards = widget.allCards;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C3A),
      appBar: AppBar(
        title: const Text("카드 선택"),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _submitSelection,
            child: const Text("선택완료", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: allCards.isEmpty
          ? const Center(child: Text("카드가 없습니다.", style: TextStyle(color: Colors.white70)))
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: allCards.length,
        itemBuilder: (context, index) {
          final card = allCards[index];
          final isSelected = selectedCards.contains(card);
          final iconPath = _getIconPath(card.type);
          Offset tapPosition = Offset.zero;

          return GestureDetector(
            onTapDown: (details) => tapPosition = details.globalPosition,
            onTap: () => _toggleCardSelection(card),
            onLongPress: () => _showCardDetails(context, card, tapPosition),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black87,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(card.image),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.white),
                            ),
                          ),
                        ),
                        if (iconPath.isNotEmpty)
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Image.asset(
                              iconPath,
                              width: 28,
                              height: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.name,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}