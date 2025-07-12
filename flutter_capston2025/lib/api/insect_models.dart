// lib/models/insect_models.dart
import 'package:flutter/foundation.dart';

@immutable
class InsectOrder {
  final String name;
  final String imageUrl;

  const InsectOrder({required this.name, required this.imageUrl});
}

@immutable
class InsectFamily {
  final String name;
  final String orderName;
  final String description;
  final String imageUrl;

  const InsectFamily({
    required this.name,
    required this.orderName,
    required this.description,
    required this.imageUrl,
  });
}