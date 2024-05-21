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
        actions: [
          IconButton(
            onPressed: () => _showCreateChatRoomDialog(context),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('CHATROOMS')
            .where('USERLIST', arrayContains: userId)
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
              final peerId = (chatRoom['USERLIST'] as List)
                  .firstWhere((id) => id != userId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('USERLIST').doc(peerId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const ListTile(title: Text('로딩 중...'));
                  }

                  final peerName = snapshot.data!['name'];

                  return ListTile(
                    title: Text(peerName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userId: userId,
                            peerId: peerId,
                            chatRoomId: chatRoom.id, // chatRoomId 추가
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateChatRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('USERLIST').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs.where((doc) => doc.id != userId).toList();

            return _CreateChatRoomDialog(userId: userId, users: users);
          },
        );
      },
    );
  }
}

class _CreateChatRoomDialog extends StatefulWidget {
  const _CreateChatRoomDialog({required this.userId, required this.users, super.key});
  final String userId;
  final List<QueryDocumentSnapshot> users;

  @override
  State<_CreateChatRoomDialog> createState() => __CreateChatRoomDialogState();
}

class __CreateChatRoomDialogState extends State<_CreateChatRoomDialog> {
  final List<String> _selectedUserIds = [];
  final Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    for (var user in widget.users) {
      _userNames[user.id] = user['name'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('채팅방 생성'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.users.map((user) {
            final userId = user.id;
            final userName = user['name'];
            return CheckboxListTile(
              title: Text(userName),
              value: _selectedUserIds.contains(userId),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedUserIds.add(userId);
                  } else {
                    _selectedUserIds.remove(userId);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _createChatRoom,
          child: const Text('생성'),
        ),
      ],
    );
  }

  void _createChatRoom() {
    if (_selectedUserIds.isNotEmpty) {
      final chatRoomId = FirebaseFirestore.instance.collection('CHATROOMS').doc().id;
      final userList = [widget.userId, ..._selectedUserIds];

      FirebaseFirestore.instance.collection('CHATROOMS').doc(chatRoomId).set({
        'USERLIST': userList,
        'id': chatRoomId,
      });

      Navigator.of(context).pop();
    }
  }
}
