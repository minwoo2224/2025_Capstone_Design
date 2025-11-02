import 'dart:math';

class InsectLabels {
  static const Map<int, String> labels = {
    0: "개미",
    1: "장수말벌",
    2: "벌",
    3: "다듬이벌레",
    4: "나비",
    5: "메뚜기",
    6: "매미",
    7: "바퀴벌레",
    8: "잠자리",
    9: "집게벌레",
    10: "반딧불이",
    11: "파리",
    12: "그리마",
    13: "무당벌레",
    14: "꽃매미",
    15: "하늘소",
    16: "사마귀",
    17: "하루살이",
    18: "모기",
    19: "나방",
    20: "반날개",
    21: "사슴벌레",
    22: "대벌레",
    23: "노린재",
    24: "장수풍뎅이",
    25: "소금쟁이",
    26: "귀뚜라미",
    27: "물장군",
    28: "쇠똥구리",
  };

  /// 🧬 곤충별 종족값 (Base Stats)
  static const Map<String, Map<String, int>> baseStats = {
    "개미": {"hp": 90, "attack": 85, "defense": 95, "speed": 130},
    "장수말벌": {"hp": 90, "attack": 125, "defense": 80, "speed": 105},
    "벌": {"hp": 80, "attack": 115, "defense": 70, "speed": 135},
    "다듬이벌레": {"hp": 85, "attack": 70, "defense": 100, "speed": 95},
    "나비": {"hp": 85, "attack": 75, "defense": 80, "speed": 160},
    "메뚜기": {"hp": 100, "attack": 90, "defense": 85, "speed": 125},
    "매미": {"hp": 110, "attack": 95, "defense": 100, "speed": 95},
    "바퀴벌레": {"hp": 130, "attack": 80, "defense": 110, "speed": 80},
    "잠자리": {"hp": 90, "attack": 90, "defense": 80, "speed": 140},
    "집게벌레": {"hp": 95, "attack": 100, "defense": 105, "speed": 100},
    "반딧불이": {"hp": 80, "attack": 75, "defense": 80, "speed": 165},
    "파리": {"hp": 70, "attack": 85, "defense": 65, "speed": 180},
    "그리마": {"hp": 115, "attack": 85, "defense": 110, "speed": 90},
    "무당벌레": {"hp": 100, "attack": 90, "defense": 100, "speed": 110},
    "꽃매미": {"hp": 90, "attack": 100, "defense": 85, "speed": 125},
    "하늘소": {"hp": 110, "attack": 110, "defense": 120, "speed": 60},
    "사마귀": {"hp": 85, "attack": 135, "defense": 75, "speed": 105},
    "하루살이": {"hp": 60, "attack": 70, "defense": 50, "speed": 190},
    "모기": {"hp": 70, "attack": 90, "defense": 55, "speed": 185},
    "나방": {"hp": 90, "attack": 80, "defense": 85, "speed": 145},
    "반날개": {"hp": 120, "attack": 75, "defense": 125, "speed": 80},
    "사슴벌레": {"hp": 115, "attack": 120, "defense": 110, "speed": 55},
    "대벌레": {"hp": 125, "attack": 65, "defense": 110, "speed": 60},
    "노린재": {"hp": 95, "attack": 85, "defense": 95, "speed": 125},
    "장수풍뎅이": {"hp": 125, "attack": 130, "defense": 115, "speed": 40},
    "소금쟁이": {"hp": 85, "attack": 80, "defense": 75, "speed": 160},
    "귀뚜라미": {"hp": 100, "attack": 95, "defense": 90, "speed": 115},
    "물장군": {"hp": 110, "attack": 120, "defense": 100, "speed": 70},
    "쇠똥구리": {"hp": 130, "attack": 85, "defense": 120, "speed": 65},
  };

  /// 🧩 인덱스로 이름 가져오기
  static String getName(int index) {
    return labels[index] ?? "Unknown";
  }

  /// ⚙️ 능력치 계산기 (개체값 포함)
  static Map<String, int> calculateStats(String name) {
    final rand = Random();
    final base = baseStats[name] ?? {"hp": 80, "attack": 80, "defense": 80, "speed": 80};

    // 개체값(IV): 0~31
    final iv = {
      "hp": rand.nextInt(32),
      "attack": rand.nextInt(32),
      "defense": rand.nextInt(32),
      "speed": rand.nextInt(32),
    };

    // 최종 능력치 계산식
    return {
      "hp": base["hp"]! * 2 + iv["hp"]!,
      "attack": (base["attack"]! * 1.5 + iv["attack"]!).toInt(),
      "defense": (base["defense"]! * 1.5 + iv["defense"]!).toInt(),
      "speed": (base["speed"]! * 1.5 + iv["speed"]!).toInt(),
    };
  }
}
