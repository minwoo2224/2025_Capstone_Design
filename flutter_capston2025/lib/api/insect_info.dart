// lib/api/insect_info.dart
import 'package:flutter/foundation.dart';

@immutable
class InsectInfo {
  final int id;             // 👈 곤충의 고유 ID (상세 정보 요청 시 사용)
  final String commonName;    // 대표 이름 (주로 한국어 이름)
  final String sciName;       // 학명
  final String imageUrl;      // 이미지 URL
  final String? description; // 👈 상세 설명을 담을 필드 (나중에 채워짐)

  const InsectInfo({
    required this.id,
    required this.commonName,
    required this.sciName,
    this.imageUrl = '',
    this.description,
  });

  // API 검색 결과(JSON)로부터 InsectInfo 객체를 만드는 부분
  factory InsectInfo.fromJson(Map<String, dynamic> json) {
    final photo = json['default_photo'];
    final imageUrl = photo != null ? photo['medium_url'] : '';

    return InsectInfo(
      id: json['id'] ?? 0, // 👈 ID 추출
      commonName: json['preferred_common_name'] ?? json['name'] ?? '이름 없음',
      sciName: json['name'] ?? '학명 없음',
      imageUrl: imageUrl,
    );
  }
}