
import 'dart:convert';
import 'package:flutter/services.dart';

class InsectCard {
  final String name;
  final String type;
  final int attack;
  final int defense;
  final int health;
  final int speed;
  final String passive;
  final double critical;
  final double evasion;
  final String order;
  final String image; // **이미지 추가 상단 필드에 추가

  InsectCard({
    required this.name,
    required this.type,
    required this.attack,
    required this.defense,
    required this.health,
    required this.speed,
    required this.passive,
    required this.critical,
    required this.evasion,
    required this.order,
    required this.image, // **이미지 추가
  });

  factory InsectCard.fromJson(Map<String, dynamic> json) {
    return InsectCard(
      name: json['name'],
      type: json['type'],
      attack: json['attack'],
      defense: json['defense'],
      health: json['health'],
      speed: json['speed'],
      passive: json['passive'],
      critical: (json['critical'] as num).toDouble(),
      evasion: (json['evasion'] as num).toDouble(),
      order: json['order'],
      image: json['image'], // **이미지 추가
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'attack': attack,
    'defense': defense,
    'health': health,
    'speed': speed,
    'passive': passive,
    'critical': critical,
    'evasion': evasion,
    'order': order,
    'image': image,
  };
}

Future<List<InsectCard>> loadInsectCards() async {
  final List<String> filenames = [
    'assets/cards/가위곤충.json',
    'assets/cards/바위곤충.json',
    'assets/cards/보곤충.json',
  ];

  List<InsectCard> cards = [];

  for (String path in filenames) {
    String data = await rootBundle.loadString(path);
    final jsonMap = jsonDecode(data);
    cards.add(InsectCard.fromJson(jsonMap));
  }

  return cards;
}
