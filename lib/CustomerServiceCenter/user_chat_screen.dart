import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserChatScreen extends StatefulWidget {
  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _textController =
  TextEditingController(); // 메시지 입력을 위한 컨트롤러
  String? userEmail; // 사용자 이메일을 저장할 변수
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore 인스턴스

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 사용자 데이터 로드
  }

  // 사용자 데이터를 로드하는 비동기 함수
  Future<void> _loadUserData() async {
    final prefs =
    await SharedPreferences.getInstance(); // SharedPreferences 인스턴스 가져오기
    setState(() {
      userEmail = prefs.getString('email'); // 사용자 이메일 가져오기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사용자 채팅'), // 앱바 제목 설정
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.white, // 배경색을 하얀색으로 설정
              child: StreamBuilder(
                stream: _firestore
                    .collection('InquireChatRooms')
                    .doc(userEmail) // 사용자 이메일을 사용하여 해당 사용자의 채팅 목록 가져오기
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(), // Firestore 스트림을 사용하여 실시간 업데이트를 수신함
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
                      bool isUser = message['sender'] ==
                          userEmail; // 메시지의 발신자가 사용자 본인인지 확인
                      return _buildMessageBubble(
                          message['text'], message['sender'], isUser);
                    },
                  );
                },
              ),
            ),
          ),
          Divider(height: 1.0), // 구분선 추가
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // 테마의 카드 색상으로 배경색 설정
            ),
            child: _buildTextComposer(), // 메시지 입력 필드 및 전송 버튼 위젯 호출
          ),
        ],
      ),
    );
  }

  // 메시지 버블을 구성하는 위젯
  Widget _buildMessageBubble(String text, String sender, bool isUser) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start, // 사용자 메시지는 오른쪽, 관리자 메시지는 왼쪽 정렬
        children: <Widget>[
          Material(
            borderRadius: BorderRadius.circular(10.0),
            elevation: 5.0,
            color: isUser ? Colors.blueAccent : Colors.grey[300],
            // 사용자 메시지는 파란색, 관리자 메시지는 회색
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.75, // 말풍선의 최대 너비를 화면의 75%로 설정
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start, // 사용자 메시지는 오른쪽, 관리자 메시지는 왼쪽 정렬
                children: <Widget>[
                  Text(
                    text,
                    style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontSize: 15.0), // 텍스트 색상과 크기 설정
                  ),
                  SizedBox(height: 5.0),
                  Text(
                    sender,
                    style: TextStyle(
                        color: isUser ? Colors.white60 : Colors.black54,
                        fontSize: 12.0), // 발신자 색상과 크기 설정
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
  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(
          color: Theme.of(context).colorScheme.secondary), // 테마에서 아이콘 색상 가져오기
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
    if (userEmail != null) {
      // 사용자 이메일이 null이 아닌 경우
      _firestore
          .collection('InquireChatRooms')
          .doc(userEmail)
          .collection('messages')
          .add({
        'text': text, // 메시지 내용
        'sender': userEmail, // 발신자 이메일
        'timestamp': Timestamp.now(), // 타임스탬프
      }).then((_) {
        // 사용자가 메시지를 보낸 후, 해당 채팅방의 hasNewMessage 필드를 true로 업데이트하여 관리자에게 알림을 보냅니다.
        _firestore
            .collection('InquireChatRooms')
            .doc(userEmail)
            .update({'hasNewMessage': true});
      });
    }
  }
}
