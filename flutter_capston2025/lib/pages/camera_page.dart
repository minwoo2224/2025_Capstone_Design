import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:math';
import 'Login/login_page.dart';
import 'Login/settings_page.dart';

Future<void> _saveInsectData(String fileName) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');
    final dataFile = File('${photoDir.path}/${fileName.replaceAll(".jpg", ".json")}');

    final random = Random();
    final types = ["묵", "찌", "빠"];
    final String randomType = types[random.nextInt(types.length)];

    final insectData = {
      "name": "insect",
      "type": randomType,
      "attack": random.nextInt(51) + 30,
      "defense": random.nextInt(51) + 30,
      "health": random.nextInt(51) + 50,
      "speed": random.nextInt(31) + 20,
      "passive": null,
      "critical": (random.nextDouble() * 0.3).toStringAsFixed(2),
      "evasion": (random.nextDouble() * 0.25).toStringAsFixed(2),
      "order": "Anyorder",
      "image": fileName,
    };

    await dataFile.writeAsString(jsonEncode(insectData));
    print('JSON 저장 경로: ${dataFile.path}');
  } catch (e) {
    print('곤충 JSON 저장 실패: $e');
  }
}

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
      final newFile = await File(pickedFile.path).copy('${photoDir.path}/$fileName');
      await _saveInsectData(fileName); // JSON 자동 저장
      setState(() {
        _lastImage = newFile;
      });
      widget.onPhotoTaken();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 🪐 우주 배경
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/camera_page/space_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 📸 최근 촬영 이미지
          if (_lastImage != null)
            Positioned(
              top: 100,
              left: 30,
              right: 30,
              child: Container(
                height: screenHeight * 0.65, // 화면의 65%만 사용
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.themeColor, width: 3),
                  boxShadow: [
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
                  // ⬇️ 안내 아이콘
                  Image.asset("assets/icons/camera_guide.png", height: 100),
                  const SizedBox(height: 12),
                  Text(
                    '사진이 없습니다!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 🚀 촬영하기 버튼
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
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ));
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Text('👤', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.white, size: 36),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
