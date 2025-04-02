import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '곤충 도감 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  Color _themeColor = Colors.deepPurple; // 기본 테마 색상
  List<File> _images = [];
  int _previewColumns = 2;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadThemeColor(); // 저장된 테마 색상 불러오기
  }

  // 저장된 테마 색상 불러오기
  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor');
    if (colorValue != null) {
      setState(() {
        _themeColor = Color(colorValue);
      });
    }
  }

  // 테마 색상 저장
  Future<void> _saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.value);
    setState(() {
      _themeColor = color;
    });
  }

  Future<void> _loadImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');
    if (await photoDir.exists()) {
      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).contains("insect_"))
          .toList();
      setState(() {
        _images = files;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showPreviewSettingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: List.generate(6, (index) => index + 1).map((num) {
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _previewColumns = num;
                });
                Navigator.pop(context);
              },
              child: Text('$num개 보기'),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: _loadImages),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: () => _showPreviewSettingSheet(context),
        onImageDeleted: _loadImages,
      ),
      SearchPage(themeColor: _themeColor),
      SettingsPage(
        themeColor: _themeColor,
        onThemeChanged: _saveThemeColor,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _themeColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '촬영'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '도감'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  final Color themeColor;
  final VoidCallback onPhotoTaken;
  const CameraPage({super.key, required this.themeColor, required this.onPhotoTaken});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _lastImage; // 마지막으로 찍은 사진을 저장

  // 테마 색상에서 연한 색상을 계산하는 함수
  Color _getLighterThemeColor(Color themeColor) {
    // Material Color인 경우 shade를 사용하여 연한 색상으로 변환
    if (themeColor is MaterialColor) {
      return themeColor.shade100; // 연한 색상 (예: deepPurple.shade100)
    }
    // Material Color이 아닌 경우, 투명도를 조정하여 연하게 만듦
    return themeColor.withOpacity(0.3);
  }

  @override
  void initState() {
    super.initState();
    // 이전에 찍은 사진 불러오기
    _loadLastImage();
  }

  Future<void> _loadLastImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');
    if (await photoDir.exists()) {
      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).contains("insect_"))
          .toList();
      if (files.isNotEmpty) {
        // 가장 최근 파일을 선택 (파일 이름에 타임스탬프가 있으므로 정렬 가능)
        files.sort((a, b) => b.path.compareTo(a.path));
        setState(() {
          _lastImage = files.first;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/insect_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }
      final fileName = 'insect_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg';
      final newFile = await File(pickedFile.path).copy(
          '${photoDir.path}/$fileName');
      setState(() {
        _lastImage = newFile; // 새로 찍은 사진을 바로 표시
      });
      widget.onPhotoTaken();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지 (이전에 찍은 사진으로 설정) + 흐림 효과
          Container(
            decoration: BoxDecoration(
              image: _lastImage != null
                  ? DecorationImage(
                image: FileImage(_lastImage!), // 이전에 찍은 사진을 배경으로 사용
                fit: BoxFit.cover,
              )
                  : null,
              color: _lastImage == null
                  ? _getLighterThemeColor(widget.themeColor) // 연한 테마 색상
                  : null,
            ),
            child: _lastImage != null
                ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.2), // 흐림 효과 위에 약간의 어두운 오버레이
              ),
            )
                : null,
          ),
          // 사진이 없을 경우 메시지 표시
          if (_lastImage == null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.themeColor, // 테마 색상으로 배경 설정
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "사진",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30, // "사진" 글씨 크게
                          fontWeight: FontWeight.bold, // 굵게
                        ),
                      ),
                      TextSpan(
                        text: "이 없습니다!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20, // 나머지 글씨는 기존 크기
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 상단 테마 색상 바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kBottomNavigationBarHeight,
              color: widget.themeColor,
            ),
          ),
          // 이전에 찍은 사진을 상단바 아래부터 촬영 버튼 위까지 표시
          if (_lastImage != null)
            Positioned(
              top: kBottomNavigationBarHeight + 20,
              // 상단바 아래부터 시작
              left: 20,
              right: 20,
              bottom: 120,
              // 촬영 버튼 위까지 (버튼 높이 + 여백 고려)
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: widget.themeColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 3 / 2, // 일반적인 사진 비율 (가로:세로 = 3:2)
                    child: Image.file(
                      _lastImage!,
                      fit: BoxFit.contain, // 비율 유지, 잘리지 않음
                    ),
                  ),
                ),
              ),
            ),
          // 하단 촬영 버튼
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: Colors.white,
                ),
                label: const Text(
                  '촬영',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CollectionPage extends StatefulWidget {
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
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  // 보색 계산 함수
  Color _getComplementaryColor(Color color) {
    return Color.fromRGBO(
      255 - color.red,
      255 - color.green,
      255 - color.blue,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final complementaryColor = _getComplementaryColor(widget.themeColor);

    return Scaffold(
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Expanded(
            child: Column(
              children: [
                // 도감 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DictionaryPage()),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            complementaryColor,
                            complementaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: complementaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "도감",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 갤러리 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GalleryPage(
                          themeColor: widget.themeColor,
                          images: widget.images,
                          previewColumns: widget.previewColumns,
                          onPreviewSetting: widget.onPreviewSetting,
                          onImageDeleted: widget.onImageDeleted,
                        ),
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            complementaryColor.withOpacity(0.7),
                            complementaryColor.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: complementaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "갤러리",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class SearchPage extends StatefulWidget {
  final Color themeColor;

  const SearchPage({super.key, required this.themeColor});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _insects = [
    "사슴벌레",
    "장수풍뎅이",
    "나비",
    "잠자리",
    "메뚜기",
    "개미",
    "벌",
    "매미",
    "딱정벌레",
    "방아깃과",
  ];
  List<String> _filteredInsects = [];

  @override
  void initState() {
    super.initState();
    _filteredInsects = _insects; // 초기에는 모든 곤충 표시
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredInsects = _insects
          .where((insect) => insect.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("검색")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "곤충 이름을 검색하세요",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
          ),
          Expanded(
            child: _filteredInsects.isEmpty
                ? const Center(
              child: Text(
                "검색 결과가 없습니다.",
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredInsects.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      _filteredInsects[index],
                      style: const TextStyle(fontSize: 18),
                    ),
                    onTap: () {
                      // 추후 상세 페이지로 이동 가능
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${_filteredInsects[index]} 선택됨"),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const GalleryPage({
    super.key,
    required this.themeColor,
    required this.images,
    required this.previewColumns,
    required this.onPreviewSetting,
    required this.onImageDeleted,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late int _columns;
  late List<File> _images;
  Map<String, List<File>> _groupedImages = {}; // 날짜별로 그룹화된 이미지

  @override
  void initState() {
    super.initState();
    _columns = widget.previewColumns;
    _images = widget.images;
    _groupImagesByDate(); // 날짜별로 그룹화
  }

  // 날짜별로 이미지 그룹화
  void _groupImagesByDate() {
    _groupedImages.clear();
    for (var image in _images) {
      // 파일 이름에서 타임스탬프 추출 (insect_타임스탬프.jpg 형식)
      final fileName = path.basename(image.path);
      final timestampStr = fileName.replaceAll('insect_', '').replaceAll('.jpg', '');
      try {
        final timestamp = int.parse(timestampStr);
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        if (_groupedImages[dateKey] == null) {
          _groupedImages[dateKey] = [];
        }
        _groupedImages[dateKey]!.add(image);
      } catch (e) {
        // 타임스탬프 파싱 실패 시 기본 날짜로 처리
        const defaultDate = "Unknown Date";
        if (_groupedImages[defaultDate] == null) {
          _groupedImages[defaultDate] = [];
        }
        _groupedImages[defaultDate]!.add(image);
      }
    }
    // 날짜별로 정렬 (최신 날짜가 위로 오도록)
    _groupedImages = Map.fromEntries(
      _groupedImages.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  // 날짜를 사용자 친화적인 형식으로 포맷팅
  String _formatDate(String dateKey) {
    if (dateKey == "Unknown Date") {
      return "알 수 없는 날짜";
    }
    try {
      final parsedDate = DateTime.parse(dateKey); // dateKey를 파싱
      final formatter = DateFormat('yyyy년 M월 d일', 'ko');
      return formatter.format(parsedDate); // 파싱된 날짜를 포맷팅
    } catch (e) {
      return dateKey;
    }
  }

  void _changePreviewColumns(int columns) {
    setState(() {
      _columns = columns;
    });
    Navigator.pop(context);
  }

  void _showPreviewSettingSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: List.generate(6, (index) => index + 1).map((num) {
            return ElevatedButton(
              onPressed: () => _changePreviewColumns(num),
              child: Text('$num개 보기'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showImageDialog(File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.file(image, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _deleteImage(File image) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("정말로 이 이미지를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("아니요"),
          ),
          TextButton(
            onPressed: () async {
              await image.delete();
              widget.onImageDeleted();
              setState(() {
                _images.remove(image);
                _groupImagesByDate(); // 삭제 후 그룹화 업데이트
              });
              Navigator.pop(context);
            },
            child: const Text("예"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("갤러리")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Expanded(
            child: _groupedImages.isEmpty
                ? const Center(child: Text("사진이 없습니다.", style: TextStyle(fontSize: 18)))
                : ListView.builder(
              itemCount: _groupedImages.length,
              itemBuilder: (context, index) {
                final date = _groupedImages.keys.elementAt(index);
                final images = _groupedImages[date]!;
                return StickyHeader(
                  header: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.grey.shade200,
                    child: Text(
                      _formatDate(date), // 포맷팅된 날짜 표시
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  content: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, idx) {
                      final image = images[idx];
                      return GestureDetector(
                        onTap: () => _showImageDialog(image),
                        onLongPress: () => _deleteImage(image),
                        child: Image.file(image, fit: BoxFit.cover),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPreviewSettingSheet,
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.grid_view),
      ),
    );
  }
}