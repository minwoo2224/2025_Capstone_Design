import 'package:flutter/material.dart';
import '../models/insect_card.dart';
import '../socket/socket_service.dart';
import 'camera_page.dart';

class CardSelectionPage extends StatefulWidget {
  final Color themeColor;
  final VoidCallback onPhotoTaken;

  const CardSelectionPage({
    super.key,
    required this.themeColor,
    required this.onPhotoTaken,
  });

  @override
  State<CardSelectionPage> createState() => _CardSelectionPageState();
}

class _CardSelectionPageState extends State<CardSelectionPage> {
  List<InsectCard> _cards = [];
  InsectCard? _selected;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final loaded = await loadInsectCards();
    setState(() {
      _cards = loaded;
    });
  }

  void _selectCard(InsectCard card) {
    setState(() {
      _selected = card;
    });
  }

  void _navigateToCameraPage() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => CameraPage(
          themeColor: widget.themeColor,
          onPhotoTaken: widget.onPhotoTaken,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _submitSelection() {
    if (_selected != null) {
      SocketService.socket.emit("joinQueue", _selected!.toServerJson());
      print("🛰 선택된 카드 1장 서버에 전송됨");
      _navigateToCameraPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("카드를 1장 선택해주세요")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("카드 선택"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToCameraPage,
        ),
      ),
      body: _cards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 2,
              children: _cards.map((card) {
                final isSelected = _selected == card;
                return GestureDetector(
                  onTap: () => _selectCard(card),
                  child: Card(
                    color: isSelected
                        ? Colors.amber[100]
                        : Colors.deepPurple.shade900.withAlpha((0.9 * 255).round()),
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isSelected ? Colors.amber : Colors.white24,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    elevation: isSelected ? 10 : 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(card.image, width: 60, height: 60),
                          const SizedBox(height: 6),
                          Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("타입: ${card.type}, 목: ${card.order}", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          Text("공: ${card.attack}, 방: ${card.defense}", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          Text("체: ${card.health}, 속: ${card.speed}", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitSelection,
        label: const Text("선택 완료"),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
    );
  }
}
