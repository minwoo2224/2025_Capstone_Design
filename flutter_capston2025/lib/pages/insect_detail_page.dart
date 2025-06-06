import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class InsectDetailPage extends StatefulWidget {
  final Map<String, dynamic> insect;
  final VoidCallback? onDelete;

  const InsectDetailPage({
    super.key,
    required this.insect,
    this.onDelete,
  });

  @override
  State<InsectDetailPage> createState() => _InsectDetailPageState();
}

class _InsectDetailPageState extends State<InsectDetailPage> {
  late String _insectName;

  @override
  void initState() {
    super.initState();
    _insectName = widget.insect['name'] ?? '이름없음';
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

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('정말 놓아줍니까?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              Navigator.of(context).pop();

              final imageFile = File(widget.insect['image']);
              final jsonFilePath = imageFile.path.replaceAll('.jpg', '.json');
              final jsonFile = File(jsonFilePath);

              if (await jsonFile.exists()) {
                await jsonFile.delete();
              }

              widget.onDelete?.call();
            },
            child: const Text('예'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: _insectName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('이름 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 8,
          decoration: const InputDecoration(hintText: '새 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              setState(() {
                _insectName = newName;
              });

              final imageFile = File(widget.insect['image']);
              final jsonPath = imageFile.path.replaceAll('.jpg', '.json');
              final jsonFile = File(jsonPath);

              if (await jsonFile.exists()) {
                try {
                  final content = await jsonFile.readAsString();
                  final data = jsonDecode(content) as Map<String, dynamic>;
                  data['name'] = newName;
                  await jsonFile.writeAsString(jsonEncode(data));
                } catch (e) {
                  debugPrint("이름 저장 실패: $e");
                }
              }

              Navigator.of(context).pop();
            },
            child: const Text('예'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _getIconPath(widget.insect['type']);
    final order = widget.insect['order'] ?? '';
    final health = widget.insect['health'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 160,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.insect['image']),
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (iconPath.isNotEmpty)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Image.asset(
                          iconPath,
                          width: 36,
                          height: 36,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _editName(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _insectName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 24, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$order과',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                '$health HP',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'ATK ${widget.insect['attack']} / DEF ${widget.insect['defense']} / SPD ${widget.insect['speed']}',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 32),
              child: GestureDetector(
                onTap: () => _confirmDeletion(context),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}