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
      name: json['name'],
      type: json['type'],
      attack: json['attack'],
      defense: json['defense'],
      health: json['health'],
      speed: json['speed'],
      critical: (json['critical'] as num).toDouble(),
      evasion: (json['evasion'] as num).toDouble(),
      order: json['order'],
      image: json['image'],
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

/// assets/cards 폴더 내 모든 JSON 카드 파일을 자동으로 로딩
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
