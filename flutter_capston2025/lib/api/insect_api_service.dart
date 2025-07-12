import 'dart:convert';
import 'package:flutter/services.dart'; // 👈 assets 파일을 읽기 위해 추가
import 'package:http/http.dart' as http;
import '../api/insect_info.dart';

class InsectApiService {
  static const String _iNaturalistBaseUrl = "https://api.inaturalist.org/v1";
  Map<String, String> _translationMap = {}; // 👈 번역 지도를 담을 변수

  // 서비스가 처음 생성될 때 번역 지도 파일을 불러옵니다.
  InsectApiService() {
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/translation_map.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _translationMap = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print("번역 파일 로딩 실패: $e");
    }
  }

  // 🦋 곤충 목록 검색 (번역 지도 사용 방식으로 수정)
  Future<List<InsectInfo>> searchInsects(String query) async {
    if (query.isEmpty) return [];

    // Step 1: 내장된 번역 지도에서 영어 이름 찾기
    // toLowerCase()로 대소문자 구분 없이 비교
    String englishQuery = _translationMap[query.toLowerCase()] ?? query;

    // Step 2: 찾은 영어 이름으로 iNaturalist API 검색
    final url = Uri.parse('$_iNaturalistBaseUrl/taxa?q=$englishQuery&is_active=true&rank=species');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'];
        return results.map((json) => InsectInfo.fromJson(json)).toList();
      } else {
        throw Exception('iNaturalist API 서버 응답 오류');
      }
    } catch (e) {
      throw Exception('데이터를 불러오는 데 실패했습니다.');
    }
  }

  // 🦋 곤충 상세 정보 가져오기 (번역 기능 제거, 영어 원문 표시)
  Future<String> getInsectDetails(int taxonId) async {
    final url = Uri.parse('$_iNaturalistBaseUrl/taxa/$taxonId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['results'] != null && data['results'].isNotEmpty) {
          final taxonData = data['results'][0];
          final summary = taxonData['wikipedia_summary'];
          return summary ?? '등록된 상세 정보가 없습니다.';
        }
        return '상세 정보가 없습니다.';
      } else {
        throw Exception('상세 정보 API 서버 응답 오류');
      }
    } catch (e) {
      throw Exception('상세 정보를 불러오는 데 실패했습니다.');
    }
  }
}