import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../models/clothing_item.dart';
import '../services/db_helper.dart';
import '../services/api_service.dart';

class FittingProvider extends ChangeNotifier {
  final DbHelper _dbHelper = DbHelper();
  final ApiService _apiService = ApiService();

  // 현재 활성화된 화면
  String _currentScreen = 'welcome';
  String get currentScreen => _currentScreen;

  // 현재 선택된 카테고리 탭
  String _selectedCategory = '전체';
  String get selectedCategory => _selectedCategory;

  // 로컬 옷장에 등록된 의류 목록
  List<ClothingItem> _clothes = [];
  List<ClothingItem> get clothes => _clothes;

  // 피팅룸에 추가된 의류 구성 (카테고리명 : 의류 객체)
  final Map<String, ClothingItem> _outfit = {};
  Map<String, ClothingItem> get outfit => _outfit;

  // 사용자의 본인 사진 로컬 파일 경로
  String? _userPhotoPath;
  String? get userPhotoPath => _userPhotoPath;

  // 인물 사진 등록 조정용 임시 경로
  String? _tempUserPhotoPath;
  String? get tempUserPhotoPath => _tempUserPhotoPath;

  void setTempUserPhoto(String? path) {
    _tempUserPhotoPath = path;
    notifyListeners();
  }

  // 가상 피팅 서버 합성 결과 이미지 (바이너리)
  Uint8List? _resultImageBytes;
  Uint8List? get resultImageBytes => _resultImageBytes;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // AI 피팅 진행률 (0.0 ~ 1.0)
  double _fittingProgress = 0.0;
  double get fittingProgress => _fittingProgress;

  // 피팅 내역 목록
  final List<Map<String, dynamic>> _fittingHistory = [];
  List<Map<String, dynamic>> get fittingHistory => List.unmodifiable(_fittingHistory);

  // 갤러리 바로 열기 플래그
  bool _shouldOpenGallery = false;
  bool _isCameraForUserPhoto = false;
  int? _selectedEventIndex;
  int? get selectedEventIndex => _selectedEventIndex;

  void setSelectedEventIndex(int? index) {
    _selectedEventIndex = index;
    notifyListeners();
  }
  bool get shouldOpenGallery => _shouldOpenGallery;
  bool get isCameraForUserPhoto => _isCameraForUserPhoto;

  void setShouldOpenGallery(bool value) {
    _shouldOpenGallery = value;
    notifyListeners();
  }

  void setIsCameraForUserPhoto(bool value) {
    _isCameraForUserPhoto = value;
    notifyListeners();
  }

  // 찜(관심) 목록
  final Set<String> _likedItems = {};
  Set<String> get likedItems => _likedItems;

  // 최근 촬영된 내역 (카메라 화면 미리보기용)
  final List<ClothingItem> _recentCaptures = [];
  List<ClothingItem> get recentCaptures => _recentCaptures;

  // 화면 전환 이력 스택
  final List<String> _screenHistory = ['qr'];
  List<String> get screenHistory => _screenHistory;

  // 카메라 권한 보안 동의 여부
  bool _cameraConsented = false;
  bool get cameraConsented => _cameraConsented;

  void setCameraConsented(bool consented) {
    _cameraConsented = consented;
    notifyListeners();
  }

  // 다중 AI 엔진 설정
  String _selectedEngine = 'vertex_vton';
  String get selectedEngine => _selectedEngine;

  void setSelectedEngine(String engine) {
    if (_selectedEngine == engine) return;
    _selectedEngine = engine;
    notifyListeners();
  }

  // 앱 알림 설정 상태 유지
  bool _masterNotice = true;
  bool _fittingNotice = true;
  bool _billingNotice = true;
  bool _marketingNotice = true;
  bool _nightNotice = true;

  bool get masterNotice => _masterNotice;
  bool get fittingNotice => _fittingNotice;
  bool get billingNotice => _billingNotice;
  bool get marketingNotice => _marketingNotice;
  bool get nightNotice => _nightNotice;

  void setNotices({
    bool? master,
    bool? fitting,
    bool? billing,
    bool? marketing,
    bool? night,
  }) {
    if (master != null) {
      _masterNotice = master;
      _fittingNotice = master;
      _billingNotice = master;
      _marketingNotice = master;
      _nightNotice = master;
    } else {
      if (fitting != null) _fittingNotice = fitting;
      if (billing != null) _billingNotice = billing;
      if (marketing != null) _marketingNotice = marketing;
      if (night != null) _nightNotice = night;

      // 하위 알림 중 하나라도 켜지면 마스터 알림도 켜짐
      if (_fittingNotice ||
          _billingNotice ||
          _marketingNotice ||
          _nightNotice) {
        _masterNotice = true;
      } else {
        _masterNotice = false; // 모든 하위 알림이 꺼지면 마스터도 꺼짐
      }
    }
    notifyListeners();
  }

  FittingProvider() {
    _initLoginState();
    loadClothes();
    loadServerUrl();
  }

  Future<void> _initLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      _currentScreen = 'fitting';
      _screenHistory.clear();
      _screenHistory.add('fitting');
      notifyListeners();
    }
  }

  // 로컬 파일에서 저장된 ngrok 서버 URL 로드
  Future<void> loadServerUrl() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/server_url.txt');
      if (await file.exists()) {
        final savedUrl = await file.readAsString();
        if (savedUrl.trim().isNotEmpty) {
          ApiService.baseUrl = savedUrl.trim();
        }
      }
    } catch (e) {
      debugPrint('서버 URL 로드 에러: $e');
    }
  }

  // ngrok 서버 URL 동적 변경 및 저장
  Future<void> updateServerUrl(String newUrl) async {
    try {
      final trimmedUrl = newUrl.trim();
      ApiService.baseUrl = trimmedUrl;
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/server_url.txt');
      await file.writeAsString(trimmedUrl);
      notifyListeners();
    } catch (e) {
      debugPrint('서버 URL 저장 에러: $e');
    }
  }

  // 화면 전환
  void setScreen(String screen) {
    if (screen != 'camera') {
      _isCameraForUserPhoto = false;
    }
    if (_currentScreen == screen) return;

    if (screen == 'qr') {
      _screenHistory.clear();
      _screenHistory.add('qr');
    } else {
      final List<String> shellScreens = [
        'home',
        'wardrobe',
        'fitting',
        'mypage',
        'history'
      ];
      if (shellScreens.contains(screen) &&
          _screenHistory.isNotEmpty &&
          shellScreens.contains(_screenHistory.last)) {
        _screenHistory.removeLast();
      }
      _screenHistory.add(screen);
    }

    _currentScreen = screen;
    notifyListeners();
  }

  // 뒤로가기 동작 (뒤로갈 화면이 존재하면 true, 없으면 false 반환)
  bool goBack() {
    _isCameraForUserPhoto = false;
    if (_screenHistory.length <= 1) {
      return false; // 앱 종료 필요
    }
    _screenHistory.removeLast(); // 현재 화면 제거
    _currentScreen = _screenHistory.last; // 이전 화면 활성화
    notifyListeners();
    return true;
  }

  // 카테고리 변경
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // 로컬 옷장 로드
  Future<void> loadClothes() async {
    final userClothes = await _dbHelper.getClothes();
    
    // 테스트용 데모 의류 3벌 정의
    final dummyItems = [
      ClothingItem(
        id: 'dummy_top_1',
        category: '상의',
        imageUrl: 'https://images.unsplash.com/photo-1578587018452-892bacefd3f2?w=500',
        name: '베이직 카키 셔츠',
        price: '35,000',
      ),
      ClothingItem(
        id: 'dummy_pants_1',
        category: '하의',
        imageUrl: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=500',
        name: '데님 와이드 팬츠',
        price: '48,000',
      ),
      ClothingItem(
        id: 'dummy_outer_1',
        category: '아우터',
        imageUrl: 'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3?w=500',
        name: '캐주얼 윈드브레이커',
        price: '89,000',
      ),
    ];

    // 기존 리스트에 데모 의류가 중복 추가되지 않도록 보장하면서 무조건 리스트에 주입합니다.
    _clothes = [...userClothes];
    for (var dummy in dummyItems) {
      if (!_clothes.any((c) => c.id == dummy.id)) {
        _clothes.add(dummy);
      }
    }
    
    notifyListeners();
  }

  // 피팅 아이템 선택/해제 토글
  void toggleOutfitItem(ClothingItem item) {
    if (_outfit.containsKey(item.category) &&
        _outfit[item.category]!.id == item.id) {
      _outfit.remove(item.category);
    } else {
      _outfit[item.category] = item;
    }
    notifyListeners();
  }

  // 피팅룸 비우기
  void clearOutfit() {
    _outfit.clear();
    notifyListeners();
  }

  // 사용자 본인 사진 지정
  void setUserPhoto(String? path) {
    _userPhotoPath = path;
    notifyListeners();
  }

  // 찜하기 기능 토글
  void toggleLikeItem(String id) {
    if (_likedItems.contains(id)) {
      _likedItems.remove(id);
    } else {
      _likedItems.add(id);
    }
    notifyListeners();
  }

  // 새 옷 로컬 저장소 및 SQLite 등록
  Future<void> captureNewClothing({
    required String imagePath,
    required String category,
    required String name,
    required String price,
  }) async {
    String finalImagePath = imagePath;
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'clothing_.jpg';
      final savedFile = await File(imagePath).copy(p.join(appDir.path, fileName));
      finalImagePath = savedFile.path;
    }

    // 2. DB 저장 객체
    final newItem = ClothingItem(
      id: 'custom_',
      category: category,
      imageUrl: finalImagePath,
      name: name,
      price: price,
    );

    // 3. SQLite 등록 및 상태 로드
    await _dbHelper.insertClothing(newItem);
    _recentCaptures.insert(0, newItem);
    if (_recentCaptures.length > 5) {
      _recentCaptures.removeLast();
    }
    await loadClothes();
  }

  // AI 가상 피팅 시작하기
  Future<void> startFitting() async {
    if (_userPhotoPath == null || _outfit.isEmpty) return;

    _isProcessing = true;
    _fittingProgress = 0.0;
    _currentScreen = 'result';
    notifyListeners();

    // 진행률 시뮬레이션 타이머 (실제 API 호출과 병행)
    const totalSeconds = 15; // 예상 소요 시간(초)
    final stopwatch = Stopwatch()..start();

    Future<void> progressLoop() async {
      while (_isProcessing && _fittingProgress < 0.95) {
        await Future.delayed(const Duration(milliseconds: 200));
        final elapsed = stopwatch.elapsed.inMilliseconds / 1000.0;
        // 로그 곡선으로 자연스러운 진행률
        final rawProgress = elapsed / totalSeconds;
        _fittingProgress = (1 - (1 / (1 + rawProgress * 4))).clamp(0.0, 0.95);
        notifyListeners();
      }
    }

    progressLoop(); // 백그라운드 진행률 루프 시작

    // 백엔드로 AI 가상 피팅 요청 전송
    final result = await _apiService.requestVirtualFitting(
      personImagePath: _userPhotoPath!,
      outfit: _outfit,
      engine: _selectedEngine,
    );

    stopwatch.stop();
    _fittingProgress = 1.0;
    _resultImageBytes = result;

    // 피팅 내역 저장
    _fittingHistory.insert(0, {
      'date': DateTime.now().toIso8601String(),
      'outfit': Map<String, dynamic>.fromEntries(
        _outfit.entries.map((e) => MapEntry(e.key, e.value.name)),
      ),
      'resultBytes': result,
    });

    _isProcessing = false;
    notifyListeners();
  }

  // 피팅 내역 개별 삭제
  void deleteFittingHistory(int index) {
    if (index >= 0 && index < _fittingHistory.length) {
      _fittingHistory.removeAt(index);
      notifyListeners();
    }
  }

  // 피팅 내역 전체 삭제
  void clearFittingHistory() {
    _fittingHistory.clear();
    notifyListeners();
  }

  // 가상 피팅 재설정
  void resetFitting() {
    _resultImageBytes = null;
    _isProcessing = false;
    _currentScreen = 'fitting';
    notifyListeners();
  }

  // 피팅 내역 복원 (결과 이미지 주입 및 결과 화면 이동)
  void restoreFittingResult(Uint8List bytes) {
    _resultImageBytes = bytes;
    _isProcessing = false;
    _currentScreen = 'result';
    notifyListeners();
  }

  // 의류 개별 삭제
  Future<void> deleteClothing(String id) async {
    await _dbHelper.deleteClothing(id);
    _likedItems.remove(id);
    _outfit.removeWhere((cat, item) => item.id == id);
    _recentCaptures.removeWhere((item) => item.id == id);
    await loadClothes();
  }

  // 의류 복수 삭제
  Future<void> deleteMultipleClothes(List<String> ids) async {
    for (var id in ids) {
      await _dbHelper.deleteClothing(id);
      _likedItems.remove(id);
      _outfit.removeWhere((cat, item) => item.id == id);
      _recentCaptures.removeWhere((item) => item.id == id);
    }
    await loadClothes();
  }

  // 의류 전체 삭제
  Future<void> deleteAllClothes() async {
    await _dbHelper.deleteAllClothes();
    _likedItems.clear();
    _outfit.clear();
    _recentCaptures.clear();
    await loadClothes();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _outfit.clear();
    _userPhotoPath = null;
    _resultImageBytes = null;
    setScreen('welcome');
    notifyListeners();
  }

  // --- 피팅 및 요금제 관리 변수 및 메서드 ---
  int _tokenCount = 0;
  int get tokenCount => _tokenCount;

  int _freeFittingCount = 3;
  int get freeFittingCount => _freeFittingCount;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  int _premiumFittingCount = 0;
  int get premiumFittingCount => _premiumFittingCount;

  void setPremium(bool value) {
    _isPremium = value;
    if (value) {
      _premiumFittingCount = 100;
    } else {
      _premiumFittingCount = 0;
    }
    notifyListeners();
  }

  void addTokens(int count) {
    _tokenCount += count;
    notifyListeners();
  }

  bool useFittingCount() {
    // 1. 프리미엄 유저인 경우 프리미엄 피팅 횟수 먼저 차감
    if (_isPremium && _premiumFittingCount > 0) {
      _premiumFittingCount--;
      notifyListeners();
      return true;
    }
    // 2. 보유 토큰 차감 (2번째 순위)
    if (_tokenCount > 0) {
      _tokenCount--;
      notifyListeners();
      return true;
    }
    // 3. 무료 피팅 차감 (3번째 순위)
    if (_freeFittingCount > 0) {
      _freeFittingCount--;
      notifyListeners();
      return true;
    }
    // 4. 모두 없으면 피팅 불가능
    return false;
  }

  // --- 1:1 문의 내역 리스트 ---
  final List<Map<String, dynamic>> _inquiries = [
    {
      'id': '1',
      'category': '결제/환불',
      'title': '정기구독 이중결제 오류 환불 요청',
      'content': '정기구독 결제 시 승인 문자가 두 번 발송되었습니다. 확인 후 한 건 취소해 주세요.',
      'date': '2026-07-09',
      'status': '답변 완료',
      'answer': '안녕하세요. 루미에르 고객센터입니다. 중복 승인된 결제 건은 즉시 카드 승인 취소 처리 완료되었습니다. 카드사에 따라 취소 반영까지 영업일 기준 3~5일이 소요될 수 있는 점 양해 부탁드립니다. 감사합니다.'
    },
    {
      'id': '2',
      'category': '피팅 오류',
      'title': '하의 피팅 시 합성 이미지 깨짐 오류',
      'content': '청바지 의류를 선택하고 AI 피팅을 진행하면 결과 화면에서 다리 부분이 찌그러져 나옵니다. 조치 방법이 있나요?',
      'date': '2026-07-10',
      'status': '답변 대기중',
      'answer': ''
    }
  ];
  List<Map<String, dynamic>> get inquiries => _inquiries;

  void addInquiry(String category, String title, String content, String email) {
    _inquiries.insert(0, {
      'id': (DateTime.now().millisecondsSinceEpoch).toString(),
      'category': category,
      'title': title,
      'content': content,
      'date': DateTime.now().toString().substring(0, 10),
      'status': '답변 대기중',
      'answer': ''
    });
    notifyListeners();
  }
}
