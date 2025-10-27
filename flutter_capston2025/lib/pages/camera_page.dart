import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
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
  Interpreter? _interpreter;
  File? _croppedImage;
  bool _isProcessing = false;
  bool _loadingShown = false;
  Key _previewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  /// 🔹 카메라 초기화
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() {});
    debugPrint("📷 카메라 초기화 완료");
  }

  /// 🔹 모델 로드
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/best_int8.tflite');
      debugPrint("✅ TFLite 모델 로드 완료");
    } catch (e) {
      debugPrint("❌ 모델 로드 실패: $e");
    }
  }

  /// 🔹 로딩 다이얼로그 표시
  Future<void> _showLoadingDialog() async {
    if (_loadingShown || !mounted) return;
    _loadingShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("잠시만 기다려주세요..."),
          ],
        ),
      ),
    );
  }

  /// 🔹 로딩 다이얼로그 닫기
  void _hideLoadingDialog() {
    if (!_loadingShown || !mounted) return;
    _loadingShown = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// 🔹 곤충 탐지
  Future<Map<String, dynamic>?> _detectInsect(File imageFile) async {
    if (_interpreter == null) return null;
    final bytes = await imageFile.readAsBytes();
    final oriImage = img.decodeImage(bytes);
    if (oriImage == null) return null;

    const inputSize = 640;
    final resized = img.copyResize(oriImage, width: inputSize, height: inputSize);
    final input = List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (y) => List.generate(
          inputSize,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
          },
        ),
      ),
    );
    final output = List.filled(1 * 300 * 6, 0.0).reshape([1, 300, 6]);
    _interpreter!.run(input, output);

    double maxConf = 0.0;
    List? bestBox;
    for (var box in output[0]) {
      final conf = box[4];
      if (conf > maxConf) {
        maxConf = conf;
        bestBox = box;
      }
    }

    if (bestBox == null || maxConf < 0.3) return null;
    return {
      "x": bestBox[0] * oriImage.width,
      "y": bestBox[1] * oriImage.height,
      "width": bestBox[2] * oriImage.width,
      "height": bestBox[3] * oriImage.height,
      "confidence": maxConf,
    };
  }

  /// 🔹 이미지 자르기 (임시 파일명 변경)
  Future<File> _cropImage(File imageFile, Map<String, dynamic> box) async {
    final decoded = img.decodeImage(await imageFile.readAsBytes());
    final fixed = img.bakeOrientation(decoded!);
    final x = max(0, box["x"].toInt());
    final y = max(0, box["y"].toInt());
    final w = min(fixed.width - x, box["width"].toInt());
    final h = min(fixed.height - y, box["height"].toInt());

    final cropped = img.copyCrop(fixed, x: x, y: y, width: w, height: h);
    final randName = DateTime.now().microsecondsSinceEpoch;
    final newPath = "${path.dirname(imageFile.path)}/cropped_insect_$randName.jpg";
    final croppedFile = File(newPath);
    await croppedFile.writeAsBytes(img.encodeJpg(cropped));
    return croppedFile;
  }

  /// 🔹 사진 촬영 및 탐지
  Future<void> _takePhoto() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _croppedImage = null;
    });

    await _showLoadingDialog();

    try {
      await _initializeControllerFuture;
      final xfile = await _controller!.takePicture();
      final imageFile = File(xfile.path);
      final box = await _detectInsect(imageFile);

      _hideLoadingDialog();

      if (box == null) {
        if (mounted) {
          setState(() => _croppedImage = null);
        }
        await showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("탐지 실패"),
            content: Text("곤충이 없습니다."),
          ),
        );
        return;
      }

      final cropped = await _cropImage(imageFile, box);

      // ✅ 이미지 캐시 정리 후 새로 렌더링
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (mounted) {
        setState(() {
          _croppedImage = cropped;
          _previewKey = UniqueKey();
        });
      }
    } catch (e, st) {
      _hideLoadingDialog();
      debugPrint("❌ 촬영 오류: $e\n$st");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// 🔹 서버 전송
  Future<Map<String, dynamic>> _sendToServer(File imageFile) async {
    try {
      final uri = Uri.parse("https://54.180.112.140/predict");
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final ioClient = IOClient(httpClient);

      debugPrint("📡 서버 요청 시작: ${imageFile.path}");
      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath("image", imageFile.path));

      final streamedResponse = await ioClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("🧾 응답 코드: ${response.statusCode}");
      debugPrint("📜 응답 본문: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        final rawClass = data["class"];
        final classIndex = (rawClass is int) ? rawClass : int.tryParse(rawClass.toString());
        final className = (classIndex != null)
            ? InsectLabels.getName(classIndex)
            : "Unknown";
        return {
          "class": className,
          "confidence": (data["confidence"] ?? 0.0).toDouble(),
        };
      }
    } catch (e, st) {
      debugPrint("❌ 서버 오류: $e\n$st");
    }
    return {"class": "Unknown", "confidence": 0.0};
  }

  /// 🔹 분류 및 저장
  Future<void> _classifyAndSave() async {
    if (_croppedImage == null) return;
    await _showLoadingDialog();
    try {
      final result = await _sendToServer(_croppedImage!);
      _hideLoadingDialog();
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            "분류 결과",
            textAlign: TextAlign.center, // ✅ 제목도 중앙정렬
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "이 곤충은 [${result['class']}] 입니다.\n"
                "정확도: ${(result['confidence'] * 100).toStringAsFixed(1)} %",
            textAlign: TextAlign.center, // ✅ 중앙정렬
            style: const TextStyle(
              fontSize: 18, // ✅ 폰트 크기 살짝 키움
              height: 1.5,  // 줄 간격 살짝 여유롭게
            ),
          ),
          actionsAlignment: MainAxisAlignment.center, // ✅ 버튼도 중앙에 배치
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "확인",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _hideLoadingDialog();
      debugPrint("❌ 분류 오류: $e");
    }
  }

  /// 🔹 다시 촬영 (프리뷰로 복귀)
  Future<void> _resetToPreview() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    if (_croppedImage != null && _croppedImage!.existsSync()) {
      try {
        await _croppedImage!.delete();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _croppedImage = null;
        _previewKey = UniqueKey();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCropped = _croppedImage != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 7,
              child: isCropped
                  ? Image.file(
                _croppedImage!,
                fit: BoxFit.contain,
                key: _previewKey,
                gaplessPlayback: false,
              )
                  : (_controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller!, key: _previewKey);
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              )),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: isCropped
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _classifyAndSave,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("서버로 전송 및 분류"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isProcessing ? Colors.grey : widget.themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(220, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isProcessing ? null : _resetToPreview,
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text(
                        "다시 촬영",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                )
                    : FloatingActionButton(
                  onPressed: _isProcessing ? null : _takePhoto,
                  backgroundColor:
                  _isProcessing ? Colors.grey : widget.themeColor,
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
