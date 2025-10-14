import 'dart:io';
import 'package:flutter/material.dart';
import 'gallery_page.dart';
import 'insect_page.dart';

class CollectionPage extends StatelessWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const CollectionPage({
    super.key,
    required this.themeColor,
    required this.images,
    required this.previewColumns,
    required this.onPreviewSetting,
    required this.onImageDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            // 상단 탭바: 다크일 때만 기존 보라색 유지, 그 외에는 테마의 AppBar 색을 따름
            isDark
                ? Container(
              color: themeColor, // 기존 유지
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: '곤충', icon: Icon(Icons.bug_report)),
                  Tab(text: '갤러리', icon: Icon(Icons.photo_library)),
                ],
              ),
            )
                : Material(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: const TabBar(
                // (원하면 여기 색 지정 생략하고 app_theme.dart의 tabBarTheme를 써도 됨)
                indicatorColor: Colors.black87,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                tabs: [
                  Tab(text: '곤충', icon: Icon(Icons.bug_report)),
                  Tab(text: '갤러리', icon: Icon(Icons.photo_library)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  InsectPage(themeColor: themeColor),
                  GalleryPage(
                    themeColor: themeColor,
                    images: images,
                    previewColumns: previewColumns,
                    onPreviewSetting: onPreviewSetting,
                    onImageDeleted: onImageDeleted,
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