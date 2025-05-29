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
    const types = ['가위', '바위', '보'];

    return {
      'name': 'Insect',
      'type': types[rand.nextInt(types.length)],
      'attack': rand.nextInt(101),
      'defense': rand.nextInt(101),
      'health': rand.nextInt(101),
      'speed': rand.nextInt(101),
      'critical': 0.1,
      'evasion': 0.1,
      'order': 'Order',
      'image': imagePath,
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
              top: 100, // 필요에 따라 이 값도 조절하여 이미지 위치를 맞출 수 있습니다.
              left: 30,
              right: 30,
              child: Container(
                height: screenHeight * 0.325,
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
          // 이곳이 수정된 부분입니다.
            Align(
              alignment: Alignment.center, // Column 자체를 가운데 정렬
              child: Column(
                mainAxisSize: MainAxisSize.min, // 필요한 만큼만 공간 차지
                children: [
                  Image.asset(
                    "assets/icons/camera_guide.png",
                    height: 340, // 요청하신 높이로 설정
                  ),
                  // SizedBox는 이제 필요에 따라 간격을 직접 조절하는 데 사용
                  const SizedBox(height: 20), // 이미지와 텍스트 사이 간격

                  const Text(
                    '사진을 찍어보세요!!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                            color: Colors.black45,
                            offset: Offset(3, 3),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                  // 만약 텍스트 아래에도 공간을 주고 싶다면 여기에 SizedBox 추가
                  // const SizedBox(height: 200), // 이전에 요청하신 200px 간격은 Text 아래에 추가하면 적절할 수 있습니다.
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