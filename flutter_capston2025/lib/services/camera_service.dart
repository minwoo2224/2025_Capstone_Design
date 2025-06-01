import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<void> captureAndSavePhoto({
  required BuildContext context,
  required VoidCallback onCompleted,
}) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);
  if (pickedFile == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final photoDir = Directory('${dir.path}/insect_photos');
  if (!await photoDir.exists()) await photoDir.create(recursive: true);

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final fileName = 'insect_$timestamp.jpg';
  final imagePath = '${photoDir.path}/$fileName';
  await File(pickedFile.path).copy(imagePath);

  final rand = Random();
  const types = ['가위', '바위', '보'];
  final insectData = {
    'name': 'Insect',
    'type': types[rand.nextInt(types.length)],
    'attack': rand.nextInt(41),
    'defense': rand.nextInt(11),
    'health': rand.nextInt(151),
    'speed': rand.nextInt(31),
    'critical': 0.1,
    'evasion': 0.1,
    'order': 'Order',
    'image': imagePath,
  };

  final dataFile = File('${photoDir.path}/insect_$timestamp.json');
  await dataFile.writeAsString(jsonEncode(insectData));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('촬영 및 저장 완료!')),
    );
  }

  onCompleted();
}