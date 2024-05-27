import 'package:flutter/material.dart';
import 'message_tile.dart';
import 'messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ChatScreen 위젯을 정의합니다. StatefulWidget을 사용하여 상태를 가질 수 있도록 합니다.
class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

// ChatScreen의 상태 클래스입니다.
class _ChatScreenState extends State<ChatScreen> {
  // 초기화 메서드입니다. 위젯이 생성될 때 한 번 호출됩니다.
  @override
  void initState() {
    super.initState();
  }

  // 세션에서 사용자 ID를 가져오는 비동기 함수입니다.
  Future<String> getUserIdFromSession() async {
    // SharedPreferences 인스턴스를 가져옵니다.
    final prefs = await SharedPreferences.getInstance();
    // 'userId' 키로 저장된 값을 반환합니다. 값이 없을 경우 기본값은 'user1'입니다.
    return prefs.getString('userId') ?? 'user1';
  }

  // 메시지를 입력받기 위한 컨트롤러입니다.
  final TextEditingController _messageController = TextEditingController();
  // 메시징 서비스를 사용하기 위한 인스턴스입니다.
  final MessagingService _messagingService = MessagingService();

  // 메시지를 보내는 비동기 함수입니다.
  Future<void> _sendMessage() async {
    // 비동기적으로 사용자 ID를 가져옵니다.
    String userId = await getUserIdFromSession();
    // 입력된 메시지가 비어있지 않으면 메시지를 보냅니다.
    if (_messageController.text.isNotEmpty) {
      // MessagingService를 사용하여 메시지를 전송합니다.
      _messagingService.sendMessage(userId, _messageController.text);
      // 메시지 입력 필드를 비웁니다.
      _messageController.clear();
    }
  }

  // UI를 빌드하는 메서드입니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Room"), // 앱 바의 제목을 설정합니다.
      ),
      body: Column(
        children: [
          // 메시지 리스트를 표시하는 영역입니다.
          Expanded(
            child: StreamBuilder(
              // 메시지 스트림을 가져옵니다.
              stream: _messagingService.getMessageStream('admin'),
              builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasData) {
                  // 데이터가 있을 경우 메시지를 리스트로 표시합니다.
                  var messages = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) => MessageTile(message: messages[index]),
                  );
                } else if (snapshot.hasError) {
                  // 오류가 발생할 경우 오류 메시지를 표시합니다.
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('데이터를 불러오는 중 오류가 발생했습니다.'),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // 상태를 갱신하여 다시 시도합니다.
                          },
                          child: Text('재시도'),
                        ),
                      ],
                    ),
                  );
                }
                // 데이터가 로딩 중일 경우 로딩 인디케이터를 표시합니다.
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
          // 메시지를 입력하고 전송하는 영역입니다.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  // 메시지를 입력받는 TextField입니다.
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message", // 힌트 텍스트를 설정합니다.
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8), // 테두리 둥글기를 설정합니다.
                      ),
                    ),
                  ),
                ),
                // 메시지를 전송하는 버튼입니다.
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: _sendMessage, // 버튼이 눌리면 _sendMessage 함수를 호출합니다.
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// 사용자의 메시지에 답장하는 화면을 정의합니다.
class ReplyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reply to User'), // 앱 바의 제목을 설정합니다.
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message from User:', // 사용자의 메시지를 표시하는 레이블입니다.
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec convallis justo vitae nunc varius fringilla.',
              // 실제 사용자 메시지를 여기에 표시해야 합니다.
            ),
            SizedBox(height: 16),
            // 답장을 입력받는 TextField입니다.
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your reply...', // 힌트 텍스트를 설정합니다.
                border: OutlineInputBorder(),
              ),
              maxLines: 4, // 여러 줄 입력을 허용합니다.
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 답장을 전송하는 기능을 추가해야 합니다.
              },
              child: Text('Send Reply'), // 버튼의 텍스트를 설정합니다.
            ),
          ],
        ),
      ),
    );
  }
}
