import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final Color themeColor;
  final ValueChanged<Color> onThemeChanged;

  const SettingsPage({super.key, required this.themeColor, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> colors = [
      {'color': Colors.deepPurple, 'name': 'Deep Purple'},
      {'color': Colors.red, 'name': 'Red'},
      {'color': Colors.green, 'name': 'Green'},
      {'color': Colors.blue, 'name': 'Blue'},
      {'color': Colors.orange, 'name': 'Orange'},
      {'color': Colors.pink, 'name': 'Pink'},
      {'color': Colors.brown, 'name': 'Brown'},
      {'color': Colors.teal, 'name': 'Teal'},
      {'color': Colors.indigo, 'name': 'Indigo'},
      {'color': Colors.amber, 'name': 'Amber'},
      {'color': Colors.cyan, 'name': 'Cyan'},
      {'color': Colors.grey, 'name': 'Grey'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: themeColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: colors.map((entry) {
                  return ElevatedButton(
                    onPressed: () => onThemeChanged(entry['color']),
                    style: ElevatedButton.styleFrom(backgroundColor: entry['color']),
                    child: Text(
                      entry['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}