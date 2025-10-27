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

  /// 🔹 곤충 탐지 (전처리/후처리 최적화)
  Future<Map<String, dynamic>?> _detectInsect(File imageFile) async {
    if (_interpreter == null) return null;
    final bytes = await imageFile.readAsBytes();
    final oriImage = img.decodeImage(bytes);
    if (oriImage == null) return null;

    // --- ✨ 1. (수정) 이미지 전처리: 비율 유지 리사이즈 (Letterboxing) ---
    const double inputSize = 640.0;

    // 원본 비율 유지를 위한 스케일 계산
    final double scale = min(
        inputSize / oriImage.width, inputSize / oriImage.height);
    final int newWidth = (oriImage.width * scale).round();
    final int newHeight = (oriImage.height * scale).round();

    // 비율 맞춰 리사이즈
    final resized = img.copyResize(
        oriImage, width: newWidth, height: newHeight);

    // 640x640 검은색 캔버스(패딩) 생성
    final padded = img.Image(
        width: inputSize.toInt(), height: inputSize.toInt());
    img.fill(padded, color: img.ColorRgb8(0, 0, 0)); // 검은색으로 채우기

    // 캔버스 중앙에 리사이즈된 이미지 붙여넣기
    final int dx = (inputSize.toInt() - newWidth) ~/ 2; // x축 여백
    final int dy = (inputSize.toInt() - newHeight) ~/ 2; // y축 여백
    img.compositeImage(padded, resized, dstX: dx, dstY: dy);
    // -------------------------------------------------------------

    // --- ✨ 2. (수정) 입력 데이터 정규화 (Normalization) ---
    final input = List.generate(
      1,
          (_) =>
          List.generate(
            inputSize.toInt(),
                (y) =>
                List.generate(
                  inputSize.toInt(),
                      (x) {
                    final pixel = padded.getPixel(x, y);

                    // ⚠️ [0, 1] 정규화 (가장 일반적인 방식)
                    return [
                      pixel.r.toDouble() / 255.0,
                      pixel.g.toDouble() / 255.0,
                      pixel.b.toDouble() / 255.0
                    ];

                    /* // ⚠️ 또는 [-1, 1] 정규화 (모델에 따라 다를 수 있음)
          return [
            (pixel.r.toDouble() - 127.5) / 127.5,
            (pixel.g.toDouble() - 127.5) / 127.5,
            (pixel.b.toDouble() - 127.5) / 127.5
          ];
          */
                  },
                ),
          ),
    );
    // ---------------------------------------------------------

    final output = List.filled(1 * 300 * 6, 0.0).reshape([1, 300, 6]);
    _interpreter!.run(input, output);

    double maxConf = 0.0;
    List? bestBox;

    const double MAX_BOX_SIZE_THRESHOLD = 0.95;
    const double MIN_CONFIDENCE_THRESHOLD = 0.1; // 인식률 0.1

    for (var box in output[0]) {
      final conf = box[4];

      // (수정) 0.1(최소 신뢰도)보다 높은 것들 중에서
      if (conf > MIN_CONFIDENCE_THRESHOLD) {
        final double w = box[2];
        final double h = box[3];

        // 비정상적인 크기(95% 이상)가 아니고
        if (w < MAX_BOX_SIZE_THRESHOLD && h < MAX_BOX_SIZE_THRESHOLD) {
          // 현재까지 찾은 것보다 신뢰도가 높으면
          if (conf > maxConf) {
            maxConf = conf;
            bestBox = box;
          }
        }
      }
    }

    // (수정) bestBox가 null이거나, 찾았더라도 maxConf가 0.1 이하면 반환
    if (bestBox == null) return null;

    // --- ✨ 3. (수정) 후처리: 좌표 원본 기준으로 역산 ---
    // 모델이 [x_center, y_center, w, h] 형식을 반환한다고 가정
    final double x_center_norm = bestBox[0];
    final double y_center_norm = bestBox[1];
    final double w_norm = bestBox[2];
    final double h_norm = bestBox[3];

    // 1. [0, 1] 정규화된 좌표를 640x640 (패딩된) 픽셀 좌표로 변환
    final double x_center_padded = x_center_norm * inputSize;
    final double y_center_padded = y_center_norm * inputSize;
    final double w_padded = w_norm * inputSize;
    final double h_padded = h_norm * inputSize;

    // 2. 중심 좌표를 (x_min, y_min) 픽셀 좌표로 변환
    final double x_min_padded = x_center_padded - (w_padded / 2);
    final double y_min_padded = y_center_padded - (h_padded / 2);

    // 3. (✨ 핵심) 패딩(dx, dy)과 스케일(scale)을 역산하여 원본 이미지 픽셀 좌표로 변환
    final double x_min_original = (x_min_padded - dx) / scale;
    final double y_min_original = (y_min_padded - dy) / scale;
    final double w_original = w_padded / scale;
    final double h_original = h_padded / scale;

    return {
      "x": x_min_original,
      "y": y_min_original,
      "width": w_original,
      "height": h_original,
      "confidence": maxConf,
    };
  }

  /// 🔹 이미지 자르기
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
