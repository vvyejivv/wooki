import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'album_upload.dart';
import 'package:wooki/map/MapMain.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SnsApp());
}

class SnsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SNS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard', // 전체 앱에 적용될 기본 폰트 설정
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Pretendard'),
          bodyMedium: TextStyle(fontFamily: 'Pretendard'),
          bodySmall: TextStyle(fontFamily: 'Pretendard'),
          displayLarge: TextStyle(fontFamily: 'Pretendard'),
          displayMedium: TextStyle(fontFamily: 'Pretendard'),
          displaySmall: TextStyle(fontFamily: 'Pretendard'),
          headlineLarge: TextStyle(fontFamily: 'Pretendard'),
          headlineMedium: TextStyle(fontFamily: 'Pretendard'),
          headlineSmall: TextStyle(fontFamily: 'Pretendard'),
          titleLarge: TextStyle(fontFamily: 'Pretendard'),
          titleMedium: TextStyle(fontFamily: 'Pretendard'),
          titleSmall: TextStyle(fontFamily: 'Pretendard'),
          labelLarge: TextStyle(fontFamily: 'Pretendard'),
          labelMedium: TextStyle(fontFamily: 'Pretendard'),
          labelSmall: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
      home: PostListPage(),
    );
  }
}

class PostListPage extends StatefulWidget {
  @override
  _PostListPageState createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('email');
    });
  }

  Future<String> _getUserName(String email) async {
    var userDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      return userDoc.docs.first['name'];
    } else {
      return 'Unknown User';
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> downloadUrls = [];
    for (var image in images) {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('sns/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }
    return downloadUrls;
  }

  void _showCommentSheet(BuildContext context, String postId, String email,
      String content, List<String> imageUrls, String cdatetime) {
    PageController pageController = PageController();
    TextEditingController _commentController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: Color(0xfffffff6),
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          FutureBuilder<String>(
                            future: _getUserName(email),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else {
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(snapshot.data!),
                                      subtitle: Text(cdatetime),
                                      trailing: Transform.translate(
                                        offset: Offset(15, 0), // 오른쪽으로 더 붙이기
                                        child: IconButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // 모달 창 닫기
                                          },
                                          icon: Icon(Icons.close),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey), // 하단 테두리만 설정
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 300, // 이미지가 더 크게 보이도록 높이를 늘림
                                            child: Stack(
                                              children: [
                                                PageView.builder(
                                                  controller: pageController,
                                                  itemCount: imageUrls.length,
                                                  itemBuilder: (context, index) {
                                                    return ClipRRect(
                                                      child: Image.network(
                                                        imageUrls[index],
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: 300,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  bottom: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                    color: Colors.black54,
                                                    child: AnimatedBuilder(
                                                      animation: pageController,
                                                      builder: (context, child) {
                                                        return Text(
                                                          '${(pageController.page?.toInt() ?? 0) + 1}/${imageUrls.length}',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ListTile(
                                            title: Text(content),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                              }
                            },
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(postId)
                                .collection('comments')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                    child:
                                        Text('댓글 불러오기 오류: ${snapshot.error}'));
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              final comments = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                // 리스트뷰 자체의 스크롤을 막음
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final commentContent = comment['comment'];
                                  final commentEmail = comment['email'];
                                  final commentTimestamp =
                                      (comment['timestamp'] as Timestamp)
                                          .toDate();
                                  final commentDate =
                                      DateFormat('yyyy-MM-dd HH:mm')
                                          .format(commentTimestamp);

                                  return FutureBuilder<String>(
                                    future: _getUserName(commentEmail),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'));
                                      } else {
                                        return ListTile(
                                          title: Text(snapshot.data!),
                                          subtitle: Text(commentContent),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(commentDate,
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey)),
                                              if (commentEmail ==
                                                  _currentUserEmail) ...[
                                                IconButton(
                                                  icon: Icon(Icons.edit),
                                                  onPressed: () {
                                                    _editComment(
                                                        context,
                                                        postId,
                                                        comment.id,
                                                        commentContent);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete),
                                                  onPressed: () {
                                                    _confirmDeleteComment(
                                                        context,
                                                        postId,
                                                        comment.id);
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 32.0),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '   댓글을 입력하세요...',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey), // 기본 하단 테두리 색상
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey), // 비활성 상태 하단 테두리 색상
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber), // 활성 상태 하단 테두리 색상
                          ),
                          contentPadding: EdgeInsets.only(right: 48.0), // 텍스트와 버튼 간격 조절
                        ),
                        maxLines: 1,
                      ),
                      Positioned(
                        right: 0,
                        child: ElevatedButton(
                          onPressed: () async {
                            // 댓글 전송 기능 추가
                            String comment = _commentController.text.trim();
                            if (comment.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(postId)
                                  .collection('comments')
                                  .add({
                                'email': _currentUserEmail,
                                'comment': comment,
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                              _commentController.clear(); // 댓글 입력 후 입력 필드 초기화
                              FocusScope.of(context).unfocus(); // 입력 필드 포커스 해제
                            }
                          },
                          child: Text('작성'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteComment(
      BuildContext context, String postId, String commentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('댓글 삭제'),
          content: Text('댓글을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteComment(postId, commentId);
                Navigator.of(context).pop();
              },
              child: Text('삭제'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editComment(BuildContext context, String postId, String commentId,
      String currentContent) {
    TextEditingController _editCommentController =
        TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // 화면 너비의 90%
            height: 400, // 고정된 높이
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _editCommentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 수정하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 7,
                ),
                SizedBox(height: 16),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String editedComment =
                            _editCommentController.text.trim();
                        if (editedComment.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .collection('comments')
                              .doc(commentId)
                              .update({'comment': editedComment});
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text('수정'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteComment(String postId, String commentId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  void _editPost(BuildContext context, String postId, String currentContent,
      List<String> currentImageUrls) {
    TextEditingController _editPostController =
        TextEditingController(text: currentContent);
    List<File> newImages = [];
    List<String> newImageUrls = List.from(currentImageUrls);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _editPostController,
                          decoration: InputDecoration(
                            hintText: '게시글을 수정하세요...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 10,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: true,
                            );
                            if (result != null) {
                              setState(() {
                                newImages = result.paths
                                    .map((path) => File(path!))
                                    .toList();
                              });
                            }
                          },
                          child: Text('새로운 이미지 선택'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        if (newImages.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: newImages.map((image) {
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.file(
                                    image,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            String editedContent =
                                _editPostController.text.trim();
                            if (editedContent.isNotEmpty) {
                              if (newImages.isNotEmpty) {
                                newImageUrls = await _uploadImages(newImages);
                              }
                              await FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(postId)
                                  .update({
                                'content': editedContent,
                                'imageUrls': newImageUrls,
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text('수정'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('게시글 삭제'),
          content: Text('게시글을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePost(postId);
                Navigator.of(context).pop();
              },
              child: Text('삭제'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentUserEmail != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(userId: _currentUserEmail!),
                ),
              );
            }
          },
        ),
        backgroundColor: Color(0xff6D605A),
        title: Text(
          '게시글 목록',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SnsAdd()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFFFFDEF),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('cdatetime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('오류 발생: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data!.docs;

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final content = post['content'];
                final email = post['email'];
                final imageUrls = List<String>.from(post['imageUrls']);
                final cdatetime = (post['cdatetime'] as Timestamp).toDate();
                final formattedDate =
                    DateFormat('yyyy-MM-dd HH:mm').format(cdatetime); // 날짜 포맷팅
                final pageController = PageController();
                final postId = post.id; // Post ID 가져오기

                return Card(
                  color: Color(0xfffffff1),
                  margin: EdgeInsets.all(8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutureBuilder<String>(
                          future: _getUserName(email),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Row(
                                children: [
                                  Text(
                                    snapshot.data!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        SizedBox(height: 8),
                        Text(
                          content,
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showCommentSheet(context, postId, email, content,
                                imageUrls, formattedDate);
                          },
                          child: Stack(
                            children: [
                              Container(
                                height: 200,
                                child: PageView.builder(
                                  controller: pageController,
                                  itemCount: imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrls[index],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 200,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  color: Colors.black54,
                                  child: AnimatedBuilder(
                                    animation: pageController,
                                    builder: (context, child) {
                                      return Text(
                                        '${(pageController.page?.toInt() ?? 0) + 1}/${imageUrls.length}',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        if (email == _currentUserEmail) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(width: 2,),
                              IconButton(
                                icon:Icon(Icons.chat_bubble_outline),
                                color: Colors.grey,
                                onPressed: () {
                                  _showCommentSheet(context, postId, email, content,
                                      imageUrls, formattedDate);
                                },
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _editPost(
                                      context, postId, content, imageUrls);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _confirmDeletePost(context, postId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
