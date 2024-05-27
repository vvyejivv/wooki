import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ChatPage.dart';
import 'LoginPage.dart';
import '../map/MapMain.dart';

class ChatRoomListPage extends StatelessWidget {
  const ChatRoomListPage({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapScreen(userId: userId,)),
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white,),
        ),
        title: const Text('채팅방 목록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),),
        actions: [
          IconButton(
            onPressed: () => _showCreateChatRoomDialog(context),
            icon: const Icon(Icons.add, color: Colors.white,),
          ),
        ],
        backgroundColor: const Color.fromRGBO(109, 96, 90, 1),
      ),
      body: Container(
        color: const Color.fromRGBO(255, 253, 239, 1),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('CHATROOMS')
              .where('USERLIST', arrayContains: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('현재 입장한 채팅방이 없어요!'));
            }

            final chatRooms = snapshot.data!.docs;

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _getSortedChatRooms(chatRooms),
              builder: (context, sortedSnapshot) {
                if (!sortedSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sortedChatRooms = sortedSnapshot.data!;

                return ListView.builder(
                  itemCount: sortedChatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = sortedChatRooms[index]['chatRoom'];
                    final recentMessage = sortedSnapshot.data![index]['recentMessage'];

                    String recentMessageText = '대화 내용이 없습니다.';
                    String recentMessageTime = '';
                    if (recentMessage != null) {
                      final data = recentMessage.data() as Map<String, dynamic>;
                      recentMessageText = _getMessageText(data);
                      recentMessageTime = _formatTimestamp(data['createdAt']);
                    }

                    return GestureDetector(
                      onLongPress: () => _showChatRoomSettingsDialog(context, chatRoom.id, chatRoom['roomName']),
                      child: ListTile(
                        title: Text(chatRoom['roomName'], style: TextStyle(fontWeight: FontWeight.w600),),
                        subtitle: Text(recentMessageText),
                        trailing: Text(recentMessageTime),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                userId: userId,
                                roomName: chatRoom['roomName'],
                                chatRoomId: chatRoom.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getSortedChatRooms(List<DocumentSnapshot> chatRooms) async {
    List<Map<String, dynamic>> chatRoomsWithRecentMessages = [];

    for (var chatRoom in chatRooms) {
      final recentMessageSnapshot = await FirebaseFirestore.instance.collection('CHATROOMS')
          .doc(chatRoom.id)
          .collection('MESSAGES')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      final recentMessage = recentMessageSnapshot.docs.isNotEmpty
          ? recentMessageSnapshot.docs.first
          : null;

      chatRoomsWithRecentMessages.add({
        'chatRoom': chatRoom,
        'recentMessage': recentMessage,
      });
    }

    chatRoomsWithRecentMessages.sort((a, b) {
      final aTimestamp = a['recentMessage']?.data()?['createdAt'] ?? 0;
      final bTimestamp = b['recentMessage']?.data()?['createdAt'] ?? 0;
      return bTimestamp.compareTo(aTimestamp);
    });

    return chatRoomsWithRecentMessages;
  }

  String _getMessageText(Map<String, dynamic> messageData) {
    switch (messageData['type']) {
      case 'text':
        return messageData['text'].length > 30
            ? messageData['text'].substring(0, 30) + '...'
            : messageData['text'];
      case 'image':
        return '사진을 보냈습니다.';
      case 'file':
        return '파일: ${messageData['name']}';
      default:
        return '알 수 없는 메시지 유형입니다.';
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return DateFormat.Hm().format(date); // 오늘 메시지면 시간만 표시
    } else {
      return DateFormat.yMd().format(date); // 다른 날 메시지면 날짜만 표시
    }
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

  void _showChatRoomSettingsDialog(BuildContext context, String chatRoomId, String peerNames) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('채팅방 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('채팅방 이름 수정'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditChatRoomNameDialog(context, chatRoomId, peerNames);
                },
              ),
              ListTile(
                title: const Text('채팅방 나가기'),
                onTap: () {
                  Navigator.of(context).pop();
                  _leaveChatRoom(context, chatRoomId);
                },
              ),
            ],
          ),
          backgroundColor: Color(0xffECEAE9),
        );
      },
    );
  }

  void _showEditChatRoomNameDialog(BuildContext context, String chatRoomId, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('채팅방 이름 수정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '새 채팅방 이름'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('CHATROOMS').doc(chatRoomId).update({
                  'roomName': controller.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  void _leaveChatRoom(BuildContext context, String chatRoomId) async {
    final chatRoomDoc = FirebaseFirestore.instance.collection('CHATROOMS').doc(chatRoomId);
    final chatRoomSnapshot = await chatRoomDoc.get();
    final userList = List<String>.from(chatRoomSnapshot['USERLIST']);

    // 현재 사용자의 이름을 가져오기
    final userSnapshot = await FirebaseFirestore.instance.collection('USERLIST').doc(userId).get();
    final userName = userSnapshot['name'];

    if (userList.length == 1) {
      await chatRoomDoc.delete();
    } else {
      userList.remove(userId);
      await chatRoomDoc.update({'USERLIST': userList});
      FirebaseFirestore.instance.collection('CHATROOMS').doc(chatRoomId).collection('MESSAGES').add({
        'text': '$userName님이 채팅방에서 나가셨어요.',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'type': 'system',
      });
    }
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
  final Map<String, dynamic> _userNames = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('채팅방 생성'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.users.map((user) {
            final userId = user.id;
            final userData = user.data() as Map<String, dynamic>;
            final userName = userData.containsKey('name') ? userData['name'] : 'Unknown';
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
              checkColor: Color(0xffFFDB1C),
              activeColor: Color(0xff6D605A),
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
          onPressed: () => _createChatRoom(context),
          child: const Text('생성'),
        ),
      ],
      backgroundColor: Color(0xffECEAE9),
    );
  }

  void _createChatRoom(BuildContext context) async {
    if (_selectedUserIds.isNotEmpty) {
      final chatRoomId = FirebaseFirestore.instance.collection('CHATROOMS').doc().id;
      final userList = [widget.userId, ..._selectedUserIds].where((id) => id != null).toList();
      final roomName = userList.map((id) => _userNames[id] ?? '').where((name) => name.isNotEmpty).join(', ');

      // 중복 체크
      final existingRooms = await FirebaseFirestore.instance.collection('CHATROOMS')
          .where('USERLIST', arrayContains: widget.userId)
          .get();

      bool isDuplicate = false;
      for (var room in existingRooms.docs) {
        final existingUserList = List<String>.from(room['USERLIST']);
        if (existingUserList.length == userList.length && existingUserList.every((id) => userList.contains(id))) {
          isDuplicate = true;
          break;
        }
      }

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미 있는 채팅방이에요!'))
        );
      } else {
        await FirebaseFirestore.instance.collection('CHATROOMS').doc(chatRoomId).set({
          'USERLIST': userList,
          'id': chatRoomId,
          'roomName': roomName,
        });

        Navigator.of(context).pop();
      }
    }
  }
}
