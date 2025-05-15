import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'Login/login_page.dart';
import 'Login/settings_page.dart';


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
      final newFile =
      await File(pickedFile.path).copy('${photoDir.path}/$fileName');
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
          Container(
            decoration: BoxDecoration(
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
