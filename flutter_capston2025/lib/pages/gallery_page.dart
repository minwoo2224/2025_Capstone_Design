import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

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
    _images = widget.images;
    _groupImagesByDate();
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
        if (_groupedImages[dateKey] == null) {
          _groupedImages[dateKey] = [];
        }
        _groupedImages[dateKey]!.add(image);
      } catch (e) {
        const defaultDate = "Unknown Date";
        if (_groupedImages[defaultDate] == null) {
          _groupedImages[defaultDate] = [];
        }
        _groupedImages[defaultDate]!.add(image);
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
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: List.generate(6, (index) => index + 1).map((num) {
            return ElevatedButton(
              onPressed: () => _changePreviewColumns(num),
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
    return Scaffold(
      appBar: AppBar(title: const Text("갤러리")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Expanded(
            child: _groupedImages.isEmpty
                ? const Center(child: Text("사진이 없습니다.", style: TextStyle(fontSize: 18)))
                : ListView.builder(
              itemCount: _groupedImages.length,
              itemBuilder: (context, index) {
                final date = _groupedImages.keys.elementAt(index);
                final images = _groupedImages[date]!;
                return StickyHeader(
                  header: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.grey.shade200,
                    child: Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
                        child: Image.file(image, fit: BoxFit.cover),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPreviewSettingSheet,
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.grid_view),
      ),
    );
  }
}