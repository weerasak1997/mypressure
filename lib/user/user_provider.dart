import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _user_data = 'Guest';
  List<double> _sysData = [];

  String get user => _user_data;
  List<double> get sysData => _sysData;

  void setUser(String name) {
    _user_data = name;
    notifyListeners();
  }
}
