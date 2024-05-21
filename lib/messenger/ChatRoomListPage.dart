import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ChatPage.dart';

class ChatRoomListPage extends StatelessWidget {
  const ChatRoomListPage({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방 목록'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatrooms')
            .where('users', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('현재 입장한 채팅방이 존재하지 않아요!'));
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final peerId = (chatRoom['users'] as List)
                  .firstWhere((id) => id != userId);

              return ListTile(
                title: Text(peerId),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userId: userId,
                        peerId: peerId,
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
