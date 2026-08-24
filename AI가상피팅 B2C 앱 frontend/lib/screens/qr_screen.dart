import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import '../services/api_service.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null) {
        setState(() {
          _isProcessing = true;
        });

        // 일시 정지 후 다이얼로그 띄우기
        _scannerController.stop();
        await _showScannedResultDialog(rawValue);

        // 다이얼로그 닫힌 후 다시 시작
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _scannerController.start();
        }
      }
    }
  }

  Future<void> _showScannedResultDialog(String result) async {
    final provider = Provider.of<FittingProvider>(context, listen: false);

    // ngrok URL인지 확인 (비밀 서버 설정 통합)
    bool isNgrok = result.contains('ngrok-free.dev');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isNgrok ? Icons.settings_ethernet : Icons.qr_code_2,
                color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(isNgrok ? '서버 주소 설정' : 'QR 스캔 결과',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNgrok
                  ? '다음 백엔드 서버 URL을 적용하시겠습니까?'
                  : '스캔된 내용입니다. 서버 URL로 적용하시겠습니까?',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                result,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기/다시 스캔', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.updateServerUrl(result);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('서버 주소가 적용되었습니다:\n$result')),
                );
                Navigator.pop(context); // 다이얼로그 닫기
                provider.setScreen('home'); // 홈으로 돌아가기
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('서버 주소로 적용'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 카메라 스캐너 뷰
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // 2. 어두운 오버레이와 투명한 사각형 (QR 가이드라인)
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),

          // 3. 안내 문구
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '사각 테두리 안에 QR 코드를 맞춰주세요',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. 상단 컨트롤 영역 (뒤로가기, 플래시 등)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 닫기 버튼
                  GestureDetector(
                    onTap: () => provider.setScreen('home'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  // 플래시 버튼
                  GestureDetector(
                    onTap: () => _scannerController.toggleTorch(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _scannerController,
                        builder: (context, state, child) {
                          final torchState = state.torchState;
                          return Icon(
                              torchState == TorchState.on
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: torchState == TorchState.on
                                  ? Colors.yellow
                                  : Colors.white,
                              size: 26);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 카메라 오버레이 (바깥쪽은 어둡게, 가운데는 뚫려있는 형태)
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final borderPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double scanAreaSize = size.width * 0.7;
    final Rect scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // 전체 화면에서 스캔 영역만큼 구멍 뚫기
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 스캔 영역 테두리 (모서리 강조) 그리기
    final double cornerLength = 30.0;

    // Top Left
    canvas.drawLine(scanArea.topLeft,
        scanArea.topLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.topLeft,
        scanArea.topLeft + Offset(0, cornerLength), borderPaint);

    // Top Right
    canvas.drawLine(scanArea.topRight,
        scanArea.topRight + Offset(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.topRight,
        scanArea.topRight + Offset(0, cornerLength), borderPaint);

    // Bottom Left
    canvas.drawLine(scanArea.bottomLeft,
        scanArea.bottomLeft + Offset(cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.bottomLeft,
        scanArea.bottomLeft + Offset(0, -cornerLength), borderPaint);

    // Bottom Right
    canvas.drawLine(scanArea.bottomRight,
        scanArea.bottomRight + Offset(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanArea.bottomRight,
        scanArea.bottomRight + Offset(0, -cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
