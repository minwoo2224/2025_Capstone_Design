import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  Color _themeColor = Colors.deepPurple;
  List<File> _images = [];
  int _previewColumns = 2;

  @override
  void initState() {
    super.initState();
    _loadImages();
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
        onThemeChanged: (color) {
          setState(() {
            _themeColor = color;
          });
        },
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

class _CameraPageState extends State<CameraPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _borderScaleAnimation; // 깜빡이는 직사각형 크기 애니메이션
  File? _lastImage; // 마지막으로 찍은 사진을 저장
  double? _imageAspectRatio; // 사진의 가로세로 비율

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
    // 애니메이션 컨트롤러 설정 (테두리 크기 깜빡임 효과)
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _borderScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(_controller); // 크기 깜빡임

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
        final imageFile = files.first;
        // 이미지의 가로세로 비율 계산
        final image = await decodeImageFromList(imageFile.readAsBytesSync());
        setState(() {
          _lastImage = imageFile;
          _imageAspectRatio = image.width / image.height;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
      final fileName = 'insect_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newFile = await File(pickedFile.path).copy('${photoDir.path}/$fileName');
      // 새로 찍은 사진의 가로세로 비율 계산
      final image = await decodeImageFromList(newFile.readAsBytesSync());
      setState(() {
        _lastImage = newFile; // 새로 찍은 사진을 바로 표시
        _imageAspectRatio = image.width / image.height;
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
          // 사진이 없을 경우 메시지와 깜빡이는 직사각형 표시
          if (_lastImage == null)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 깜빡이는 직사각형
                  ScaleTransition(
                    scale: _borderScaleAnimation, // 크기 애니메이션 적용
                    child: Container(
                      width: 180, // 텍스트 크기에 맞춘 기본 크기
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // 텍스트 (사진 글씨는 크게, 굵게, 흰색, 배경은 테마 색상)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                ],
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
              top: kBottomNavigationBarHeight + 20, // 상단바 아래부터 시작
              left: 20,
              right: 20,
              bottom: 120, // 촬영 버튼 위까지 (버튼 높이 + 여백 고려)
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
                  child: _imageAspectRatio != null
                      ? AspectRatio(
                    aspectRatio: _imageAspectRatio!,
                    child: Image.file(
                      _lastImage!,
                      fit: BoxFit.contain, // 비율 유지
                    ),
                  )
                      : Image.file(
                    _lastImage!,
                    fit: BoxFit.contain, // 비율 유지
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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














class CollectionPage extends StatelessWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const CollectionPage({super.key, required this.themeColor, required this.images, required this.previewColumns, required this.onPreviewSetting, required this.onImageDeleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: themeColor),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DictionaryPage()),
                    ),
                    child: Container(
                      color: Colors.deepPurple.shade200, // Light purple for Dictionary
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: const Text("도감", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GalleryPage(
                        themeColor: themeColor,
                        images: images,
                        previewColumns: previewColumns,
                        onPreviewSetting: onPreviewSetting,
                        onImageDeleted: onImageDeleted,
                      )),
                    ),
                    child: Container(
                      color: Colors.deepPurple.shade100, // Even lighter purple for Gallery
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: const Text("갤러리", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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

class SearchPage extends StatelessWidget {
  final Color themeColor;

  const SearchPage({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("검색")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: themeColor),
          const Expanded(
            child: Center(
              child: Text(
                "검색 기능은 추후 업데이트 예정입니다.",
                style: TextStyle(fontSize: 18),
              ),
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
  Map<String, List<File>> _imagesByDate = {}; // 날짜별로 사진 그룹화
  List<String> _dates = []; // 날짜 태그 리스트

  @override
  void initState() {
    super.initState();
    _columns = widget.previewColumns;
    _images = widget.images;
    _groupImagesByDate();
  }

  void _groupImagesByDate() {
    _imagesByDate.clear();
    _dates.clear();

    // 사진을 날짜별로 그룹화
    for (var image in _images) {
      // 파일명에서 타임스탬프 추출 (insect_타임스탬프.jpg 형식)
      final fileName = path.basename(image.path); // 파일명 추출
      final timestampStr = fileName.replaceAll('insect_', '').replaceAll('.jpg', '');
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) continue;

      // 타임스탬프를 날짜로 변환 (yyyy-MM-dd 형식)
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // 날짜별로 사진 추가
      if (_imagesByDate.containsKey(dateKey)) {
        _imagesByDate[dateKey]!.add(image);
      } else {
        _imagesByDate[dateKey] = [image];
        _dates.add(dateKey);
      }
    }

    // 날짜 정렬 (최신순)
    _dates.sort((a, b) => b.compareTo(a));
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
                _groupImagesByDate(); // 사진 삭제 후 날짜별 그룹 업데이트
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
            child: _dates.isEmpty
                ? const Center(child: Text("사진이 없습니다.", style: TextStyle(fontSize: 18)))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                final dateImages = _imagesByDate[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              color: widget.themeColor,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 해당 날짜의 사진들
                    GridView.builder(
                      shrinkWrap: true, // ListView 안에서 GridView가 크기를 조정하도록
                      physics: const NeverScrollableScrollPhysics(), // GridView의 스크롤 비활성화
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: dateImages.length,
                      itemBuilder: (context, index) {
                        final image = dateImages[index];
                        return GestureDetector(
                          onTap: () => _showImageDialog(image),
                          onLongPress: () => _deleteImage(image),
                          child: Image.file(image, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ],
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
