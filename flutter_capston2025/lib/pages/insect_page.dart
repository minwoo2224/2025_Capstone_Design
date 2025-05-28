import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'insect_detail_page.dart';

class InsectPage extends StatefulWidget {
  final Color themeColor;

  const InsectPage({super.key, required this.themeColor});

  @override
  State<InsectPage> createState() => _InsectPageState();
}

class _InsectPageState extends State<InsectPage> {
  List<Map<String, dynamic>> _insects = [];

  @override
  void initState() {
    super.initState();
    _loadInsects();
  }

  Future<void> _loadInsects() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/insect_data.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final data = jsonDecode(content) as List<dynamic>;
        final insects = data.cast<Map<String, dynamic>>();
        setState(() {
          _insects = insects.reversed.toList(); // 최신 순 정렬
        });
      }
    }
  }

  String _getIconPath(String type) {
    switch (type) {
      case '가위':
        return 'assets/icons/scissors.png';
      case '바위':
        return 'assets/icons/rock.png';
      case '보':
        return 'assets/icons/paper.png';
      default:
        return '';
    }
  }

  Widget _buildInsectCard(Map<String, dynamic> insect) {
    final imagePath = insect['image'];
    final type = insect['type'];
    final iconPath = _getIconPath(type);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          isDismissible: false,
          builder: (_) => InsectDetailPage(insect: insect),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                if (iconPath.isNotEmpty)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Image.asset(
                      iconPath,
                      width: 28,
                      height: 28,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            insect['name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C3A),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _insects.isEmpty
            ? const Center(
          child: Text(
            '저장된 곤충이 없습니다.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        )
            : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: _insects.length,
          itemBuilder: (context, index) {
            return _buildInsectCard(_insects[index]);
          },
        ),
      ),
    );
  }
}