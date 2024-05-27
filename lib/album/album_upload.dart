import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'album_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SnsAddApp());
}

class SnsAddApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SNS Add',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SnsAdd(),
    );
  }
}

class SnsAdd extends StatefulWidget {
  @override
  _SnsAddState createState() => _SnsAddState();
}

class _SnsAddState extends State<SnsAdd> {
  final TextEditingController _contentCtrl = TextEditingController();
  List<File> _images = [];
  int _currentIndex = 0;

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _images = result.paths.map((path) => File(path!)).toList();
      });
    } else {
      print('이미지 선택 안됨');
    }
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
                title: Text('게시글 작성'),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _images.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.grey[800],
                      size: 50,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '사진 올리기',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '(클릭하여 사진 추가)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    PageView.builder(
                      itemCount: _images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        color: Colors.black54,
                        child: Text(
                          '${_currentIndex + 1}/${_images.length}',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentCtrl,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                upload();
              },
              child: Text('업로드'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> upload() async {
    final content = _contentCtrl.text.trim();
    const email = "test24@kakao.com"; // 하드코딩된 이메일

    if (content.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('값 다 넣어라')));
      return;
    }

    List<String> imageUrls = [];
    for (var image in _images) {
      var imageUrl = await _uploadImage(image);
      imageUrls.add(imageUrl);
    }

    await FirebaseFirestore.instance.collection('posts').add({
      'email': email,
      'content': content,
      'imageUrls': imageUrls,
      'cdatetime': FieldValue.serverTimestamp(), // 현재 시간 저장
    });

    // 작성된 게시글 및 이미지 초기화
    _contentCtrl.clear();
    setState(() {
      _images = [];
      _currentIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 되었습니다!')));
  }

  Future<String> _uploadImage(File image) async {
    final ref = firebase_storage.FirebaseStorage.instance.ref().child('sns/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = ref.putFile(image);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
