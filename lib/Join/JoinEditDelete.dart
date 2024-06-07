import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../firebase_options.dart';
import '../map/MapMain.dart';
import '../CustomerServiceCenter/main.dart';
import '../main.dart';

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
                builder: (context) => MapScreen(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color.fromARGB(255, 255, 253, 239),
        title: Text('사용자 목록', style: TextStyle(fontWeight: FontWeight.w600),),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            color: Colors.grey,
          ),
        ),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Customer(),
                )
            );
          }, icon: Icon(Icons.help))
        ],
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  late String _imageURL;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'];
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
    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('USERLIST').doc(widget.user.id).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'pwd': _passwordController.text,
        'imagePath': _imageURL,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('정보가 업데이트되었습니다.')),
      );

      if (mounted) { // Check if the widget is still mounted
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MapScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }


  void _deleteUser() async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Barrier',
      transitionDuration: Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        final TextEditingController _emailController = TextEditingController();
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 253, 239),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '정말 탈퇴하시겠습니까?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  Text('현재 유저의 이메일을 입력하세요:'),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_emailController.text == widget.user['email']) {
                            try {
                              await FirebaseFirestore.instance.collection('USERLIST').doc(widget.user.id).delete();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FirstMain(),
                                  )
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('탈퇴 중 오류가 발생했습니다: $e')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('이메일이 일치하지 않습니다.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFE458),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text('예', style: TextStyle(color: Color(0xFF3A281F), fontWeight: FontWeight.bold),),
                      ),
                      SizedBox(width: 15), // 버튼 간의 간격을 좁히기 위해 설정
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6D605A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text('아니오', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                builder: (context) => MapScreen(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color.fromARGB(255, 255, 253, 239),
        title: Text('사용자 정보 수정', style: TextStyle(fontWeight: FontWeight.w600),),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            color: Colors.grey,
          ),
        ),
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
                  border: UnderlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  border: UnderlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: UnderlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordConfirmController,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  border: UnderlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _updateUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 50), // 버튼 크기 조정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // 둥근 모서리 직사각형
                      ),
                      backgroundColor: Color(0xFFFFE458),
                    ),
                    child: Text('업데이트', style: TextStyle(color: Color(0xFF3A281F), fontWeight: FontWeight.w600, fontSize: 15),),
                  ),
                  SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: _deleteUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(100, 50), // 버튼 크기 조정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // 둥근 모서리 직사각형
                      ),
                      backgroundColor: Color(0xFF6D605A),
                    ),
                    child: Text('탈퇴', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
