import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';


void main() async{
  // Firebase 초기화가 완료되기를 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //앱 실행
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('일정관리'),//앱 바의 제목
        ),
        body: MyHomePage(),
      ),
    );
  }
}
class MyHomePage  extends StatefulWidget {
  const MyHomePage ({super.key});

  @override
  State<MyHomePage > createState() => _SchedulerListState();
}

class _SchedulerListState extends State<MyHomePage > {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

