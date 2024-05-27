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
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.userId);
    _scrollController = ScrollController();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    FirebaseFirestore.instance.collection('CHATROOMS')
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
                  child: Text('사진', style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.normal)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('파일'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('취소'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('files/${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}');
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
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
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
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

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
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

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
        final data = doc.data() as Map<String, dynamic>;
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

  Future<List<String>> _getParticipants() async {
    final chatRoomDoc = await FirebaseFirestore.instance.collection('CHATROOMS')
        .doc(widget.chatRoomId)
        .get();

    final userEmails = List<String>.from(chatRoomDoc['USERLIST']);

    final userDocs = await Future.wait(
        userEmails.map((userEmail) => FirebaseFirestore.instance.collection('USERLIST').where('email', isEqualTo: userEmail).get())
    );

    return userDocs.map((userQuery) => userQuery.docs.first['name'] as String).toList();
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatRoomListPage(userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.roomName),
      backgroundColor: const Color.fromRGBO(255, 253, 239, 1),
    ),
    drawer: Drawer(
      backgroundColor: Color(0xffFFFDEF),
      child: FutureBuilder<List<String>>(
        future: _getParticipants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('사람이 없어요!'));
          }
          final participants = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: participants.map((participant) => Container(
                    color: Color(0xff6D605A),
                    child: ListTile(
                      textColor: Colors.white,
                      title: Text(participant, style: TextStyle(fontWeight: FontWeight.w600)),
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
        backgroundColor: Color.fromRGBO(255, 253, 239, 1),
        primaryColor: Color.fromRGBO(109, 96, 90, 1),
        secondaryColor: Color.fromRGBO(236, 234, 233, 1),
        userAvatarImageBackgroundColor: Color.fromRGBO(168, 152, 145, 1),
      ),
      customMessageBuilder: (message, {required int messageWidth}) {
        if (message is types.CustomMessage && message.metadata != null) {
          final text = message.metadata!['text'] as String;
          return Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.black),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    ),
  );
}
