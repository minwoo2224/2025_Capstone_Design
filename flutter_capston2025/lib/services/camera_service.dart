import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../utils/insect_labels.dart';

class CameraService {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  CameraController? get controller => _controller;
  Future<void>? get initializeControllerFuture => _initializeControllerFuture;

  /// 카메라 초기화
  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
  }

  /// 카메라 해제
  void dispose() {
    _controller?.dispose();
  }

  /// 사진 촬영 후 서버 전송 및 결과 반환
  Future<Map<String, dynamic>> takeAndSendPhoto() async {
    try {
      await _initializeControllerFuture;
      final xfile = await _controller!.takePicture();
      final imageFile = File(xfile.path);

      // 서버로 전송
      final result = await _sendToServer(imageFile);

      return {
        "class": result["class"],
        "confidence": result["confidence"],
        "file": imageFile
      };
    } catch (e, st) {
      print("Error taking photo: $e\n$st");
      return {"class": "Unknown", "confidence": 0.0, "file": null};
    }
  }

  /// 서버 전송 (SSL 무시 포함)
  Future<Map<String, dynamic>> _sendToServer(File imageFile) async {
    try {
      final uri = Uri.parse("https://52.79.156.232/predict");

      // SSL 무시 HttpClient
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

        // class 값이 int인지 string인지 확인 후 변환
        dynamic rawClass = data["class"];
        int? classIndex;

        if (rawClass is int) {
          classIndex = rawClass;
        } else if (rawClass is String) {
          classIndex = int.tryParse(rawClass);
        }

        final className = classIndex != null
            ? InsectLabels.getName(classIndex)
            : "Unknown";

        return {
          "class": className,
          "confidence": (data["confidence"] ?? 0.0).toDouble(),
        };
      } else {
        return {"class": "Unknown", "confidence": 0.0};
      }
    } catch (e) {
      print("Server error: $e");
      return {"class": "Unknown", "confidence": 0.0};
    }
  }

  /// 곤충 데이터 저장
  Future<void> saveInsect(File imageFile, String classification) async {
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

    print("곤충 저장 완료: $classification ($savedPath)");
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
}
