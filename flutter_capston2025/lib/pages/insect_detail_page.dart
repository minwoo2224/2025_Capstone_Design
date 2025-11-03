import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
//251103 수정
import 'package:share_plus/share_plus.dart';

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

  //251103 수정---------------------------------------------------
  Future<void> _shareImageOnly() async {
    final imgPath = widget.insect['image']?.toString();

    if (imgPath == null || imgPath.isEmpty || !File(imgPath).existsSync()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 이미지 파일을 찾을 수 없어요.')),
      );
      return;
    }

    // 이미지 단독 공유 → 시스템 공유 시트에서 X/페북/인스타 선택 시
    // 해당 앱의 새 글쓰기 화면으로 이동
    await Share.shareXFiles([XFile(imgPath)]);
  }
  //------------------------------------------------------------

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

          // 공유 버튼 251103------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ShareMiniButton(
                label: '공유',
                icon: Icons.share, // 원하면 Icons.ios_share 등으로 교체 가능
                //251103 수정
                onTap: _shareImageOnly,
                // 테마 색을 쓰고 싶으면 아래 줄로 교체:
                // bg: Theme.of(context).colorScheme.primary,
                bg: const Color(0xFF6750A4), // 예: 보라톤 고정
                fg: Colors.white,
              ),
            ),
          )
          //------------------------------------------------------
        ],
      ),
    );
  }
}

// 251103 수정-----------------------------------------------
class _ShareMiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;

  const _ShareMiniButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: fg),
          ),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
//-------------------------------------------------------------