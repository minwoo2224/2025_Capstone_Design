import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'insect_detail_page.dart';
import '../widgets/themed_background.dart';

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
    final photoDir = Directory('${dir.path}/insect_photos');

    if (await photoDir.exists()) {
      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      List<Map<String, dynamic>> insects = [];

      for (var file in files) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            insects.add(data);
          }
        } catch (_) {
          // malformed or corrupted file
        }
      }

      setState(() {
        _insects = insects.reversed.toList();
      });
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

  void _deleteInsect(Map<String, dynamic> insect) async {
    final imageFile = File(insect['image']);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    final jsonFilePath = imageFile.path.replaceAll('.jpg', '.json');
    final jsonFile = File(jsonFilePath);
    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }

    setState(() {
      _insects.removeWhere((item) => item['image'] == insect['image']);
    });
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
          builder: (_) => InsectDetailPage(
            insect: insect,
            onDelete: () => _deleteInsect(insect),
          ),
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
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _insects.isEmpty
              ? Center(
            child: Text(
              '저장된 곤충이 없습니다.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black87,
                fontSize: 18,
              ),
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
      ),
    );
  }
}