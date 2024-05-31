import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventPage extends StatefulWidget {
  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  // TextEditingController를 사용하여 각 필드의 텍스트를 관리합니다.
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  // 이미지 URL의 미리보기를 저장하는 변수입니다.
  String _imageUrlPreview = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이벤트 추가'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이벤트 이름을 입력하는 텍스트 필드입니다.
            TextField(
              controller: eventNameController,
              decoration: InputDecoration(labelText: '이벤트 이름'),
            ),
            // 이벤트 설명을 입력하는 텍스트 필드입니다.
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: '이벤트 설명'),
            ),
            SizedBox(height: 16.0),
            // 이미지 URL을 입력하는 텍스트 필드입니다.
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(labelText: '이미지 URL'),
              // 텍스트가 변경될 때마다 미리보기를 업데이트합니다.
              onChanged: (value) {
                setState(() {
                  _imageUrlPreview = value;
                });
              },
            ),
            SizedBox(height: 8.0),
            // 이미지 URL 미리보기를 표시합니다.
            if (_imageUrlPreview.isNotEmpty)
              Image.network(
                _imageUrlPreview,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 16.0),
            // '추가' 버튼을 누르면 Firestore에 이벤트를 추가합니다.
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('events').add({
                  'eventName': eventNameController.text,
                  'description': descriptionController.text,
                  'imageUrl': imageUrlController.text,
                });
                // 이전 화면으로 이동합니다.
                Navigator.pop(context);
              },
              child: Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}