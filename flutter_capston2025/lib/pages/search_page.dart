
import 'package:flutter/material.dart';
import 'family_detail_page.dart';

class SearchPage extends StatefulWidget {
  final Color themeColor;

  const SearchPage({super.key, required this.themeColor});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final Map<String, List<String>> _insectOrders = {
    "딱정벌레": ["사슴벌레과", "풍뎅이과"],
    "벌": ["꿀벌과", "말벌과"],
    "나비": ["흰나비과", "호랑나비과"],
  };

  final Map<String, Map<String, String>> familyData = {
    "사슴벌레과": {
      "description": "암수 모두 진한 갈색 또는 약한 갈색을 띠며, 수컷의 머리의 투구모양의 돌기가 큰 특징이다. 암컷은 다른 사슴벌레보다 머리 부분이 앞으로 길게 돌출한것이 특징이며, 다리부분의 노란 털과 수컷의 경우 온몸에 황금색의 털이 많이 분포하고 있다.",
      "image": "assets/images/family_detail_page/딱정벌레/사슴벌레과/사슴벌레1.jpg"
    },
    "풍뎅이과": {
      "description": "우리나라에서 가장 큰 풍뎅이류로 수컷과 암컷은 수컷에 잘 발달되어 있는 큰 뿔로서 쉽게 구별이 가능하며, 수컷은 암컷보다 광택이 강하고 암컷은 수컷보다 털이 많이 분포되어 있다",
      "image": "assets/images/family_detail_page/딱정벌레/풍뎅이과/풍뎅이1.jpg"
    },
    "꿀벌과": {
      "description": "몸길이는 12 mm 내외이다. 날개는 투명하고 황색이며, 맥은 흑갈색이고, 발목마디는 황갈색이다.",
      "image": "assets/images/family_detail_page/벌/꿀벌과/꿀벌1.jpg"
    },
    "말벌과": {
      "description": "말벌속의 일반특징에 추가하여 다음과 같은 특징을 가지고 있다. 두순은 서로 접하고 있는 큰 점각을 가지고 있다. 두순 정단 함입은 얕으며, 치상돌기의 끝은 반원형을 이룬다. 견판전용골선은 완전하다. 전흉배판 측면 하방에는 주름이 나 있다. 제1복절 후연의 노란 줄무늬가 매우 가는 특징에 의하여 다른 종들과 용이하게 구분된다.",
      "image": "assets/images/family_detail_page/벌/말벌과/말벌1.jpg"
    },
    "흰나비과": {
      "description": "종 대부분의 날개가 흰색이나 노란색 계통이며 배추흰나비, 큰줄흰나비는 검정 무늬가 있다.",
      "image": "assets/images/family_detail_page/나비/흰나비과/흰나비1.jpg"
    },
    "호랑나비과": {
      "description": "몸빛은 검거나 어두운 갈색이고 누런색, 붉은색, 남색 따위의 아름다운 얼룩무늬가 있다. ",
      "image": "assets/images/family_detail_page/나비/호랑나비과/호랑나비1.jpg"
    }
  };

  List<String> _orderResults = [];
  List<Map<String, String>> _familyResults = [];
  String? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _orderResults = _insectOrders.keys.toList();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _selectedOrder = null;
      if (query.isEmpty) {
        _orderResults = _insectOrders.keys.toList();
        _familyResults.clear();
      } else {
        _orderResults = _insectOrders.keys
            .where((order) => order.toLowerCase().contains(query))
            .toList();
        _familyResults = [];
        _insectOrders.forEach((order, families) {
          for (final family in families) {
            if (family.toLowerCase().contains(query)) {
              _familyResults.add({"order": order, "family": family});
            }
          }
        });
      }
    });
  }

  void _onOrderTap(String order) {
    setState(() {
      _selectedOrder = order;
    });
  }

  void _onFamilyTap(String family) {
    final data = familyData[family];
    if (data != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FamilyDetailPage(
            familyName: family,
            description: data["description"]!,
            imagePath: data["image"]!,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final families = _selectedOrder != null ? _insectOrders[_selectedOrder!]! : [];

    return Scaffold(
      appBar: AppBar(title: const Text("곤충 백과사전")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "곤충 목 또는 분류를 검색하세요",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          if (_selectedOrder != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedOrder = null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("돌아가기"),
                  ),
                  Text(
                    "${_selectedOrder!} → 분류",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedOrder != null
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: families.length,
                    itemBuilder: (context, index) {
                      final family = families[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(family, style: const TextStyle(fontSize: 17)),
                          onTap: () => _onFamilyTap(family),
                        ),
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (_orderResults.isNotEmpty)
                        ..._orderResults.map((order) => Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(order, style: const TextStyle(fontSize: 18)),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _onOrderTap(order),
                              ),
                            )),
                      if (_familyResults.isNotEmpty)
                        ..._familyResults.map((entry) => Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(entry["family"]!, style: const TextStyle(fontSize: 17)),
                                subtitle: Text("(${entry["order"]})"),
                                onTap: () => _onFamilyTap(entry["family"]!),
                              ),
                            )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
