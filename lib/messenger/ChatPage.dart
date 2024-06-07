import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'ChatRoomListPage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.userId,
    required this.roomName,
    required this.chatRoomId,
    super.key,
  });
  final String userId;
  final String roomName;
  final String chatRoomId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  late final types.User _user;
  Map<String, Map<String, String>> _participants = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko', null); // 로케일 데이터를 초기화합니다.
    _user = types.User(id: widget.userId);
    _loadMessages();
    _loadParticipants();
  }

  void _addMessage(types.Message message) {
    FirebaseFirestore.instance
        .collection('CHATROOMS')
        .doc(widget.chatRoomId)
        .collection('MESSAGES')
        .add(message.toJson());
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('사진', style: TextStyle(color: Color(0xFF3A281F))),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('파일', style: TextStyle(color: Color(0xFF3A281F))),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('취소', style: TextStyle(color: Color(0xFF3A281F))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDateTime(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateFormat dateFormat = DateFormat.yMMMMd('ko');
    return dateFormat.format(dateTime);
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('files/chatrooms/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}');
      await storageRef.putFile(file);

      final downloadUrl = await storageRef.getDownloadURL();

      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: downloadUrl,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final file = File(result.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('images/chatrooms/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(file);

      final downloadUrl = await storageRef.getDownloadURL();
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: downloadUrl,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(isLoading: true);

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(isLoading: null);

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection('CHATROOMS')
        .doc(widget.chatRoomId)
        .collection('MESSAGES')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['type'] == 'system') {
          return types.CustomMessage(
            author: types.User(id: ''),
            createdAt: data['createdAt'],
            id: doc.id,
            metadata: {'text': data['text']},
          );
        } else {
          return types.Message.fromJson(data);
        }
      }).toList();

      setState(() {
        _messages = messages;
      });
    });
  }

  Future<List<Map<String, String>>> _getParticipants() async {
    final chatRoomDoc = await FirebaseFirestore.instance
        .collection('CHATROOMS')
        .doc(widget.chatRoomId)
        .get();

    final userEmails = List<String>.from(chatRoomDoc['USERLIST']);

    final userDocs = await Future.wait(
        userEmails.map((userEmail) => FirebaseFirestore.instance
            .collection('USERLIST')
            .where('email', isEqualTo: userEmail)
            .get()));

    return userDocs.map((userQuery) {
      final userData = userQuery.docs.first.data();
      return {
        'email': userData['email'] as String,
        'name': userData['name'] as String,
        'imagePath': userData['imagePath'] as String,
      };
    }).toList();
  }

  Future<void> _loadParticipants() async {
    final participants = await _getParticipants();

    setState(() {
      _participants = {for (var user in participants) user['email']!: user};
    });
  }

  void _leaveChatRoom() async {
    final chatRoomDoc = FirebaseFirestore.instance.collection('CHATROOMS').doc(widget.chatRoomId);
    final chatRoomSnapshot = await chatRoomDoc.get();
    final userList = List<String>.from(chatRoomSnapshot['USERLIST']);

    // 현재 사용자의 이름을 가져오기
    final userQuery = await FirebaseFirestore.instance.collection('USERLIST').where('email', isEqualTo: widget.userId).get();
    final userName = userQuery.docs.first['name'];

    if (userList.length == 1) {
      await chatRoomDoc.delete();
    } else {
      userList.remove(widget.userId);
      await chatRoomDoc.update({'USERLIST': userList});
      FirebaseFirestore.instance.collection('CHATROOMS').doc(widget.chatRoomId).collection('MESSAGES').add({
        'text': '$userName님이 채팅방에서 나가셨어요.',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'type': 'system',
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatRoomListPage(userId: widget.userId)),
    );
  }

  Widget _customMessageBuilder(types.Message message, {required int messageWidth}) {
    if (message is types.CustomMessage && message.metadata != null) {
      final text = message.metadata!['text'] as String;
      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w500, color: Color(0xFF3A281F)),
            ),
            const SizedBox(height: 4),
            Text(
              formatDateTime(message.createdAt!), // 날짜 포맷팅 함수 적용
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _customBubbleBuilder(
      Widget child, {
        required types.Message message,
        required bool nextMessageInGroup,
      }) {
    if (message.author.id != _user.id) {
      final user = _participants[message.author.id];
      if (user != null) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user['imagePath']!),
              radius: 30, // 프로필 이미지 크기 조정
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // 상대방 메시지 배경색 설정
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(0.0), // 메시지 박스 패딩 조정
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(109, 96, 90, 1), // 본인의 메시지 배경색 설정
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(0.0), // 메시지 박스 패딩 조정
                  child: DefaultTextStyle(
                    style: TextStyle(color: Colors.white), // 본인의 메시지 글자색 설정
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.roomName, style: TextStyle(color: Color(0xff3A281F)),),
      backgroundColor: const Color(0xffFFFDEF),
      iconTheme: IconThemeData(color: Color(0xff3A281F)),
    ),
    drawer: Drawer(
      backgroundColor: Color(0xffFFFDEF),
      child: FutureBuilder<List<Map<String, String>>>(
        future: _getParticipants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              children: [
                Expanded(child: Center(child: Text('사람이 없어요!'))),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('방에서 나가기'),
                      onTap: _leaveChatRoom,
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: const Text('뒤로 가기'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ChatRoomListPage(userId: widget.userId)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          }
          final participants = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: participants.map((participant) => Container(
                    color: Color(0xffFFFDEF),
                    child: ListTile(
                      textColor: Color(0xff3A281F),
                      title: Text(participant['name']!, style: TextStyle(fontWeight: FontWeight.w600)),
                      leading: participant['imagePath'] != null
                          ? CircleAvatar(
                        backgroundImage: NetworkImage(participant['imagePath']!),
                      )
                          : CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('방에서 나가기'),
                    onTap: _leaveChatRoom,
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_back),
                    title: const Text('뒤로 가기'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ChatRoomListPage(userId: widget.userId)),
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
    body: Chat(
      messages: _messages,
      onAttachmentPressed: _handleAttachmentPressed,
      onMessageTap: _handleMessageTap,
      onSendPressed: _handleSendPressed,
      user: _user,
      l10n: const ChatL10nKo(
        inputPlaceholder: '대화를 입력하세요...',
        emptyChatPlaceholder: '주고받은 대화가 없어요!',
      ),
      theme: const DefaultChatTheme(
        inputBackgroundColor: Colors.white,
        inputTextColor: Colors.black,
        backgroundColor: Color(0xFFFFFDEF),
        primaryColor: Color(0xFF6D605A),
        secondaryColor: Color(0xFFECEAE9),
        userAvatarImageBackgroundColor: Color(0xFFA89891),
      ),
      customMessageBuilder: _customMessageBuilder,
      bubbleBuilder: _customBubbleBuilder,
    ),
  );
}
