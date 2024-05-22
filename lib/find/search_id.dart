import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchId with ChangeNotifier {
  bool _isSearch = false;
  bool get isSearch => _isSearch;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  Future<void> search(String phone) async {
    var checkId = await _fs.collection('USERLIST')
        .where('phone', isEqualTo: phone)
        .get();

    if (checkId.docs.isEmpty) {
      _isSearch = true;
    } else {
      _isSearch = false;
    }

    notifyListeners();
  }
}