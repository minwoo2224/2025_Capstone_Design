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

  Future<void> _loadModel() async {
    try {
      _interpreter =
      await Interpreter.fromAsset('assets/models/best_int8.tflite');
      debugPrint("✅ TFLite 모델 로드 완료");
    } catch (e) {
      debugPrint("❌ 모델 로드 실패: $e");
    }
  }

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

  void _hideLoadingDialog() {
    if (!_loadingShown || !mounted) return;
    _loadingShown = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<Map<String, dynamic>?> _detectInsect(File imageFile) async {
    if (_interpreter == null) return null;
    final bytes = await imageFile.readAsBytes();
    final oriImage = img.decodeImage(bytes);
    if (oriImage == null) return null;

    const double inputSize = 640.0;
    final double scale =
    min(inputSize / oriImage.width, inputSize / oriImage.height);
    final int newWidth = (oriImage.width * scale).round();
    final int newHeight = (oriImage.height * scale).round();

    final resized =
    img.copyResize(oriImage, width: newWidth, height: newHeight);

    final padded =
    img.Image(width: inputSize.toInt(), height: inputSize.toInt());
    img.fill(padded, color: img.ColorRgb8(0, 0, 0));

    final int dx = (inputSize.toInt() - newWidth) ~/ 2;
    final int dy = (inputSize.toInt() - newHeight) ~/ 2;
    img.compositeImage(padded, resized, dstX: dx, dstY: dy);

    final input = List.generate(
      1,
          (_) => List.generate(
        inputSize.toInt(),
            (y) => List.generate(
          inputSize.toInt(),
              (x) {
            final pixel = padded.getPixel(x, y);
            return [
              pixel.r.toDouble() / 255.0,
              pixel.g.toDouble() / 255.0,
              pixel.b.toDouble() / 255.0
            ];
          },
        ),
      ),
    );

    final output = List.filled(1 * 300 * 6, 0.0).reshape([1, 300, 6]);
    _interpreter!.run(input, output);

    double maxConf = 0.0;
    List? bestBox;
    const double MAX_BOX_SIZE_THRESHOLD = 0.95;
    const double MIN_CONFIDENCE_THRESHOLD = 0.1;

    for (var box in output[0]) {
      final double conf = (box[4] as num).toDouble();
      if (conf > MIN_CONFIDENCE_THRESHOLD) {
        final double w = (box[2] as num).toDouble();
        final double h = (box[3] as num).toDouble();
        if (w < MAX_BOX_SIZE_THRESHOLD && h < MAX_BOX_SIZE_THRESHOLD) {
          if (conf > maxConf) {
            maxConf = conf;
            bestBox = box;
          }
        }
      }
    }

    if (bestBox == null) return null;

    final double x_center_norm = (bestBox[0] as num).toDouble();
    final double y_center_norm = (bestBox[1] as num).toDouble();
    final double w_norm = (bestBox[2] as num).toDouble();
    final double h_norm = (bestBox[3] as num).toDouble();

    final double x_center_padded = x_center_norm * inputSize;
    final double y_center_padded = y_center_norm * inputSize;
    final double w_padded = w_norm * inputSize;
    final double h_padded = h_norm * inputSize;

    final double x_min_padded = x_center_padded - (w_padded / 2);
    final double y_min_padded = y_center_padded - (h_padded / 2);

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

  Future<File> _cropImage(File imageFile, Map<String, dynamic> box) async {
    final decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) throw Exception("Failed to decode image for cropping.");
    final fixed = img.bakeOrientation(decoded);
    if (fixed == null) throw Exception("Failed to bake image orientation.");

    final double x_in = box["x"];
    final double y_in = box["y"];
    final double w_in = box["width"];
    final double h_in = box["height"];
    final double x2_in = x_in + w_in;
    final double y2_in = y_in + h_in;

    final int x = max(0, x_in.round());
    final int y = max(0, y_in.round());
    final int x2 = min(fixed.width, x2_in.round());
    final int y2 = min(fixed.height, y2_in.round());

    final int w = x2 - x;
    final int h = y2 - y;

    if (w <= 0 || h <= 0) {
      throw Exception("Invalid crop dimensions: Box is outside image bounds.");
    }

    final cropped = img.copyCrop(fixed, x: x, y: y, width: w, height: h);
    final randName = DateTime.now().microsecondsSinceEpoch;
    final newPath =
        "${path.dirname(imageFile.path)}/cropped_insect_$randName.jpg";
    final croppedFile = File(newPath);
    await croppedFile.writeAsBytes(img.encodeJpg(cropped));
    return croppedFile;
  }

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
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("처리 실패"),
            content: Text("오류가 발생했습니다: ${e.toString()}"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, dynamic>> _sendToServer(File imageFile) async {
    try {
      final uri = Uri.parse("https://54.180.80.49/predict");
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      final ioClient = IOClient(httpClient);
      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath("image", imageFile.path));
      final streamedResponse = await ioClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        final rawClass = data["class"];
        final classIndex =
        (rawClass is int) ? rawClass : int.tryParse(rawClass.toString());
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

  /// 🔹 분류 및 저장 (정확도 제거 + 결과 후 자동 저장)
  Future<void> _classifyAndSave() async {
    if (_croppedImage == null) return;
    await _showLoadingDialog();
    try {
      final result = await _sendToServer(_croppedImage!);
      _hideLoadingDialog();

      // 결과 표시 (정확도 X)
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            "분류 결과",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "이 곤충은 [${result['class']}] 입니다.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.5),
          ),
          actionsAlignment: MainAxisAlignment.center,
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

      // ✅ 결과창 이후 자동 저장
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/insect_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = "${photoDir.path}/insect_$timestamp.jpg";
      await _croppedImage!.copy(savedPath);

      final className = result['class'];
      final stats = InsectLabels.calculateStats(className);

      final rand = Random();
      const types = ['가위', '바위', '보'];

      final insectData = {
        'name': className,
        'type': types[rand.nextInt(types.length)],
        'attack': stats['attack'],
        'defense': stats['defense'],
        'health': stats['hp'],
        'speed': stats['speed'],
        'critical': 0.1,
        'evasion': 0.1,
        'order': className,
        'image': savedPath,
      };

      final jsonFile =
      File("${photoDir.path}/insect_$timestamp.json");
      await jsonFile.writeAsString(jsonEncode(insectData));
      debugPrint("✅ 곤충 저장 완료: ${result['class']} ($savedPath)");

    } catch (e) {
      _hideLoadingDialog();
      debugPrint("❌ 분류 오류: $e");
    }
  }

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
                  if (snapshot.connectionState ==
                      ConnectionState.done) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CameraPreview(_controller!, key: _previewKey),
                        LayoutBuilder(builder: (context, constraints) {
                          final double guideSize =
                              constraints.maxWidth * 0.35;
                          return Center(
                            child: SizedBox(
                              width: guideSize,
                              height: guideSize,
                              child: CustomPaint(
                                painter: DottedSquarePainter(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                  dashWidth: 8.0,
                                  dashSpace: 6.0,
                                ),
                              ),
                            ),
                          );
                        }),
                        LayoutBuilder(
                            builder: (context, constraints) {
                              final double guideSize =
                                  constraints.maxWidth * 0.35;
                              return Positioned(
                                top: (constraints.maxHeight / 2) +
                                    (guideSize / 2) +
                                    16,
                                left: 0,
                                right: 0,
                                child: Text(
                                  "곤충을 사각형 안에 맞춰주세요",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                    Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2,
                                        color: Colors.black
                                            .withOpacity(0.7),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ],
                    );
                  } else {
                    return const Center(
                        child: CircularProgressIndicator());
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
                      onPressed:
                      _isProcessing ? null : _classifyAndSave,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("서버로 전송 및 분류"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessing
                            ? Colors.grey
                            : widget.themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(220, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed:
                      _isProcessing ? null : _resetToPreview,
                      icon: const Icon(Icons.refresh,
                          color: Colors.white70),
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

// 점선 가이드
class DottedSquarePainter extends CustomPainter {
  final Paint _paint;
  final double dashWidth;
  final double dashSpace;

  DottedSquarePainter({
    Color color = Colors.white,
    double strokeWidth = 2.0,
    this.dashWidth = 8.0, // 점선 길이
    this.dashSpace = 6.0, // 점선 간격
  }) : _paint = Paint()
    ..color = color.withOpacity(0.8) // 반투명
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Top line
    _drawDashedLine(canvas, Offset(0, 0), Offset(width, 0));
    // Bottom line
    _drawDashedLine(canvas, Offset(0, height), Offset(width, height));
    // Left line
    _drawDashedLine(canvas, Offset(0, 0), Offset(0, height));
    // Right line
    _drawDashedLine(canvas, Offset(width, 0), Offset(width, height));
  }

  // 점선을 그리는 내부 로직
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);

    // [수정] dashCount는 횟수이므로 int 타입
    final int dashCount = (distance / (dashWidth + dashSpace)).floor();

    final double unitDx = dx / distance * (dashWidth + dashSpace);
    final double unitDy = dy / distance * (dashWidth + dashSpace);
    final double dashDx = dx / distance * dashWidth;
    final double dashDy = dy / distance * dashWidth;

    Offset start = p1;
    for (int i = 0; i < dashCount; i++) {
      final Offset end = Offset(start.dx + dashDx, start.dy + dashDy);
      canvas.drawLine(start, end, _paint);
      start = Offset(start.dx + unitDx, start.dy + unitDy);
    }
    // 마지막 남은 부분 그리기
    final double remaining = distance - (dashCount * (dashWidth + dashSpace));
    if (remaining > 0) {
      final Offset end = Offset(
          start.dx + (dx / distance * min(remaining, dashWidth)),
          start.dy + (dy / distance * min(remaining, dashWidth)));
      canvas.drawLine(start, end, _paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
