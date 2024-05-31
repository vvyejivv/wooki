import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditEventPage extends StatelessWidget {
  final DocumentSnapshot event;
  final bool isAdmin;

  const EditEventPage({required this.event, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final TextEditingController eventNameController =
    TextEditingController(text: event['eventName']);
    final TextEditingController descriptionController =
    TextEditingController(text: event['description']);
    final TextEditingController imageUrlController =
    TextEditingController(text: event['imageUrl']);

    String _imageUrl = event['imageUrl'];

    return Scaffold(
      appBar: AppBar(
        title: Text('이벤트 수정'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        style: TextStyle(fontWeight: FontWeight.bold),
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
            SizedBox(height: 16.0),
                  Text(
                    '이벤트 이름',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    event['eventName'],
                  ),
                  Divider(),
                  Text(
                    '이벤트 설명',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    event['description'],
                  ),
                  Divider(),
                  if (_imageUrl.isNotEmpty)

            if (isAdmin) // 관리자인 경우에만 수정 및 삭제 버튼 표시
              Row(
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
                                  event.reference.delete();
                                  Navigator.of(context).pop();
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
                      });
                      Navigator.pop(context);
                    },
                    child: Text('수정'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
