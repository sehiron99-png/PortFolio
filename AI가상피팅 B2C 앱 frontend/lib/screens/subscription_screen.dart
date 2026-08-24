import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _showPaymentDialog(BuildContext context, String title, String price,
      VoidCallback onSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false, // 결제 도중 실수로 닫히지 않도록 차단
      builder: (dialogContext) {
        int selectedMethod = 0; // 0: 카드, 1: 카카오페이, 2: 네이버페이, 3: 토스페이
        int currentStep = 0;    // 0: 수단 선택, 1: 비밀번호 입력, 2: 결제 처리 중, 3: 지문 인식
        String pinCode = '';    // 입력된 6자리 비밀번호
        bool isScanning = false;
        bool isScanSuccess = false;
        Timer? scanTimer;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 결제 수단별 테마 정보 정의
            String methodName = '신용/체크카드';
            Color themeColor = AppTheme.primary;
            Color themeTextColor = Colors.white;
            IconData methodIcon = Icons.credit_card_rounded;

            if (selectedMethod == 1) {
              methodName = '카카오페이';
              themeColor = const Color(0xFFFFE812);
              themeTextColor = const Color(0xFF3C1E1E);
              methodIcon = Icons.wallet_rounded;
            } else if (selectedMethod == 2) {
              methodName = '네이버페이';
              themeColor = const Color(0xFF03C75A);
              themeTextColor = Colors.white;
              methodIcon = Icons.account_balance_wallet_rounded;
            } else if (selectedMethod == 3) {
              methodName = '토스페이';
              themeColor = const Color(0xFF0064FF);
              themeTextColor = Colors.white;
              methodIcon = Icons.swap_horizontal_circle_rounded;
            }

            // Step 3: 지문 인식 화면
            if (currentStep == 3) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '생체 인증 결제',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              scanTimer?.cancel();
                              setDialogState(() {
                                currentStep = 1; // PIN 입력으로 돌아감
                                isScanning = false;
                                isScanSuccess = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '지문 인식',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '하단 지문 센서를 길게 터치하여\n결제 인증을 완료해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
                      ),
                      const SizedBox(height: 36),

                      // Interactive Scanning Widget
                      GestureDetector(
                        onTapDown: (_) {
                          setDialogState(() {
                            isScanning = true;
                          });
                          // 1.2초 후 지문 인식 성공으로 시뮬레이션
                          scanTimer = Timer(const Duration(milliseconds: 1200), () {
                            setDialogState(() {
                              isScanning = false;
                              isScanSuccess = true;
                            });
                            Future.delayed(const Duration(milliseconds: 800), () {
                              setDialogState(() {
                                currentStep = 2; // 결제 처리 중 단계로 이동
                              });
                              Future.delayed(const Duration(milliseconds: 1500), () {
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  onSuccess();
                                }
                              });
                            });
                          });
                        },
                        onTapUp: (_) {
                          if (!isScanSuccess) {
                            scanTimer?.cancel();
                            setDialogState(() {
                              isScanning = false;
                            });
                          }
                        },
                        onTapCancel: () {
                          if (!isScanSuccess) {
                            scanTimer?.cancel();
                            setDialogState(() {
                              isScanning = false;
                            });
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulsing aura
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isScanSuccess
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : isScanning
                                        ? (selectedMethod == 0 ? AppTheme.accent : themeColor).withValues(alpha: 0.15)
                                        : Colors.grey[100],
                                border: Border.all(
                                  color: isScanSuccess
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : isScanning
                                          ? (selectedMethod == 0 ? AppTheme.accent : themeColor).withValues(alpha: 0.4)
                                          : Colors.grey[200]!,
                                  width: 2,
                                ),
                              ),
                            ),
                            // Fingerprint Icon
                            Icon(
                              isScanSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.fingerprint_rounded,
                              size: 60,
                              color: isScanSuccess
                                  ? Colors.green
                                  : isScanning
                                      ? (selectedMethod == 0 ? AppTheme.accent : themeColor)
                                      : Colors.grey[400],
                            ),
                            // Dynamic circular progress sweep if scanning
                            if (isScanning)
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    selectedMethod == 0 ? AppTheme.accent : themeColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isScanSuccess
                            ? '지문 인식 성공!'
                            : isScanning
                                ? '지문 스캔 중...'
                                : '손가락을 센서에 올려놓고 계세요',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isScanSuccess
                              ? Colors.green
                              : isScanning
                                  ? (selectedMethod == 0 ? AppTheme.accent : themeColor)
                                  : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            }

            // Step 2: 결제 처리 중 화면
            if (currentStep == 2) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primary),
                      const SizedBox(height: 24),
                      const Text(
                        '결제 요청 승인 중...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '안전한 결제 연결을 위해 잠시만 대기해주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Step 1: 비밀번호 입력(키패드) 화면
            if (currentStep == 1) {
              return Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 결제처 브랜드 헤더
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(methodIcon, size: 14, color: selectedMethod == 0 ? AppTheme.accent : themeColor),
                            const SizedBox(width: 6),
                            Text(
                              methodName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: selectedMethod == 0 ? AppTheme.primary : themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '결제 비밀번호 입력',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '본인 확인을 위해 비밀번호 6자리를 입력해주세요.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),

                      // 비밀번호 입력 도트들 (6자리)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          bool isEntered = index < pinCode.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isEntered
                                  ? (selectedMethod == 0 ? AppTheme.primary : themeColor)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isEntered
                                    ? (selectedMethod == 0 ? AppTheme.primary : themeColor)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      // 지문 인증 바로가기 버튼 추가
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            currentStep = 3; // 지문 스캐너 화면으로 이동
                            isScanning = false;
                            isScanSuccess = false;
                          });
                        },
                        icon: Icon(Icons.fingerprint_rounded, size: 20, color: selectedMethod == 0 ? AppTheme.accent : themeColor),
                        label: Text(
                          '지문 인증 사용',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selectedMethod == 0 ? AppTheme.accent : themeColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: (selectedMethod == 0 ? AppTheme.accent : themeColor).withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3x4 키패드 그리드
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          // 키패드 배치 구성
                          if (index == 9) {
                            // 빈칸 또는 취소
                            return TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  currentStep = 0;
                                  pinCode = '';
                                });
                              },
                              child: const Text(
                                '이전',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey),
                              ),
                            );
                          }
                          if (index == 11) {
                            // 지우기
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (pinCode.isNotEmpty) {
                                  setDialogState(() {
                                    pinCode = pinCode.substring(0, pinCode.length - 1);
                                  });
                                }
                              },
                              child: const Center(
                                child: Icon(Icons.backspace_outlined,
                                    size: 18, color: Colors.black54),
                              ),
                            );
                          }

                          // 숫자 구하기
                          int number = index;
                          if (index == 10) number = 0;
                          else if (index < 9) number = index + 1;

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (pinCode.length < 6) {
                                setDialogState(() {
                                  pinCode += number.toString();
                                });
                                // 6자리 모두 채우면 결제 처리 시작
                                if (pinCode.length == 6) {
                                  setDialogState(() {
                                    currentStep = 2;
                                  });
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                      onSuccess();
                                    }
                                  });
                                }
                              }
                            },
                            child: Center(
                              child: Text(
                                number.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            // Step 0: 결제 동의 및 수단 선택 화면 (기본 화면)
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon with subtle glow
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5A7059), Color(0xFF3E4A3D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5A7059).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title & Subtitle
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '루미에르 안전 결제 서비스',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Checkout Details Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '결제 상품',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '총 결제 금액',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method Selector Mock
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '결제 수단 선택',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 2x2 Grid of detailed payment methods
                    Column(
                      children: [
                        Row(
                          children: [
                            _buildMethodTile(
                              label: '신용/체크카드',
                              icon: Icons.credit_card_rounded,
                              selectedColor: AppTheme.accent,
                              isSelected: selectedMethod == 0,
                              onTap: () => setDialogState(() => selectedMethod = 0),
                            ),
                            const SizedBox(width: 8),
                            _buildMethodTile(
                              label: '카카오페이',
                              icon: Icons.wallet_rounded,
                              selectedColor: const Color(0xFFFFE812), // Kakao Yellow
                              textColor: const Color(0xFF3C1E1E),
                              isSelected: selectedMethod == 1,
                              onTap: () => setDialogState(() => selectedMethod = 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMethodTile(
                              label: '네이버페이',
                              icon: Icons.account_balance_wallet_rounded,
                              selectedColor: const Color(0xFF03C75A), // Naver Green
                              isSelected: selectedMethod == 2,
                              onTap: () => setDialogState(() => selectedMethod = 2),
                            ),
                            const SizedBox(width: 8),
                            _buildMethodTile(
                              label: '토스페이',
                              icon: Icons.swap_horizontal_circle_rounded,
                              selectedColor: const Color(0xFF0064FF), // Toss Blue
                              isSelected: selectedMethod == 3,
                              onTap: () => setDialogState(() => selectedMethod = 3),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Security Note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: Color(0xFF5A7059),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '안전하게 암호화되어 결제됩니다.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setDialogState(() {
                                currentStep = 1; // 비밀번호 입력 단계로 진입
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 3,
                              shadowColor: AppTheme.primary.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '결제하기',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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
        );
      },
    );
  }

  Widget _buildMethodTile({
    required String label,
    required IconData icon,
    required Color selectedColor,
    Color? textColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeTextColor = textColor ?? selectedColor;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.grey[200]!,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeTextColor : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopSuccessBanner(BuildContext context, String message) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, scale, child) {
                final double opacityValue = ((scale - 0.8) * 5).clamp(0.0, 1.0);
                return Opacity(
                  opacity: opacityValue,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E382A), // Dark Sage Green
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF5A7059).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5A7059),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '충전 완료',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE2C573), // Gold text
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

    Overlay.of(context).insert(overlayEntry);

    // Auto dismiss after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      overlayEntry.remove();
    });
  }

  Widget _buildPrecautionsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                '구독 및 결제 유의사항',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[700],
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPrecautionText('결제 완료 후 7일 이내에 피팅 횟수를 사용하지 않은 경우 전액 환불이 가능합니다.'),
          const SizedBox(height: 6),
          _buildPrecautionText('정기 구독(Premium)은 매월 동일한 일자에 자동 결제됩니다.'),
          const SizedBox(height: 6),
          _buildPrecautionText('디지털 콘텐츠 특성상 부분 환불이나 이미 소진된 피팅 횟수에 대한 환불은 불가합니다.'),
          const SizedBox(height: 6),
          _buildPrecautionText('충전형 토큰은 구매 후 유효기간 없이 영구적으로 사용하실 수 있습니다.'),
          const SizedBox(height: 6),
          _buildPrecautionText('결제 및 환불 관련 문의는 마이페이지 > 고객센터로 접수해 주시기 바랍니다.'),
        ],
      ),
    );
  }

  Widget _buildPrecautionText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5, right: 6),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.primary, size: 20),
          onPressed: () => provider.goBack(),
        ),
        title: const Text('구독 플랜',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '나에게 딱 맞는 루미에르 플랜을 선택해보세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 피팅으로 매일 새로운 스타일을 경험해보세요.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 32),

            // 1. 일반 플랜 (Free & Token) 세로로 나열
            _buildSmallPlanCard(
              context,
              title: 'Free',
              rightText: null,
              rightWidget: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '기본형',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '남은 피팅 : ${provider.freeFittingCount}회',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              price: '무료',
              priceSuffix: '',
              detailBoxText: '매월 3회 기본 제공',
              buttonText: '기본 제공 활성화됨',
              backgroundColor: Colors.white,
              borderColor: Colors.grey[300]!.withValues(alpha: 0.5),
              textColor: Colors.black87,
              titleTextColor: Colors.white,
              buttonBgColor: Colors.grey[200]!,
              buttonTextColor: Colors.black54,
              isOutlineButton: false,
              titleBgColor: Colors.black87,
              titleBorderColor: Colors.black87,
              infoDialogTitle: 'Free 플랜 안내',
              infoDialogContent:
                  '• 모든 사용자에게 매월 3회의 무료 피팅 횟수가 기본 제공됩니다.\n• 미사용 잔여 횟수는 다음 달로 이월되지 않습니다.',
              onPressedOverride: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('기본 제공되는 플랜입니다.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSmallPlanCard(
              context,
              title: 'Token',
              rightText: null,
              rightWidget: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '충전식',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '남은 피팅 : ${provider.tokenCount}회',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black, // 더 진한 검정으로 변경
                    ),
                  ),
                ],
              ),
              price: '₩ 1,000',
              priceSuffix: '/ 10회',
              isPriceBoxed: false,
              detailBoxText: null,
              featureItems: const ['광고 시청 생략 가능', '충전한 토큰 영구 사용'],
              featureBgColor: Colors.white.withValues(alpha: 0.5),
              buttonText: '토큰 충전',
              backgroundGradient: const LinearGradient(
                colors: [
                  Color(0xFFE8EFE5), // Soft Sage Green
                  Color(0xFFF6F4EE), // Soft Beige White
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              backgroundColor: Colors.transparent,
              borderColor: AppTheme.accent.withValues(alpha: 0.15),
              textColor: AppTheme.primary,
              titleTextColor: Colors.white,
              buttonBgColor: AppTheme.accent,
              buttonTextColor: Colors.white,
              isOutlineButton: false,
              titleBgColor: const Color(0xFF2E382A),
              titleBorderColor: const Color(0xFF2E382A),
              infoDialogTitle: '토큰 충전 플랜 안내',
              infoDialogContent:
                  '• 횟수 제한 없이 자유로운 토큰 충전 및 무한 누적 가능\n• 원할 때마다 필요한 만큼 충전하여 넉넉하게 사용\n• 대기 시간 및 광고 시청 없이 즉시 피팅 결과 확인 가능',
              infoIconColor: AppTheme.primary,
              onPressedOverride: () {
                _showPaymentDialog(context, '토큰 10회 충전', '₩ 1,000', () {
                  provider.addTokens(10);
                  _showTopSuccessBanner(context, '토큰 10회가 성공적으로 충전되었습니다.');
                });
              },
            ),

            const SizedBox(height: 16),

            // 2. 월간 구독 (프리미엄을 제일 밑에)
            _buildPremiumCard(context),
            const SizedBox(height: 32),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            const SizedBox(height: 32),

            // 3. 유의사항 및 환불정책 영역
            _buildPrecautionsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 상단 좌우 배치되는 작은 카드
  Widget _buildSmallPlanCard(
    BuildContext context, {
    required String title,
    String? rightText,
    Widget? rightWidget,
    String? price,
    String? priceSuffix,
    bool isPriceBoxed = false,
    double? customPriceFontSize,
    String? detailBoxText,
    List<String>? featureItems,
    Color? featureBgColor,
    Color? rightTextBgColor,
    required String buttonText,
    required Color backgroundColor,
    Gradient? backgroundGradient,
    required Color borderColor,
    required Color textColor,
    Color? titleTextColor,
    Color? priceColor,
    required Color buttonBgColor,
    required Color buttonTextColor,
    required bool isOutlineButton,
    Color? titleBgColor,
    Color? titleBorderColor,
    VoidCallback? onPressedOverride,
    String? infoDialogTitle,
    String? infoDialogContent,
    Color? infoIconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundGradient == null ? backgroundColor : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: titleBgColor ??
                      const Color(0xFF5A7059).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: titleBorderColor ??
                        const Color(0xFF5A7059).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleTextColor ?? textColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (rightWidget != null)
                rightWidget
              else if (rightText != null && rightText.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        rightTextBgColor ?? Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rightText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              const Spacer(),
              if (infoDialogTitle != null && infoDialogContent != null)
                GestureDetector(
                  onTap: () => _showInfoDialog(
                      context, infoDialogTitle, infoDialogContent),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: infoIconColor ?? textColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
            ],
          ),
          if (price != null && price.isNotEmpty) ...[
            const SizedBox(height: 16),
            isPriceBoxed
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: priceColor ?? AppTheme.primary,
                          ),
                        ),
                        if (priceSuffix != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1, left: 4),
                            child: Text(
                              priceSuffix,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: (priceColor ?? AppTheme.primary)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: customPriceFontSize ?? 20,
                          fontWeight: FontWeight.w800,
                          color: priceColor ?? AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (priceSuffix != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            priceSuffix,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (priceColor ?? AppTheme.primary)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
          ],
          if (detailBoxText != null && detailBoxText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                detailBoxText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: textColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
          if (featureItems != null && featureItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...featureItems.map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildFeatureItem(text, textColor,
                      bgColor: featureBgColor),
                )),
          ],
          if (buttonText != '기본 제공 활성화됨') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: onPressedOverride ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$buttonText 준비 중입니다')),
                      );
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBgColor,
                  elevation: isOutlineButton ? 0 : 6,
                  shadowColor: buttonBgColor.withValues(alpha: 0.5),
                  splashFactory: NoSplash.splashFactory,
                  animationDuration: const Duration(milliseconds: 150),
                  side: isOutlineButton
                      ? BorderSide(color: Colors.grey[300]!, width: 1.5)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.black.withValues(alpha: 0.1);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.black.withValues(alpha: 0.05);
                    }
                    return Colors.transparent;
                  }),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: buttonTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: buttonTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 하단 넓게 배치되는 프리미엄 카드
  Widget _buildPremiumCard(BuildContext context) {
    const textColor = Colors.white;
    final provider = Provider.of<FittingProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151515), // Deep dark
            Color(0xFF262626), // Dark charcoal
            Color(0xFF1C1C1C), // Deep dark
            Color(0xFF2E2B25), // Very subtle gold-dark tint
            Color(0xFF151515), // Deep dark
          ],
          stops: [0.0, 0.3, 0.5, 0.8, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFE2C573).withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LoopShimmer(
                controller: _shimmerController,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A), // 카드와 동일한 검은색 계열
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2C573), // 은은하게 빛나는 골드 테두리
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE2C573).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE2C573),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '정기 구독',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '남은 피팅 : ${provider.isPremium ? provider.premiumFittingCount : 0}회',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFE2C573),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showInfoDialog(context, '정기 구독 플랜 안내',
                    '• 광고 시청 없이 언제나 쾌적하게 피팅 이용 가능\n• 매월 100회의 넉넉한 피팅 횟수 제공\n• 100회 모두 소진 시 토큰 충전을 통해 끊김 없이 계속 이용 가능'),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price
          LoopShimmer(
            controller: _shimmerController,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '₩ 5,000',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE2C573),
                    letterSpacing: 0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/ 월 (100회)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE2C573).withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          ),

          const SizedBox(height: 18),

          // Features
          _buildFeatureItem('광고 시청 생략 가능', textColor),
          const SizedBox(height: 8),
          _buildFeatureItem('매월 100회 피팅 제공', textColor),

          const SizedBox(height: 18),

          if (provider.isPremium) ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2C573), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: Color(0xFFE2C573)),
                    SizedBox(width: 8),
                    Text(
                      '구독 활성화 중',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE2C573),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              '구독 해지 안내',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                        content: const Text(
                          '정말 프리미엄 구독을 해지하시겠습니까?\n해지 시 잔여 피팅 횟수는 이번 달 말까지 유지되며, 이후 추가 결제가 차단됩니다.',
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('유지하기',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('해지하기',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ],
                      );
                    },
                  ).then((value) {
                    if (value == true && context.mounted) {
                      provider.setPremium(false);
                      _showTopSuccessBanner(context, '구독이 성공적으로 해지되었습니다.');
                    }
                  });
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '구독 해지하기',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.5),
                    decoration: TextDecoration.underline,
                    decorationColor: textColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ] else ...[
            LoopShimmer(
              controller: _shimmerController,
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    _showPaymentDialog(context, '프리미엄 구독', '₩ 5,000 / 월', () {
                      provider.setPremium(true);
                      _showTopSuccessBanner(context, '프리미엄 구독(100회)이 완료되었습니다.');
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2C573),
                    elevation: 8,
                    shadowColor: const Color(0xFFE2C573).withValues(alpha: 0.4),
                    splashFactory: NoSplash.splashFactory,
                    animationDuration: const Duration(milliseconds: 150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.black.withValues(alpha: 0.1);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.black.withValues(alpha: 0.05);
                      }
                      return Colors.transparent;
                    }),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '프리미엄 구독',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, Color textColor, {Color? bgColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: textColor.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF5A7059)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인',
                  style: TextStyle(
                      color: Color(0xFF5A7059),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ],
        );
      },
    );
  }
}

class LoopShimmer extends StatefulWidget {
  final Widget child;
  final AnimationController? controller;
  const LoopShimmer({super.key, required this.child, this.controller});

  @override
  State<LoopShimmer> createState() => _LoopShimmerState();
}

class _LoopShimmerState extends State<LoopShimmer> with TickerProviderStateMixin {
  AnimationController? _localController;
  AnimationController get _effectiveController => widget.controller ?? _localController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _localController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3000),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _effectiveController,
      builder: (context, child) {
        final double value = _effectiveController.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-2.5 + (value * 5.0), -1.2),
              end: Alignment(-1.5 + (value * 5.0), 1.2),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.35),
                const Color(0xFFE2C573).withValues(alpha: 0.2), // Subtle golden shimmer
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.0),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.43, 0.5, 0.57, 0.65, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
