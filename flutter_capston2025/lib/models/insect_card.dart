import 'dart:convert';
import 'package:flutter/services.dart';

class InsectCard {
  final String name;
  final String type;
  final int attack;
  final int defense;
  final int health;
  final int speed;
  final double critical;
  final double evasion;
  final String order;
  final String image;

  InsectCard({
    required this.name,
    required this.type,
    required this.attack,
    required this.defense,
    required this.health,
    required this.speed,
    required this.critical,
    required this.evasion,
    required this.order,
    required this.image,
  });

  factory InsectCard.fromJson(Map<String, dynamic> json) {
    return InsectCard(
      name: json['name'] ?? '알 수 없음',
      type: json['type'] ?? '기타',
      attack: json['attack'] ?? 0,
      defense: json['defense'] ?? json['defend'] ?? 0,  // 둘 중 하나 사용
      health: json['health'] ?? json['hp'] ?? 100,      // 서버는 'hp' 사용
      speed: json['speed'] ?? 0,
      critical: (json['critical'] ?? 0).toDouble(),
      evasion: (json['evasion'] ?? 0).toDouble(),
      order: json['order'] ?? '기타',
      image: json['image'] ?? '',  // 상대 카드는 이미지가 없을 수 있음
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'attack': attack,
    'defense': defense,
    'health': health,
    'speed': speed,
    'critical': critical,
    'evasion': evasion,
    'order': order,
    'image': image,
  };

  Map<String, dynamic> toServerJson() => {
    'name': name,
    'type': type,
    'attack': attack,
    'defense': defense,
    'health': health,
    'speed': speed,
  };
}

Future<List<InsectCard>> loadInsectCards() async {
  final manifestContent = await rootBundle.loadString('AssetManifest.json');
  final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);

  final cardPaths = manifestMap.keys
      .where((path) =>
  path.startsWith('assets/cards/') && path.endsWith('.json'))
      .toList();

  List<InsectCard> cards = [];

  for (String path in cardPaths) {
    final jsonString = await rootBundle.loadString(path);
    final jsonMap = jsonDecode(jsonString);
    cards.add(InsectCard.fromJson(jsonMap));
  }

  return cards;
}
