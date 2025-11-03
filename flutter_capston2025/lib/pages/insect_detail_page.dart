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
    // 이름 변경 기능이 삭제되었으므로, _insectName 변수는 초기 로드 후 변경되지 않습니다.
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
        content: const Text('저장된 곤충 카드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () async {
              // 1. 다이얼로그 닫기
              Navigator.of(context).pop();
              // 2. 상세 페이지 닫기
              Navigator.of(context).pop();

              final imageFile = File(widget.insect['image']);
              // .jpg 파일을 .json 파일 경로로 대체하여 JSON 파일 경로를 계산
              final jsonFilePath = imageFile.path.replaceAll('.jpg', '.json');
              final jsonFile = File(jsonFilePath);

              // 3. 파일 삭제
              if (await jsonFile.exists()) {
                await jsonFile.delete();
              }
              if (await imageFile.exists()) {
                await imageFile.delete();
              }

              // 4. 콜백 호출
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

  // NOTE: _editName(BuildContext context) 메서드는 요청에 따라 삭제됨

  @override
  Widget build(BuildContext context) {
    final iconPath = _getIconPath(widget.insect['type']);
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
              // ⭐️ 이름 변경 기능 삭제 및 텍스트 스타일 수정 ⭐️
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _insectName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // 색상 수정
                      // decoration: TextDecoration.underline; // 밑줄 제거
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ⭐️ order 표시 삭제됨 ⭐️
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
          // ⭐️ 닫기 버튼 (왼쪽 아래) ⭐️
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 32),
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
          // ⭐️ 삭제 버튼 (오른쪽 아래) ⭐️
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