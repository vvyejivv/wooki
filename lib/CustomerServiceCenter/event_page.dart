import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event_card.dart'; // 이벤트 카드 위젯을 가져옵니다.
import 'add_event_page.dart'; // 이벤트 추가 페이지를 가져옵니다.
import 'firestore_service.dart'; // Firestore 서비스를 가져옵니다.

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool isAdmin = false; // 사용자의 관리자 여부를 저장하는 변수입니다.

  @override
  void initState() {
    super.initState();
    _loadSessionData(); // 세션 데이터를 로드하는 함수를 호출합니다.
  }

  // 사용자의 세션 데이터를 로드하는 비동기 함수입니다.
  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferences 인스턴스를 가져옵니다.
    String? email = prefs.getString('email'); // SharedPreferences에서 이메일을 가져옵니다.
    if (email != null) {
      // 이메일이 null이 아닌 경우에만 실행됩니다.
      bool adminStatus = await FirestoreService().isAdminByEmail(email); // FirestoreService를 사용하여 관리자 여부를 확인합니다.
      setState(() {
        isAdmin = adminStatus; // 관리자 여부를 상태에 반영합니다.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '이벤트',
          textAlign: TextAlign.center,
        ), // 앱바 제목을 설정합니다.
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('events').snapshots(), // Firestore의 이벤트 컬렉션을 스트림으로 가져옵니다.
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터가 로드되기를 기다리는 중일 때
            return Center(child: CircularProgressIndicator()); // 로딩 인디케이터를 표시합니다.
          } else if (snapshot.hasError) {
            // 에러가 발생한 경우
            return Center(child: Text('Error: ${snapshot.error}')); // 에러 메시지를 표시합니다.
          } else {
            // 데이터가 성공적으로 로드된 경우
            final events = snapshot.data!.docs; // 이벤트 목록을 가져옵니다.
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index]; // 현재 이벤트를 가져옵니다.
                return EventCard(event: event, isAdmin: isAdmin); // 이벤트 카드를 반환합니다.
              },
            );
          }
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEventPage()), // 이벤트 추가 페이지로 이동합니다.
          );
        },
        child: Icon(Icons.add), // 플로팅 액션 버튼에 아이콘을 설정합니다.
      )
          : null, // 관리자가 아닌 경우 플로팅 액션 버튼을 표시하지 않습니다.
    );
  }
}