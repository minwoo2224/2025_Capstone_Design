import 'package:flutter/material.dart';

class DictionaryPage extends StatelessWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("도감")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: Theme.of(context).colorScheme.primary),
          const Expanded(
            child: Center(
              child: Text("추후 업데이트", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}