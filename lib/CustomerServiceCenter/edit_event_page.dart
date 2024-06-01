import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditEventPage extends StatelessWidget {
  final DocumentSnapshot event; // 수정할 이벤트 정보
  final bool isAdmin; // 관리자 여부

  const EditEventPage({required this.event, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    // 이벤트 이름을 편집하기 위한 컨트롤러
    final TextEditingController eventNameController = TextEditingController(text: event['eventName']);
    // 이벤트 설명을 편집하기 위한 컨트롤러
    final TextEditingController descriptionController = TextEditingController(text: event['description']);
    // 이미지 URL을 편집하기 위한 컨트롤러
    final TextEditingController imageUrlController = TextEditingController(text: event['imageUrl']);
    // 현재 이미지 URL
    String _imageUrl = event['imageUrl'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Center(child: Text('이벤트 수정')), // 이벤트 수정 텍스트를 가운데 정렬
            pinned: true, // 스크롤 할 때 항상 보이도록 설정
            leading: IconButton( // 뒤로가기 아이콘
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context); // 이전 화면으로 이동
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  SizedBox(height: 16.0),
                  Text(
                    '이벤트 정보',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    '이벤트 이름',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    event['eventName'], // 기존 이벤트 이름 표시
                  ),
                  Divider(),
                  Text(
                    '이벤트 설명',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    event['description'], // 기존 이벤트 설명 표시
                  ),
                  Divider(),
                  SizedBox(height: 20.0),

                  if (isAdmin) // 관리자인 경우에만 입력 필드 표시
                    TextField(
                      controller: eventNameController,
                      decoration: InputDecoration(labelText: '이벤트 이름'),
                    ),
                  if (isAdmin) // 관리자인 경우에만 입력 필드 표시
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: '이벤트 설명'),
                    ),
                  SizedBox(height: 16.0),
                  if (isAdmin) // 관리자인 경우에만 이미지 입력 필드 표시
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imageUrlController,
                            decoration: InputDecoration(labelText: '이미지 URL'),
                            onChanged: (value) {
                              _imageUrl = value;
                            },
                          ),
                        ),
                        SizedBox(width: 16.0),
                        if (_imageUrl.isNotEmpty)
                          Image.network(
                            _imageUrl,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  if (!isAdmin) // 사용자인 경우에는 내용만 보여줌
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '이미지 URL',
                              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
                            ),
                            SizedBox(height: 8.0),
                            Image.network(
                              _imageUrl,
                              height: 300,
                              width: 400,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ],
                    ),
                  Divider(),
                  if (_imageUrl.isNotEmpty)
                    if (isAdmin) // 관리자인 경우에만 수정 및 삭제 버튼 표시
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('이벤트 삭제'),
                                    content: Text('이벤트를 삭제하시겠습니까?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('취소'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          event.reference.delete(); // 이벤트 삭제
                                          Navigator.of(context).pop(); // 다이얼로그 닫기
                                        },
                                        child: Text('예'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Text('삭제하기'),
                          ),
                          SizedBox(width: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              event.reference.update({
                                'eventName': eventNameController.text,
                                'description': descriptionController.text,
                                'imageUrl': imageUrlController.text,
                              }); // 이벤트 정보 업데이트
                              Navigator.pop(context); // 이전 화면으로 돌아가기
                            },
                            child: Text('수정'),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
