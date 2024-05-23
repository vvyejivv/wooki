import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchId with ChangeNotifier {
  Find? _find;
  Find? get find => _find;
  bool _isSearch = false;
  bool get isSearch => _isSearch;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Future<void> search(String phone) async {
    var checkId = await _fs.collection('USERLIST')
        .where('phone', isEqualTo: phone)
        .get();

    if (checkId.docs.isNotEmpty) {
      var doc = checkId.docs.first;
      _isSearch = true;
      _find = Find(
          email: doc['email'],
          name: doc['name'],
          phone: doc['phone']
      );
    } else {
      _isSearch = false;
      _find = null;
    }

    notifyListeners();
  }
}

class Find {
  final String email;
  final String name;
  final String phone;

  Find({required this.email, required this.name , required this.phone});
}