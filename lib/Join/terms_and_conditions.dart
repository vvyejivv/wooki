import 'package:flutter/material.dart';
import 'package:wooki/Join/Join1.dart';
import 'package:wooki/login/Login_main.dart';

void main() {
  runApp(
    const terms_and_conditions(),
  );
}

class terms_and_conditions extends StatelessWidget {
  const terms_and_conditions({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const TermsOfServiceAgreement(),
    );
  }
}

class TermsOfServiceAgreement extends StatefulWidget {
  const TermsOfServiceAgreement({super.key});

  @override
  State<TermsOfServiceAgreement> createState() => _TermsOfServiceAgreementState();
}

class _TermsOfServiceAgreementState extends State<TermsOfServiceAgreement> {
  List<bool> _isChecked = List.generate(5, (_) => false);

  // 버튼 활성화 상태를 반환하는 getter로 모든 필수 항목이 선택되었는지 검사
  bool get _buttonActive => _isChecked.sublist(1, 4).every((checked) => checked);

  void _updateCheckState(int index) {
    setState(() {
      if (index == 0) { // "모두 동의" 선택시 모든 체크박스 상태를 토글
        bool isAllChecked = !_isChecked.every((element) => element);
        _isChecked = List.generate(5, (index) => isAllChecked);
      } else { // 개별 체크박스 토글 및 "모두 동의" 상태 업데이트
        _isChecked[index] = !_isChecked[index];
        _isChecked[0] = _isChecked.getRange(1, 5).every((element) => element);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed:() {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginApp(),)
            );
          }, // 뒤로 가기 버튼
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('회원가입 약관 동의', style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w700)),
            const SizedBox(height: 50),
            ..._renderCheckList(),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonActive ? Colors.blue : Colors.grey,
                    ),
                    onPressed: _buttonActive ? () {
                      // 가입 로직 추가 필요
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => JoinEx2(),)
                      );
                    } : null, // 버튼 활성화 상태에 따라 동작 제어
                    child: const Text('가입하기', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 체크리스트를 생성하는 메소드
  List<Widget> _renderCheckList() {
    List<String> labels = [
      '모두 동의',
      '만 14세 이상입니다.(필수)',
      '개인정보처리방침(필수)',
      '서비스 이용 약관(필수)',
      '이벤트 및 할인 혜택 안내 동의(선택)',
    ];

    // 첫 번째 체크박스와 구분선 추가
    List<Widget> list = [
      renderContainer(_isChecked[0], labels[0], () => _updateCheckState(0)),
      const Divider(thickness: 1.0),
    ];

    // 필수 및 선택 체크박스 추가
    list.addAll(List.generate(4, (index) => renderContainer(_isChecked[index + 1], labels[index + 1], () => _updateCheckState(index + 1))));

    return list;
  }

  // 체크박스와 라벨을 표시하는 컨테이너 위젯
  Widget renderContainer(bool checked, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: checked ? Colors.blue : Colors.grey, width: 2.0),
                color: checked ? Colors.blue : Colors.white,
              ),
              child: Icon(Icons.check, color: checked ? Colors.white : Colors.grey, size: 18),
            ),
            const SizedBox(width: 15),
            Text(text, style: const TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
