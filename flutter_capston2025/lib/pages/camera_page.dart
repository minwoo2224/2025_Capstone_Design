import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraPage extends StatefulWidget {
  final Color themeColor;
  final VoidCallback onPhotoTaken;

  const CameraPage({
    super.key,
    required this.themeColor,
    required this.onPhotoTaken,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _lastImage;

  @override
  void initState() {
    super.initState();
    _loadLastImage();
  }

  Future<void> _loadLastImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');
    if (await photoDir.exists()) {
      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).contains("insect_"))
          .toList();
      if (files.isNotEmpty) {
        files.sort((a, b) => b.path.compareTo(a.path));
        setState(() {
          _lastImage = files.first;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/insect_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final fileName = 'insect_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imagePath = '${photoDir.path}/$fileName';
      final newFile = await File(pickedFile.path).copy(imagePath);

      final insectData = _generateInsectData(imagePath);
      await _saveInsectData(insectData);

      setState(() {
        _lastImage = newFile;
      });

      widget.onPhotoTaken();
    }
  }

  Map<String, dynamic> _generateInsectData(String imagePath) {
    final rand = Random();
    final types = ['묵', '찌', '빠'];

    return {
      'name': 'Insect',
      'image': imagePath,
      'order': 'Order',
      'type': types[rand.nextInt(types.length)],
      'attack': rand.nextInt(101), // 0~100
      'defense': rand.nextInt(101),
      'health': rand.nextInt(101),
      'speed': rand.nextInt(101),
    };
  }

  Future<void> _saveInsectData(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/insect_data.json');

    List<dynamic> existing = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        existing = jsonDecode(content);
      }
    }

    existing.add(data);
    await file.writeAsString(jsonEncode(existing));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/camera_page/space_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_lastImage != null)
            Positioned(
              top: 100,
              left: 30,
              right: 30,
              child: Container(
                height: screenHeight * 0.65,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.themeColor, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_lastImage!, fit: BoxFit.cover),
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/icons/camera_guide.png", height: 100),
                  const SizedBox(height: 12),
                  const Text(
                    '사진이 없습니다!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(2, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 30),
                    SizedBox(width: 12),
                    Text(
                      '촬영하기 🚀',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}