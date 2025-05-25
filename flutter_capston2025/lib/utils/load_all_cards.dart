import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../models/insect_card.dart';

Future<List<InsectCard>> loadAllCards() async {
  final directory = Directory('assets/cards');
  final assetManifest = await rootBundle.loadString('AssetManifest.json');

  final List<String> cardFiles = json
      .decode(assetManifest)
      .keys
      .where((key) => key.startsWith('assets/cards/') && key.endsWith('.json'))
      .toList();

  final List<InsectCard> allCards = [];

  for (final path in cardFiles) {
    final String jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final InsectCard card = InsectCard.fromJson(jsonMap);
    allCards.add(card);
  }

  return allCards;
}
