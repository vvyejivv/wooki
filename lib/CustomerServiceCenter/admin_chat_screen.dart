import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminChatScreen extends StatefulWidget {
  @override
  _AdminChatScreenState createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스
  String? adminEmail; // 관리자 이메일을 저장할 변수

  @override
  void initState() {
    super.initState();
    _loadAdminData(); // 관리자 데이터 로드
  }

  // 관리자 데이터를 로드하는 비동기 함수
  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferences 인스턴스 가져오기
    setState(() {
      adminEmail = prefs.getString('email'); // 관리자 이메일 가져오기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('관리자 채팅'), // 앱바 제목 설정
      ),
      body: StreamBuilder(
        stream: _firestore.collection('chatRooms').snapshots(), // 채팅방 컬렉션에서 스냅샷을 수신
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            // 스냅샷에 데이터가 없으면 로딩 표시
            return Center(child: CircularProgressIndicator());
          }
          final chatRooms = snapshot.data!.docs; // 스냅샷에서 채팅방 목록 가져오기
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index]; // 각 채팅방 가져오기
              return ListTile(
                title: Text(chatRoom.id), // 채팅방 ID 표시
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        chatRoomId: chatRoom.id,
                        adminEmail: adminEmail!, // 관리자 이메일 전달
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatRoomScreen extends StatelessWidget {
  final String chatRoomId; // 채팅방 ID
  final String adminEmail; // 관리자 이메일
  final TextEditingController _textController = TextEditingController(); // 메시지 입력을 위한 컨트롤러
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스

  ChatRoomScreen({required this.chatRoomId, required this.adminEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('채팅방 - $chatRoomId'), // 앱바 제목 설정
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(), // 해당 채팅방의 메시지 컬렉션에서 스냅샷을 수신
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  // 스냅샷에 데이터가 없으면 로딩 표시
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs; // 스냅샷에서 메시지 목록 가져오기
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index]; // 각 메시지 가져오기
                    return ListTile(
                      title: Text(message['text']), // 메시지 텍스트 표시
                      subtitle: Text(message['sender']), // 발신자 표시
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1.0), // 구분선 추가
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // 테마의 카드 색상으로 배경색 설정
            ),
            child: _buildTextComposer(context), // 메시지 입력 필드 및 전송 버튼 위젯 호출
          ),
        ],
      ),
    );
  }

  // 메시지 입력 필드 및 전송 버튼을 구성하는 위젯
  Widget _buildTextComposer(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary), // 테마에서 아이콘 색상 가져오기
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration.collapsed(
                  hintText: '메시지를 입력하세요.',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _handleSubmitted(_textController.text); // 메시지 전송 함수 호출
              },
            ),
          ],
        ),
      ),
    );
  }

  // 메시지 전송 시 호출되는 함수
  void _handleSubmitted(String text) {
    _textController.clear(); // 입력 필드 비우기
    _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'text': text, // 메시지 내용
      'sender': adminEmail, // 발신자 이메일
      'timestamp': Timestamp.now(), // 타임스탬프
    });
  }
}
