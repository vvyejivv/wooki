import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: AdminChatScreen(),
  ));
}

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
      if (adminEmail != null) {
        _addTestData(); // 사용자 이메일 목록을 받아 테스트 데이터 추가
      }
    });
  }

  // 테스트 데이터를 추가하는 함수
  Future<void> _addTestData() async {
    final userList = await _firestore.collection('USERLIST').get(); // USERLIST 컬렉션의 문서를 가져오기
    for (var user in userList.docs) {
      final userEmail = user.data()['email']; // 각 문서의 이메일 가져오기
      final chatRoomRef = _firestore.collection('InquireChatRooms').doc(userEmail);
      try {
        await chatRoomRef.update({'updatedAt': Timestamp.now()});
      } catch (e) {
        print('문서가 존재하지 않습니다. 새로운 문서를 생성합니다.');
        // 문서가 존재하지 않을 경우, 새로운 문서를 생성합니다.
        await chatRoomRef.set({
          'createdAt': Timestamp.now(),
          'hasNewMessage': false, // 새 메시지 필드를 초기화합니다.
        });

        // 처음 채팅방을 생성할 때만 환영 메시지를 추가합니다.
        final messageRef = chatRoomRef.collection('messages').doc();
        await messageRef.set({
          'text': '안녕하세요 관리자 입니다 1:1 질문란 입니다',
          'sender': '관리자',
          'timestamp': Timestamp.now(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '관리자 채팅',
          textAlign: TextAlign.center,
        ), // 앱바 제목 설정
        centerTitle: true,
      ),
      body: adminEmail == null
          ? Center(child: CircularProgressIndicator()) // 관리자 이메일이 로드될 때까지 로딩 표시
          : StreamBuilder(
        stream: _firestore.collection('InquireChatRooms').snapshots(), // 채팅방 컬렉션에서 스냅샷을 수신
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            // 에러가 발생한 경우
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            // 스냅샷에 데이터가 없으면 로딩 표시
            return Center(child: CircularProgressIndicator());
          }
          final chatRooms = snapshot.data!.docs;
          chatRooms.forEach((doc) => print(doc.data())); // 각 문서의 데이터를 출력
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final hasNewMessage = chatRoom['hasNewMessage'] ?? false;
              return ListTile(
                title: Text(chatRoom.id), // 채팅방 ID 표시
                trailing: hasNewMessage ? Icon(Icons.notification_important, color: Colors.red) : null, // 새 메시지가 있는 경우 빨간색 느낌표 아이콘을 표시
                onTap: () {
                  _firestore
                      .collection('InquireChatRooms')
                      .doc(chatRoom.id)
                      .update({'hasNewMessage': false}); // 채팅방을 클릭하면 새 메시지 상태를 false로 업데이트
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
                  .collection('InquireChatRooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(), // 해당 채팅방의 메시지 컬렉션에서 스냅샷을 수신
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  // 에러가 발생한 경우
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  // 스냅샷에 데이터가 없으면 로딩 표시
                  return Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                messages.forEach((doc) => print(doc.data())); // 각 메시지의 데이터를 출력
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isUser = message['sender'] != '관리자'; // 메시지의 발신자가 관리자가 아닌지 확인
                    return _buildMessageBubble(context, message['text'], message['sender'], isUser);
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

  // 메시지 버블을 구성하는 위젯
  Widget _buildMessageBubble(BuildContext context, String text, String sender, bool isUser) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end, // 사용자 메시지는 왼쪽, 관리자 메시지는 오른쪽 정렬
        children: <Widget>[
          Material(
            borderRadius: BorderRadius.circular(10.0),
            elevation: 5.0,
            color: isUser ? Colors.grey[300] : Colors.blueAccent, // 사용자 메시지는 회색, 관리자 메시지는 파란색
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75, // 말풍선의 최대 너비를 화면의 75%로 설정
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text,
                    style: TextStyle(color: isUser ? Colors.black : Colors.white, fontSize: 15.0), // 텍스트 색상과 크기 설정
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    sender,
                    style: TextStyle(color: isUser ? Colors.black54 : Colors.white60, fontSize: 12.0), // 발신자 색상과 크기 설정
                  ),
                ],
              ),
            ),
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
                _handleSubmitted(context, _textController.text); // 메시지 전송 함수 호출
              },
            ),
          ],
        ),
      ),
    );
  }

  // 메시지 전송 시 호출되는 함수
  void _handleSubmitted(BuildContext context, String text) {
    _textController.clear(); // 입력 필드 비우기
    _firestore.collection('InquireChatRooms').doc(chatRoomId).collection('messages').add({
      'text': text, // 메시지 내용
      'sender': '사용자', // 사용자가 보낸 것으로 표시
      'timestamp': Timestamp.now(), // 타임스탬프
    }).then((_) {
      // 사용자가 메시지를 보낸 후, 해당 채팅방의 hasNewMessage 필드를 true로 업데이트
      _firestore.collection('InquireChatRooms').doc(chatRoomId).update({'hasNewMessage': true});
    });
  }
}
