import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';
import 'package:flutter_capston2025/storage/login_storage.dart';
import 'package:flutter_capston2025/pages/game_page.dart';

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

    SocketService.sendCardData(userUid!, selectedCards);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(
          userUid: userUid!,
          playerCards: selectedCards,
          opponentCards: [],
          themeColor: Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCards = widget.allCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("카드 선택"),
        actions: [
          TextButton(
            onPressed: _submitSelection,
            child: const Text("선택완료", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: allCards.isEmpty
          ? const Center(child: Text("카드가 없습니다."))
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: allCards.length,
        itemBuilder: (context, index) {
          final card = allCards[index];
          final isSelected = selectedCards.contains(card);
          return GestureDetector(
            onTap: () => _toggleCardSelection(card),
            child: Card(
              color: isSelected ? Colors.lightGreen[100] : Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (card.image.isNotEmpty)
                    Image.asset(card.image, height: 60, fit: BoxFit.contain),
                  const SizedBox(height: 8),
                  Text(card.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("목: ${card.order}", style: const TextStyle(color: Colors.black)),
                  Text("공격력: ${card.attack}", style: const TextStyle(color: Colors.black)),
                  Text("방어력: ${card.defense}", style: const TextStyle(color: Colors.black)),
                  Text("체력: ${card.health}", style: const TextStyle(color: Colors.black)),
                  Text("속도: ${card.speed}", style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
