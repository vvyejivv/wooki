import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../map/MapMain.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('임시 로그인 페이지'),
      ),
      body: Center(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('USERLIST').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('사용자가 없습니다.');
            }

            final users = snapshot.data!.docs;

            return ListView(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: users.map((user) {
                    final userData = user.data() as Map<String, dynamic>;

                    if (!userData.containsKey('name')) {
                      return const SizedBox.shrink(); // name 필드가 없으면 빈 위젯 반환
                    }

                    final name = userData['name'];
                    final userId = user.id;

                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(userId: userId),
                          ),
                        );
                      },
                      child: Text('$name(으)로 로그인'),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
