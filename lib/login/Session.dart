import 'package:flutter/material.dart';

class Session with ChangeNotifier {
  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void login(String username, String email, String phone) {
    _user = User(username: username, email : email, phone : phone);
    notifyListeners();
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
}