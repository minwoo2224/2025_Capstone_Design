import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_capston2025/utils/insect_labels.dart';

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
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  File? _lastImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// 카메라 초기화
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  /// 사진 촬영
  Future<void> _takePhoto() async {
    try {
      await _initializeControllerFuture;

      final xfile = await _controller!.takePicture();
      final imageFile = File(xfile.path);

      // 서버로 전송
      final result = await _sendToServer(imageFile);
      final classification = result['class'];
      final confidence = result['confidence'];

      if (!mounted) return;

      // 결과 다이얼로그 표시
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text("분류 결과"),
            content: Text(
              "이 곤충은 [$classification] 입니다.\n"
                  "정확도: ${(confidence * 100).toStringAsFixed(1)} %",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // 취소
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveInsect(imageFile, classification);
                },
                child: const Text("확인"),
              ),
            ],
          );
        },
      );
    } catch (e, st) {
      debugPrint("Error taking photo: $e\n$st");
    }
  }

  /// 서버 전송
  Future<Map<String, dynamic>> _sendToServer(File imageFile) async {
    try {
      final uri = Uri.parse("https://52.79.156.232/predict");

      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      final ioClient = IOClient(httpClient);

      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath("image", imageFile.path));

      final streamedResponse = await ioClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔹 class 값이 int일 수도 있고 String일 수도 있으므로 변환 처리
        final dynamic rawClass = data["class"];
        int? classIndex;
        if (rawClass is int) {
          classIndex = rawClass;
        } else if (rawClass is String) {
          classIndex = int.tryParse(rawClass);
        }

        final className =
        (classIndex != null) ? InsectLabels.getName(classIndex) : "Unknown";

        return {
          "class": className,
          "confidence": (data["confidence"] ?? 0.0).toDouble(),
        };
      } else {
        return {"class": "Unknown", "confidence": 0.0};
      }
    } catch (e) {
      debugPrint("Server error: $e");
      return {"class": "Unknown", "confidence": 0.0};
    }
  }


  /// 곤충 데이터 저장
  Future<void> _saveInsect(File imageFile, String classification) async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');

    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'insect_$timestamp.jpg';
    final savedPath = path.join(photoDir.path, fileName);

    final newFile = await imageFile.copy(savedPath);

    final insectData = _generateInsectData(savedPath, classification);
    final jsonFile = File('${photoDir.path}/insect_$timestamp.json');
    await jsonFile.writeAsString(jsonEncode(insectData));

    if (mounted) {
      setState(() => _lastImage = newFile);
    }
    widget.onPhotoTaken();
  }

  /// 랜덤 곤충 데이터 생성
  Map<String, dynamic> _generateInsectData(
      String imagePath, String classification) {
    final rand = Random();
    const types = ['가위', '바위', '보'];

    return {
      'name': classification,
      'type': types[rand.nextInt(types.length)],
      'attack': rand.nextInt(41),
      'defense': rand.nextInt(11),
      'health': rand.nextInt(151),
      'speed': rand.nextInt(31),
      'critical': 0.1,
      'evasion': 0.1,
      'order': classification,
      'image': imagePath,
    };
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 카메라 미리보기 (화면 상단에 배치)
            Expanded(
              flex: 7, // 위쪽 70% 영역 차지
              child: _controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller!);
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),

            // 아래쪽 빈 공간 + 버튼
            Expanded(
              flex: 3, // 아래쪽 30% 영역
              child: Center(
                child: FloatingActionButton(
                  onPressed: _takePhoto,
                  backgroundColor: widget.themeColor,
                  child: const Icon(Icons.camera_alt, size: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
