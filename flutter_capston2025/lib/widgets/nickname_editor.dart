import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_capston2025/utils/nickname_utils.dart';
import 'package:flutter_capston2025/utils/nickname_words.dart';
import 'package:flutter_capston2025/services/user_service.dart';
import '../storage/login_storage.dart';

class NicknameEditor extends StatefulWidget {
  final bool isGuest;
  final String userUid;
  final String initialNickname;
  final VoidCallback? refreshUserData;

  const NicknameEditor({
    super.key,
    required this.isGuest,
    required this.userUid,
    required this.initialNickname,
    this.refreshUserData,
  });

  @override
  State<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<NicknameEditor> {
  final TextEditingController _controller = TextEditingController();
  String _status = '';
  bool _canEdit = true;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _checkEditAvailability();
  }

  void _loadNickname() async {
    final nickname = await readNicknameFromTxt(guest: widget.isGuest);
    setState(() {
      _controller.text = nickname.isNotEmpty ? nickname : widget.initialNickname;
    });
  }

  void _checkEditAvailability() async {
    _canEdit = await canEditNickname();
    setState(() {});
  }

  String _generateRandomNickname() {
    final adj = adjectives[_random.nextInt(adjectives.length)];
    final bug = insects[_random.nextInt(insects.length)];
    return '$adj$bug';
  }

  void _setRandomNickname() {
    final nickname = _generateRandomNickname();
    setState(() {
      _controller.text = nickname;
    });
  }

  void _updateNickname() async {
    final nickname = _controller.text.trim();

    if (widget.isGuest) {
      setState(() => _status = '비회원은 닉네임 변경이 불가능 합니다.');
      return;
    }
    if (nickname.isEmpty) {
      setState(() => _status = '닉네임을 입력해주세요.');
      return;
    }
    if (_countKoreanChars(nickname) > 8) {
      setState(() => _status = '닉네임은 한글 기준 8자 이하만 가능합니다.');
      return;
    }
    if (!_canEdit) {
      setState(() => _status = '닉네임은 하루에 한 번만 수정 가능합니다.');
      return;
    }

    try {
      await updateNickname(widget.userUid, nickname);
      await markNicknameEditedToday();
      await saveNicknameToTxt(nickname, guest: widget.isGuest); // 🔥 변경 즉시 txt 저장

      setState(() {
        _controller.text = nickname;
        _status = '닉네임이 성공적으로 변경되었습니다.';
        _canEdit = false;
      });

      widget.refreshUserData?.call();
    } catch (e) {
      setState(() => _status = '닉네임 변경 실패: $e');
    }
  }

  int _countKoreanChars(String text) {
    return text.runes.where((r) => r >= 0xAC00 && r <= 0xD7A3).length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("닉네임 (최대 8자)", style: TextStyle(color: Colors.amber, fontSize: 17)),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: widget.isGuest ? null : _setRandomNickname,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text("🎲", style: TextStyle(fontSize: 28)),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  readOnly: widget.isGuest || !_canEdit,
                  maxLength: 8,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: (!_canEdit || widget.isGuest) ? () {
                  setState(() {
                    _status = widget.isGuest
                        ? '비회원은 닉네임 변경이 불가능 합니다.'
                        : '닉네임은 하루에 한 번만 수정 가능합니다.';
                  });
                } : _updateNickname,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('변경'),
              ),
            ],
          ),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('성공') ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
