import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화를 위한 패키지
import 'package:flutter/material.dart'; // Flutter UI 구성 요소를 사용하기 위한 패키지
import 'package:intl/date_symbol_data_local.dart'; // 날짜 형식 설정을 위한 패키지
import '../firebase_options.dart'; // Firebase 프로젝트 설정을 위한 옵션 파일
import 'package:wooki/Schefuler/home_Screens.dart'; // 홈 화면 위젯 파일 임포트

void main() async {
  // Flutter 앱이 시작될 때 세션을 초기화합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 한국 로케일(ko_KR)의 날짜 형식 설정을 초기화합니다.
  initializeDateFormatting('ko_KR', null).then((_) {
    // 날짜 형식 설정이 완료된 후 앱을 실행합니다.
    runApp(Schefuler());
  });
}

// 앱의 최상위 위젯을 정의하는 Schefuler 클래스입니다.
class Schefuler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일정 관리', // 앱의 타이틀을 설정합니다.
      theme: ThemeData(), // 앱의 테마를 설정합니다.
      home: HomeScreen(updateScheduleCount: (DateTime) {}), // 앱이 실행될 때 보여줄 홈 화면을 HomeScreen 위젯으로 설정합니다.
    );
  }
}
