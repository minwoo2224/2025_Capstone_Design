import 'dart:io';
import 'package:flutter/material.dart';

class InsectDetailPage extends StatelessWidget {
  final Map<String, dynamic> insect;
  final VoidCallback onDelete;

  const InsectDetailPage({
    super.key,
    required this.insect,
    required this.onDelete,
  });

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
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              onDelete();
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
    final iconPath = _getIconPath(insect['type']);
    final order = insect['order'] ?? '';
    final health = insect['health'];

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
                        File(insect['image']),
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
              Text(
                insect['name'] ?? '이름없음',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
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
                  'ATK ${insect['attack']} / DEF ${insect['defense']} / SPD ${insect['speed']}',
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