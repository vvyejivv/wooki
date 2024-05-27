import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Chat'), // 앱 바 제목 설정
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('chatMessages').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          List<ChatMessage> chatMessages = snapshot.data!.docs.map((doc) {
            return ChatMessage(
              userName: doc['userName'],
              message: doc['message'],
            );
          }).toList();

          return ListView.builder(
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(chatMessages[index].userName),
                subtitle: Text(chatMessages[index].message),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReplyScreen()),
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

class ChatMessage {
  final String userName;
  final String message;

  ChatMessage({required this.userName, required this.message});
}

class ReplyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reply to User'), // 앱 바 제목 설정
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message from User:', // 사용자로부터의 메시지 표시
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec convallis justo vitae nunc varius fringilla.', // 사용자의 메시지 내용
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your reply...', // 답장 입력 필드 힌트
                border: OutlineInputBorder(), // 테두리 스타일 설정
              ),
              maxLines: 4, // 여러 줄의 텍스트 입력을 허용
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 답장 전송 기능 추가
              },
              child: Text('Send Reply'), // 답장 전송 버튼 텍스트
            ),
          ],
        ),
      ),
    );
  }
}
