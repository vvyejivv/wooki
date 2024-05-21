import 'package:flutter/material.dart';


class Session with ChangeNotifier {
  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void login(String username, String email, String phone) {
    _user = User(username: username, email : email, phone : phone);
    notifyListeners();
    print('세션 정보가 저장되었습니다: ${_user!.getUsername}, ${_user!.getEmail}, ${_user!.getPhone}');

  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
class User {
  final String username;
  final String email;
  final String phone;

  User({required this.username, required this.email, required this.phone});
  String get getUsername => username;
  String get getEmail => email;
  String get getPhone => phone;
}