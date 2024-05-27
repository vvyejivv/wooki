// 필요한 패키지들을 임포트합니다.
import 'package:firebase_core/firebase_core.dart'; // Firebase 초기화를 위한 패키지
import 'package:flutter/material.dart'; // Flutter의 UI 구성 요소를 사용하기 위한 패키지
import 'package:wooki/firebase_options.dart'; // Firebase 프로젝트 설정을 위한 옵션 파일
import 'package:wooki/CustomerServiceCenter/main_screens.dart'; // MainScreens 위젯 파일 임포트
import 'package:provider/provider.dart'; // Provider 패키지 임포트
import '../login/Session.dart';// Session 클래스 임포트

// 앱의 메인 함수
void main() async {
  // 비동기 작업이 필요한 경우, Flutter의 UI 스레드가 초기화될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase를 초기화합니다. Firebase의 모든 서비스 사용 전에 필수적으로 수행되어야 합니다.
  // DefaultFirebaseOptions.currentPlatform을 통해 플랫폼(안드로이드, iOS 등)에 맞는 설정을 자동으로 불러옵니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // MyApp 위젯을 루트 위젯으로 사용하는 애플리케이션을 실행합니다.
  runApp(
    ChangeNotifierProvider(
      create: (context) => Session(),
      child: const Customer(),
    ),
  );
}

// 앱의 최상위 위젯을 정의하는 MyApp 클래스. StatelessWidget을 상속받아 변경 가능한 상태를 관리하지 않습니다.
class Customer extends StatelessWidget {
  const Customer({super.key}); // 생성자에서 선택적으로 key를 전달받을 수 있습니다.

  @override
  Widget build(BuildContext context) {
    // MaterialApp 위젯을 반환합니다. Flutter 앱의 기본 구조를 형성합니다.
    return MaterialApp(
      title: '고객센터', // 앱의 타이틀을 설정합니다.
      theme: ThemeData(
        primarySwatch: Colors.blue, // 앱의 전역 테마 색상을 설정합니다.
        visualDensity: VisualDensity.adaptivePlatformDensity, // 각 플랫폼에 맞는 밀도로 조정합니다.
      ),
      home: const MainScreens(), // 앱이 실행될 때 보여줄 홈 화면을 MainScreens 위젯으로 설정합니다.
    );
  }
}
