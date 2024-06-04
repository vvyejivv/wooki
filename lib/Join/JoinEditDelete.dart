import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../firebase_options.dart';
import '../map/MapMain.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // SharedPreferences를 사용하여 세션에서 사용자 이메일 가져오기
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userEmail = prefs.getString('email'); // 세션에서 사용자 이메일 가져오기

  if (userEmail != null) {
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
        .collection('USERLIST')
        .doc(userEmail)
        .get();

    bool isAdmin = userDoc.data()?['IsAdmin'] ?? false;

    runApp(UserEditApp(user: userDoc, isAdmin: isAdmin));
  } else {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('User email not found in session'),
        ),
      ),
    ));
  }
}

class UserEditApp extends StatelessWidget {
  final DocumentSnapshot user;
  final bool isAdmin;

  const UserEditApp({required this.user, required this.isAdmin, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(user: user, isAdmin: isAdmin),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final DocumentSnapshot user;
  final bool isAdmin;

  const HomeScreen({required this.user, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return isAdmin ? UserListScreen(user: user) : UserEditScreen(user: user);
  }
}

class UserListScreen extends StatelessWidget {
  final DocumentSnapshot user;

  UserListScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 253, 239),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(userId: user['email']),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color.fromARGB(255, 255, 253, 239),
        title: Text('사용자 목록'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('USERLIST').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          }

          final users = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>).containsKey('name'))
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userName = user['name'];
              final userEmail = user['email'];

              return ListTile(
                title: Text(userName),
                subtitle: Text(userEmail),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserEditScreen(user: user),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class UserEditScreen extends StatefulWidget {
  final DocumentSnapshot user;

  UserEditScreen({required this.user});

  @override
  _UserEditScreenState createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late String _imageURL;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'];
    _emailController.text = widget.user['email'];
    _phoneController.text = widget.user['phone'];
    _passwordController.text = widget.user['pwd'];
    _imageURL = widget.user['imagePath'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageURL = pickedFile.path;
      });
    }
  }

  void _updateUser() async {
    try {
      await FirebaseFirestore.instance.collection('USERLIST').doc(widget.user.id).update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'pwd': _passwordController.text,
        'imagePath': _imageURL,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정보가 업데이트되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업데이트 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _deleteUser() async {
    try {
      await FirebaseFirestore.instance.collection('USERLIST').doc(widget.user.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자가 삭제되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 253, 239),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(userId: widget.user['email']),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color.fromARGB(255, 255, 253, 239),
        title: Text('사용자 정보 수정'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteUser,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  _pickImage();
                },
                child: _imageURL.isNotEmpty
                    ? ClipOval(
                  child: _imageURL.startsWith('http')
                      ? Image.network(
                    _imageURL,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    File(_imageURL),
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                )
                    : Icon(Icons.add_a_photo, size: 150),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUser,
                child: Text('업데이트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(255, 219, 28, 1),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _deleteUser,
                child: Text('삭제'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(255, 219, 28, 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
