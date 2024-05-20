import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainPage());
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFDEF),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            mapController = controller;
          });
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(37.5070, 126.7219),
          zoom: 14.0,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF4E3E36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.home, size: 35, color: Colors.white60,),
              onPressed: (){},
            ),
            IconButton(
              icon: Icon(Icons.photo, size: 30, color: Colors.white60,),
              onPressed: (){},
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(), // 동그란 모양으로 버튼을 만듭니다.
                backgroundColor: Colors.transparent, // 배경색을 투명하게 설정합니다.
              ),
              child: Image.asset('assets/img/wooki3.png',height: 60,),
              onPressed: (){},
            ),
            IconButton(
              icon: Icon(Icons.calendar_month, size: 30, color: Colors.white60,),
              onPressed: (){},
            ),
            IconButton(
              icon: Icon(Icons.menu, size: 30, color: Colors.white60,),
              onPressed: (){},
            ),
          ],
        ),
      ),
    );
  }
}
