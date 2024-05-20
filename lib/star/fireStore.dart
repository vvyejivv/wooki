import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp2());
}

class MyApp2 extends StatefulWidget {
  const MyApp2({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp2> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();

  void _addUser() async {
    if (_name.text.isNotEmpty && _age.text.isNotEmpty) {
      FirebaseFirestore fs = FirebaseFirestore.instance;
      CollectionReference users = fs.collection("users");

      await users.add({
        'name': _name.text,
        'age': int.parse(_age.text),
      });

      _name.clear();
      _age.clear();
    } else {
      print("이름 또는 나이 입력");
    }
  }

  void _updateUser() async{
    FirebaseFirestore fs = FirebaseFirestore.instance;
    CollectionReference users = fs.collection("users");

    QuerySnapshot snap = await users.where('name', isEqualTo: '홍길동').get();
    for(QueryDocumentSnapshot doc in snap.docs){
      users.doc(doc.id).update({'age' : 30});
    }
  }

  Widget _listUser(){
    return StreamBuilder(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snap){
          return ListView(

          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("firestore")),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: "이름",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _age,
                  decoration: InputDecoration(
                    labelText: "나이",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addUser,
                  child: Text("사용자 추가!"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateUser,
                  child: Text("사용자 수정!"),
                ),
                SizedBox(height: 20),
                Expanded(child: _listUser())
              ],
            ),
          ),
        ),
      ),
    );
  }
}