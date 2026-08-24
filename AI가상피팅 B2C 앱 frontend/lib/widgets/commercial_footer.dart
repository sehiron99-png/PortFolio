import 'package:flutter/material.dart';

class CommercialFooter extends StatelessWidget {
  const CommercialFooter({Key? key}) : super(key: key);

  void _showPolicyDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      ' 대한 상세 내용이 이곳에 표시됩니다.\n\n현재는 임시 텍스트입니다. 향후 실제  전문으로 교체될 예정입니다.\n\n제1조 (목적)\n이 약관은 (주)니어네트웍스가 제공하는 제반 서비스의 이용과 관련하여 회사와 회원과의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.',
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('확인',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48.0, bottom: 20.0, left: 24.0, right: 24.0),
      color: Colors.grey[100], // 맨 밑칸 배경을 약간 진하게
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '버전 정보 v1.0.0',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '(주)니어네트웍스 | 대표자: 이복동',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '사업자등록번호: 514-81-98341 | 통신판매업신고: 제2024-대구달서-0000호\n고객센터: 053-123-4567 | 이메일: contact@nearnetworks.com\n주소: 대구광역시 달서구 장기로 58',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.5,
              color: Colors.grey[400], // 더 연한 회색 적용
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showPolicyDialog(context, '이용약관'),
                child: Text('이용약관',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400])), // 약간 연하게 (700 -> 500 -> 400)
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 10, color: Colors.grey[300]),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showPolicyDialog(context, '개인정보처리방침'),
                child: Text('개인정보처리방침',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400])), // 약간 연하게
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 10, color: Colors.grey[300]),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showPolicyDialog(context, '사업자정보확인'),
                child: Text('사업자정보확인',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400])), // 약간 연하게
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 NearNetworks Inc. All rights reserved.',
            style: TextStyle(fontSize: 9, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
