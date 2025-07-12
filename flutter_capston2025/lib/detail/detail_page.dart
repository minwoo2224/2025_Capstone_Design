import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../api/insect_info.dart';
import '../api/insect_api_service.dart';

class DetailPage extends StatefulWidget {
  final InsectInfo insect;

  const DetailPage({
    super.key,
    required this.insect,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final InsectApiService _apiService = InsectApiService();
  late Future<String> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _apiService.getInsectDetails(widget.insect.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.insect.commonName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.insect.imageUrl.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.insect.imageUrl,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.bug_report, size: 100, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(widget.insect.commonName, style: Theme.of(context).textTheme.headlineMedium),
            Text(widget.insect.sciName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
            const Divider(height: 30),

            FutureBuilder<String>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('정보를 불러올 수 없습니다: ${snapshot.error}'));
                }
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('상세 정보 (출처: Wikipedia)', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      // 👈 2. Text 위젯을 Html 위젯으로 교체합니다.
                      Html(
                        data: snapshot.data!,
                        style: {
                          // 👈 3. 전체 텍스트 스타일을 앱 테마에 맞게 설정합니다.
                          "body": Style(
                            fontSize: FontSize(16.0),
                            lineHeight: LineHeight.number(1.6),
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        },
                      ),
                    ],
                  );
                }
                return const Center(child: Text('표시할 정보가 없습니다.'));
              },
            ),
          ],
        ),
      ),
    );
  }
}