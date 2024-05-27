import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 intl 패키지 추가
import 'album_upload.dart';

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

  void _showCommentSheet(BuildContext context, String postId, String email, String content, List<String> imageUrls, String cdatetime) {
    PageController pageController = PageController();
    TextEditingController _commentController = TextEditingController();

    showModalBottomSheet(
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
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              } else {
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(snapshot.data!),
                                      subtitle: Text(cdatetime),
                                    ),
                                    Container(
                                      height: 300,  // 이미지가 더 크게 보이도록 높이를 늘림
                                      child: Stack(
                                        children: [
                                          PageView.builder(
                                            controller: pageController,
                                            itemCount: imageUrls.length,
                                            itemBuilder: (context, index) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
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
                                return Center(child: Text('댓글 불러오기 오류: ${snapshot.error}'));
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              final comments = snapshot.data!.docs;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(), // 리스트뷰 자체의 스크롤을 막음
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final commentContent = comment['comment'];
                                  final commentEmail = comment['email'];
                                  final commentTimestamp = (comment['timestamp'] as Timestamp).toDate();
                                  final commentDate = DateFormat('yyyy-MM-dd HH:mm').format(commentTimestamp);

                                  return FutureBuilder<String>(
                                    future: _getUserName(commentEmail),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(child: Text('Error: ${snapshot.error}'));
                                      } else {
                                        return ListTile(
                                          title: Text(snapshot.data!),
                                          subtitle: Text(commentContent),
                                          trailing: Text(commentDate, style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    // 댓글 전송 기능 추가
                    String comment = _commentController.text.trim();
                    if (comment.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .add({
                        'email': 'vvyejivv@gmail.com',
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
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 40), // AppBar 높이 + 공백 높이
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: 10), // AppBar 위에 공백 추가
              AppBar(
                title: Text('게시글 목록'),
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
                automaticallyImplyLeading: false, // 공백 때문에 leading padding 제거
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                            return Text(
                              snapshot.data!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
                      Text(
                        '게시일: $formattedDate',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _showCommentSheet(context, postId, email, content, imageUrls, formattedDate);
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
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.star_border,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.share,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
