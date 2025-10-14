import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../widgets/themed_background.dart'; // 종이 테마 배경 위해

class GalleryPage extends StatefulWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const GalleryPage({
    super.key,
    required this.themeColor,
    required this.images,
    required this.previewColumns,
    required this.onPreviewSetting,
    required this.onImageDeleted,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late int _columns;
  late List<File> _images;
  Map<String, List<File>> _groupedImages = {};

  @override
  void initState() {
    super.initState();
    _columns = widget.previewColumns;
    _images = widget.images
        .where((file) =>
    file.path.endsWith('.jpg') &&
        file.existsSync() &&
        _isValidImage(file))
        .toList();

    // 최신 이미지가 먼저 나오도록 정렬
    _images.sort((a, b) => b.path.compareTo(a.path));

    _groupImagesByDate();
  }

  bool _isValidImage(File file) {
    try {
      final bytes = file.readAsBytesSync();
      return bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _groupImagesByDate() {
    _groupedImages.clear();
    for (var image in _images) {
      final fileName = path.basename(image.path);
      final timestampStr = fileName.replaceAll('insect_', '').replaceAll('.jpg', '');
      try {
        final timestamp = int.parse(timestampStr);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        _groupedImages.putIfAbsent(dateKey, () => []).add(image);
      } catch (e) {
        const defaultDate = "Unknown Date";
        _groupedImages.putIfAbsent(defaultDate, () => []).add(image);
      }
    }
    _groupedImages = Map.fromEntries(
      _groupedImages.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatDate(String dateKey) {
    if (dateKey == "Unknown Date") {
      return "알 수 없는 날짜";
    }
    try {
      final parsedDate = DateTime.parse(dateKey);
      final formatter = DateFormat('yyyy년 M월 d일', 'ko');
      return formatter.format(parsedDate);
    } catch (e) {
      return dateKey;
    }
  }

  void _changePreviewColumns(int columns) {
    setState(() {
      _columns = columns;
    });
    Navigator.pop(context);
  }

  void _showPreviewSettingSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(6, (i) => i + 1).map((num) {
            return ElevatedButton(
              onPressed: () => _changePreviewColumns(num),
              style: ElevatedButton.styleFrom(
                // 텍스트 색: 라이트=검정, 다크=흰색 (이미 적용해둔 상태 유지)
                foregroundColor: isDark ? Colors.white : Colors.black87,
                backgroundColor: Theme.of(context).colorScheme.surface,
                // ✅ 테두리 색: 라이트(종이/하양)=검정, 다크=기존 포인트 컬러 유지
                side: BorderSide(
                  color: isDark ? widget.themeColor : Colors.black87,
                  width: 1.2,
                ),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
              child: Text('$num개 보기'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showImageDialog(File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.file(image, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _deleteImage(File image) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("정말로 이 이미지를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("아니요"),
          ),
          TextButton(
            onPressed: () async {
              await image.delete();
              widget.onImageDeleted();
              setState(() {
                _images.remove(image);
                _groupImagesByDate();
              });
              Navigator.pop(context);
            },
            child: const Text("예"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 종이/하양: AppBar 색, 다크: 기존 색(widget.themeColor)
    final Color fabColor = isDark
        ? widget.themeColor
        : (Theme.of(context).appBarTheme.backgroundColor ??
        Colors.white);

    return Scaffold(
      body: ThemedBackground(
        child: Column(
          children: [
            Expanded(
              child: _groupedImages.isEmpty
                  ? Center(
                    child: Text(
                      "사진이 없습니다.",
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  )

                  : ListView.builder(
                itemCount: _groupedImages.length,
                itemBuilder: (context, index) {
                  final date = _groupedImages.keys.elementAt(index);
                  final images = _groupedImages[date]!;

                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final headerBg = isDark
                      ? Colors.white.withOpacity(0.08)   // 다크: 살짝 밝은 오버레이
                      : Colors.black.withOpacity(0.06);  // 라이트/종이: 살짝 어두운 오버레이
                  final headerTitleColor = isDark ? Colors.white : Colors.black87;

                  return StickyHeader(
                    header: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: headerBg,
                      child: Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: headerTitleColor,
                        ),
                      ),
                    ),
                    content: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: images.length,
                      itemBuilder: (context, idx) {
                        final image = images[idx];
                        return GestureDetector(
                          onTap: () => _showImageDialog(image),
                          onLongPress: () => _deleteImage(image),
                          child: Builder(
                            builder: (_) {
                              try {
                                return Image.file(image, fit: BoxFit.cover);
                              } catch (e) {
                                return Container(
                                  color: Colors.red.shade900,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Invalid image',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showPreviewSettingSheet,
        backgroundColor: fabColor,   // ← AppBar와 동일
        // foregroundColor는 지정 안 함(기본값 사용). 필요하면 직접 정해도 됨.
        child: const Icon(Icons.grid_view),
      ),
    );
  }
}