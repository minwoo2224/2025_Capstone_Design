import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const GuideDialog({super.key, required this.onComplete});

  @override
  State<GuideDialog> createState() => _GuideDialogState();
}

class _GuideDialogState extends State<GuideDialog> {
  int _currentIndex = 0;
  bool _dontShowAgain = false;

  final List<String> _imagePaths = [
    'assets/images/guides/guide1.png',
    'assets/images/guides/guide2.png',
  ];

  final List<String> _descriptions = [
    '곤충을 최대한 가까이서 찍어주세요',
    '위험한 곤충은 조심해서 촬영해 주세요',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: PageView.builder(
                itemCount: _imagePaths.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (_, index) => Image.asset(_imagePaths[index]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_imagePaths.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index ? Colors.purple : Colors.grey,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _descriptions[_currentIndex],
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    unselectedWidgetColor: Colors.black,
                  ),
                  child: Checkbox(
                    checkColor: Colors.black,
                    fillColor: MaterialStateProperty.all(Colors.white),
                    side: const BorderSide(color: Colors.black),
                    value: _dontShowAgain,
                    onChanged: (value) {
                      setState(() => _dontShowAgain = value ?? false);
                    },
                  ),
                ),
                const Text(
                  '다시 보지 않겠습니다',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (_dontShowAgain) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('skipGuide', true);
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('예', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('아니오', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}