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
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: themeColor,
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
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