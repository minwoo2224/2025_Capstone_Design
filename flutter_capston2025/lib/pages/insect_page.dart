import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

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
            final insect = _insects[index];
            return Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(insect['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insect['name'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}