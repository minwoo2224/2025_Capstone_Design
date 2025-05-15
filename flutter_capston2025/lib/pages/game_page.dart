import 'dart:math';
import 'package:flutter/material.dart';
import '../models/insect_card.dart';
import 'card_selection_page.dart';

class GamePage extends StatefulWidget {
  final InsectCard? playerCard;
  final InsectCard? opponentCard;
  final Color themeColor;

  const GamePage({
    super.key,
    this.playerCard,
    this.opponentCard,
    required this.themeColor,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late InsectCard player;
  late InsectCard opponent;
  int playerHealth = 0;
  int opponentHealth = 0;
  String battleLog = '';
  bool playerTurn = true;
  bool battleEnded = false;
  bool showDamage = false;
  int damageAmount = 0;

  late AnimationController _attackController;
  late Animation<Offset> _attackAnimation;
  late AnimationController _hitController;
  late Animation<Offset> _hitAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.playerCard == null || widget.opponentCard == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CardSelectionPage(
              themeColor: widget.themeColor,
              onPhotoTaken: () {},
            ),
          ),
        );
      });
      return;
    }

    player = widget.playerCard!;
    opponent = widget.opponentCard!;
    playerHealth = player.health;
    opponentHealth = opponent.health;

    _initAnimations();
    Future.delayed(const Duration(seconds: 1), startBattle);
  }

  void _initAnimations() {
    _attackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _hitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _attackAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _attackController, curve: Curves.easeOut));

    _hitAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.1, 0),
    ).animate(CurvedAnimation(parent: _hitController, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _attackController.dispose();
    _hitController.dispose();
    super.dispose();
  }

  void startBattle() async {
    while (!battleEnded) {
      await Future.delayed(const Duration(milliseconds: 500));
      await performAttack();
    }
  }

  Future<void> performAttack() async {
    if (battleEnded) return;

    InsectCard attacker = playerTurn ? player : opponent;
    InsectCard defender = playerTurn ? opponent : player;

    bool evaded = Random().nextDouble() < defender.evasion;
    bool critical = Random().nextDouble() < attacker.critical;

    double typeMultiplier = getTypeMultiplier(attacker.type, defender.type);
    int baseDamage = max(0, attacker.attack - defender.defense);
    double totalDamage = baseDamage * typeMultiplier * (critical ? 1.5 : 1);
    damageAmount = totalDamage.round();

    _attackAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: Offset.zero,
          end: playerTurn ? const Offset(0.4, -0.2) : const Offset(-1.0, 1.0),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: playerTurn ? const Offset(0.4, -0.2) : const Offset(-1.0, 1.0),
          end: playerTurn ? const Offset(-0.2, 0.1) : const Offset(0.5, -0.3),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: playerTurn ? const Offset(-0.2, 0.1) : const Offset(0.5, -0.3),
          end: Offset.zero,
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _attackController, curve: Curves.easeOut));

    _attackController.forward(from: 0);
    if (!evaded) _hitController.forward(from: 0);

    setState(() => showDamage = true);

    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      showDamage = false;
      if (evaded) {
        battleLog = '${defender.name}이(가) 공격을 회피했습니다!';
      } else {
        if (playerTurn) {
          opponentHealth = max(0, opponentHealth - damageAmount);
        } else {
          playerHealth = max(0, playerHealth - damageAmount);
        }
        battleLog = '${attacker.name}의 공격! ${critical ? "치명타! " : ""}$damageAmount의 피해를 입혔습니다';
      }

      if (playerHealth <= 0 || opponentHealth <= 0) {
        battleEnded = true;
        battleLog = playerHealth <= 0
            ? '${opponent.name}의 승리!'
            : '${player.name}의 승리!';
      } else {
        playerTurn = !playerTurn;
      }
    });
  }

  double getTypeMultiplier(String atkType, String defType) {
    if ((atkType == '가위' && defType == '보') ||
        (atkType == '보' && defType == '바위') ||
        (atkType == '바위' && defType == '가위')) {
      return 1.5;
    }
    return 1.0;
  }

  Widget buildBattleInfoBar(String name, int hp, int maxHp, Alignment align) {
    return Align(
      alignment: align,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: hp / maxHp,
              backgroundColor: Colors.grey[300],
              color: Colors.redAccent,
              minHeight: 8,
            ),
            Text('$hp / $maxHp', style: const TextStyle(fontSize: 10, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playerCard == null || widget.opponentCard == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("곤충 배틀"),
        backgroundColor: widget.themeColor,
      ),
      body: Stack(
        children: [
          // ✅ 배경 이미지 추가
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/forest_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // 기존 상대 곤충 UI
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                buildBattleInfoBar(opponent.name, opponentHealth, opponent.health, Alignment.centerRight),
                const SizedBox(height: 4),
                SlideTransition(
                  position: playerTurn ? Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_attackController) : _hitAnimation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(opponent.image, height: 100),
                      if (showDamage && playerTurn)
                        Positioned(
                          top: 0,
                          left: -70,
                          child: Text(
                            '-$damageAmount',
                            style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 플레이어 곤충 UI
          Positioned(
            bottom: 100,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: playerTurn ? _attackAnimation : Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_hitController),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(player.image, height: 100),
                      if (showDamage && !playerTurn)
                        Positioned(
                          top: 0,
                          right: -70,
                          child: Text(
                            '-$damageAmount',
                            style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                buildBattleInfoBar(player.name, playerHealth, player.health, Alignment.centerLeft),
              ],
            ),
          ),

          // 전투 로그
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
              ),
              child: Text(
                battleLog,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
