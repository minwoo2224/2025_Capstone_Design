import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';

class InsectCard {
  final String name;
  int attack;
  int health;
  final int speed;
  final String type;
  final String imagePath;

  InsectCard({
    required this.name,
    required this.attack,
    required this.health,
    required this.speed,
    required this.type,
    required this.imagePath,
  });
}

class GamePage extends StatefulWidget {
  final List<InsectCard> playerCards;

  const GamePage({super.key, required this.playerCards});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<InsectCard> enemyCards = [];
  InsectCard? playerSelected;
  InsectCard? enemySelected;
  String resultMessage = "";
  int secondsLeft = 10;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _bringEnemyCards();
    _startTimer();
  }
//지금은 랜덤으로 생성. 나중에는 연결해서 상대방이 유저로 변경할 예정
  void _bringEnemyCards() {
    final types = ["가위", "바위", "보"];
    final rand = Random();
    enemyCards = List.generate(3, (index) {
      return InsectCard(
        name: "적 곤충 ${index + 1}",
        attack: rand.nextInt(5) + 5,
        health: rand.nextInt(10) + 20,
        speed: rand.nextInt(5) + 1,
        type: types[rand.nextInt(3)],
        imagePath: "", // 추후 이미지 추가 가능
      );
    });
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        secondsLeft--;
        if (secondsLeft == 0) {
          _autoSelect();
          _startBattle();
          timer?.cancel();
        }
      });
    });
  }

  void _autoSelect() {
    final rand = Random();
    playerSelected ??= widget.playerCards[rand.nextInt(3)];
    enemySelected ??= enemyCards[rand.nextInt(3)];
  }

  void _selectCard(InsectCard card) {
    setState(() {
      playerSelected = card;
      enemySelected = enemyCards[Random().nextInt(3)];
    });
    timer?.cancel();
    _startBattle();
  }

  int _typeBonus(String atk, String def) {
    if ((atk == "가위" && def == "보") ||
        (atk == "보" && def == "바위") ||
        (atk == "바위" && def == "가위")) {
      return 2;
    }
    return 0;
  }

  void _startBattle() {
    if (playerSelected == null || enemySelected == null) return;

    final player = playerSelected!;
    final enemy = enemySelected!;

    InsectCard first, second;

    // 스피드가 다르면 빠른 쪽이 먼저
    if (player.speed > enemy.speed) {
      first = player;
      second = enemy;
    } else if (player.speed < enemy.speed) {
      first = enemy;
      second = player;
    } else {
      // 스피드가 같을 경우 → 타입 상성 우위 판단
      int playerBonus = _typeBonus(player.type, enemy.type);
      int enemyBonus = _typeBonus(enemy.type, player.type);

      if (playerBonus > enemyBonus) {
        first = player;
        second = enemy;
      } else if (enemyBonus > playerBonus) {
        first = enemy;
        second = player;
      } else {
        // 타입도 같으면 랜덤
        final rand = Random();
        if (rand.nextBool()) {
          first = player;
          second = enemy;
        } else {
          first = enemy;
          second = player;
        }
      }
    }

    final firstBonus = _typeBonus(first.type, second.type);
    second.health -= (first.attack + firstBonus);

    if (second.health > 0) {
      final secondBonus = _typeBonus(second.type, first.type);
      first.health -= (second.attack + secondBonus);
    }

    setState(() {
      resultMessage = "$first.name 이 먼저 공격!\n"
          "${second.name} 체력: ${second.health <= 0 ? "기절!" : second.health}";
    });
  }

//카드 UI 출력 함수(카드 클릭 가능 여부, 선택되면 연두색으로, 곤충 이미지, 능력치)
  Widget _buildCard(InsectCard card, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade100 : Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            if (card.imagePath.isNotEmpty)
              Image.file(File(card.imagePath), height: 60),
            Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("공: ${card.attack} 체: ${card.health} 속: ${card.speed}"),
            Text("타입: ${card.type}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { //전체 화면 구성
    return Scaffold(
      appBar: AppBar(title: const Text("곤충 배틀")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text("카드를 선택하세요 (${secondsLeft}초 남음)", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          const Text("상대 카드", style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: enemyCards
                .map((card) => _buildCard(card, false, () {}))
                .toList(),
          ),
          const Divider(height: 30),
          const Text("내 카드", style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.playerCards
                .map((card) => _buildCard(
              card,
              card == playerSelected,
                  () => _selectCard(card),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(
            resultMessage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

/*
나중에 cardselctionpage에 들어갈 코드


Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CardSelectionPage(
      allCards: myInsectCards,
      onCardsSelected: (selected) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GamePage(playerCards: selected),
          ),
        );
      },
    ),
  ),
);

**추가할 예정**
모델이 곤충을 분류하면 그 분류한


 */