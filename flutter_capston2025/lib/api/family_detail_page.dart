// lib/pages/family_detail_page.dart
import 'package:flutter/material.dart';
import '../api/insect_models.dart';

class FamilyDetailPage extends StatelessWidget {
  final InsectFamily family;

  const FamilyDetailPage({super.key, required this.family});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(family.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: family.imageUrl, // Hero 애니메이션을 위한 태그
              child: Image.asset(
                family.imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '분류: ${family.orderName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '특징',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    family.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}