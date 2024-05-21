import 'package:flutter/material.dart';
import 'ChatRoomListPage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인 페이지'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomListPage(userId: 'user1'),
                  ),
                );
              },
              child: const Text('User1로 로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomListPage(userId: 'user2'),
                  ),
                );
              },
              child: const Text('User2로 로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomListPage(userId: 'user3'),
                  ),
                );
              },
              child: const Text('User3로 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
