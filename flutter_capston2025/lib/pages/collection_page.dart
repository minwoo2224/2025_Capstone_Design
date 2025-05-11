
import 'dart:io';
import 'package:flutter/material.dart';
import 'gallery_page.dart';
import 'dictionary_page.dart';

class CollectionPage extends StatefulWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const CollectionPage({
    super.key,
    required this.themeColor,
    required this.images,
    required this.previewColumns,
    required this.onPreviewSetting,
    required this.onImageDeleted,
  });

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 59, 36, 173),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double iconSize = constraints.maxWidth * 0.15; // ⬆️ 모든 곤충 크기 증가
            return Stack(
              children: [
                ..._buildInsectImages(iconSize),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildButton(
                        label: "도감",
                        icon: Icons.menu_book,
                        color: Colors.amber.shade400,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DictionaryPage()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildButton(
                        label: "갤러리",
                        icon: Icons.photo_library,
                        color: Colors.cyanAccent.shade400,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryPage(
                              themeColor: widget.themeColor,
                              images: widget.images,
                              previewColumns: widget.previewColumns,
                              onPreviewSetting: widget.onPreviewSetting,
                              onImageDeleted: widget.onImageDeleted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildInsectImages(double size) {
    const positions = [
      Alignment(-1.0, -0.85), // ⬇️ 1번: 아래로
      Alignment(0.0, -0.85),  // ⬇️ 2번: 아래로
      Alignment(1.0, -0.85),  // ⬇️ 3번: 아래로
      Alignment.centerLeft,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomCenter,
      Alignment.bottomRight,
      Alignment(-0.7, -0.4), // ⬆️ 9번: 위로
      Alignment(0.7, -0.4),  // ⬆️ 10번: 위로
      Alignment(-0.6, 0.6),
      Alignment(0.6, 0.6),
    ];
    return List.generate(12, (i) {
      return Align(
        alignment: positions[i],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/insect${i + 1}.png',
            width: size,
            height: size,
          ),
        ),
      );
    });
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 240,
      height: 70,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28, color: Colors.black),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          elevation: 6,
        ),
      ),
    );
  }
}
