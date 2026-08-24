import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import '../models/clothing_item.dart';
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}
class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionDenied = false;
  final ImagePicker _picker = ImagePicker();
    final List<ClothingItem> _sessionCaptures = [];
  int _selectedCameraIndex = 0;
  bool _showGuideText = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    final provider = Provider.of<FittingProvider>(context, listen: false);
    if (provider.shouldOpenGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setShouldOpenGallery(false);
        _pickFromGallery(provider);
      });
    } else {
      _initializeCamera();
    }
    
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _showGuideText = false;
        });
      }
    });
  }
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('사용 가능한 카메라가 없습니다.');
        return;
      }
      // 첫 구동 시 기본 후면 카메라 세팅
      if (_controller == null) {
        final backCameraIndex = _cameras!.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backCameraIndex != -1 ? backCameraIndex : 0;
      }
      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.max, // 사용자 카메라 자체 최대 해상도 사용
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraPermissionDenied = false;
        });
      }
    } catch (e) {
      if (e is CameraException) {
        if (e.code == 'CameraAccessDenied') {
          debugPrint('카메라 접근 권한이 거부되었습니다.');
          if (mounted) {
            setState(() {
              _isCameraPermissionDenied = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('카메라 사용 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.')),
            );
            // 권한 거부 시 홈 화면으로 안전하게 복귀
            final provider =
                Provider.of<FittingProvider>(context, listen: false);
            provider.goBack();
          }
        } else {
          debugPrint('카메라 초기화 에러: ${e.description}');
        }
      }
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    // 앱 수명주기 변화 관리 (포그라운드/백그라운드 자원 할당 해제)
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }
  // 전면/후면 카메라 렌즈 전환 토글
  Future<void> _toggleCameraLens() async {
    if (_cameras == null || _cameras!.length < 2 || _controller == null) {
      return;
    }
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _isCameraInitialized = false;
    setState(() {});
    await _controller!.dispose();
    _controller = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('카메라 렌즈 전환 에러: $e');
    }
  }
  // 인앱 카메라 셔터 촬영 동작
  Future<void> _takePhoto(FittingProvider provider) async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라가 준비되지 않았습니다.')),
      );
      return;
    }
    if (cameraController.value.isTakingPicture) {
      return;
    }
    try {
      // 방향 고정 없이 바로 촬영 - 전체화면 전환 방지
      final XFile file = await cameraController.takePicture();
      if (!mounted) return;
      if (provider.isCameraForUserPhoto) {
        _showUserPhotoRegistrationDialog(file.path);
      } else {
        _showRegistrationSheet(file.path, provider);
      }
    } catch (e) {
      debugPrint('사진 촬영 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 촬영에 실패했습니다.')),
        );
      }
    }
  }
  // 갤러리 앨범에서 의류 사진 다중 불러오기 동작
  Future<void> _pickFromGallery(FittingProvider provider) async {
    final bool wasCameraInitialized = _controller != null && _controller!.value.isInitialized;
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      if (pickedFiles.isEmpty) {
        if (!wasCameraInitialized) {
          provider.goBack();
        }
        return;
      }
      
      for (final pickedFile in pickedFiles) {
        if (!mounted) break;
        if (provider.isCameraForUserPhoto) {
          _showUserPhotoRegistrationDialog(pickedFile.path);
        } else {
          await _showRegistrationSheet(pickedFile.path, provider);
        }
      }
      
      if (!wasCameraInitialized) {
        provider.goBack();
      }
    } catch (e) {
      debugPrint('사진 불러오기 실패: $e');
      if (!wasCameraInitialized) {
        provider.goBack();
      }
    }
  }

  void _showUserPhotoRegistrationDialog(String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목 중앙 + 오른쪽 뒤로가기 버튼
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        '인물 사진 촬영 완료',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          final prov = Provider.of<FittingProvider>(context, listen: false);
                          prov.setIsCameraForUserPhoto(false);
                          prov.goBack();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_back, size: 20, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 촬영된 사진 - 원본 비율 그대로, 가로/세로 모두 대응
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb
                      ? Image.network(
                          imagePath,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(imagePath),
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // 다이얼로그만 닫기 (카메라로 복귀)
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                          side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('재촬영',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final provider = Provider.of<FittingProvider>(context, listen: false);
                          provider.setTempUserPhoto(imagePath);
                          provider.setIsCameraForUserPhoto(false);
                          Navigator.pop(context);
                          provider.setScreen('fitting');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('인물사진으로 등록',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRegistrationSheet(String imagePath, FittingProvider provider) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = provider.selectedCategory;
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '새 의류 등록',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '촬영한 옷의 정보와 카테고리를 지정해 주세요',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.network(
                                    imagePath,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  )
                                : Image.file(
                                    File(imagePath),
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '카테고리',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            ['상의', '하의', '원피스', '아우터', '신발'].map((cat) {
                          final isSelected = selectedCategory == cat;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => selectedCategory = cat);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: AppTheme.accent, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.accent
                                      : Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: '옷 이름',
                          labelStyle:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          hintText: '예: 크롭 린넨 셔츠',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '가격 (원)',
                          labelStyle:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          hintText: '예: 45,000',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppTheme.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context); // 다이얼로그 닫기
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[800],
                                side: BorderSide(
                                    color: Colors.grey[600]!, width: 1.5),
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('재촬영',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                final priceText = priceController.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('옷 이름을 입력해 주세요.')),
                                  );
                                  return;
                                }
                                final parsedPrice =
                                    int.tryParse(priceText.replaceAll(',', ''));
                                final formattedPrice = parsedPrice != null
                                    ? parsedPrice.toString().replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]},')
                                    : priceText;
                                await provider.captureNewClothing(
                                  imagePath: imagePath,
                                  category: selectedCategory,
                                  name: name,
                                  price: formattedPrice,
                                );
                                if (provider.recentCaptures.isNotEmpty) {
                                  setState(() {
                                    _sessionCaptures.insert(
                                        0, provider.recentCaptures.first);
                                  });
                                }
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '[$selectedCategory] $name 이(가) 등록되었습니다.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.checkroom, size: 20),
                                  SizedBox(width: 8),
                                  Text('옷장에 저장하기',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    final double bottomPanelHeight =
        16.0 + 72.0 + 16.0 + MediaQuery.of(context).padding.bottom;
    final double thumbnailStripHeight =
        _sessionCaptures.isNotEmpty ? (56.0 + 16.0) : 0.0;
    final double totalBottomHeight = bottomPanelHeight + thumbnailStripHeight;
    return Stack(
        children: [
          // 1. 실시간 인앱 카메라 프리뷰 피드
          Positioned.fill(
            child: _isCameraInitialized && _controller != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      // 카메라 비율에 맞춰 프리뷰 표시 (웹에서는 카메라 자체 종횡비 사용)
                      final camValue = _controller!.value;
                      final camAspect = kIsWeb
                          ? _controller!.value.aspectRatio
                          : (camValue.previewSize != null
                              ? camValue.previewSize!.height /
                                  camValue.previewSize!.width
                              : 9 / 16);
                      return Center(
                        child: AspectRatio(
                          aspectRatio: camAspect,
                          child: CameraPreview(_controller!),
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFF151820),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppTheme.accent),
                      ),
                    ),
                  ),
          ),
          // 2. 가이드라인 및 텍스트 오버레이 (카메라 화면 위에 오버레이)
          _buildCameraGuides(totalBottomHeight + 20),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 200), // 가이드라인 하단에 안내 텍스트 배치
                AnimatedOpacity(
                  opacity: _showGuideText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      provider.isCameraForUserPhoto ? '가이드에 맞춰 인물을 촬영해주세요' : '매장의 옷을 테두리 안에 맞춰주세요',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 4. 상단 바
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => provider.goBack(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    Text(
                      provider.isCameraForUserPhoto ? '인물 촬영' : '옷 촬영',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // 도움말 (가이드 팝업) 버튼 추가
                        GestureDetector(
                          onTap: () => _showClothesGuideDialog(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.help_outline,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => provider.setScreen('wardrobe'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_bag_outlined,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 5. 하단 셔터 및 컨트롤바
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: true,
              child: Container(
                color: const Color(0xFF0A0A0A),
                padding: const EdgeInsets.only(
                    top: 16, bottom: 40, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 최근 촬영된 목록 썸네일 스트립
                    if (_sessionCaptures.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 56,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _sessionCaptures.length,
                            itemBuilder: (context, index) {
                              final item = _sessionCaptures[index];
                              return Container(
                                width: 56,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.accent, width: 2),
                                ),
                                child: ClipRRect(
                                  child: kIsWeb
                                      ? Image.network(item.imageUrl, fit: BoxFit.cover)
                                      : (File(item.imageUrl).existsSync()
                                          ? Image.file(File(item.imageUrl), fit: BoxFit.cover)
                                          : Image.network(item.imageUrl, fit: BoxFit.cover)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    // 셔터 및 갤러리/카메라 스위칭 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 갤러리 불러오기
                        GestureDetector(
                          onTap: () => _pickFromGallery(provider),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.image_outlined,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        // 촬영 셔터 버튼 (실제 인앱 카메라 촬영)
                        GestureDetector(
                          onTap: () => _takePhoto(provider),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 4),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: AppTheme.primary, size: 24),
                            ),
                          ),
                        ),
                        // 전면/후면 카메라 전환 버튼
                        GestureDetector(
                          onTap: _toggleCameraLens,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.flip_camera_ios_outlined,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildCameraGuides(double bottomPadding) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(
            top: 80, bottom: bottomPadding, left: 40, right: 40),
        child: Stack(
          children: [
            // 좌상단
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.accent, width: 2),
                    left: BorderSide(color: AppTheme.accent, width: 2),
                  ),
                ),
              ),
            ),
            // 우상단
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.accent, width: 2),
                    right: BorderSide(color: AppTheme.accent, width: 2),
                  ),
                ),
              ),
            ),
            // 좌하단
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.accent, width: 2),
                    left: BorderSide(color: AppTheme.accent, width: 2),
                  ),
                ),
              ),
            ),
            // 우하단
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.accent, width: 2),
                    right: BorderSide(color: AppTheme.accent, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showClothesGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: UnconstrainedBox(
            child: Container(
              width: 300, // 세로 길이를 낮추기 위해 가로폭을 300으로 대칭 일치
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 (타이틀 + 우측 닫기 x 버튼)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '올바른 인물 촬영 예시', // 인물 전용 타이틀
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 이미지 + 설명 가로 배치
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 좋은 예시 이미지 (가이드 단독 이미지)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/guide_user_fullbody.png',
                            width: 140,
                            height: 190,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 140,
                              height: 190,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Icon(Icons.person_outline_rounded, // 인물 가이드에 적합한 사람 아이콘
                                  size: 48, color: AppTheme.accent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // 설명 목록 (O/X 표시 및 각 한 줄씩 설명 기입)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              _GuideLine(
                                  prefix: 'O',
                                  prefixColor: Colors.green,
                                  text: '입으려는 부위까지 나오는 사진'),
                              SizedBox(height: 8),
                              _GuideLine(
                                  prefix: 'O',
                                  prefixColor: Colors.green,
                                  text: '단독으로 나오는 사진'),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                              ),
                              _GuideLine(
                                  prefix: 'X',
                                  prefixColor: Colors.red,
                                  text: '의류 방향과 다른 자세의 사진'),
                              SizedBox(height: 8),
                              _GuideLine(
                                  prefix: 'X',
                                  prefixColor: Colors.red,
                                  text: '여러 사람과 찍힌 사진'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    // 하단 확인 단추 (의류 팝업과 완전 통일: 와이드 플랫 올리브 버튼)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF8E9B61), // 의류 확인 버튼과 동일한 올리브색 수혈
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '확인했습니다',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 가이드 한 줄 설명 위젯
class _GuideLine extends StatelessWidget {
  final String prefix;
  final Color prefixColor;
  final String text;
  const _GuideLine({
    required this.prefix,
    required this.prefixColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prefix,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: prefixColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600, // 의류 가이드라인과 완전 동일
                color: Color(0xFF374151), // 의류와 동일한 짙은 회색 계열
                height: 1.3),
          ),
        ),
      ],
    );
  }
}